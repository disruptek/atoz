
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
  Call_AddAttributesToFindings_612996 = ref object of OpenApiRestCall_612658
proc url_AddAttributesToFindings_612998(protocol: Scheme; host: string; base: string;
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

proc validate_AddAttributesToFindings_612997(path: JsonNode; query: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true, default = newJString(
      "InspectorService.AddAttributesToFindings"))
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

proc call*(call_613154: Call_AddAttributesToFindings_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AddAttributesToFindings_612996; body: JsonNode): Recallable =
  ## addAttributesToFindings
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var addAttributesToFindings* = Call_AddAttributesToFindings_612996(
    name: "addAttributesToFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.AddAttributesToFindings",
    validator: validate_AddAttributesToFindings_612997, base: "/",
    url: url_AddAttributesToFindings_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTarget_613265 = ref object of OpenApiRestCall_612658
proc url_CreateAssessmentTarget_613267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssessmentTarget_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTarget"))
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

proc call*(call_613277: Call_CreateAssessmentTarget_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_CreateAssessmentTarget_613265; body: JsonNode): Recallable =
  ## createAssessmentTarget
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var createAssessmentTarget* = Call_CreateAssessmentTarget_613265(
    name: "createAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTarget",
    validator: validate_CreateAssessmentTarget_613266, base: "/",
    url: url_CreateAssessmentTarget_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTemplate_613280 = ref object of OpenApiRestCall_612658
proc url_CreateAssessmentTemplate_613282(protocol: Scheme; host: string;
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

proc validate_CreateAssessmentTemplate_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTemplate"))
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

proc call*(call_613292: Call_CreateAssessmentTemplate_613280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateAssessmentTemplate_613280; body: JsonNode): Recallable =
  ## createAssessmentTemplate
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createAssessmentTemplate* = Call_CreateAssessmentTemplate_613280(
    name: "createAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTemplate",
    validator: validate_CreateAssessmentTemplate_613281, base: "/",
    url: url_CreateAssessmentTemplate_613282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExclusionsPreview_613295 = ref object of OpenApiRestCall_612658
proc url_CreateExclusionsPreview_613297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExclusionsPreview_613296(path: JsonNode; query: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true, default = newJString(
      "InspectorService.CreateExclusionsPreview"))
  if valid_613298 != nil:
    section.add "X-Amz-Target", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_CreateExclusionsPreview_613295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateExclusionsPreview_613295; body: JsonNode): Recallable =
  ## createExclusionsPreview
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createExclusionsPreview* = Call_CreateExclusionsPreview_613295(
    name: "createExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateExclusionsPreview",
    validator: validate_CreateExclusionsPreview_613296, base: "/",
    url: url_CreateExclusionsPreview_613297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceGroup_613310 = ref object of OpenApiRestCall_612658
proc url_CreateResourceGroup_613312(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceGroup_613311(path: JsonNode; query: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "InspectorService.CreateResourceGroup"))
  if valid_613313 != nil:
    section.add "X-Amz-Target", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Signature")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Signature", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Content-Sha256", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Date")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Date", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Credential")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Credential", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Security-Token")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Security-Token", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Algorithm")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Algorithm", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-SignedHeaders", valid_613320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613322: Call_CreateResourceGroup_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateResourceGroup_613310; body: JsonNode): Recallable =
  ## createResourceGroup
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createResourceGroup* = Call_CreateResourceGroup_613310(
    name: "createResourceGroup", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateResourceGroup",
    validator: validate_CreateResourceGroup_613311, base: "/",
    url: url_CreateResourceGroup_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentRun_613325 = ref object of OpenApiRestCall_612658
proc url_DeleteAssessmentRun_613327(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentRun_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentRun"))
  if valid_613328 != nil:
    section.add "X-Amz-Target", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Signature")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Signature", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Content-Sha256", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Date")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Date", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Credential")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Credential", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Security-Token")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Security-Token", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Algorithm")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Algorithm", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-SignedHeaders", valid_613335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_DeleteAssessmentRun_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_DeleteAssessmentRun_613325; body: JsonNode): Recallable =
  ## deleteAssessmentRun
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var deleteAssessmentRun* = Call_DeleteAssessmentRun_613325(
    name: "deleteAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentRun",
    validator: validate_DeleteAssessmentRun_613326, base: "/",
    url: url_DeleteAssessmentRun_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTarget_613340 = ref object of OpenApiRestCall_612658
proc url_DeleteAssessmentTarget_613342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentTarget_613341(path: JsonNode; query: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTarget"))
  if valid_613343 != nil:
    section.add "X-Amz-Target", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Signature")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Signature", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Content-Sha256", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Date")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Date", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Credential")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Credential", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Security-Token")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Security-Token", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Algorithm")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Algorithm", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-SignedHeaders", valid_613350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613352: Call_DeleteAssessmentTarget_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_DeleteAssessmentTarget_613340; body: JsonNode): Recallable =
  ## deleteAssessmentTarget
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var deleteAssessmentTarget* = Call_DeleteAssessmentTarget_613340(
    name: "deleteAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTarget",
    validator: validate_DeleteAssessmentTarget_613341, base: "/",
    url: url_DeleteAssessmentTarget_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTemplate_613355 = ref object of OpenApiRestCall_612658
proc url_DeleteAssessmentTemplate_613357(protocol: Scheme; host: string;
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

proc validate_DeleteAssessmentTemplate_613356(path: JsonNode; query: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTemplate"))
  if valid_613358 != nil:
    section.add "X-Amz-Target", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Signature")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Signature", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Content-Sha256", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Date")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Date", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Credential")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Credential", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Security-Token")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Security-Token", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Algorithm")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Algorithm", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-SignedHeaders", valid_613365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613367: Call_DeleteAssessmentTemplate_613355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_DeleteAssessmentTemplate_613355; body: JsonNode): Recallable =
  ## deleteAssessmentTemplate
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var deleteAssessmentTemplate* = Call_DeleteAssessmentTemplate_613355(
    name: "deleteAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTemplate",
    validator: validate_DeleteAssessmentTemplate_613356, base: "/",
    url: url_DeleteAssessmentTemplate_613357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentRuns_613370 = ref object of OpenApiRestCall_612658
proc url_DescribeAssessmentRuns_613372(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssessmentRuns_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentRuns"))
  if valid_613373 != nil:
    section.add "X-Amz-Target", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Signature")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Signature", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Content-Sha256", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Date")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Date", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Credential")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Credential", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Security-Token")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Security-Token", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Algorithm")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Algorithm", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-SignedHeaders", valid_613380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613382: Call_DescribeAssessmentRuns_613370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_DescribeAssessmentRuns_613370; body: JsonNode): Recallable =
  ## describeAssessmentRuns
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var describeAssessmentRuns* = Call_DescribeAssessmentRuns_613370(
    name: "describeAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentRuns",
    validator: validate_DescribeAssessmentRuns_613371, base: "/",
    url: url_DescribeAssessmentRuns_613372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTargets_613385 = ref object of OpenApiRestCall_612658
proc url_DescribeAssessmentTargets_613387(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTargets_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTargets"))
  if valid_613388 != nil:
    section.add "X-Amz-Target", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Signature")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Signature", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Content-Sha256", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Date")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Date", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Credential")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Credential", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Security-Token")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Security-Token", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Algorithm")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Algorithm", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-SignedHeaders", valid_613395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613397: Call_DescribeAssessmentTargets_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_DescribeAssessmentTargets_613385; body: JsonNode): Recallable =
  ## describeAssessmentTargets
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var describeAssessmentTargets* = Call_DescribeAssessmentTargets_613385(
    name: "describeAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTargets",
    validator: validate_DescribeAssessmentTargets_613386, base: "/",
    url: url_DescribeAssessmentTargets_613387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTemplates_613400 = ref object of OpenApiRestCall_612658
proc url_DescribeAssessmentTemplates_613402(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTemplates_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTemplates"))
  if valid_613403 != nil:
    section.add "X-Amz-Target", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613412: Call_DescribeAssessmentTemplates_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_DescribeAssessmentTemplates_613400; body: JsonNode): Recallable =
  ## describeAssessmentTemplates
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var describeAssessmentTemplates* = Call_DescribeAssessmentTemplates_613400(
    name: "describeAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTemplates",
    validator: validate_DescribeAssessmentTemplates_613401, base: "/",
    url: url_DescribeAssessmentTemplates_613402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCrossAccountAccessRole_613415 = ref object of OpenApiRestCall_612658
proc url_DescribeCrossAccountAccessRole_613417(protocol: Scheme; host: string;
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

proc validate_DescribeCrossAccountAccessRole_613416(path: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "InspectorService.DescribeCrossAccountAccessRole"))
  if valid_613418 != nil:
    section.add "X-Amz-Target", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_DescribeCrossAccountAccessRole_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_DescribeCrossAccountAccessRole_613415): Recallable =
  ## describeCrossAccountAccessRole
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  result = call_613427.call(nil, nil, nil, nil, nil)

var describeCrossAccountAccessRole* = Call_DescribeCrossAccountAccessRole_613415(
    name: "describeCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeCrossAccountAccessRole",
    validator: validate_DescribeCrossAccountAccessRole_613416, base: "/",
    url: url_DescribeCrossAccountAccessRole_613417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExclusions_613428 = ref object of OpenApiRestCall_612658
proc url_DescribeExclusions_613430(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExclusions_613429(path: JsonNode; query: JsonNode;
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
  var valid_613431 = header.getOrDefault("X-Amz-Target")
  valid_613431 = validateParameter(valid_613431, JString, required = true, default = newJString(
      "InspectorService.DescribeExclusions"))
  if valid_613431 != nil:
    section.add "X-Amz-Target", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Signature")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Signature", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Content-Sha256", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Date")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Date", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Credential")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Credential", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Security-Token")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Security-Token", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Algorithm")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Algorithm", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-SignedHeaders", valid_613438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613440: Call_DescribeExclusions_613428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ## 
  let valid = call_613440.validator(path, query, header, formData, body)
  let scheme = call_613440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613440.url(scheme.get, call_613440.host, call_613440.base,
                         call_613440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613440, url, valid)

