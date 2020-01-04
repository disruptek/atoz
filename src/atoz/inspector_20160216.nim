
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
  Call_AddAttributesToFindings_601727 = ref object of OpenApiRestCall_601389
proc url_AddAttributesToFindings_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AddAttributesToFindings_601728(path: JsonNode; query: JsonNode;
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "InspectorService.AddAttributesToFindings"))
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

proc call*(call_601885: Call_AddAttributesToFindings_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AddAttributesToFindings_601727; body: JsonNode): Recallable =
  ## addAttributesToFindings
  ## Assigns attributes (key and value pairs) to the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var addAttributesToFindings* = Call_AddAttributesToFindings_601727(
    name: "addAttributesToFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.AddAttributesToFindings",
    validator: validate_AddAttributesToFindings_601728, base: "/",
    url: url_AddAttributesToFindings_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTarget_601996 = ref object of OpenApiRestCall_601389
proc url_CreateAssessmentTarget_601998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAssessmentTarget_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTarget"))
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

proc call*(call_602008: Call_CreateAssessmentTarget_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreateAssessmentTarget_601996; body: JsonNode): Recallable =
  ## createAssessmentTarget
  ## Creates a new assessment target using the ARN of the resource group that is generated by <a>CreateResourceGroup</a>. If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments. You can create up to 50 assessment targets per AWS account. You can run up to 500 concurrent agents per AWS account. For more information, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html"> Amazon Inspector Assessment Targets</a>.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createAssessmentTarget* = Call_CreateAssessmentTarget_601996(
    name: "createAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTarget",
    validator: validate_CreateAssessmentTarget_601997, base: "/",
    url: url_CreateAssessmentTarget_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssessmentTemplate_602011 = ref object of OpenApiRestCall_601389
proc url_CreateAssessmentTemplate_602013(protocol: Scheme; host: string;
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

proc validate_CreateAssessmentTemplate_602012(path: JsonNode; query: JsonNode;
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "InspectorService.CreateAssessmentTemplate"))
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

proc call*(call_602023: Call_CreateAssessmentTemplate_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateAssessmentTemplate_602011; body: JsonNode): Recallable =
  ## createAssessmentTemplate
  ## Creates an assessment template for the assessment target that is specified by the ARN of the assessment target. If the <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_slr.html">service-linked role</a> isn’t already registered, this action also creates and registers a service-linked role to grant Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createAssessmentTemplate* = Call_CreateAssessmentTemplate_602011(
    name: "createAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateAssessmentTemplate",
    validator: validate_CreateAssessmentTemplate_602012, base: "/",
    url: url_CreateAssessmentTemplate_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExclusionsPreview_602026 = ref object of OpenApiRestCall_601389
proc url_CreateExclusionsPreview_602028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExclusionsPreview_602027(path: JsonNode; query: JsonNode;
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "InspectorService.CreateExclusionsPreview"))
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

proc call*(call_602038: Call_CreateExclusionsPreview_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateExclusionsPreview_602026; body: JsonNode): Recallable =
  ## createExclusionsPreview
  ## Starts the generation of an exclusions preview for the specified assessment template. The exclusions preview lists the potential exclusions (ExclusionPreview) that Inspector can detect before it runs the assessment. 
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createExclusionsPreview* = Call_CreateExclusionsPreview_602026(
    name: "createExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateExclusionsPreview",
    validator: validate_CreateExclusionsPreview_602027, base: "/",
    url: url_CreateExclusionsPreview_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceGroup_602041 = ref object of OpenApiRestCall_601389
proc url_CreateResourceGroup_602043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateResourceGroup_602042(path: JsonNode; query: JsonNode;
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "InspectorService.CreateResourceGroup"))
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

