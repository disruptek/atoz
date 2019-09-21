
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddAttributesToFindings_602770 = ref object of OpenApiRestCall_602433
proc url_AddAttributesToFindings_602772(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddAttributesToFindings_602771(path: JsonNode; query: JsonNode;
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602899 = header.getOrDefault("X-Amz-Target")
  valid_602899 = validateParameter(valid_602899, JString, required = true, default = newJString(
      "InspectorService.AddAttributesToFindings"))
  if valid_602899 != nil:
    section.add "X-Amz-Target", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_AddAttributesToFindings_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AddAttributesToFindings_602770; body: JsonNode): Recallable =
  ## addAttributesToFindings
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var addAttributesToFindings* = Call_AddAttributesToFindings_602770(
    name: "addAttributesToFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.AddAttributesToFindings",
    validator: validate_AddAttributesToFindings_602771, base: "/",
    url: url_AddAttributesToFindings_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTarget_603039 = ref object of OpenApiRestCall_602433
proc url_CreateAssessmentTarget_603041(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssessmentTarget_603040(path: JsonNode; query: JsonNode;
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
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603044 = header.getOrDefault("X-Amz-Target")
  valid_603044 = validateParameter(valid_603044, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTarget"))
  if valid_603044 != nil:
    section.add "X-Amz-Target", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Content-Sha256", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Algorithm")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Algorithm", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-SignedHeaders", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Credential")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Credential", valid_603049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603051: Call_CreateAssessmentTarget_603039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CreateAssessmentTarget_603039; body: JsonNode): Recallable =
  ## createAssessmentTarget
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var createAssessmentTarget* = Call_CreateAssessmentTarget_603039(
    name: "createAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTarget",
    validator: validate_CreateAssessmentTarget_603040, base: "/",
    url: url_CreateAssessmentTarget_603041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTemplate_603054 = ref object of OpenApiRestCall_602433
proc url_CreateAssessmentTemplate_603056(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAssessmentTemplate_603055(path: JsonNode; query: JsonNode;
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
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603059 = header.getOrDefault("X-Amz-Target")
  valid_603059 = validateParameter(valid_603059, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTemplate"))
  if valid_603059 != nil:
    section.add "X-Amz-Target", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Content-Sha256", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-Algorithm")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Algorithm", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Signature", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-SignedHeaders", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Credential")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Credential", valid_603064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603066: Call_CreateAssessmentTemplate_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_CreateAssessmentTemplate_603054; body: JsonNode): Recallable =
  ## createAssessmentTemplate
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var createAssessmentTemplate* = Call_CreateAssessmentTemplate_603054(
    name: "createAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTemplate",
    validator: validate_CreateAssessmentTemplate_603055, base: "/",
    url: url_CreateAssessmentTemplate_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExclusionsPreview_603069 = ref object of OpenApiRestCall_602433
proc url_CreateExclusionsPreview_603071(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateExclusionsPreview_603070(path: JsonNode; query: JsonNode;
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
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603074 = header.getOrDefault("X-Amz-Target")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "InspectorService.CreateExclusionsPreview"))
  if valid_603074 != nil:
    section.add "X-Amz-Target", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Content-Sha256", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Algorithm")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Algorithm", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Signature")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Signature", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-SignedHeaders", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Credential")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Credential", valid_603079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603081: Call_CreateExclusionsPreview_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_CreateExclusionsPreview_603069; body: JsonNode): Recallable =
  ## createExclusionsPreview
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var createExclusionsPreview* = Call_CreateExclusionsPreview_603069(
    name: "createExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateExclusionsPreview",
    validator: validate_CreateExclusionsPreview_603070, base: "/",
    url: url_CreateExclusionsPreview_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceGroup_603084 = ref object of OpenApiRestCall_602433
proc url_CreateResourceGroup_603086(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateResourceGroup_603085(path: JsonNode; query: JsonNode;
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
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603089 = header.getOrDefault("X-Amz-Target")
  valid_603089 = validateParameter(valid_603089, JString, required = true, default = newJString(
      "InspectorService.CreateResourceGroup"))
  if valid_603089 != nil:
    section.add "X-Amz-Target", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Content-Sha256", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Signature", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-SignedHeaders", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Credential")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Credential", valid_603094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_CreateResourceGroup_603084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_CreateResourceGroup_603084; body: JsonNode): Recallable =
  ## createResourceGroup
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var createResourceGroup* = Call_CreateResourceGroup_603084(
    name: "createResourceGroup", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateResourceGroup",
    validator: validate_CreateResourceGroup_603085, base: "/",
    url: url_CreateResourceGroup_603086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentRun_603099 = ref object of OpenApiRestCall_602433
proc url_DeleteAssessmentRun_603101(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentRun_603100(path: JsonNode; query: JsonNode;
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603104 = header.getOrDefault("X-Amz-Target")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentRun"))
  if valid_603104 != nil:
    section.add "X-Amz-Target", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Content-Sha256", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Algorithm")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Algorithm", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Signature")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Signature", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Credential")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Credential", valid_603109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_DeleteAssessmentRun_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_DeleteAssessmentRun_603099; body: JsonNode): Recallable =
  ## deleteAssessmentRun
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var deleteAssessmentRun* = Call_DeleteAssessmentRun_603099(
    name: "deleteAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentRun",
    validator: validate_DeleteAssessmentRun_603100, base: "/",
    url: url_DeleteAssessmentRun_603101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTarget_603114 = ref object of OpenApiRestCall_602433
proc url_DeleteAssessmentTarget_603116(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentTarget_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603119 = header.getOrDefault("X-Amz-Target")
  valid_603119 = validateParameter(valid_603119, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTarget"))
  if valid_603119 != nil:
    section.add "X-Amz-Target", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Content-Sha256", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Algorithm")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Algorithm", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Signature")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Signature", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603126: Call_DeleteAssessmentTarget_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_DeleteAssessmentTarget_603114; body: JsonNode): Recallable =
  ## deleteAssessmentTarget
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var deleteAssessmentTarget* = Call_DeleteAssessmentTarget_603114(
    name: "deleteAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTarget",
    validator: validate_DeleteAssessmentTarget_603115, base: "/",
    url: url_DeleteAssessmentTarget_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTemplate_603129 = ref object of OpenApiRestCall_602433
proc url_DeleteAssessmentTemplate_603131(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAssessmentTemplate_603130(path: JsonNode; query: JsonNode;
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
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Security-Token")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Security-Token", valid_603133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603134 = header.getOrDefault("X-Amz-Target")
  valid_603134 = validateParameter(valid_603134, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTemplate"))
  if valid_603134 != nil:
    section.add "X-Amz-Target", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Algorithm")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Algorithm", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Signature")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Signature", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-SignedHeaders", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_DeleteAssessmentTemplate_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_DeleteAssessmentTemplate_603129; body: JsonNode): Recallable =
  ## deleteAssessmentTemplate
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var deleteAssessmentTemplate* = Call_DeleteAssessmentTemplate_603129(
    name: "deleteAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTemplate",
    validator: validate_DeleteAssessmentTemplate_603130, base: "/",
    url: url_DeleteAssessmentTemplate_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentRuns_603144 = ref object of OpenApiRestCall_602433
proc url_DescribeAssessmentRuns_603146(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentRuns_603145(path: JsonNode; query: JsonNode;
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
  var valid_603147 = header.getOrDefault("X-Amz-Date")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Date", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Security-Token")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Security-Token", valid_603148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603149 = header.getOrDefault("X-Amz-Target")
  valid_603149 = validateParameter(valid_603149, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentRuns"))
  if valid_603149 != nil:
    section.add "X-Amz-Target", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Content-Sha256", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Algorithm")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Algorithm", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-SignedHeaders", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Credential")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Credential", valid_603154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603156: Call_DescribeAssessmentRuns_603144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_DescribeAssessmentRuns_603144; body: JsonNode): Recallable =
  ## describeAssessmentRuns
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var describeAssessmentRuns* = Call_DescribeAssessmentRuns_603144(
    name: "describeAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentRuns",
    validator: validate_DescribeAssessmentRuns_603145, base: "/",
    url: url_DescribeAssessmentRuns_603146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTargets_603159 = ref object of OpenApiRestCall_602433
proc url_DescribeAssessmentTargets_603161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentTargets_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = header.getOrDefault("X-Amz-Date")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Date", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Security-Token")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Security-Token", valid_603163
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603164 = header.getOrDefault("X-Amz-Target")
  valid_603164 = validateParameter(valid_603164, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTargets"))
  if valid_603164 != nil:
    section.add "X-Amz-Target", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Content-Sha256", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Algorithm")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Algorithm", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Signature")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Signature", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-SignedHeaders", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Credential")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Credential", valid_603169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603171: Call_DescribeAssessmentTargets_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_DescribeAssessmentTargets_603159; body: JsonNode): Recallable =
  ## describeAssessmentTargets
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var describeAssessmentTargets* = Call_DescribeAssessmentTargets_603159(
    name: "describeAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTargets",
    validator: validate_DescribeAssessmentTargets_603160, base: "/",
    url: url_DescribeAssessmentTargets_603161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTemplates_603174 = ref object of OpenApiRestCall_602433
proc url_DescribeAssessmentTemplates_603176(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAssessmentTemplates_603175(path: JsonNode; query: JsonNode;
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
  var valid_603177 = header.getOrDefault("X-Amz-Date")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Date", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Security-Token")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Security-Token", valid_603178
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603179 = header.getOrDefault("X-Amz-Target")
  valid_603179 = validateParameter(valid_603179, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTemplates"))
  if valid_603179 != nil:
    section.add "X-Amz-Target", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603186: Call_DescribeAssessmentTemplates_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_DescribeAssessmentTemplates_603174; body: JsonNode): Recallable =
  ## describeAssessmentTemplates
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var describeAssessmentTemplates* = Call_DescribeAssessmentTemplates_603174(
    name: "describeAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTemplates",
    validator: validate_DescribeAssessmentTemplates_603175, base: "/",
    url: url_DescribeAssessmentTemplates_603176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCrossAccountAccessRole_603189 = ref object of OpenApiRestCall_602433
proc url_DescribeCrossAccountAccessRole_603191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCrossAccountAccessRole_603190(path: JsonNode;
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
  var valid_603192 = header.getOrDefault("X-Amz-Date")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Date", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603194 = header.getOrDefault("X-Amz-Target")
  valid_603194 = validateParameter(valid_603194, JString, required = true, default = newJString(
      "InspectorService.DescribeCrossAccountAccessRole"))
  if valid_603194 != nil:
    section.add "X-Amz-Target", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603200: Call_DescribeCrossAccountAccessRole_603189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  ## 
  let valid = call_603200.validator(path, query, header, formData, body)
  let scheme = call_603200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603200.url(scheme.get, call_603200.host, call_603200.base,
                         call_603200.route, valid.getOrDefault("path"))
  result = hook(call_603200, url, valid)

proc call*(call_603201: Call_DescribeCrossAccountAccessRole_603189): Recallable =
  ## describeCrossAccountAccessRole
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  result = call_603201.call(nil, nil, nil, nil, nil)

var describeCrossAccountAccessRole* = Call_DescribeCrossAccountAccessRole_603189(
    name: "describeCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeCrossAccountAccessRole",
    validator: validate_DescribeCrossAccountAccessRole_603190, base: "/",
    url: url_DescribeCrossAccountAccessRole_603191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExclusions_603202 = ref object of OpenApiRestCall_602433
proc url_DescribeExclusions_603204(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeExclusions_603203(path: JsonNode; query: JsonNode;
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
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603207 = header.getOrDefault("X-Amz-Target")
  valid_603207 = validateParameter(valid_603207, JString, required = true, default = newJString(
      "InspectorService.DescribeExclusions"))
  if valid_603207 != nil:
    section.add "X-Amz-Target", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603214: Call_DescribeExclusions_603202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ## 
  let valid = call_603214.validator(path, query, header, formData, body)
  let scheme = call_603214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603214.url(scheme.get, call_603214.host, call_603214.base,
                         call_603214.route, valid.getOrDefault("path"))
  result = hook(call_603214, url, valid)

proc call*(call_603215: Call_DescribeExclusions_603202; body: JsonNode): Recallable =
  ## describeExclusions
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ##   body: JObject (required)
  var body_603216 = newJObject()
  if body != nil:
    body_603216 = body
  result = call_603215.call(nil, nil, nil, nil, body_603216)

var describeExclusions* = Call_DescribeExclusions_603202(
    name: "describeExclusions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeExclusions",
    validator: validate_DescribeExclusions_603203, base: "/",
    url: url_DescribeExclusions_603204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFindings_603217 = ref object of OpenApiRestCall_602433
proc url_DescribeFindings_603219(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFindings_603218(path: JsonNode; query: JsonNode;
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
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603222 = header.getOrDefault("X-Amz-Target")
  valid_603222 = validateParameter(valid_603222, JString, required = true, default = newJString(
      "InspectorService.DescribeFindings"))
  if valid_603222 != nil:
    section.add "X-Amz-Target", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Content-Sha256", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Algorithm")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Algorithm", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Signature")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Signature", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-SignedHeaders", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Credential")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Credential", valid_603227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603229: Call_DescribeFindings_603217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_603229.validator(path, query, header, formData, body)
  let scheme = call_603229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603229.url(scheme.get, call_603229.host, call_603229.base,
                         call_603229.route, valid.getOrDefault("path"))
  result = hook(call_603229, url, valid)

proc call*(call_603230: Call_DescribeFindings_603217; body: JsonNode): Recallable =
  ## describeFindings
  ## Describes the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_603231 = newJObject()
  if body != nil:
    body_603231 = body
  result = call_603230.call(nil, nil, nil, nil, body_603231)

var describeFindings* = Call_DescribeFindings_603217(name: "describeFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeFindings",
    validator: validate_DescribeFindings_603218, base: "/",
    url: url_DescribeFindings_603219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceGroups_603232 = ref object of OpenApiRestCall_602433
proc url_DescribeResourceGroups_603234(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeResourceGroups_603233(path: JsonNode; query: JsonNode;
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
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603237 = header.getOrDefault("X-Amz-Target")
  valid_603237 = validateParameter(valid_603237, JString, required = true, default = newJString(
      "InspectorService.DescribeResourceGroups"))
  if valid_603237 != nil:
    section.add "X-Amz-Target", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Content-Sha256", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Algorithm")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Algorithm", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Signature")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Signature", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-SignedHeaders", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Credential")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Credential", valid_603242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_DescribeResourceGroups_603232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_DescribeResourceGroups_603232; body: JsonNode): Recallable =
  ## describeResourceGroups
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ##   body: JObject (required)
  var body_603246 = newJObject()
  if body != nil:
    body_603246 = body
  result = call_603245.call(nil, nil, nil, nil, body_603246)

var describeResourceGroups* = Call_DescribeResourceGroups_603232(
    name: "describeResourceGroups", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeResourceGroups",
    validator: validate_DescribeResourceGroups_603233, base: "/",
    url: url_DescribeResourceGroups_603234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRulesPackages_603247 = ref object of OpenApiRestCall_602433
proc url_DescribeRulesPackages_603249(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRulesPackages_603248(path: JsonNode; query: JsonNode;
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
  var valid_603250 = header.getOrDefault("X-Amz-Date")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Date", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Security-Token")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Security-Token", valid_603251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603252 = header.getOrDefault("X-Amz-Target")
  valid_603252 = validateParameter(valid_603252, JString, required = true, default = newJString(
      "InspectorService.DescribeRulesPackages"))
  if valid_603252 != nil:
    section.add "X-Amz-Target", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Content-Sha256", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Signature")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Signature", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-SignedHeaders", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603259: Call_DescribeRulesPackages_603247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ## 
  let valid = call_603259.validator(path, query, header, formData, body)
  let scheme = call_603259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603259.url(scheme.get, call_603259.host, call_603259.base,
                         call_603259.route, valid.getOrDefault("path"))
  result = hook(call_603259, url, valid)

proc call*(call_603260: Call_DescribeRulesPackages_603247; body: JsonNode): Recallable =
  ## describeRulesPackages
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ##   body: JObject (required)
  var body_603261 = newJObject()
  if body != nil:
    body_603261 = body
  result = call_603260.call(nil, nil, nil, nil, body_603261)

var describeRulesPackages* = Call_DescribeRulesPackages_603247(
    name: "describeRulesPackages", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeRulesPackages",
    validator: validate_DescribeRulesPackages_603248, base: "/",
    url: url_DescribeRulesPackages_603249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssessmentReport_603262 = ref object of OpenApiRestCall_602433
proc url_GetAssessmentReport_603264(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAssessmentReport_603263(path: JsonNode; query: JsonNode;
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
  var valid_603265 = header.getOrDefault("X-Amz-Date")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Date", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Security-Token")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Security-Token", valid_603266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603267 = header.getOrDefault("X-Amz-Target")
  valid_603267 = validateParameter(valid_603267, JString, required = true, default = newJString(
      "InspectorService.GetAssessmentReport"))
  if valid_603267 != nil:
    section.add "X-Amz-Target", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Content-Sha256", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Algorithm")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Algorithm", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Signature")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Signature", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-SignedHeaders", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Credential")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Credential", valid_603272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603274: Call_GetAssessmentReport_603262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ## 
  let valid = call_603274.validator(path, query, header, formData, body)
  let scheme = call_603274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603274.url(scheme.get, call_603274.host, call_603274.base,
                         call_603274.route, valid.getOrDefault("path"))
  result = hook(call_603274, url, valid)

proc call*(call_603275: Call_GetAssessmentReport_603262; body: JsonNode): Recallable =
  ## getAssessmentReport
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ##   body: JObject (required)
  var body_603276 = newJObject()
  if body != nil:
    body_603276 = body
  result = call_603275.call(nil, nil, nil, nil, body_603276)

var getAssessmentReport* = Call_GetAssessmentReport_603262(
    name: "getAssessmentReport", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetAssessmentReport",
    validator: validate_GetAssessmentReport_603263, base: "/",
    url: url_GetAssessmentReport_603264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExclusionsPreview_603277 = ref object of OpenApiRestCall_602433
proc url_GetExclusionsPreview_603279(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetExclusionsPreview_603278(path: JsonNode; query: JsonNode;
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
  var valid_603280 = query.getOrDefault("maxResults")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "maxResults", valid_603280
  var valid_603281 = query.getOrDefault("nextToken")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "nextToken", valid_603281
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
      "InspectorService.GetExclusionsPreview"))
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

proc call*(call_603291: Call_GetExclusionsPreview_603277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_GetExclusionsPreview_603277; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getExclusionsPreview
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603293 = newJObject()
  var body_603294 = newJObject()
  add(query_603293, "maxResults", newJString(maxResults))
  add(query_603293, "nextToken", newJString(nextToken))
  if body != nil:
    body_603294 = body
  result = call_603292.call(nil, query_603293, nil, nil, body_603294)

var getExclusionsPreview* = Call_GetExclusionsPreview_603277(
    name: "getExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetExclusionsPreview",
    validator: validate_GetExclusionsPreview_603278, base: "/",
    url: url_GetExclusionsPreview_603279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTelemetryMetadata_603296 = ref object of OpenApiRestCall_602433
proc url_GetTelemetryMetadata_603298(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTelemetryMetadata_603297(path: JsonNode; query: JsonNode;
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
  var valid_603299 = header.getOrDefault("X-Amz-Date")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Date", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Security-Token")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Security-Token", valid_603300
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603301 = header.getOrDefault("X-Amz-Target")
  valid_603301 = validateParameter(valid_603301, JString, required = true, default = newJString(
      "InspectorService.GetTelemetryMetadata"))
  if valid_603301 != nil:
    section.add "X-Amz-Target", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Content-Sha256", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Algorithm")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Algorithm", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Signature")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Signature", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-SignedHeaders", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Credential")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Credential", valid_603306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603308: Call_GetTelemetryMetadata_603296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the data that is collected for the specified assessment run.
  ## 
  let valid = call_603308.validator(path, query, header, formData, body)
  let scheme = call_603308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603308.url(scheme.get, call_603308.host, call_603308.base,
                         call_603308.route, valid.getOrDefault("path"))
  result = hook(call_603308, url, valid)

proc call*(call_603309: Call_GetTelemetryMetadata_603296; body: JsonNode): Recallable =
  ## getTelemetryMetadata
  ## Information about the data that is collected for the specified assessment run.
  ##   body: JObject (required)
  var body_603310 = newJObject()
  if body != nil:
    body_603310 = body
  result = call_603309.call(nil, nil, nil, nil, body_603310)

var getTelemetryMetadata* = Call_GetTelemetryMetadata_603296(
    name: "getTelemetryMetadata", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetTelemetryMetadata",
    validator: validate_GetTelemetryMetadata_603297, base: "/",
    url: url_GetTelemetryMetadata_603298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRunAgents_603311 = ref object of OpenApiRestCall_602433
proc url_ListAssessmentRunAgents_603313(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentRunAgents_603312(path: JsonNode; query: JsonNode;
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
  var valid_603314 = query.getOrDefault("maxResults")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "maxResults", valid_603314
  var valid_603315 = query.getOrDefault("nextToken")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "nextToken", valid_603315
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
      "InspectorService.ListAssessmentRunAgents"))
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

proc call*(call_603325: Call_ListAssessmentRunAgents_603311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_603325.validator(path, query, header, formData, body)
  let scheme = call_603325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603325.url(scheme.get, call_603325.host, call_603325.base,
                         call_603325.route, valid.getOrDefault("path"))
  result = hook(call_603325, url, valid)

proc call*(call_603326: Call_ListAssessmentRunAgents_603311; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentRunAgents
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603327 = newJObject()
  var body_603328 = newJObject()
  add(query_603327, "maxResults", newJString(maxResults))
  add(query_603327, "nextToken", newJString(nextToken))
  if body != nil:
    body_603328 = body
  result = call_603326.call(nil, query_603327, nil, nil, body_603328)

var listAssessmentRunAgents* = Call_ListAssessmentRunAgents_603311(
    name: "listAssessmentRunAgents", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRunAgents",
    validator: validate_ListAssessmentRunAgents_603312, base: "/",
    url: url_ListAssessmentRunAgents_603313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRuns_603329 = ref object of OpenApiRestCall_602433
proc url_ListAssessmentRuns_603331(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentRuns_603330(path: JsonNode; query: JsonNode;
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
  var valid_603332 = query.getOrDefault("maxResults")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "maxResults", valid_603332
  var valid_603333 = query.getOrDefault("nextToken")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "nextToken", valid_603333
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
  var valid_603334 = header.getOrDefault("X-Amz-Date")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Date", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Security-Token")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Security-Token", valid_603335
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603336 = header.getOrDefault("X-Amz-Target")
  valid_603336 = validateParameter(valid_603336, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRuns"))
  if valid_603336 != nil:
    section.add "X-Amz-Target", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603343: Call_ListAssessmentRuns_603329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_603343.validator(path, query, header, formData, body)
  let scheme = call_603343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603343.url(scheme.get, call_603343.host, call_603343.base,
                         call_603343.route, valid.getOrDefault("path"))
  result = hook(call_603343, url, valid)

proc call*(call_603344: Call_ListAssessmentRuns_603329; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentRuns
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603345 = newJObject()
  var body_603346 = newJObject()
  add(query_603345, "maxResults", newJString(maxResults))
  add(query_603345, "nextToken", newJString(nextToken))
  if body != nil:
    body_603346 = body
  result = call_603344.call(nil, query_603345, nil, nil, body_603346)

var listAssessmentRuns* = Call_ListAssessmentRuns_603329(
    name: "listAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRuns",
    validator: validate_ListAssessmentRuns_603330, base: "/",
    url: url_ListAssessmentRuns_603331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTargets_603347 = ref object of OpenApiRestCall_602433
proc url_ListAssessmentTargets_603349(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentTargets_603348(path: JsonNode; query: JsonNode;
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
  var valid_603350 = query.getOrDefault("maxResults")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "maxResults", valid_603350
  var valid_603351 = query.getOrDefault("nextToken")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "nextToken", valid_603351
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
  var valid_603352 = header.getOrDefault("X-Amz-Date")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Date", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Security-Token")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Security-Token", valid_603353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603354 = header.getOrDefault("X-Amz-Target")
  valid_603354 = validateParameter(valid_603354, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTargets"))
  if valid_603354 != nil:
    section.add "X-Amz-Target", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Content-Sha256", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Algorithm")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Algorithm", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Signature")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Signature", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-SignedHeaders", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Credential")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Credential", valid_603359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603361: Call_ListAssessmentTargets_603347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_603361.validator(path, query, header, formData, body)
  let scheme = call_603361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603361.url(scheme.get, call_603361.host, call_603361.base,
                         call_603361.route, valid.getOrDefault("path"))
  result = hook(call_603361, url, valid)

proc call*(call_603362: Call_ListAssessmentTargets_603347; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentTargets
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603363 = newJObject()
  var body_603364 = newJObject()
  add(query_603363, "maxResults", newJString(maxResults))
  add(query_603363, "nextToken", newJString(nextToken))
  if body != nil:
    body_603364 = body
  result = call_603362.call(nil, query_603363, nil, nil, body_603364)

var listAssessmentTargets* = Call_ListAssessmentTargets_603347(
    name: "listAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTargets",
    validator: validate_ListAssessmentTargets_603348, base: "/",
    url: url_ListAssessmentTargets_603349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTemplates_603365 = ref object of OpenApiRestCall_602433
proc url_ListAssessmentTemplates_603367(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAssessmentTemplates_603366(path: JsonNode; query: JsonNode;
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
  var valid_603368 = query.getOrDefault("maxResults")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "maxResults", valid_603368
  var valid_603369 = query.getOrDefault("nextToken")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "nextToken", valid_603369
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
  var valid_603370 = header.getOrDefault("X-Amz-Date")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Date", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-Security-Token")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Security-Token", valid_603371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603372 = header.getOrDefault("X-Amz-Target")
  valid_603372 = validateParameter(valid_603372, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTemplates"))
  if valid_603372 != nil:
    section.add "X-Amz-Target", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Content-Sha256", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Algorithm")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Algorithm", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Signature")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Signature", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-SignedHeaders", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Credential")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Credential", valid_603377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603379: Call_ListAssessmentTemplates_603365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_603379.validator(path, query, header, formData, body)
  let scheme = call_603379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603379.url(scheme.get, call_603379.host, call_603379.base,
                         call_603379.route, valid.getOrDefault("path"))
  result = hook(call_603379, url, valid)

proc call*(call_603380: Call_ListAssessmentTemplates_603365; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listAssessmentTemplates
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603381 = newJObject()
  var body_603382 = newJObject()
  add(query_603381, "maxResults", newJString(maxResults))
  add(query_603381, "nextToken", newJString(nextToken))
  if body != nil:
    body_603382 = body
  result = call_603380.call(nil, query_603381, nil, nil, body_603382)

var listAssessmentTemplates* = Call_ListAssessmentTemplates_603365(
    name: "listAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTemplates",
    validator: validate_ListAssessmentTemplates_603366, base: "/",
    url: url_ListAssessmentTemplates_603367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSubscriptions_603383 = ref object of OpenApiRestCall_602433
proc url_ListEventSubscriptions_603385(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEventSubscriptions_603384(path: JsonNode; query: JsonNode;
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
  var valid_603386 = query.getOrDefault("maxResults")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "maxResults", valid_603386
  var valid_603387 = query.getOrDefault("nextToken")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "nextToken", valid_603387
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
  var valid_603388 = header.getOrDefault("X-Amz-Date")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Date", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Security-Token")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Security-Token", valid_603389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603390 = header.getOrDefault("X-Amz-Target")
  valid_603390 = validateParameter(valid_603390, JString, required = true, default = newJString(
      "InspectorService.ListEventSubscriptions"))
  if valid_603390 != nil:
    section.add "X-Amz-Target", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_ListEventSubscriptions_603383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_ListEventSubscriptions_603383; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listEventSubscriptions
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603399 = newJObject()
  var body_603400 = newJObject()
  add(query_603399, "maxResults", newJString(maxResults))
  add(query_603399, "nextToken", newJString(nextToken))
  if body != nil:
    body_603400 = body
  result = call_603398.call(nil, query_603399, nil, nil, body_603400)

var listEventSubscriptions* = Call_ListEventSubscriptions_603383(
    name: "listEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListEventSubscriptions",
    validator: validate_ListEventSubscriptions_603384, base: "/",
    url: url_ListEventSubscriptions_603385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExclusions_603401 = ref object of OpenApiRestCall_602433
proc url_ListExclusions_603403(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListExclusions_603402(path: JsonNode; query: JsonNode;
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
  var valid_603404 = query.getOrDefault("maxResults")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "maxResults", valid_603404
  var valid_603405 = query.getOrDefault("nextToken")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "nextToken", valid_603405
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603408 = header.getOrDefault("X-Amz-Target")
  valid_603408 = validateParameter(valid_603408, JString, required = true, default = newJString(
      "InspectorService.ListExclusions"))
  if valid_603408 != nil:
    section.add "X-Amz-Target", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-SignedHeaders", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_ListExclusions_603401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List exclusions that are generated by the assessment run.
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_ListExclusions_603401; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listExclusions
  ## List exclusions that are generated by the assessment run.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603417 = newJObject()
  var body_603418 = newJObject()
  add(query_603417, "maxResults", newJString(maxResults))
  add(query_603417, "nextToken", newJString(nextToken))
  if body != nil:
    body_603418 = body
  result = call_603416.call(nil, query_603417, nil, nil, body_603418)

var listExclusions* = Call_ListExclusions_603401(name: "listExclusions",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListExclusions",
    validator: validate_ListExclusions_603402, base: "/", url: url_ListExclusions_603403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_603419 = ref object of OpenApiRestCall_602433
proc url_ListFindings_603421(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFindings_603420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603422 = query.getOrDefault("maxResults")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "maxResults", valid_603422
  var valid_603423 = query.getOrDefault("nextToken")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "nextToken", valid_603423
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
  var valid_603424 = header.getOrDefault("X-Amz-Date")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Date", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Security-Token")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Security-Token", valid_603425
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603426 = header.getOrDefault("X-Amz-Target")
  valid_603426 = validateParameter(valid_603426, JString, required = true, default = newJString(
      "InspectorService.ListFindings"))
  if valid_603426 != nil:
    section.add "X-Amz-Target", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Content-Sha256", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Algorithm")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Algorithm", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Signature")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Signature", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-SignedHeaders", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Credential")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Credential", valid_603431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603433: Call_ListFindings_603419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_603433.validator(path, query, header, formData, body)
  let scheme = call_603433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603433.url(scheme.get, call_603433.host, call_603433.base,
                         call_603433.route, valid.getOrDefault("path"))
  result = hook(call_603433, url, valid)

proc call*(call_603434: Call_ListFindings_603419; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFindings
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603435 = newJObject()
  var body_603436 = newJObject()
  add(query_603435, "maxResults", newJString(maxResults))
  add(query_603435, "nextToken", newJString(nextToken))
  if body != nil:
    body_603436 = body
  result = call_603434.call(nil, query_603435, nil, nil, body_603436)

var listFindings* = Call_ListFindings_603419(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListFindings",
    validator: validate_ListFindings_603420, base: "/", url: url_ListFindings_603421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRulesPackages_603437 = ref object of OpenApiRestCall_602433
proc url_ListRulesPackages_603439(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRulesPackages_603438(path: JsonNode; query: JsonNode;
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
  var valid_603440 = query.getOrDefault("maxResults")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "maxResults", valid_603440
  var valid_603441 = query.getOrDefault("nextToken")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "nextToken", valid_603441
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
      "InspectorService.ListRulesPackages"))
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

proc call*(call_603451: Call_ListRulesPackages_603437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available Amazon Inspector rules packages.
  ## 
  let valid = call_603451.validator(path, query, header, formData, body)
  let scheme = call_603451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603451.url(scheme.get, call_603451.host, call_603451.base,
                         call_603451.route, valid.getOrDefault("path"))
  result = hook(call_603451, url, valid)

proc call*(call_603452: Call_ListRulesPackages_603437; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRulesPackages
  ## Lists all available Amazon Inspector rules packages.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603453 = newJObject()
  var body_603454 = newJObject()
  add(query_603453, "maxResults", newJString(maxResults))
  add(query_603453, "nextToken", newJString(nextToken))
  if body != nil:
    body_603454 = body
  result = call_603452.call(nil, query_603453, nil, nil, body_603454)

var listRulesPackages* = Call_ListRulesPackages_603437(name: "listRulesPackages",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListRulesPackages",
    validator: validate_ListRulesPackages_603438, base: "/",
    url: url_ListRulesPackages_603439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603455 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603457(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_603456(path: JsonNode; query: JsonNode;
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
  var valid_603458 = header.getOrDefault("X-Amz-Date")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Date", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Security-Token")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Security-Token", valid_603459
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603460 = header.getOrDefault("X-Amz-Target")
  valid_603460 = validateParameter(valid_603460, JString, required = true, default = newJString(
      "InspectorService.ListTagsForResource"))
  if valid_603460 != nil:
    section.add "X-Amz-Target", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Content-Sha256", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Algorithm")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Algorithm", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Signature")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Signature", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-SignedHeaders", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Credential")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Credential", valid_603465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603467: Call_ListTagsForResource_603455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with an assessment template.
  ## 
  let valid = call_603467.validator(path, query, header, formData, body)
  let scheme = call_603467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603467.url(scheme.get, call_603467.host, call_603467.base,
                         call_603467.route, valid.getOrDefault("path"))
  result = hook(call_603467, url, valid)

proc call*(call_603468: Call_ListTagsForResource_603455; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with an assessment template.
  ##   body: JObject (required)
  var body_603469 = newJObject()
  if body != nil:
    body_603469 = body
  result = call_603468.call(nil, nil, nil, nil, body_603469)

var listTagsForResource* = Call_ListTagsForResource_603455(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListTagsForResource",
    validator: validate_ListTagsForResource_603456, base: "/",
    url: url_ListTagsForResource_603457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PreviewAgents_603470 = ref object of OpenApiRestCall_602433
proc url_PreviewAgents_603472(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PreviewAgents_603471(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603473 = query.getOrDefault("maxResults")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "maxResults", valid_603473
  var valid_603474 = query.getOrDefault("nextToken")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "nextToken", valid_603474
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
  var valid_603475 = header.getOrDefault("X-Amz-Date")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Date", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Security-Token")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Security-Token", valid_603476
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603477 = header.getOrDefault("X-Amz-Target")
  valid_603477 = validateParameter(valid_603477, JString, required = true, default = newJString(
      "InspectorService.PreviewAgents"))
  if valid_603477 != nil:
    section.add "X-Amz-Target", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Content-Sha256", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Algorithm")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Algorithm", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Signature")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Signature", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-SignedHeaders", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Credential")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Credential", valid_603482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603484: Call_PreviewAgents_603470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ## 
  let valid = call_603484.validator(path, query, header, formData, body)
  let scheme = call_603484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603484.url(scheme.get, call_603484.host, call_603484.base,
                         call_603484.route, valid.getOrDefault("path"))
  result = hook(call_603484, url, valid)

proc call*(call_603485: Call_PreviewAgents_603470; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## previewAgents
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603486 = newJObject()
  var body_603487 = newJObject()
  add(query_603486, "maxResults", newJString(maxResults))
  add(query_603486, "nextToken", newJString(nextToken))
  if body != nil:
    body_603487 = body
  result = call_603485.call(nil, query_603486, nil, nil, body_603487)

var previewAgents* = Call_PreviewAgents_603470(name: "previewAgents",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.PreviewAgents",
    validator: validate_PreviewAgents_603471, base: "/", url: url_PreviewAgents_603472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCrossAccountAccessRole_603488 = ref object of OpenApiRestCall_602433
proc url_RegisterCrossAccountAccessRole_603490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterCrossAccountAccessRole_603489(path: JsonNode;
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
  var valid_603491 = header.getOrDefault("X-Amz-Date")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Date", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Security-Token")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Security-Token", valid_603492
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603493 = header.getOrDefault("X-Amz-Target")
  valid_603493 = validateParameter(valid_603493, JString, required = true, default = newJString(
      "InspectorService.RegisterCrossAccountAccessRole"))
  if valid_603493 != nil:
    section.add "X-Amz-Target", valid_603493
  var valid_603494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Content-Sha256", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Algorithm")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Algorithm", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Signature")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Signature", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-SignedHeaders", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Credential")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Credential", valid_603498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603500: Call_RegisterCrossAccountAccessRole_603488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_603500.validator(path, query, header, formData, body)
  let scheme = call_603500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603500.url(scheme.get, call_603500.host, call_603500.base,
                         call_603500.route, valid.getOrDefault("path"))
  result = hook(call_603500, url, valid)

proc call*(call_603501: Call_RegisterCrossAccountAccessRole_603488; body: JsonNode): Recallable =
  ## registerCrossAccountAccessRole
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_603502 = newJObject()
  if body != nil:
    body_603502 = body
  result = call_603501.call(nil, nil, nil, nil, body_603502)

var registerCrossAccountAccessRole* = Call_RegisterCrossAccountAccessRole_603488(
    name: "registerCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RegisterCrossAccountAccessRole",
    validator: validate_RegisterCrossAccountAccessRole_603489, base: "/",
    url: url_RegisterCrossAccountAccessRole_603490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributesFromFindings_603503 = ref object of OpenApiRestCall_602433
proc url_RemoveAttributesFromFindings_603505(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveAttributesFromFindings_603504(path: JsonNode; query: JsonNode;
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
  var valid_603506 = header.getOrDefault("X-Amz-Date")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Date", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Security-Token")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Security-Token", valid_603507
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603508 = header.getOrDefault("X-Amz-Target")
  valid_603508 = validateParameter(valid_603508, JString, required = true, default = newJString(
      "InspectorService.RemoveAttributesFromFindings"))
  if valid_603508 != nil:
    section.add "X-Amz-Target", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-Content-Sha256", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Algorithm")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Algorithm", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Signature")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Signature", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-SignedHeaders", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Credential")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Credential", valid_603513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603515: Call_RemoveAttributesFromFindings_603503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ## 
  let valid = call_603515.validator(path, query, header, formData, body)
  let scheme = call_603515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603515.url(scheme.get, call_603515.host, call_603515.base,
                         call_603515.route, valid.getOrDefault("path"))
  result = hook(call_603515, url, valid)

proc call*(call_603516: Call_RemoveAttributesFromFindings_603503; body: JsonNode): Recallable =
  ## removeAttributesFromFindings
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ##   body: JObject (required)
  var body_603517 = newJObject()
  if body != nil:
    body_603517 = body
  result = call_603516.call(nil, nil, nil, nil, body_603517)

var removeAttributesFromFindings* = Call_RemoveAttributesFromFindings_603503(
    name: "removeAttributesFromFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RemoveAttributesFromFindings",
    validator: validate_RemoveAttributesFromFindings_603504, base: "/",
    url: url_RemoveAttributesFromFindings_603505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTagsForResource_603518 = ref object of OpenApiRestCall_602433
proc url_SetTagsForResource_603520(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetTagsForResource_603519(path: JsonNode; query: JsonNode;
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
  var valid_603521 = header.getOrDefault("X-Amz-Date")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Date", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Security-Token")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Security-Token", valid_603522
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603523 = header.getOrDefault("X-Amz-Target")
  valid_603523 = validateParameter(valid_603523, JString, required = true, default = newJString(
      "InspectorService.SetTagsForResource"))
  if valid_603523 != nil:
    section.add "X-Amz-Target", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-Content-Sha256", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Algorithm")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Algorithm", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Signature")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Signature", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-SignedHeaders", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Credential")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Credential", valid_603528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603530: Call_SetTagsForResource_603518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_603530.validator(path, query, header, formData, body)
  let scheme = call_603530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603530.url(scheme.get, call_603530.host, call_603530.base,
                         call_603530.route, valid.getOrDefault("path"))
  result = hook(call_603530, url, valid)

proc call*(call_603531: Call_SetTagsForResource_603518; body: JsonNode): Recallable =
  ## setTagsForResource
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_603532 = newJObject()
  if body != nil:
    body_603532 = body
  result = call_603531.call(nil, nil, nil, nil, body_603532)

var setTagsForResource* = Call_SetTagsForResource_603518(
    name: "setTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SetTagsForResource",
    validator: validate_SetTagsForResource_603519, base: "/",
    url: url_SetTagsForResource_603520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssessmentRun_603533 = ref object of OpenApiRestCall_602433
proc url_StartAssessmentRun_603535(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartAssessmentRun_603534(path: JsonNode; query: JsonNode;
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
  var valid_603536 = header.getOrDefault("X-Amz-Date")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Date", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Security-Token")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Security-Token", valid_603537
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603538 = header.getOrDefault("X-Amz-Target")
  valid_603538 = validateParameter(valid_603538, JString, required = true, default = newJString(
      "InspectorService.StartAssessmentRun"))
  if valid_603538 != nil:
    section.add "X-Amz-Target", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Content-Sha256", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Algorithm")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Algorithm", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Signature")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Signature", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-SignedHeaders", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Credential")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Credential", valid_603543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603545: Call_StartAssessmentRun_603533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ## 
  let valid = call_603545.validator(path, query, header, formData, body)
  let scheme = call_603545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603545.url(scheme.get, call_603545.host, call_603545.base,
                         call_603545.route, valid.getOrDefault("path"))
  result = hook(call_603545, url, valid)

proc call*(call_603546: Call_StartAssessmentRun_603533; body: JsonNode): Recallable =
  ## startAssessmentRun
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ##   body: JObject (required)
  var body_603547 = newJObject()
  if body != nil:
    body_603547 = body
  result = call_603546.call(nil, nil, nil, nil, body_603547)

var startAssessmentRun* = Call_StartAssessmentRun_603533(
    name: "startAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StartAssessmentRun",
    validator: validate_StartAssessmentRun_603534, base: "/",
    url: url_StartAssessmentRun_603535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAssessmentRun_603548 = ref object of OpenApiRestCall_602433
proc url_StopAssessmentRun_603550(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopAssessmentRun_603549(path: JsonNode; query: JsonNode;
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
  var valid_603551 = header.getOrDefault("X-Amz-Date")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Date", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Security-Token")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Security-Token", valid_603552
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603553 = header.getOrDefault("X-Amz-Target")
  valid_603553 = validateParameter(valid_603553, JString, required = true, default = newJString(
      "InspectorService.StopAssessmentRun"))
  if valid_603553 != nil:
    section.add "X-Amz-Target", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Content-Sha256", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Algorithm")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Algorithm", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Signature")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Signature", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-SignedHeaders", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Credential")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Credential", valid_603558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603560: Call_StopAssessmentRun_603548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_603560.validator(path, query, header, formData, body)
  let scheme = call_603560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603560.url(scheme.get, call_603560.host, call_603560.base,
                         call_603560.route, valid.getOrDefault("path"))
  result = hook(call_603560, url, valid)

proc call*(call_603561: Call_StopAssessmentRun_603548; body: JsonNode): Recallable =
  ## stopAssessmentRun
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_603562 = newJObject()
  if body != nil:
    body_603562 = body
  result = call_603561.call(nil, nil, nil, nil, body_603562)

var stopAssessmentRun* = Call_StopAssessmentRun_603548(name: "stopAssessmentRun",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StopAssessmentRun",
    validator: validate_StopAssessmentRun_603549, base: "/",
    url: url_StopAssessmentRun_603550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToEvent_603563 = ref object of OpenApiRestCall_602433
proc url_SubscribeToEvent_603565(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubscribeToEvent_603564(path: JsonNode; query: JsonNode;
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
  var valid_603566 = header.getOrDefault("X-Amz-Date")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Date", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Security-Token")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Security-Token", valid_603567
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603568 = header.getOrDefault("X-Amz-Target")
  valid_603568 = validateParameter(valid_603568, JString, required = true, default = newJString(
      "InspectorService.SubscribeToEvent"))
  if valid_603568 != nil:
    section.add "X-Amz-Target", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Content-Sha256", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Algorithm")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Algorithm", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Signature")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Signature", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-SignedHeaders", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_SubscribeToEvent_603563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_SubscribeToEvent_603563; body: JsonNode): Recallable =
  ## subscribeToEvent
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_603577 = newJObject()
  if body != nil:
    body_603577 = body
  result = call_603576.call(nil, nil, nil, nil, body_603577)

var subscribeToEvent* = Call_SubscribeToEvent_603563(name: "subscribeToEvent",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SubscribeToEvent",
    validator: validate_SubscribeToEvent_603564, base: "/",
    url: url_SubscribeToEvent_603565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromEvent_603578 = ref object of OpenApiRestCall_602433
proc url_UnsubscribeFromEvent_603580(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UnsubscribeFromEvent_603579(path: JsonNode; query: JsonNode;
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
  var valid_603581 = header.getOrDefault("X-Amz-Date")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Date", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Security-Token")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Security-Token", valid_603582
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603583 = header.getOrDefault("X-Amz-Target")
  valid_603583 = validateParameter(valid_603583, JString, required = true, default = newJString(
      "InspectorService.UnsubscribeFromEvent"))
  if valid_603583 != nil:
    section.add "X-Amz-Target", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603590: Call_UnsubscribeFromEvent_603578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_603590.validator(path, query, header, formData, body)
  let scheme = call_603590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603590.url(scheme.get, call_603590.host, call_603590.base,
                         call_603590.route, valid.getOrDefault("path"))
  result = hook(call_603590, url, valid)

proc call*(call_603591: Call_UnsubscribeFromEvent_603578; body: JsonNode): Recallable =
  ## unsubscribeFromEvent
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_603592 = newJObject()
  if body != nil:
    body_603592 = body
  result = call_603591.call(nil, nil, nil, nil, body_603592)

var unsubscribeFromEvent* = Call_UnsubscribeFromEvent_603578(
    name: "unsubscribeFromEvent", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UnsubscribeFromEvent",
    validator: validate_UnsubscribeFromEvent_603579, base: "/",
    url: url_UnsubscribeFromEvent_603580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssessmentTarget_603593 = ref object of OpenApiRestCall_602433
proc url_UpdateAssessmentTarget_603595(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateAssessmentTarget_603594(path: JsonNode; query: JsonNode;
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
  var valid_603596 = header.getOrDefault("X-Amz-Date")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Date", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Security-Token")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Security-Token", valid_603597
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603598 = header.getOrDefault("X-Amz-Target")
  valid_603598 = validateParameter(valid_603598, JString, required = true, default = newJString(
      "InspectorService.UpdateAssessmentTarget"))
  if valid_603598 != nil:
    section.add "X-Amz-Target", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Content-Sha256", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Algorithm")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Algorithm", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Signature")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Signature", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-SignedHeaders", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603605: Call_UpdateAssessmentTarget_603593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ## 
  let valid = call_603605.validator(path, query, header, formData, body)
  let scheme = call_603605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603605.url(scheme.get, call_603605.host, call_603605.base,
                         call_603605.route, valid.getOrDefault("path"))
  result = hook(call_603605, url, valid)

proc call*(call_603606: Call_UpdateAssessmentTarget_603593; body: JsonNode): Recallable =
  ## updateAssessmentTarget
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ##   body: JObject (required)
  var body_603607 = newJObject()
  if body != nil:
    body_603607 = body
  result = call_603606.call(nil, nil, nil, nil, body_603607)

var updateAssessmentTarget* = Call_UpdateAssessmentTarget_603593(
    name: "updateAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UpdateAssessmentTarget",
    validator: validate_UpdateAssessmentTarget_603594, base: "/",
    url: url_UpdateAssessmentTarget_603595, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