proc call*(call_613441: Call_DescribeExclusions_613428; body: JsonNode): Recallable =
  ## describeExclusions
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ##   body: JObject (required)
  var body_613442 = newJObject()
  if body != nil:
    body_613442 = body
  result = call_613441.call(nil, nil, nil, nil, body_613442)

var describeExclusions* = Call_DescribeExclusions_613428(
    name: "describeExclusions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeExclusions",
    validator: validate_DescribeExclusions_613429, base: "/",
    url: url_DescribeExclusions_613430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFindings_613443 = ref object of OpenApiRestCall_612658
proc url_DescribeFindings_613445(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFindings_613444(path: JsonNode; query: JsonNode;
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
  var valid_613446 = header.getOrDefault("X-Amz-Target")
  valid_613446 = validateParameter(valid_613446, JString, required = true, default = newJString(
      "InspectorService.DescribeFindings"))
  if valid_613446 != nil:
    section.add "X-Amz-Target", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Signature")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Signature", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Content-Sha256", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Date")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Date", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Credential")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Credential", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Security-Token")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Security-Token", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Algorithm")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Algorithm", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-SignedHeaders", valid_613453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613455: Call_DescribeFindings_613443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_613455.validator(path, query, header, formData, body)
  let scheme = call_613455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613455.url(scheme.get, call_613455.host, call_613455.base,
                         call_613455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613455, url, valid)

proc call*(call_613456: Call_DescribeFindings_613443; body: JsonNode): Recallable =
  ## describeFindings
  ## Describes the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_613457 = newJObject()
  if body != nil:
    body_613457 = body
  result = call_613456.call(nil, nil, nil, nil, body_613457)