proc call*(call_602053: Call_CreateResourceGroup_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateResourceGroup_602041; body: JsonNode): Recallable =
  ## createResourceGroup
  ## Creates a resource group using the specified set of tags (key and value pairs) that are used to select the EC2 instances to be included in an Amazon Inspector assessment target. The created resource group is then used to create an Amazon Inspector assessment target. For more information, see <a>CreateAssessmentTarget</a>.
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createResourceGroup* = Call_CreateResourceGroup_602041(
    name: "createResourceGroup", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.CreateResourceGroup",
    validator: validate_CreateResourceGroup_602042, base: "/",
    url: url_CreateResourceGroup_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentRun_602056 = ref object of OpenApiRestCall_601389
proc url_DeleteAssessmentRun_602058(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentRun_602057(path: JsonNode; query: JsonNode;
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentRun"))
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

proc call*(call_602068: Call_DeleteAssessmentRun_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_DeleteAssessmentRun_602056; body: JsonNode): Recallable =
  ## deleteAssessmentRun
  ## Deletes the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var deleteAssessmentRun* = Call_DeleteAssessmentRun_602056(
    name: "deleteAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentRun",
    validator: validate_DeleteAssessmentRun_602057, base: "/",
    url: url_DeleteAssessmentRun_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTarget_602071 = ref object of OpenApiRestCall_601389
proc url_DeleteAssessmentTarget_602073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAssessmentTarget_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTarget"))
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

proc call*(call_602083: Call_DeleteAssessmentTarget_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DeleteAssessmentTarget_602071; body: JsonNode): Recallable =
  ## deleteAssessmentTarget
  ## Deletes the assessment target that is specified by the ARN of the assessment target.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var deleteAssessmentTarget* = Call_DeleteAssessmentTarget_602071(
    name: "deleteAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTarget",
    validator: validate_DeleteAssessmentTarget_602072, base: "/",
    url: url_DeleteAssessmentTarget_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssessmentTemplate_602086 = ref object of OpenApiRestCall_601389
proc url_DeleteAssessmentTemplate_602088(protocol: Scheme; host: string;
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

proc validate_DeleteAssessmentTemplate_602087(path: JsonNode; query: JsonNode;
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "InspectorService.DeleteAssessmentTemplate"))
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

proc call*(call_602098: Call_DeleteAssessmentTemplate_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DeleteAssessmentTemplate_602086; body: JsonNode): Recallable =
  ## deleteAssessmentTemplate
  ## Deletes the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var deleteAssessmentTemplate* = Call_DeleteAssessmentTemplate_602086(
    name: "deleteAssessmentTemplate", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DeleteAssessmentTemplate",
    validator: validate_DeleteAssessmentTemplate_602087, base: "/",
    url: url_DeleteAssessmentTemplate_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentRuns_602101 = ref object of OpenApiRestCall_601389
proc url_DescribeAssessmentRuns_602103(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAssessmentRuns_602102(path: JsonNode; query: JsonNode;
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentRuns"))
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

proc call*(call_602113: Call_DescribeAssessmentRuns_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DescribeAssessmentRuns_602101; body: JsonNode): Recallable =
  ## describeAssessmentRuns
  ## Describes the assessment runs that are specified by the ARNs of the assessment runs.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var describeAssessmentRuns* = Call_DescribeAssessmentRuns_602101(
    name: "describeAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentRuns",
    validator: validate_DescribeAssessmentRuns_602102, base: "/",
    url: url_DescribeAssessmentRuns_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTargets_602116 = ref object of OpenApiRestCall_601389
proc url_DescribeAssessmentTargets_602118(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTargets_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTargets"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_DescribeAssessmentTargets_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_DescribeAssessmentTargets_602116; body: JsonNode): Recallable =
  ## describeAssessmentTargets
  ## Describes the assessment targets that are specified by the ARNs of the assessment targets.
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var describeAssessmentTargets* = Call_DescribeAssessmentTargets_602116(
    name: "describeAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTargets",
    validator: validate_DescribeAssessmentTargets_602117, base: "/",
    url: url_DescribeAssessmentTargets_602118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssessmentTemplates_602131 = ref object of OpenApiRestCall_601389
proc url_DescribeAssessmentTemplates_602133(protocol: Scheme; host: string;
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

proc validate_DescribeAssessmentTemplates_602132(path: JsonNode; query: JsonNode;
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
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "InspectorService.DescribeAssessmentTemplates"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_DescribeAssessmentTemplates_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_DescribeAssessmentTemplates_602131; body: JsonNode): Recallable =
  ## describeAssessmentTemplates
  ## Describes the assessment templates that are specified by the ARNs of the assessment templates.
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var describeAssessmentTemplates* = Call_DescribeAssessmentTemplates_602131(
    name: "describeAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeAssessmentTemplates",
    validator: validate_DescribeAssessmentTemplates_602132, base: "/",
    url: url_DescribeAssessmentTemplates_602133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCrossAccountAccessRole_602146 = ref object of OpenApiRestCall_601389
proc url_DescribeCrossAccountAccessRole_602148(protocol: Scheme; host: string;
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

proc validate_DescribeCrossAccountAccessRole_602147(path: JsonNode;
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
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "InspectorService.DescribeCrossAccountAccessRole"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602157: Call_DescribeCrossAccountAccessRole_602146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  ## 
  let valid = call_602157.validator(path, query, header, formData, body)
  let scheme = call_602157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602157.url(scheme.get, call_602157.host, call_602157.base,
                         call_602157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602157, url, valid)

proc call*(call_602158: Call_DescribeCrossAccountAccessRole_602146): Recallable =
  ## describeCrossAccountAccessRole
  ## Describes the IAM role that enables Amazon Inspector to access your AWS account.
  result = call_602158.call(nil, nil, nil, nil, nil)

var describeCrossAccountAccessRole* = Call_DescribeCrossAccountAccessRole_602146(
    name: "describeCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeCrossAccountAccessRole",
    validator: validate_DescribeCrossAccountAccessRole_602147, base: "/",
    url: url_DescribeCrossAccountAccessRole_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExclusions_602159 = ref object of OpenApiRestCall_601389
proc url_DescribeExclusions_602161(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExclusions_602160(path: JsonNode; query: JsonNode;
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
  var valid_602162 = header.getOrDefault("X-Amz-Target")
  valid_602162 = validateParameter(valid_602162, JString, required = true, default = newJString(
      "InspectorService.DescribeExclusions"))
  if valid_602162 != nil:
    section.add "X-Amz-Target", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Signature")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Signature", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Date")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Date", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Credential")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Credential", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Security-Token")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Security-Token", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Algorithm")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Algorithm", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-SignedHeaders", valid_602169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602171: Call_DescribeExclusions_602159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ## 
  let valid = call_602171.validator(path, query, header, formData, body)
  let scheme = call_602171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602171.url(scheme.get, call_602171.host, call_602171.base,
                         call_602171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602171, url, valid)

proc call*(call_602172: Call_DescribeExclusions_602159; body: JsonNode): Recallable =
  ## describeExclusions
  ## Describes the exclusions that are specified by the exclusions' ARNs.
  ##   body: JObject (required)
  var body_602173 = newJObject()
  if body != nil:
    body_602173 = body
  result = call_602172.call(nil, nil, nil, nil, body_602173)

var describeExclusions* = Call_DescribeExclusions_602159(
    name: "describeExclusions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeExclusions",
    validator: validate_DescribeExclusions_602160, base: "/",
    url: url_DescribeExclusions_602161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFindings_602174 = ref object of OpenApiRestCall_601389
proc url_DescribeFindings_602176(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFindings_602175(path: JsonNode; query: JsonNode;
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
  var valid_602177 = header.getOrDefault("X-Amz-Target")
  valid_602177 = validateParameter(valid_602177, JString, required = true, default = newJString(
      "InspectorService.DescribeFindings"))
  if valid_602177 != nil:
    section.add "X-Amz-Target", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Security-Token")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Security-Token", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-SignedHeaders", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_DescribeFindings_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the findings that are specified by the ARNs of the findings.
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602186, url, valid)

proc call*(call_602187: Call_DescribeFindings_602174; body: JsonNode): Recallable =
  ## describeFindings
  ## Describes the findings that are specified by the ARNs of the findings.
  ##   body: JObject (required)
  var body_602188 = newJObject()
  if body != nil:
    body_602188 = body
  result = call_602187.call(nil, nil, nil, nil, body_602188)

var describeFindings* = Call_DescribeFindings_602174(name: "describeFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeFindings",
    validator: validate_DescribeFindings_602175, base: "/",
    url: url_DescribeFindings_602176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeResourceGroups_602189 = ref object of OpenApiRestCall_601389
proc url_DescribeResourceGroups_602191(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeResourceGroups_602190(path: JsonNode; query: JsonNode;
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
  var valid_602192 = header.getOrDefault("X-Amz-Target")
  valid_602192 = validateParameter(valid_602192, JString, required = true, default = newJString(
      "InspectorService.DescribeResourceGroups"))
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

proc call*(call_602201: Call_DescribeResourceGroups_602189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ## 
  let valid = call_602201.validator(path, query, header, formData, body)
  let scheme = call_602201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602201.url(scheme.get, call_602201.host, call_602201.base,
                         call_602201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602201, url, valid)

proc call*(call_602202: Call_DescribeResourceGroups_602189; body: JsonNode): Recallable =
  ## describeResourceGroups
  ## Describes the resource groups that are specified by the ARNs of the resource groups.
  ##   body: JObject (required)
  var body_602203 = newJObject()
  if body != nil:
    body_602203 = body
  result = call_602202.call(nil, nil, nil, nil, body_602203)

var describeResourceGroups* = Call_DescribeResourceGroups_602189(
    name: "describeResourceGroups", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeResourceGroups",
    validator: validate_DescribeResourceGroups_602190, base: "/",
    url: url_DescribeResourceGroups_602191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRulesPackages_602204 = ref object of OpenApiRestCall_601389
proc url_DescribeRulesPackages_602206(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRulesPackages_602205(path: JsonNode; query: JsonNode;
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
  var valid_602207 = header.getOrDefault("X-Amz-Target")
  valid_602207 = validateParameter(valid_602207, JString, required = true, default = newJString(
      "InspectorService.DescribeRulesPackages"))
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

proc call*(call_602216: Call_DescribeRulesPackages_602204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602216, url, valid)

proc call*(call_602217: Call_DescribeRulesPackages_602204; body: JsonNode): Recallable =
  ## describeRulesPackages
  ## Describes the rules packages that are specified by the ARNs of the rules packages.
  ##   body: JObject (required)
  var body_602218 = newJObject()
  if body != nil:
    body_602218 = body
  result = call_602217.call(nil, nil, nil, nil, body_602218)

var describeRulesPackages* = Call_DescribeRulesPackages_602204(
    name: "describeRulesPackages", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.DescribeRulesPackages",
    validator: validate_DescribeRulesPackages_602205, base: "/",
    url: url_DescribeRulesPackages_602206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAssessmentReport_602219 = ref object of OpenApiRestCall_601389
proc url_GetAssessmentReport_602221(protocol: Scheme; host: string; base: string;
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

proc validate_GetAssessmentReport_602220(path: JsonNode; query: JsonNode;
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
  var valid_602222 = header.getOrDefault("X-Amz-Target")
  valid_602222 = validateParameter(valid_602222, JString, required = true, default = newJString(
      "InspectorService.GetAssessmentReport"))
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

proc call*(call_602231: Call_GetAssessmentReport_602219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ## 
  let valid = call_602231.validator(path, query, header, formData, body)
  let scheme = call_602231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602231.url(scheme.get, call_602231.host, call_602231.base,
                         call_602231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602231, url, valid)

proc call*(call_602232: Call_GetAssessmentReport_602219; body: JsonNode): Recallable =
  ## getAssessmentReport
  ## Produces an assessment report that includes detailed and comprehensive results of a specified assessment run. 
  ##   body: JObject (required)
  var body_602233 = newJObject()
  if body != nil:
    body_602233 = body
  result = call_602232.call(nil, nil, nil, nil, body_602233)

var getAssessmentReport* = Call_GetAssessmentReport_602219(
    name: "getAssessmentReport", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetAssessmentReport",
    validator: validate_GetAssessmentReport_602220, base: "/",
    url: url_GetAssessmentReport_602221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExclusionsPreview_602234 = ref object of OpenApiRestCall_601389
proc url_GetExclusionsPreview_602236(protocol: Scheme; host: string; base: string;
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

proc validate_GetExclusionsPreview_602235(path: JsonNode; query: JsonNode;
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
  var valid_602237 = query.getOrDefault("nextToken")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "nextToken", valid_602237
  var valid_602238 = query.getOrDefault("maxResults")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "maxResults", valid_602238
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
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "InspectorService.GetExclusionsPreview"))
  if valid_602239 != nil:
    section.add "X-Amz-Target", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_GetExclusionsPreview_602234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_GetExclusionsPreview_602234; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getExclusionsPreview
  ## Retrieves the exclusions preview (a list of ExclusionPreview objects) specified by the preview token. You can obtain the preview token by running the CreateExclusionsPreview API.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602250 = newJObject()
  var body_602251 = newJObject()
  add(query_602250, "nextToken", newJString(nextToken))
  if body != nil:
    body_602251 = body
  add(query_602250, "maxResults", newJString(maxResults))
  result = call_602249.call(nil, query_602250, nil, nil, body_602251)

var getExclusionsPreview* = Call_GetExclusionsPreview_602234(
    name: "getExclusionsPreview", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetExclusionsPreview",
    validator: validate_GetExclusionsPreview_602235, base: "/",
    url: url_GetExclusionsPreview_602236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTelemetryMetadata_602253 = ref object of OpenApiRestCall_601389
proc url_GetTelemetryMetadata_602255(protocol: Scheme; host: string; base: string;
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

proc validate_GetTelemetryMetadata_602254(path: JsonNode; query: JsonNode;
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
  var valid_602256 = header.getOrDefault("X-Amz-Target")
  valid_602256 = validateParameter(valid_602256, JString, required = true, default = newJString(
      "InspectorService.GetTelemetryMetadata"))
  if valid_602256 != nil:
    section.add "X-Amz-Target", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Signature")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Signature", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Content-Sha256", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Date")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Date", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Credential")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Credential", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Security-Token")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Security-Token", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Algorithm")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Algorithm", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-SignedHeaders", valid_602263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602265: Call_GetTelemetryMetadata_602253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Information about the data that is collected for the specified assessment run.
  ## 
  let valid = call_602265.validator(path, query, header, formData, body)
  let scheme = call_602265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602265.url(scheme.get, call_602265.host, call_602265.base,
                         call_602265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602265, url, valid)

proc call*(call_602266: Call_GetTelemetryMetadata_602253; body: JsonNode): Recallable =
  ## getTelemetryMetadata
  ## Information about the data that is collected for the specified assessment run.
  ##   body: JObject (required)
  var body_602267 = newJObject()
  if body != nil:
    body_602267 = body
  result = call_602266.call(nil, nil, nil, nil, body_602267)

var getTelemetryMetadata* = Call_GetTelemetryMetadata_602253(
    name: "getTelemetryMetadata", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.GetTelemetryMetadata",
    validator: validate_GetTelemetryMetadata_602254, base: "/",
    url: url_GetTelemetryMetadata_602255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRunAgents_602268 = ref object of OpenApiRestCall_601389
proc url_ListAssessmentRunAgents_602270(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRunAgents_602269(path: JsonNode; query: JsonNode;
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
  var valid_602271 = query.getOrDefault("nextToken")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "nextToken", valid_602271
  var valid_602272 = query.getOrDefault("maxResults")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "maxResults", valid_602272
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
  var valid_602273 = header.getOrDefault("X-Amz-Target")
  valid_602273 = validateParameter(valid_602273, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRunAgents"))
  if valid_602273 != nil:
    section.add "X-Amz-Target", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Signature")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Signature", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Content-Sha256", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Date")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Date", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Credential")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Credential", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Security-Token")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Security-Token", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Algorithm")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Algorithm", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-SignedHeaders", valid_602280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602282: Call_ListAssessmentRunAgents_602268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_602282.validator(path, query, header, formData, body)
  let scheme = call_602282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602282.url(scheme.get, call_602282.host, call_602282.base,
                         call_602282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602282, url, valid)

proc call*(call_602283: Call_ListAssessmentRunAgents_602268; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRunAgents
  ## Lists the agents of the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602284 = newJObject()
  var body_602285 = newJObject()
  add(query_602284, "nextToken", newJString(nextToken))
  if body != nil:
    body_602285 = body
  add(query_602284, "maxResults", newJString(maxResults))
  result = call_602283.call(nil, query_602284, nil, nil, body_602285)

var listAssessmentRunAgents* = Call_ListAssessmentRunAgents_602268(
    name: "listAssessmentRunAgents", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRunAgents",
    validator: validate_ListAssessmentRunAgents_602269, base: "/",
    url: url_ListAssessmentRunAgents_602270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentRuns_602286 = ref object of OpenApiRestCall_601389
proc url_ListAssessmentRuns_602288(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentRuns_602287(path: JsonNode; query: JsonNode;
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
  var valid_602289 = query.getOrDefault("nextToken")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "nextToken", valid_602289
  var valid_602290 = query.getOrDefault("maxResults")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "maxResults", valid_602290
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
  var valid_602291 = header.getOrDefault("X-Amz-Target")
  valid_602291 = validateParameter(valid_602291, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentRuns"))
  if valid_602291 != nil:
    section.add "X-Amz-Target", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Signature")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Signature", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Content-Sha256", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Credential")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Credential", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Security-Token")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Security-Token", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-SignedHeaders", valid_602298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602300: Call_ListAssessmentRuns_602286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ## 
  let valid = call_602300.validator(path, query, header, formData, body)
  let scheme = call_602300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602300.url(scheme.get, call_602300.host, call_602300.base,
                         call_602300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602300, url, valid)

proc call*(call_602301: Call_ListAssessmentRuns_602286; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentRuns
  ## Lists the assessment runs that correspond to the assessment templates that are specified by the ARNs of the assessment templates.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602302 = newJObject()
  var body_602303 = newJObject()
  add(query_602302, "nextToken", newJString(nextToken))
  if body != nil:
    body_602303 = body
  add(query_602302, "maxResults", newJString(maxResults))
  result = call_602301.call(nil, query_602302, nil, nil, body_602303)

var listAssessmentRuns* = Call_ListAssessmentRuns_602286(
    name: "listAssessmentRuns", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentRuns",
    validator: validate_ListAssessmentRuns_602287, base: "/",
    url: url_ListAssessmentRuns_602288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTargets_602304 = ref object of OpenApiRestCall_601389
proc url_ListAssessmentTargets_602306(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTargets_602305(path: JsonNode; query: JsonNode;
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
  var valid_602307 = query.getOrDefault("nextToken")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "nextToken", valid_602307
  var valid_602308 = query.getOrDefault("maxResults")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "maxResults", valid_602308
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
  var valid_602309 = header.getOrDefault("X-Amz-Target")
  valid_602309 = validateParameter(valid_602309, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTargets"))
  if valid_602309 != nil:
    section.add "X-Amz-Target", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Signature")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Signature", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Content-Sha256", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Date")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Date", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Security-Token")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Security-Token", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Algorithm")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Algorithm", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-SignedHeaders", valid_602316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602318: Call_ListAssessmentTargets_602304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ## 
  let valid = call_602318.validator(path, query, header, formData, body)
  let scheme = call_602318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602318.url(scheme.get, call_602318.host, call_602318.base,
                         call_602318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602318, url, valid)

proc call*(call_602319: Call_ListAssessmentTargets_602304; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTargets
  ## Lists the ARNs of the assessment targets within this AWS account. For more information about assessment targets, see <a href="https://docs.aws.amazon.com/inspector/latest/userguide/inspector_applications.html">Amazon Inspector Assessment Targets</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602320 = newJObject()
  var body_602321 = newJObject()
  add(query_602320, "nextToken", newJString(nextToken))
  if body != nil:
    body_602321 = body
  add(query_602320, "maxResults", newJString(maxResults))
  result = call_602319.call(nil, query_602320, nil, nil, body_602321)

var listAssessmentTargets* = Call_ListAssessmentTargets_602304(
    name: "listAssessmentTargets", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTargets",
    validator: validate_ListAssessmentTargets_602305, base: "/",
    url: url_ListAssessmentTargets_602306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssessmentTemplates_602322 = ref object of OpenApiRestCall_601389
proc url_ListAssessmentTemplates_602324(protocol: Scheme; host: string; base: string;
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

proc validate_ListAssessmentTemplates_602323(path: JsonNode; query: JsonNode;
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
  var valid_602325 = query.getOrDefault("nextToken")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "nextToken", valid_602325
  var valid_602326 = query.getOrDefault("maxResults")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "maxResults", valid_602326
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
  var valid_602327 = header.getOrDefault("X-Amz-Target")
  valid_602327 = validateParameter(valid_602327, JString, required = true, default = newJString(
      "InspectorService.ListAssessmentTemplates"))
  if valid_602327 != nil:
    section.add "X-Amz-Target", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Signature")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Signature", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Content-Sha256", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Date")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Date", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Credential")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Credential", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Security-Token")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Security-Token", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602336: Call_ListAssessmentTemplates_602322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ## 
  let valid = call_602336.validator(path, query, header, formData, body)
  let scheme = call_602336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602336.url(scheme.get, call_602336.host, call_602336.base,
                         call_602336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602336, url, valid)

proc call*(call_602337: Call_ListAssessmentTemplates_602322; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssessmentTemplates
  ## Lists the assessment templates that correspond to the assessment targets that are specified by the ARNs of the assessment targets.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602338 = newJObject()
  var body_602339 = newJObject()
  add(query_602338, "nextToken", newJString(nextToken))
  if body != nil:
    body_602339 = body
  add(query_602338, "maxResults", newJString(maxResults))
  result = call_602337.call(nil, query_602338, nil, nil, body_602339)

var listAssessmentTemplates* = Call_ListAssessmentTemplates_602322(
    name: "listAssessmentTemplates", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListAssessmentTemplates",
    validator: validate_ListAssessmentTemplates_602323, base: "/",
    url: url_ListAssessmentTemplates_602324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSubscriptions_602340 = ref object of OpenApiRestCall_601389
proc url_ListEventSubscriptions_602342(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSubscriptions_602341(path: JsonNode; query: JsonNode;
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
  var valid_602343 = query.getOrDefault("nextToken")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "nextToken", valid_602343
  var valid_602344 = query.getOrDefault("maxResults")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "maxResults", valid_602344
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
  var valid_602345 = header.getOrDefault("X-Amz-Target")
  valid_602345 = validateParameter(valid_602345, JString, required = true, default = newJString(
      "InspectorService.ListEventSubscriptions"))
  if valid_602345 != nil:
    section.add "X-Amz-Target", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Signature")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Signature", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Content-Sha256", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Date")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Date", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Credential")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Credential", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Security-Token")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Security-Token", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Algorithm")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Algorithm", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-SignedHeaders", valid_602352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602354: Call_ListEventSubscriptions_602340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ## 
  let valid = call_602354.validator(path, query, header, formData, body)
  let scheme = call_602354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602354.url(scheme.get, call_602354.host, call_602354.base,
                         call_602354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602354, url, valid)

proc call*(call_602355: Call_ListEventSubscriptions_602340; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listEventSubscriptions
  ## Lists all the event subscriptions for the assessment template that is specified by the ARN of the assessment template. For more information, see <a>SubscribeToEvent</a> and <a>UnsubscribeFromEvent</a>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602356 = newJObject()
  var body_602357 = newJObject()
  add(query_602356, "nextToken", newJString(nextToken))
  if body != nil:
    body_602357 = body
  add(query_602356, "maxResults", newJString(maxResults))
  result = call_602355.call(nil, query_602356, nil, nil, body_602357)

var listEventSubscriptions* = Call_ListEventSubscriptions_602340(
    name: "listEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListEventSubscriptions",
    validator: validate_ListEventSubscriptions_602341, base: "/",
    url: url_ListEventSubscriptions_602342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExclusions_602358 = ref object of OpenApiRestCall_601389
proc url_ListExclusions_602360(protocol: Scheme; host: string; base: string;
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

proc validate_ListExclusions_602359(path: JsonNode; query: JsonNode;
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
  var valid_602361 = query.getOrDefault("nextToken")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "nextToken", valid_602361
  var valid_602362 = query.getOrDefault("maxResults")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "maxResults", valid_602362
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
  var valid_602363 = header.getOrDefault("X-Amz-Target")
  valid_602363 = validateParameter(valid_602363, JString, required = true, default = newJString(
      "InspectorService.ListExclusions"))
  if valid_602363 != nil:
    section.add "X-Amz-Target", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Signature")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Signature", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Content-Sha256", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Credential")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Credential", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-SignedHeaders", valid_602370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602372: Call_ListExclusions_602358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List exclusions that are generated by the assessment run.
  ## 
  let valid = call_602372.validator(path, query, header, formData, body)
  let scheme = call_602372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602372.url(scheme.get, call_602372.host, call_602372.base,
                         call_602372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602372, url, valid)

proc call*(call_602373: Call_ListExclusions_602358; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listExclusions
  ## List exclusions that are generated by the assessment run.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602374 = newJObject()
  var body_602375 = newJObject()
  add(query_602374, "nextToken", newJString(nextToken))
  if body != nil:
    body_602375 = body
  add(query_602374, "maxResults", newJString(maxResults))
  result = call_602373.call(nil, query_602374, nil, nil, body_602375)

var listExclusions* = Call_ListExclusions_602358(name: "listExclusions",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListExclusions",
    validator: validate_ListExclusions_602359, base: "/", url: url_ListExclusions_602360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_602376 = ref object of OpenApiRestCall_601389
proc url_ListFindings_602378(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_602377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602379 = query.getOrDefault("nextToken")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "nextToken", valid_602379
  var valid_602380 = query.getOrDefault("maxResults")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "maxResults", valid_602380
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
  var valid_602381 = header.getOrDefault("X-Amz-Target")
  valid_602381 = validateParameter(valid_602381, JString, required = true, default = newJString(
      "InspectorService.ListFindings"))
  if valid_602381 != nil:
    section.add "X-Amz-Target", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_ListFindings_602376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_ListFindings_602376; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFindings
  ## Lists findings that are generated by the assessment runs that are specified by the ARNs of the assessment runs.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602392 = newJObject()
  var body_602393 = newJObject()
  add(query_602392, "nextToken", newJString(nextToken))
  if body != nil:
    body_602393 = body
  add(query_602392, "maxResults", newJString(maxResults))
  result = call_602391.call(nil, query_602392, nil, nil, body_602393)

var listFindings* = Call_ListFindings_602376(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListFindings",
    validator: validate_ListFindings_602377, base: "/", url: url_ListFindings_602378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRulesPackages_602394 = ref object of OpenApiRestCall_601389
proc url_ListRulesPackages_602396(protocol: Scheme; host: string; base: string;
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

proc validate_ListRulesPackages_602395(path: JsonNode; query: JsonNode;
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
  var valid_602397 = query.getOrDefault("nextToken")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "nextToken", valid_602397
  var valid_602398 = query.getOrDefault("maxResults")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "maxResults", valid_602398
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
  var valid_602399 = header.getOrDefault("X-Amz-Target")
  valid_602399 = validateParameter(valid_602399, JString, required = true, default = newJString(
      "InspectorService.ListRulesPackages"))
  if valid_602399 != nil:
    section.add "X-Amz-Target", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Signature")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Signature", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Content-Sha256", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Date")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Date", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Credential")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Credential", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Security-Token")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Security-Token", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Algorithm")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Algorithm", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-SignedHeaders", valid_602406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602408: Call_ListRulesPackages_602394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all available Amazon Inspector rules packages.
  ## 
  let valid = call_602408.validator(path, query, header, formData, body)
  let scheme = call_602408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602408.url(scheme.get, call_602408.host, call_602408.base,
                         call_602408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602408, url, valid)

proc call*(call_602409: Call_ListRulesPackages_602394; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRulesPackages
  ## Lists all available Amazon Inspector rules packages.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602410 = newJObject()
  var body_602411 = newJObject()
  add(query_602410, "nextToken", newJString(nextToken))
  if body != nil:
    body_602411 = body
  add(query_602410, "maxResults", newJString(maxResults))
  result = call_602409.call(nil, query_602410, nil, nil, body_602411)

var listRulesPackages* = Call_ListRulesPackages_602394(name: "listRulesPackages",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListRulesPackages",
    validator: validate_ListRulesPackages_602395, base: "/",
    url: url_ListRulesPackages_602396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602412 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602414(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602413(path: JsonNode; query: JsonNode;
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
  var valid_602415 = header.getOrDefault("X-Amz-Target")
  valid_602415 = validateParameter(valid_602415, JString, required = true, default = newJString(
      "InspectorService.ListTagsForResource"))
  if valid_602415 != nil:
    section.add "X-Amz-Target", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Signature")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Signature", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Content-Sha256", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Date")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Date", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Credential")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Credential", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Security-Token")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Security-Token", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Algorithm")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Algorithm", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-SignedHeaders", valid_602422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602424: Call_ListTagsForResource_602412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags associated with an assessment template.
  ## 
  let valid = call_602424.validator(path, query, header, formData, body)
  let scheme = call_602424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602424.url(scheme.get, call_602424.host, call_602424.base,
                         call_602424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602424, url, valid)

proc call*(call_602425: Call_ListTagsForResource_602412; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags associated with an assessment template.
  ##   body: JObject (required)
  var body_602426 = newJObject()
  if body != nil:
    body_602426 = body
  result = call_602425.call(nil, nil, nil, nil, body_602426)

var listTagsForResource* = Call_ListTagsForResource_602412(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.ListTagsForResource",
    validator: validate_ListTagsForResource_602413, base: "/",
    url: url_ListTagsForResource_602414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PreviewAgents_602427 = ref object of OpenApiRestCall_601389
proc url_PreviewAgents_602429(protocol: Scheme; host: string; base: string;
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

proc validate_PreviewAgents_602428(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602430 = query.getOrDefault("nextToken")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "nextToken", valid_602430
  var valid_602431 = query.getOrDefault("maxResults")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "maxResults", valid_602431
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
  var valid_602432 = header.getOrDefault("X-Amz-Target")
  valid_602432 = validateParameter(valid_602432, JString, required = true, default = newJString(
      "InspectorService.PreviewAgents"))
  if valid_602432 != nil:
    section.add "X-Amz-Target", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Signature")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Signature", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Content-Sha256", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Date")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Date", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Credential")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Credential", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Algorithm")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Algorithm", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602441: Call_PreviewAgents_602427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ## 
  let valid = call_602441.validator(path, query, header, formData, body)
  let scheme = call_602441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602441.url(scheme.get, call_602441.host, call_602441.base,
                         call_602441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602441, url, valid)

proc call*(call_602442: Call_PreviewAgents_602427; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## previewAgents
  ## Previews the agents installed on the EC2 instances that are part of the specified assessment target.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602443 = newJObject()
  var body_602444 = newJObject()
  add(query_602443, "nextToken", newJString(nextToken))
  if body != nil:
    body_602444 = body
  add(query_602443, "maxResults", newJString(maxResults))
  result = call_602442.call(nil, query_602443, nil, nil, body_602444)

var previewAgents* = Call_PreviewAgents_602427(name: "previewAgents",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.PreviewAgents",
    validator: validate_PreviewAgents_602428, base: "/", url: url_PreviewAgents_602429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCrossAccountAccessRole_602445 = ref object of OpenApiRestCall_601389
proc url_RegisterCrossAccountAccessRole_602447(protocol: Scheme; host: string;
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

proc validate_RegisterCrossAccountAccessRole_602446(path: JsonNode;
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
  var valid_602448 = header.getOrDefault("X-Amz-Target")
  valid_602448 = validateParameter(valid_602448, JString, required = true, default = newJString(
      "InspectorService.RegisterCrossAccountAccessRole"))
  if valid_602448 != nil:
    section.add "X-Amz-Target", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Signature")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Signature", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Content-Sha256", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Date")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Date", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Credential")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Credential", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Security-Token")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Security-Token", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Algorithm")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Algorithm", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-SignedHeaders", valid_602455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602457: Call_RegisterCrossAccountAccessRole_602445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ## 
  let valid = call_602457.validator(path, query, header, formData, body)
  let scheme = call_602457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602457.url(scheme.get, call_602457.host, call_602457.base,
                         call_602457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602457, url, valid)

proc call*(call_602458: Call_RegisterCrossAccountAccessRole_602445; body: JsonNode): Recallable =
  ## registerCrossAccountAccessRole
  ## Registers the IAM role that grants Amazon Inspector access to AWS Services needed to perform security assessments.
  ##   body: JObject (required)
  var body_602459 = newJObject()
  if body != nil:
    body_602459 = body
  result = call_602458.call(nil, nil, nil, nil, body_602459)

var registerCrossAccountAccessRole* = Call_RegisterCrossAccountAccessRole_602445(
    name: "registerCrossAccountAccessRole", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RegisterCrossAccountAccessRole",
    validator: validate_RegisterCrossAccountAccessRole_602446, base: "/",
    url: url_RegisterCrossAccountAccessRole_602447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAttributesFromFindings_602460 = ref object of OpenApiRestCall_601389
proc url_RemoveAttributesFromFindings_602462(protocol: Scheme; host: string;
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

proc validate_RemoveAttributesFromFindings_602461(path: JsonNode; query: JsonNode;
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
  var valid_602463 = header.getOrDefault("X-Amz-Target")
  valid_602463 = validateParameter(valid_602463, JString, required = true, default = newJString(
      "InspectorService.RemoveAttributesFromFindings"))
  if valid_602463 != nil:
    section.add "X-Amz-Target", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Signature")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Signature", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Content-Sha256", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Date")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Date", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Credential")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Credential", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Security-Token")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Security-Token", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Algorithm")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Algorithm", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-SignedHeaders", valid_602470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602472: Call_RemoveAttributesFromFindings_602460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ## 
  let valid = call_602472.validator(path, query, header, formData, body)
  let scheme = call_602472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602472.url(scheme.get, call_602472.host, call_602472.base,
                         call_602472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602472, url, valid)

proc call*(call_602473: Call_RemoveAttributesFromFindings_602460; body: JsonNode): Recallable =
  ## removeAttributesFromFindings
  ## Removes entire attributes (key and value pairs) from the findings that are specified by the ARNs of the findings where an attribute with the specified key exists.
  ##   body: JObject (required)
  var body_602474 = newJObject()
  if body != nil:
    body_602474 = body
  result = call_602473.call(nil, nil, nil, nil, body_602474)

var removeAttributesFromFindings* = Call_RemoveAttributesFromFindings_602460(
    name: "removeAttributesFromFindings", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.RemoveAttributesFromFindings",
    validator: validate_RemoveAttributesFromFindings_602461, base: "/",
    url: url_RemoveAttributesFromFindings_602462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTagsForResource_602475 = ref object of OpenApiRestCall_601389
proc url_SetTagsForResource_602477(protocol: Scheme; host: string; base: string;
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

proc validate_SetTagsForResource_602476(path: JsonNode; query: JsonNode;
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
  var valid_602478 = header.getOrDefault("X-Amz-Target")
  valid_602478 = validateParameter(valid_602478, JString, required = true, default = newJString(
      "InspectorService.SetTagsForResource"))
  if valid_602478 != nil:
    section.add "X-Amz-Target", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Signature")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Signature", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Content-Sha256", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Date")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Date", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Credential")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Credential", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Security-Token")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Security-Token", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Algorithm")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Algorithm", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-SignedHeaders", valid_602485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602487: Call_SetTagsForResource_602475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ## 
  let valid = call_602487.validator(path, query, header, formData, body)
  let scheme = call_602487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602487.url(scheme.get, call_602487.host, call_602487.base,
                         call_602487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602487, url, valid)

proc call*(call_602488: Call_SetTagsForResource_602475; body: JsonNode): Recallable =
  ## setTagsForResource
  ## Sets tags (key and value pairs) to the assessment template that is specified by the ARN of the assessment template.
  ##   body: JObject (required)
  var body_602489 = newJObject()
  if body != nil:
    body_602489 = body
  result = call_602488.call(nil, nil, nil, nil, body_602489)

var setTagsForResource* = Call_SetTagsForResource_602475(
    name: "setTagsForResource", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SetTagsForResource",
    validator: validate_SetTagsForResource_602476, base: "/",
    url: url_SetTagsForResource_602477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssessmentRun_602490 = ref object of OpenApiRestCall_601389
proc url_StartAssessmentRun_602492(protocol: Scheme; host: string; base: string;
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

proc validate_StartAssessmentRun_602491(path: JsonNode; query: JsonNode;
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
  var valid_602493 = header.getOrDefault("X-Amz-Target")
  valid_602493 = validateParameter(valid_602493, JString, required = true, default = newJString(
      "InspectorService.StartAssessmentRun"))
  if valid_602493 != nil:
    section.add "X-Amz-Target", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Signature")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Signature", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Content-Sha256", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Date")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Date", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Credential")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Credential", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Security-Token")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Security-Token", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Algorithm")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Algorithm", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-SignedHeaders", valid_602500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602502: Call_StartAssessmentRun_602490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ## 
  let valid = call_602502.validator(path, query, header, formData, body)
  let scheme = call_602502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602502.url(scheme.get, call_602502.host, call_602502.base,
                         call_602502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602502, url, valid)

proc call*(call_602503: Call_StartAssessmentRun_602490; body: JsonNode): Recallable =
  ## startAssessmentRun
  ## Starts the assessment run specified by the ARN of the assessment template. For this API to function properly, you must not exceed the limit of running up to 500 concurrent agents per AWS account.
  ##   body: JObject (required)
  var body_602504 = newJObject()
  if body != nil:
    body_602504 = body
  result = call_602503.call(nil, nil, nil, nil, body_602504)

var startAssessmentRun* = Call_StartAssessmentRun_602490(
    name: "startAssessmentRun", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StartAssessmentRun",
    validator: validate_StartAssessmentRun_602491, base: "/",
    url: url_StartAssessmentRun_602492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAssessmentRun_602505 = ref object of OpenApiRestCall_601389
proc url_StopAssessmentRun_602507(protocol: Scheme; host: string; base: string;
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

proc validate_StopAssessmentRun_602506(path: JsonNode; query: JsonNode;
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
  var valid_602508 = header.getOrDefault("X-Amz-Target")
  valid_602508 = validateParameter(valid_602508, JString, required = true, default = newJString(
      "InspectorService.StopAssessmentRun"))
  if valid_602508 != nil:
    section.add "X-Amz-Target", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Signature")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Signature", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Content-Sha256", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Date")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Date", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Credential")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Credential", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Security-Token")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Security-Token", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Algorithm")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Algorithm", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-SignedHeaders", valid_602515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602517: Call_StopAssessmentRun_602505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ## 
  let valid = call_602517.validator(path, query, header, formData, body)
  let scheme = call_602517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602517.url(scheme.get, call_602517.host, call_602517.base,
                         call_602517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602517, url, valid)

proc call*(call_602518: Call_StopAssessmentRun_602505; body: JsonNode): Recallable =
  ## stopAssessmentRun
  ## Stops the assessment run that is specified by the ARN of the assessment run.
  ##   body: JObject (required)
  var body_602519 = newJObject()
  if body != nil:
    body_602519 = body
  result = call_602518.call(nil, nil, nil, nil, body_602519)

var stopAssessmentRun* = Call_StopAssessmentRun_602505(name: "stopAssessmentRun",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.StopAssessmentRun",
    validator: validate_StopAssessmentRun_602506, base: "/",
    url: url_StopAssessmentRun_602507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubscribeToEvent_602520 = ref object of OpenApiRestCall_601389
proc url_SubscribeToEvent_602522(protocol: Scheme; host: string; base: string;
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

proc validate_SubscribeToEvent_602521(path: JsonNode; query: JsonNode;
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
  var valid_602523 = header.getOrDefault("X-Amz-Target")
  valid_602523 = validateParameter(valid_602523, JString, required = true, default = newJString(
      "InspectorService.SubscribeToEvent"))
  if valid_602523 != nil:
    section.add "X-Amz-Target", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Signature")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Signature", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Content-Sha256", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Date")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Date", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Credential")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Credential", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Security-Token")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Security-Token", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Algorithm")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Algorithm", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-SignedHeaders", valid_602530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602532: Call_SubscribeToEvent_602520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_602532.validator(path, query, header, formData, body)
  let scheme = call_602532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602532.url(scheme.get, call_602532.host, call_602532.base,
                         call_602532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602532, url, valid)

proc call*(call_602533: Call_SubscribeToEvent_602520; body: JsonNode): Recallable =
  ## subscribeToEvent
  ## Enables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_602534 = newJObject()
  if body != nil:
    body_602534 = body
  result = call_602533.call(nil, nil, nil, nil, body_602534)

var subscribeToEvent* = Call_SubscribeToEvent_602520(name: "subscribeToEvent",
    meth: HttpMethod.HttpPost, host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.SubscribeToEvent",
    validator: validate_SubscribeToEvent_602521, base: "/",
    url: url_SubscribeToEvent_602522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnsubscribeFromEvent_602535 = ref object of OpenApiRestCall_601389
proc url_UnsubscribeFromEvent_602537(protocol: Scheme; host: string; base: string;
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

proc validate_UnsubscribeFromEvent_602536(path: JsonNode; query: JsonNode;
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
  var valid_602538 = header.getOrDefault("X-Amz-Target")
  valid_602538 = validateParameter(valid_602538, JString, required = true, default = newJString(
      "InspectorService.UnsubscribeFromEvent"))
  if valid_602538 != nil:
    section.add "X-Amz-Target", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Signature")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Signature", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Date")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Date", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Credential")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Credential", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Security-Token")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Security-Token", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Algorithm")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Algorithm", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-SignedHeaders", valid_602545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602547: Call_UnsubscribeFromEvent_602535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ## 
  let valid = call_602547.validator(path, query, header, formData, body)
  let scheme = call_602547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602547.url(scheme.get, call_602547.host, call_602547.base,
                         call_602547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602547, url, valid)

proc call*(call_602548: Call_UnsubscribeFromEvent_602535; body: JsonNode): Recallable =
  ## unsubscribeFromEvent
  ## Disables the process of sending Amazon Simple Notification Service (SNS) notifications about a specified event to a specified SNS topic.
  ##   body: JObject (required)
  var body_602549 = newJObject()
  if body != nil:
    body_602549 = body
  result = call_602548.call(nil, nil, nil, nil, body_602549)

var unsubscribeFromEvent* = Call_UnsubscribeFromEvent_602535(
    name: "unsubscribeFromEvent", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UnsubscribeFromEvent",
    validator: validate_UnsubscribeFromEvent_602536, base: "/",
    url: url_UnsubscribeFromEvent_602537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssessmentTarget_602550 = ref object of OpenApiRestCall_601389
proc url_UpdateAssessmentTarget_602552(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAssessmentTarget_602551(path: JsonNode; query: JsonNode;
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
  var valid_602553 = header.getOrDefault("X-Amz-Target")
  valid_602553 = validateParameter(valid_602553, JString, required = true, default = newJString(
      "InspectorService.UpdateAssessmentTarget"))
  if valid_602553 != nil:
    section.add "X-Amz-Target", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Signature")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Signature", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Content-Sha256", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Date")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Date", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Credential")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Credential", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Security-Token")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Security-Token", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Algorithm")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Algorithm", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-SignedHeaders", valid_602560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602562: Call_UpdateAssessmentTarget_602550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ## 
  let valid = call_602562.validator(path, query, header, formData, body)
  let scheme = call_602562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602562.url(scheme.get, call_602562.host, call_602562.base,
                         call_602562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602562, url, valid)

proc call*(call_602563: Call_UpdateAssessmentTarget_602550; body: JsonNode): Recallable =
  ## updateAssessmentTarget
  ## <p>Updates the assessment target that is specified by the ARN of the assessment target.</p> <p>If resourceGroupArn is not specified, all EC2 instances in the current AWS account and region are included in the assessment target.</p>
  ##   body: JObject (required)
  var body_602564 = newJObject()
  if body != nil:
    body_602564 = body
  result = call_602563.call(nil, nil, nil, nil, body_602564)

var updateAssessmentTarget* = Call_UpdateAssessmentTarget_602550(
    name: "updateAssessmentTarget", meth: HttpMethod.HttpPost,
    host: "inspector.amazonaws.com",
    route: "/#X-Amz-Target=InspectorService.UpdateAssessmentTarget",
    validator: validate_UpdateAssessmentTarget_602551, base: "/",
    url: url_UpdateAssessmentTarget_602552, schemes: {Scheme.Https, Scheme.Http})
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