var describeFindings* = Call_DescribeFindings_613443(name: "describeFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeFindings",
    validator: validate_DescribeFindings_613444, base: "/",
    url: url_DescribeFindings_613445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceGroups_613458 = ref object of OpenApiRestCall_612658
proc url_DescribeResourceGroups_613460(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeResourceGroups_613459(path: JsonNode; query: JsonNode;
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
  var valid_613461 = header.getOrDefault("X-Amz-Target")
  valid_613461 = validateParameter(valid_613461, JString, required = true, default = newJString(
      "InspectorService.DescribeResourceGroups"))
  if valid_613461 != nil:
    section.add "X-Amz-Target", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Signature")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Signature", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Content-Sha256", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Date")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Date", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Credential")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Credential", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Security-Token")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Security-Token", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Algorithm")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Algorithm", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-SignedHeaders", valid_613468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_DescribeResourceGroups_613458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_DescribeResourceGroups_613458; body: JsonNode): Recallable =
  ## describeResourceGroups
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ##   body: JObject (required)
  var body_613472 = newJObject()
  if body != nil:
    body_613472 = body
  result = call_613471.call(nil, nil, nil, nil, body_613472)

var describeResourceGroups* = Call_DescribeResourceGroups_613458(
    name: "describeResourceGroups", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeResourceGroups",
    validator: validate_DescribeResourceGroups_613459, base: "/",
    url: url_DescribeResourceGroups_613460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRulesPackages_613473 = ref object of OpenApiRestCall_612658
proc url_DescribeRulesPackages_613475(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRulesPackages_613474(path: JsonNode; query: JsonNode;
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
  var valid_613476 = header.getOrDefault("X-Amz-Target")
  valid_613476 = validateParameter(valid_613476, JString, required = true, default = newJString(
      "InspectorService.DescribeRulesPackages"))
  if valid_613476 != nil:
    section.add "X-Amz-Target", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Signature")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Signature", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Content-Sha256", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Date")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Date", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Credential")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Credential", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Security-Token")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Security-Token", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Algorithm")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Algorithm", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-SignedHeaders", valid_613483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613485: Call_DescribeRulesPackages_613473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ## 
  let valid = call_613485.validator(path, query, header, formData, body)
  let scheme = call_613485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613485.url(scheme.get, call_613485.host, call_613485.base,
                         call_613485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613485, url, valid)

proc call*(call_613486: Call_DescribeRulesPackages_613473; body: JsonNode): Recallable =
  ## describeRulesPackages
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ##   body: JObject (required)
  var body_613487 = newJObject()
  if body != nil:
    body_613487 = body
  result = call_613486.call(nil, nil, nil, nil, body_613487)

var describeRulesPackages* = Call_DescribeRulesPackages_613473(
    name: "describeRulesPackages", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeRulesPackages",
    validator: validate_DescribeRulesPackages_613474, base: "/",
    url: url_DescribeRulesPackages_613475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssessmentReport_613488 = ref object of OpenApiRestCall_612658
proc url_GetAssessmentReport_613490(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssessmentReport_613489(path: JsonNode; query: JsonNode;
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
  var valid_613491 = header.getOrDefault("X-Amz-Target")
  valid_613491 = validateParameter(valid_613491, JString, required = true, default = newJString(
      "InspectorService.GetAssessmentReport"))
  if valid_613491 != nil:
    section.add "X-Amz-Target", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Signature")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Signature", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Content-Sha256", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Date")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Date", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Credential")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Credential", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Security-Token")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Security-Token", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Algorithm")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Algorithm", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-SignedHeaders", valid_613498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613500: Call_GetAssessmentReport_613488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ## 
  let valid = call_613500.validator(path, query, header, formData, body)
  let scheme = call_613500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613500.url(scheme.get, call_613500.host, call_613500.base,
                         call_613500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613500, url, valid)

proc call*(call_613501: Call_GetAssessmentReport_613488; body: JsonNode): Recallable =
  ## getAssessmentReport
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ##   body: JObject (required)
  var body_613502 = newJObject()
  if body != nil:
    body_613502 = body
  result = call_613501.call(nil, nil, nil, nil, body_613502)

var getAssessmentReport* = Call_GetAssessmentReport_613488(
    name: "getAssessmentReport", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetAssessmentReport",
    validator: validate_GetAssessmentReport_613489, base: "/",
    url: url_GetAssessmentReport_613490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExclusionsPreview_613503 = ref object of OpenApiRestCall_612658
proc url_GetExclusionsPreview_613505(protocol: Scheme; host: string; base: string;
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

proc validate_GetExclusionsPreview_613504(path: JsonNode; query: JsonNode;
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
  var valid_613506 = query.getOrDefault("nextToken")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "nextToken", valid_613506
  var valid_613507 = query.getOrDefault("maxResults")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "maxResults", valid_613507
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "InspectorService.GetExclusionsPreview"))
  if valid_613508 != nil:
    section.add "X-Amz-Target", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_GetExclusionsPreview_613503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_GetExclusionsPreview_613503; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExclusionsPreview
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613519 = newJObject()
  var body_613520 = newJObject()
  add(query_613519, "nextToken", newJString(nextToken))
  if body != nil:
    body_613520 = body
  add(query_613519, "maxResults", newJString(maxResults))
  result = call_613518.call(nil, query_613519, nil, nil, body_613520)

var getExclusionsPreview* = Call_GetExclusionsPreview_613503(
    name: "getExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetExclusionsPreview",
    validator: validate_GetExclusionsPreview_613504, base: "/",
    url: url_GetExclusionsPreview_613505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTelemetryMetadata_613522 = ref object of OpenApiRestCall_612658
proc url_GetTelemetryMetadata_613524(protocol: Scheme; host: string; base: string;
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

proc validate_GetTelemetryMetadata_613523(path: JsonNode; query: JsonNode;
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
  var valid_613525 = header.getOrDefault("X-Amz-Target")
  valid_613525 = validateParameter(valid_613525, JString, required = true, default = newJString(
      "InspectorService.GetTelemetryMetadata"))
  if valid_613525 != nil:
    section.add "X-Amz-Target", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Signature")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Signature", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Content-Sha256", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Date")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Date", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Credential")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Credential", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Security-Token")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Security-Token", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Algorithm")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Algorithm", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-SignedHeaders", valid_613532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613534: Call_GetTelemetryMetadata_613522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the data that is collected for the specified assessment run.
  ## 
  let valid = call_613534.validator(path, query, header, formData, body)
  let scheme = call_613534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613534.url(scheme.get, call_613534.host, call_613534.base,
                         call_613534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613534, url, valid)

proc call*(call_613535: Call_GetTelemetryMetadata_613522; body: JsonNode): Recallable =
  ## getTelemetryMetadata
  ## Information about the data that is collected for the specified assessment run.
  ##   body: JObject (required)
  var body_613536 = newJObject()
  if body != nil:
    body_613536 = body
  result = call_613535.call(nil, nil, nil, nil, body_613536)

var getTelemetryMetadata* = Call_GetTelemetryMetadata_613522(
    name: "getTelemetryMetadata", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetTelemetryMetadata",
    validator: validate_GetTelemetryMetadata_613523, base: "/",
    url: url_GetTelemetryMetadata_613524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRunAgents_613537 = ref object of OpenApiRestCall_612658
proc url_ListAssessmentRunAgents_613539(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRunAgents_613538(path: JsonNode; query: JsonNode;
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
  var valid_613540 = query.getOrDefault("nextToken")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "nextToken", valid_613540
  var valid_613541 = query.getOrDefault("maxResults")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "maxResults", valid_613541
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
  var valid_613542 = header.getOrDefault("X-Amz-Target")
  valid_613542 = validateParameter(valid_613542, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRunAgents"))
  if valid_613542 != nil:
    section.add "X-Amz-Target", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Signature")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Signature", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Content-Sha256", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Date")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Date", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Credential")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Credential", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Security-Token")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Security-Token", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-Algorithm")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Algorithm", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-SignedHeaders", valid_613549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613551: Call_ListAssessmentRunAgents_613537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_613551.validator(path, query, header, formData, body)
  let scheme = call_613551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613551.url(scheme.get, call_613551.host, call_613551.base,
                         call_613551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613551, url, valid)

proc call*(call_613552: Call_ListAssessmentRunAgents_613537; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRunAgents
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613553 = newJObject()
  var body_613554 = newJObject()
  add(query_613553, "nextToken", newJString(nextToken))
  if body != nil:
    body_613554 = body
  add(query_613553, "maxResults", newJString(maxResults))
  result = call_613552.call(nil, query_613553, nil, nil, body_613554)

var listAssessmentRunAgents* = Call_ListAssessmentRunAgents_613537(
    name: "listAssessmentRunAgents", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRunAgents",
    validator: validate_ListAssessmentRunAgents_613538, base: "/",
    url: url_ListAssessmentRunAgents_613539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRuns_613555 = ref object of OpenApiRestCall_612658
proc url_ListAssessmentRuns_613557(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRuns_613556(path: JsonNode; query: JsonNode;
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
  var valid_613558 = query.getOrDefault("nextToken")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "nextToken", valid_613558
  var valid_613559 = query.getOrDefault("maxResults")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "maxResults", valid_613559
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
  var valid_613560 = header.getOrDefault("X-Amz-Target")
  valid_613560 = validateParameter(valid_613560, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRuns"))
  if valid_613560 != nil:
    section.add "X-Amz-Target", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Signature")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Signature", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Content-Sha256", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Date")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Date", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-Credential")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-Credential", valid_613564
  var valid_613565 = header.getOrDefault("X-Amz-Security-Token")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Security-Token", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Algorithm")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Algorithm", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-SignedHeaders", valid_613567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613569: Call_ListAssessmentRuns_613555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_613569.validator(path, query, header, formData, body)
  let scheme = call_613569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613569.url(scheme.get, call_613569.host, call_613569.base,
                         call_613569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613569, url, valid)

proc call*(call_613570: Call_ListAssessmentRuns_613555; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRuns
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613571 = newJObject()
  var body_613572 = newJObject()
  add(query_613571, "nextToken", newJString(nextToken))
  if body != nil:
    body_613572 = body
  add(query_613571, "maxResults", newJString(maxResults))
  result = call_613570.call(nil, query_613571, nil, nil, body_613572)

var listAssessmentRuns* = Call_ListAssessmentRuns_613555(
    name: "listAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRuns",
    validator: validate_ListAssessmentRuns_613556, base: "/",
    url: url_ListAssessmentRuns_613557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTargets_613573 = ref object of OpenApiRestCall_612658
proc url_ListAssessmentTargets_613575(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTargets_613574(path: JsonNode; query: JsonNode;
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
  var valid_613576 = query.getOrDefault("nextToken")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "nextToken", valid_613576
  var valid_613577 = query.getOrDefault("maxResults")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "maxResults", valid_613577
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
  var valid_613578 = header.getOrDefault("X-Amz-Target")
  valid_613578 = validateParameter(valid_613578, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTargets"))
  if valid_613578 != nil:
    section.add "X-Amz-Target", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Signature")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Signature", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Content-Sha256", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-Date")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-Date", valid_613581
  var valid_613582 = header.getOrDefault("X-Amz-Credential")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Credential", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Security-Token")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Security-Token", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Algorithm")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Algorithm", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-SignedHeaders", valid_613585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613587: Call_ListAssessmentTargets_613573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_613587.validator(path, query, header, formData, body)
  let scheme = call_613587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613587.url(scheme.get, call_613587.host, call_613587.base,
                         call_613587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613587, url, valid)

proc call*(call_613588: Call_ListAssessmentTargets_613573; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTargets
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613589 = newJObject()
  var body_613590 = newJObject()
  add(query_613589, "nextToken", newJString(nextToken))
  if body != nil:
    body_613590 = body
  add(query_613589, "maxResults", newJString(maxResults))
  result = call_613588.call(nil, query_613589, nil, nil, body_613590)

var listAssessmentTargets* = Call_ListAssessmentTargets_613573(
    name: "listAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTargets",
    validator: validate_ListAssessmentTargets_613574, base: "/",
    url: url_ListAssessmentTargets_613575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTemplates_613591 = ref object of OpenApiRestCall_612658
proc url_ListAssessmentTemplates_613593(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTemplates_613592(path: JsonNode; query: JsonNode;
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
  var valid_613594 = query.getOrDefault("nextToken")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "nextToken", valid_613594
  var valid_613595 = query.getOrDefault("maxResults")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "maxResults", valid_613595
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
  var valid_613596 = header.getOrDefault("X-Amz-Target")
  valid_613596 = validateParameter(valid_613596, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTemplates"))
  if valid_613596 != nil:
    section.add "X-Amz-Target", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Signature")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Signature", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Content-Sha256", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Date")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Date", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Credential")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Credential", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Security-Token")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Security-Token", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Algorithm")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Algorithm", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-SignedHeaders", valid_613603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613605: Call_ListAssessmentTemplates_613591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_613605.validator(path, query, header, formData, body)
  let scheme = call_613605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613605.url(scheme.get, call_613605.host, call_613605.base,
                         call_613605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613605, url, valid)

proc call*(call_613606: Call_ListAssessmentTemplates_613591; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTemplates
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613607 = newJObject()
  var body_613608 = newJObject()
  add(query_613607, "nextToken", newJString(nextToken))
  if body != nil:
    body_613608 = body
  add(query_613607, "maxResults", newJString(maxResults))
  result = call_613606.call(nil, query_613607, nil, nil, body_613608)

var listAssessmentTemplates* = Call_ListAssessmentTemplates_613591(
    name: "listAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTemplates",
    validator: validate_ListAssessmentTemplates_613592, base: "/",
    url: url_ListAssessmentTemplates_613593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSubscriptions_613609 = ref object of OpenApiRestCall_612658
proc url_ListEventSubscriptions_613611(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSubscriptions_613610(path: JsonNode; query: JsonNode;
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
  var valid_613612 = query.getOrDefault("nextToken")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "nextToken", valid_613612
  var valid_613613 = query.getOrDefault("maxResults")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "maxResults", valid_613613
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
  var valid_613614 = header.getOrDefault("X-Amz-Target")
  valid_613614 = validateParameter(valid_613614, JString, required = true, default = newJString(
      "InspectorService.ListEventSubscriptions"))
  if valid_613614 != nil:
    section.add "X-Amz-Target", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Signature")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Signature", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Content-Sha256", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Date")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Date", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Credential")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Credential", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Security-Token")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Security-Token", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Algorithm")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Algorithm", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-SignedHeaders", valid_613621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613623: Call_ListEventSubscriptions_613609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ## 
  let valid = call_613623.validator(path, query, header, formData, body)
  let scheme = call_613623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613623.url(scheme.get, call_613623.host, call_613623.base,
                         call_613623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613623, url, valid)

proc call*(call_613624: Call_ListEventSubscriptions_613609; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEventSubscriptions
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613625 = newJObject()
  var body_613626 = newJObject()
  add(query_613625, "nextToken", newJString(nextToken))
  if body != nil:
    body_613626 = body
  add(query_613625, "maxResults", newJString(maxResults))
  result = call_613624.call(nil, query_613625, nil, nil, body_613626)

var listEventSubscriptions* = Call_ListEventSubscriptions_613609(
    name: "listEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListEventSubscriptions",
    validator: validate_ListEventSubscriptions_613610, base: "/",
    url: url_ListEventSubscriptions_613611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExclusions_613627 = ref object of OpenApiRestCall_612658
proc url_ListExclusions_613629(protocol: Scheme; host: string; base: string;
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

proc validate_ListExclusions_613628(path: JsonNode; query: JsonNode;
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
  var valid_613630 = query.getOrDefault("nextToken")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "nextToken", valid_613630
  var valid_613631 = query.getOrDefault("maxResults")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "maxResults", valid_613631
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
  var valid_613632 = header.getOrDefault("X-Amz-Target")
  valid_613632 = validateParameter(valid_613632, JString, required = true, default = newJString(
      "InspectorService.ListExclusions"))
  if valid_613632 != nil:
    section.add "X-Amz-Target", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Signature")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Signature", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Content-Sha256", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Date")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Date", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Credential")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Credential", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Security-Token")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Security-Token", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Algorithm")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Algorithm", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-SignedHeaders", valid_613639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613641: Call_ListExclusions_613627; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List exclusions that are generated by the assessment run.
  ## 
  let valid = call_613641.validator(path, query, header, formData, body)
  let scheme = call_613641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613641.url(scheme.get, call_613641.host, call_613641.base,
                         call_613641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613641, url, valid)

proc call*(call_613642: Call_ListExclusions_613627; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listExclusions
  ## List exclusions that are generated by the assessment run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613643 = newJObject()
  var body_613644 = newJObject()
  add(query_613643, "nextToken", newJString(nextToken))
  if body != nil:
    body_613644 = body
  add(query_613643, "maxResults", newJString(maxResults))
  result = call_613642.call(nil, query_613643, nil, nil, body_613644)

var listExclusions* = Call_ListExclusions_613627(name: "listExclusions",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListExclusions",
    validator: validate_ListExclusions_613628, base: "/", url: url_ListExclusions_613629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_613645 = ref object of OpenApiRestCall_612658
proc url_ListFindings_613647(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_613646(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613648 = query.getOrDefault("nextToken")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "nextToken", valid_613648
  var valid_613649 = query.getOrDefault("maxResults")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "maxResults", valid_613649
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
  var valid_613650 = header.getOrDefault("X-Amz-Target")
  valid_613650 = validateParameter(valid_613650, JString, required = true, default = newJString(
      "InspectorService.ListFindings"))
  if valid_613650 != nil:
    section.add "X-Amz-Target", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Signature")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Signature", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Content-Sha256", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Date")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Date", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Credential")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Credential", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Security-Token")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Security-Token", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Algorithm")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Algorithm", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-SignedHeaders", valid_613657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613659: Call_ListFindings_613645; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_613659.validator(path, query, header, formData, body)
  let scheme = call_613659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613659.url(scheme.get, call_613659.host, call_613659.base,
                         call_613659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613659, url, valid)

proc call*(call_613660: Call_ListFindings_613645; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613661 = newJObject()
  var body_613662 = newJObject()
  add(query_613661, "nextToken", newJString(nextToken))
  if body != nil:
    body_613662 = body
  add(query_613661, "maxResults", newJString(maxResults))
  result = call_613660.call(nil, query_613661, nil, nil, body_613662)

var listFindings* = Call_ListFindings_613645(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListFindings",
    validator: validate_ListFindings_613646, base: "/", url: url_ListFindings_613647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRulesPackages_613663 = ref object of OpenApiRestCall_612658
proc url_ListRulesPackages_613665(protocol: Scheme; host: string; base: string;
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

proc validate_ListRulesPackages_613664(path: JsonNode; query: JsonNode;
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
  var valid_613666 = query.getOrDefault("nextToken")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "nextToken", valid_613666
  var valid_613667 = query.getOrDefault("maxResults")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "maxResults", valid_613667
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
  var valid_613668 = header.getOrDefault("X-Amz-Target")
  valid_613668 = validateParameter(valid_613668, JString, required = true, default = newJString(
      "InspectorService.ListRulesPackages"))
  if valid_613668 != nil:
    section.add "X-Amz-Target", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Signature")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Signature", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Content-Sha256", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Date")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Date", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Credential")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Credential", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Security-Token")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Security-Token", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Algorithm")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Algorithm", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-SignedHeaders", valid_613675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613677: Call_ListRulesPackages_613663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available Amazon Inspector rules packages.
  ## 
  let valid = call_613677.validator(path, query, header, formData, body)
  let scheme = call_613677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613677.url(scheme.get, call_613677.host, call_613677.base,
                         call_613677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613677, url, valid)

proc call*(call_613678: Call_ListRulesPackages_613663; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRulesPackages
  ## Lists all available Amazon Inspector rules packages.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613679 = newJObject()
  var body_613680 = newJObject()
  add(query_613679, "nextToken", newJString(nextToken))
  if body != nil:
    body_613680 = body
  add(query_613679, "maxResults", newJString(maxResults))
  result = call_613678.call(nil, query_613679, nil, nil, body_613680)

var listRulesPackages* = Call_ListRulesPackages_613663(name: "listRulesPackages",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListRulesPackages",
    validator: validate_ListRulesPackages_613664, base: "/",
    url: url_ListRulesPackages_613665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613681 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613683(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613682(path: JsonNode; query: JsonNode;
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
  var valid_613684 = header.getOrDefault("X-Amz-Target")
  valid_613684 = validateParameter(valid_613684, JString, required = true, default = newJString(
      "InspectorService.ListTagsForResource"))
  if valid_613684 != nil:
    section.add "X-Amz-Target", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Signature")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Signature", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Content-Sha256", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Date")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Date", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Credential")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Credential", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Security-Token")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Security-Token", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Algorithm")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Algorithm", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-SignedHeaders", valid_613691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613693: Call_ListTagsForResource_613681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with an assessment template.
  ## 
  let valid = call_613693.validator(path, query, header, formData, body)
  let scheme = call_613693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613693.url(scheme.get, call_613693.host, call_613693.base,
                         call_613693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613693, url, valid)

proc call*(call_613694: Call_ListTagsForResource_613681; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with an assessment template.
  ##   body: JObject (required)
  var body_613695 = newJObject()
  if body != nil:
    body_613695 = body
  result = call_613694.call(nil, nil, nil, nil, body_613695)

var listTagsForResource* = Call_ListTagsForResource_613681(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListTagsForResource",
    validator: validate_ListTagsForResource_613682, base: "/",
    url: url_ListTagsForResource_613683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PreviewAgents_613696 = ref object of OpenApiRestCall_612658
proc url_PreviewAgents_613698(protocol: Scheme; host: string; base: string;
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

proc validate_PreviewAgents_613697(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613699 = query.getOrDefault("nextToken")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "nextToken", valid_613699
  var valid_613700 = query.getOrDefault("maxResults")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "maxResults", valid_613700
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
  var valid_613701 = header.getOrDefault("X-Amz-Target")
  valid_613701 = validateParameter(valid_613701, JString, required = true, default = newJString(
      "InspectorService.PreviewAgents"))
  if valid_613701 != nil:
    section.add "X-Amz-Target", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_PreviewAgents_613696; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ## 
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_PreviewAgents_613696; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## previewAgents
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_613712 = newJObject()
  var body_613713 = newJObject()
  add(query_613712, "nextToken", newJString(nextToken))
  if body != nil:
    body_613713 = body
  add(query_613712, "maxResults", newJString(maxResults))
  result = call_613711.call(nil, query_613712, nil, nil, body_613713)

var previewAgents* = Call_PreviewAgents_613696(name: "previewAgents",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.PreviewAgents",
    validator: validate_PreviewAgents_613697, base: "/", url: url_PreviewAgents_613698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCrossAccountAccessRole_613714 = ref object of OpenApiRestCall_612658
proc url_RegisterCrossAccountAccessRole_613716(protocol: Scheme; host: string;
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

proc validate_RegisterCrossAccountAccessRole_613715(path: JsonNode;
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
  var valid_613717 = header.getOrDefault("X-Amz-Target")
  valid_613717 = validateParameter(valid_613717, JString, required = true, default = newJString(
      "InspectorService.RegisterCrossAccountAccessRole"))
  if valid_613717 != nil:
    section.add "X-Amz-Target", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Signature")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Signature", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Content-Sha256", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Date")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Date", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Credential")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Credential", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Security-Token")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Security-Token", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Algorithm")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Algorithm", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-SignedHeaders", valid_613724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613726: Call_RegisterCrossAccountAccessRole_613714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_613726.validator(path, query, header, formData, body)
  let scheme = call_613726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613726.url(scheme.get, call_613726.host, call_613726.base,
                         call_613726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613726, url, valid)

proc call*(call_613727: Call_RegisterCrossAccountAccessRole_613714; body: JsonNode): Recallable =
  ## registerCrossAccountAccessRole
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_613728 = newJObject()
  if body != nil:
    body_613728 = body
  result = call_613727.call(nil, nil, nil, nil, body_613728)

var registerCrossAccountAccessRole* = Call_RegisterCrossAccountAccessRole_613714(
    name: "registerCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RegisterCrossAccountAccessRole",
    validator: validate_RegisterCrossAccountAccessRole_613715, base: "/",
    url: url_RegisterCrossAccountAccessRole_613716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributesFromFindings_613729 = ref object of OpenApiRestCall_612658
proc url_RemoveAttributesFromFindings_613731(protocol: Scheme; host: string;
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

proc validate_RemoveAttributesFromFindings_613730(path: JsonNode; query: JsonNode;
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
  var valid_613732 = header.getOrDefault("X-Amz-Target")
  valid_613732 = validateParameter(valid_613732, JString, required = true, default = newJString(
      "InspectorService.RemoveAttributesFromFindings"))
  if valid_613732 != nil:
    section.add "X-Amz-Target", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Signature")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Signature", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Content-Sha256", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Date")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Date", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Credential")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Credential", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Security-Token")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Security-Token", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Algorithm")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Algorithm", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-SignedHeaders", valid_613739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613741: Call_RemoveAttributesFromFindings_613729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ## 
  let valid = call_613741.validator(path, query, header, formData, body)
  let scheme = call_613741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613741.url(scheme.get, call_613741.host, call_613741.base,
                         call_613741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613741, url, valid)

proc call*(call_613742: Call_RemoveAttributesFromFindings_613729; body: JsonNode): Recallable =
  ## removeAttributesFromFindings
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ##   body: JObject (required)
  var body_613743 = newJObject()
  if body != nil:
    body_613743 = body
  result = call_613742.call(nil, nil, nil, nil, body_613743)

var removeAttributesFromFindings* = Call_RemoveAttributesFromFindings_613729(
    name: "removeAttributesFromFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RemoveAttributesFromFindings",
    validator: validate_RemoveAttributesFromFindings_613730, base: "/",
    url: url_RemoveAttributesFromFindings_613731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTagsForResource_613744 = ref object of OpenApiRestCall_612658
proc url_SetTagsForResource_613746(protocol: Scheme; host: string; base: string;
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

proc validate_SetTagsForResource_613745(path: JsonNode; query: JsonNode;
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
  var valid_613747 = header.getOrDefault("X-Amz-Target")
  valid_613747 = validateParameter(valid_613747, JString, required = true, default = newJString(
      "InspectorService.SetTagsForResource"))
  if valid_613747 != nil:
    section.add "X-Amz-Target", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Signature")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Signature", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Content-Sha256", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Date")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Date", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Credential")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Credential", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Security-Token")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Security-Token", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Algorithm")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Algorithm", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-SignedHeaders", valid_613754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613756: Call_SetTagsForResource_613744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_613756.validator(path, query, header, formData, body)
  let scheme = call_613756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613756.url(scheme.get, call_613756.host, call_613756.base,
                         call_613756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613756, url, valid)

proc call*(call_613757: Call_SetTagsForResource_613744; body: JsonNode): Recallable =
  ## setTagsForResource
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_613758 = newJObject()
  if body != nil:
    body_613758 = body
  result = call_613757.call(nil, nil, nil, nil, body_613758)

var setTagsForResource* = Call_SetTagsForResource_613744(
    name: "setTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SetTagsForResource",
    validator: validate_SetTagsForResource_613745, base: "/",
    url: url_SetTagsForResource_613746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssessmentRun_613759 = ref object of OpenApiRestCall_612658
proc url_StartAssessmentRun_613761(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssessmentRun_613760(path: JsonNode; query: JsonNode;
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
  var valid_613762 = header.getOrDefault("X-Amz-Target")
  valid_613762 = validateParameter(valid_613762, JString, required = true, default = newJString(
      "InspectorService.StartAssessmentRun"))
  if valid_613762 != nil:
    section.add "X-Amz-Target", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Signature")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Signature", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Content-Sha256", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Date")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Date", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Credential")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Credential", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Security-Token")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Security-Token", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Algorithm")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Algorithm", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-SignedHeaders", valid_613769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613771: Call_StartAssessmentRun_613759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ## 
  let valid = call_613771.validator(path, query, header, formData, body)
  let scheme = call_613771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613771.url(scheme.get, call_613771.host, call_613771.base,
                         call_613771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613771, url, valid)

proc call*(call_613772: Call_StartAssessmentRun_613759; body: JsonNode): Recallable =
  ## startAssessmentRun
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ##   body: JObject (required)
  var body_613773 = newJObject()
  if body != nil:
    body_613773 = body
  result = call_613772.call(nil, nil, nil, nil, body_613773)

var startAssessmentRun* = Call_StartAssessmentRun_613759(
    name: "startAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StartAssessmentRun",
    validator: validate_StartAssessmentRun_613760, base: "/",
    url: url_StartAssessmentRun_613761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAssessmentRun_613774 = ref object of OpenApiRestCall_612658
proc url_StopAssessmentRun_613776(protocol: Scheme; host: string; base: string;
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

proc validate_StopAssessmentRun_613775(path: JsonNode; query: JsonNode;
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
  var valid_613777 = header.getOrDefault("X-Amz-Target")
  valid_613777 = validateParameter(valid_613777, JString, required = true, default = newJString(
      "InspectorService.StopAssessmentRun"))
  if valid_613777 != nil:
    section.add "X-Amz-Target", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Signature")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Signature", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Content-Sha256", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Date")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Date", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Credential")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Credential", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Security-Token")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Security-Token", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Algorithm")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Algorithm", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-SignedHeaders", valid_613784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613786: Call_StopAssessmentRun_613774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_613786.validator(path, query, header, formData, body)
  let scheme = call_613786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613786.url(scheme.get, call_613786.host, call_613786.base,
                         call_613786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613786, url, valid)

proc call*(call_613787: Call_StopAssessmentRun_613774; body: JsonNode): Recallable =
  ## stopAssessmentRun
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_613788 = newJObject()
  if body != nil:
    body_613788 = body
  result = call_613787.call(nil, nil, nil, nil, body_613788)

var stopAssessmentRun* = Call_StopAssessmentRun_613774(name: "stopAssessmentRun",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StopAssessmentRun",
    validator: validate_StopAssessmentRun_613775, base: "/",
    url: url_StopAssessmentRun_613776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToEvent_613789 = ref object of OpenApiRestCall_612658
proc url_SubscribeToEvent_613791(protocol: Scheme; host: string; base: string;
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

proc validate_SubscribeToEvent_613790(path: JsonNode; query: JsonNode;
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
  var valid_613792 = header.getOrDefault("X-Amz-Target")
  valid_613792 = validateParameter(valid_613792, JString, required = true, default = newJString(
      "InspectorService.SubscribeToEvent"))
  if valid_613792 != nil:
    section.add "X-Amz-Target", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Signature")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Signature", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Content-Sha256", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Date")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Date", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Credential")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Credential", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Security-Token")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Security-Token", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Algorithm")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Algorithm", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-SignedHeaders", valid_613799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613801: Call_SubscribeToEvent_613789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_613801.validator(path, query, header, formData, body)
  let scheme = call_613801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613801.url(scheme.get, call_613801.host, call_613801.base,
                         call_613801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613801, url, valid)

proc call*(call_613802: Call_SubscribeToEvent_613789; body: JsonNode): Recallable =
  ## subscribeToEvent
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_613803 = newJObject()
  if body != nil:
    body_613803 = body
  result = call_613802.call(nil, nil, nil, nil, body_613803)

var subscribeToEvent* = Call_SubscribeToEvent_613789(name: "subscribeToEvent",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SubscribeToEvent",
    validator: validate_SubscribeToEvent_613790, base: "/",
    url: url_SubscribeToEvent_613791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromEvent_613804 = ref object of OpenApiRestCall_612658
proc url_UnsubscribeFromEvent_613806(protocol: Scheme; host: string; base: string;
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

proc validate_UnsubscribeFromEvent_613805(path: JsonNode; query: JsonNode;
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
  var valid_613807 = header.getOrDefault("X-Amz-Target")
  valid_613807 = validateParameter(valid_613807, JString, required = true, default = newJString(
      "InspectorService.UnsubscribeFromEvent"))
  if valid_613807 != nil:
    section.add "X-Amz-Target", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Signature")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Signature", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Content-Sha256", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Date")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Date", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Credential")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Credential", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Security-Token")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Security-Token", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Algorithm")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Algorithm", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-SignedHeaders", valid_613814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613816: Call_UnsubscribeFromEvent_613804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_613816.validator(path, query, header, formData, body)
  let scheme = call_613816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613816.url(scheme.get, call_613816.host, call_613816.base,
                         call_613816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613816, url, valid)

proc call*(call_613817: Call_UnsubscribeFromEvent_613804; body: JsonNode): Recallable =
  ## unsubscribeFromEvent
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_613818 = newJObject()
  if body != nil:
    body_613818 = body
  result = call_613817.call(nil, nil, nil, nil, body_613818)

var unsubscribeFromEvent* = Call_UnsubscribeFromEvent_613804(
    name: "unsubscribeFromEvent", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UnsubscribeFromEvent",
    validator: validate_UnsubscribeFromEvent_613805, base: "/",
    url: url_UnsubscribeFromEvent_613806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssessmentTarget_613819 = ref object of OpenApiRestCall_612658
proc url_UpdateAssessmentTarget_613821(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssessmentTarget_613820(path: JsonNode; query: JsonNode;
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
  var valid_613822 = header.getOrDefault("X-Amz-Target")
  valid_613822 = validateParameter(valid_613822, JString, required = true, default = newJString(
      "InspectorService.UpdateAssessmentTarget"))
  if valid_613822 != nil:
    section.add "X-Amz-Target", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Signature")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Signature", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Content-Sha256", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Date")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Date", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Credential")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Credential", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Security-Token")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Security-Token", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Algorithm")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Algorithm", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-SignedHeaders", valid_613829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613831: Call_UpdateAssessmentTarget_613819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ## 
  let valid = call_613831.validator(path, query, header, formData, body)
  let scheme = call_613831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613831.url(scheme.get, call_613831.host, call_613831.base,
                         call_613831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613831, url, valid)

proc call*(call_613832: Call_UpdateAssessmentTarget_613819; body: JsonNode): Recallable =
  ## updateAssessmentTarget
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ##   body: JObject (required)
  var body_613833 = newJObject()
  if body != nil:
    body_613833 = body
  result = call_613832.call(nil, nil, nil, nil, body_613833)

var updateAssessmentTarget* = Call_UpdateAssessmentTarget_613819(
    name: "updateAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UpdateAssessmentTarget",
    validator: validate_UpdateAssessmentTarget_613820, base: "/",
    url: url_UpdateAssessmentTarget_613821, schemes: {Scheme.Https, Scheme.Http})
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
