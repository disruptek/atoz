
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon SageMaker Service
## version: 2017-07-24
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides APIs for creating and managing Amazon SageMaker resources.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sagemaker/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.sagemaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.sagemaker.ap-southeast-1.amazonaws.com", "us-west-2": "api.sagemaker.us-west-2.amazonaws.com", "eu-west-2": "api.sagemaker.eu-west-2.amazonaws.com", "ap-northeast-3": "api.sagemaker.ap-northeast-3.amazonaws.com", "eu-central-1": "api.sagemaker.eu-central-1.amazonaws.com", "us-east-2": "api.sagemaker.us-east-2.amazonaws.com", "us-east-1": "api.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "api.sagemaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.sagemaker.ap-south-1.amazonaws.com", "eu-north-1": "api.sagemaker.eu-north-1.amazonaws.com", "ap-northeast-2": "api.sagemaker.ap-northeast-2.amazonaws.com", "us-west-1": "api.sagemaker.us-west-1.amazonaws.com", "us-gov-east-1": "api.sagemaker.us-gov-east-1.amazonaws.com", "eu-west-3": "api.sagemaker.eu-west-3.amazonaws.com", "cn-north-1": "api.sagemaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.sagemaker.sa-east-1.amazonaws.com", "eu-west-1": "api.sagemaker.eu-west-1.amazonaws.com", "us-gov-west-1": "api.sagemaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.sagemaker.ap-southeast-2.amazonaws.com", "ca-central-1": "api.sagemaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.sagemaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.sagemaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.sagemaker.us-west-2.amazonaws.com",
      "eu-west-2": "api.sagemaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.sagemaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.sagemaker.eu-central-1.amazonaws.com",
      "us-east-2": "api.sagemaker.us-east-2.amazonaws.com",
      "us-east-1": "api.sagemaker.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.sagemaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.sagemaker.ap-south-1.amazonaws.com",
      "eu-north-1": "api.sagemaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.sagemaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.sagemaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.sagemaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.sagemaker.eu-west-3.amazonaws.com",
      "cn-north-1": "api.sagemaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.sagemaker.sa-east-1.amazonaws.com",
      "eu-west-1": "api.sagemaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.sagemaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.sagemaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.sagemaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sagemaker"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_610996 = ref object of OpenApiRestCall_610658
proc url_AddTags_610998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AddTags_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AddTags_610996; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var addTags* = Call_AddTags_610996(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_610997, base: "/",
                                url: url_AddTags_610998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_611265 = ref object of OpenApiRestCall_610658
proc url_AssociateTrialComponent_611267(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTrialComponent_611266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_AssociateTrialComponent_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_AssociateTrialComponent_611265; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var associateTrialComponent* = Call_AssociateTrialComponent_611265(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_611266, base: "/",
    url: url_AssociateTrialComponent_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_611280 = ref object of OpenApiRestCall_610658
proc url_CreateAlgorithm_611282(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlgorithm_611281(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CreateAlgorithm_611280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CreateAlgorithm_611280; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var createAlgorithm* = Call_CreateAlgorithm_611280(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_611281, base: "/", url: url_CreateAlgorithm_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_611295 = ref object of OpenApiRestCall_610658
proc url_CreateApp_611297(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_611296(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true,
                                 default = newJString("SageMaker.CreateApp"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_CreateApp_611295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CreateApp_611295; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var createApp* = Call_CreateApp_611295(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                    validator: validate_CreateApp_611296,
                                    base: "/", url: url_CreateApp_611297,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_611310 = ref object of OpenApiRestCall_610658
proc url_CreateAutoMLJob_611312(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAutoMLJob_611311(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates an AutoPilot job.
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
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_CreateAutoMLJob_611310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_CreateAutoMLJob_611310; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var createAutoMLJob* = Call_CreateAutoMLJob_611310(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_611311, base: "/", url: url_CreateAutoMLJob_611312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_611325 = ref object of OpenApiRestCall_610658
proc url_CreateCodeRepository_611327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCodeRepository_611326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
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
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_CreateCodeRepository_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_CreateCodeRepository_611325; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var createCodeRepository* = Call_CreateCodeRepository_611325(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_611326, base: "/",
    url: url_CreateCodeRepository_611327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_611340 = ref object of OpenApiRestCall_610658
proc url_CreateCompilationJob_611342(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCompilationJob_611341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
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
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_CreateCompilationJob_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_CreateCompilationJob_611340; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var createCompilationJob* = Call_CreateCompilationJob_611340(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_611341, base: "/",
    url: url_CreateCompilationJob_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_611355 = ref object of OpenApiRestCall_610658
proc url_CreateDomain_611357(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_611356(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
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
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true,
                                 default = newJString("SageMaker.CreateDomain"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_CreateDomain_611355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateDomain_611355; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createDomain* = Call_CreateDomain_611355(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_611356, base: "/", url: url_CreateDomain_611357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_611370 = ref object of OpenApiRestCall_610658
proc url_CreateEndpoint_611372(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_611371(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
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
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_CreateEndpoint_611370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_CreateEndpoint_611370; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var createEndpoint* = Call_CreateEndpoint_611370(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_611371, base: "/", url: url_CreateEndpoint_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_611385 = ref object of OpenApiRestCall_610658
proc url_CreateEndpointConfig_611387(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpointConfig_611386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
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
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_CreateEndpointConfig_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_CreateEndpointConfig_611385; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var createEndpointConfig* = Call_CreateEndpointConfig_611385(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_611386, base: "/",
    url: url_CreateEndpointConfig_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_611400 = ref object of OpenApiRestCall_610658
proc url_CreateExperiment_611402(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExperiment_611401(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
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
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_CreateExperiment_611400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_CreateExperiment_611400; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var createExperiment* = Call_CreateExperiment_611400(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_611401, base: "/",
    url: url_CreateExperiment_611402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_611415 = ref object of OpenApiRestCall_610658
proc url_CreateFlowDefinition_611417(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowDefinition_611416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a flow definition.
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
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_CreateFlowDefinition_611415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_CreateFlowDefinition_611415; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var createFlowDefinition* = Call_CreateFlowDefinition_611415(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_611416, base: "/",
    url: url_CreateFlowDefinition_611417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_611430 = ref object of OpenApiRestCall_610658
proc url_CreateHumanTaskUi_611432(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHumanTaskUi_611431(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
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
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_CreateHumanTaskUi_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_CreateHumanTaskUi_611430; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var createHumanTaskUi* = Call_CreateHumanTaskUi_611430(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_611431, base: "/",
    url: url_CreateHumanTaskUi_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_611445 = ref object of OpenApiRestCall_610658
proc url_CreateHyperParameterTuningJob_611447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHyperParameterTuningJob_611446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
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
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_CreateHyperParameterTuningJob_611445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_CreateHyperParameterTuningJob_611445; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_611445(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_611446, base: "/",
    url: url_CreateHyperParameterTuningJob_611447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_611460 = ref object of OpenApiRestCall_610658
proc url_CreateLabelingJob_611462(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLabelingJob_611461(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
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
  var valid_611463 = header.getOrDefault("X-Amz-Target")
  valid_611463 = validateParameter(valid_611463, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_611463 != nil:
    section.add "X-Amz-Target", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_CreateLabelingJob_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_CreateLabelingJob_611460; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var createLabelingJob* = Call_CreateLabelingJob_611460(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_611461, base: "/",
    url: url_CreateLabelingJob_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_611475 = ref object of OpenApiRestCall_610658
proc url_CreateModel_611477(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModel_611476(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
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
  var valid_611478 = header.getOrDefault("X-Amz-Target")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_611478 != nil:
    section.add "X-Amz-Target", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Signature")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Signature", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Content-Sha256", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Date")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Date", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Credential")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Credential", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Security-Token")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Security-Token", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Algorithm")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Algorithm", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-SignedHeaders", valid_611485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611487: Call_CreateModel_611475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_611487.validator(path, query, header, formData, body)
  let scheme = call_611487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611487.url(scheme.get, call_611487.host, call_611487.base,
                         call_611487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611487, url, valid)

proc call*(call_611488: Call_CreateModel_611475; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_611489 = newJObject()
  if body != nil:
    body_611489 = body
  result = call_611488.call(nil, nil, nil, nil, body_611489)

var createModel* = Call_CreateModel_611475(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_611476,
                                        base: "/", url: url_CreateModel_611477,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_611490 = ref object of OpenApiRestCall_610658
proc url_CreateModelPackage_611492(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelPackage_611491(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
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
  var valid_611493 = header.getOrDefault("X-Amz-Target")
  valid_611493 = validateParameter(valid_611493, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_611493 != nil:
    section.add "X-Amz-Target", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611502: Call_CreateModelPackage_611490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_611502.validator(path, query, header, formData, body)
  let scheme = call_611502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611502.url(scheme.get, call_611502.host, call_611502.base,
                         call_611502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611502, url, valid)

proc call*(call_611503: Call_CreateModelPackage_611490; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_611504 = newJObject()
  if body != nil:
    body_611504 = body
  result = call_611503.call(nil, nil, nil, nil, body_611504)

var createModelPackage* = Call_CreateModelPackage_611490(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_611491, base: "/",
    url: url_CreateModelPackage_611492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_611505 = ref object of OpenApiRestCall_610658
proc url_CreateMonitoringSchedule_611507(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMonitoringSchedule_611506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
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
  var valid_611508 = header.getOrDefault("X-Amz-Target")
  valid_611508 = validateParameter(valid_611508, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
  if valid_611508 != nil:
    section.add "X-Amz-Target", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_CreateMonitoringSchedule_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_CreateMonitoringSchedule_611505; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_611519 = newJObject()
  if body != nil:
    body_611519 = body
  result = call_611518.call(nil, nil, nil, nil, body_611519)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_611505(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_611506, base: "/",
    url: url_CreateMonitoringSchedule_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_611520 = ref object of OpenApiRestCall_610658
proc url_CreateNotebookInstance_611522(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstance_611521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
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
  var valid_611523 = header.getOrDefault("X-Amz-Target")
  valid_611523 = validateParameter(valid_611523, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_611523 != nil:
    section.add "X-Amz-Target", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_CreateNotebookInstance_611520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_CreateNotebookInstance_611520; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var createNotebookInstance* = Call_CreateNotebookInstance_611520(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_611521, base: "/",
    url: url_CreateNotebookInstance_611522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_611535 = ref object of OpenApiRestCall_610658
proc url_CreateNotebookInstanceLifecycleConfig_611537(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_611536(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
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
  var valid_611538 = header.getOrDefault("X-Amz-Target")
  valid_611538 = validateParameter(valid_611538, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_611538 != nil:
    section.add "X-Amz-Target", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611547: Call_CreateNotebookInstanceLifecycleConfig_611535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_611547.validator(path, query, header, formData, body)
  let scheme = call_611547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611547.url(scheme.get, call_611547.host, call_611547.base,
                         call_611547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611547, url, valid)

proc call*(call_611548: Call_CreateNotebookInstanceLifecycleConfig_611535;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_611549 = newJObject()
  if body != nil:
    body_611549 = body
  result = call_611548.call(nil, nil, nil, nil, body_611549)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_611535(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_611536, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_611537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_611550 = ref object of OpenApiRestCall_610658
proc url_CreatePresignedDomainUrl_611552(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedDomainUrl_611551(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
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
  var valid_611553 = header.getOrDefault("X-Amz-Target")
  valid_611553 = validateParameter(valid_611553, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_611553 != nil:
    section.add "X-Amz-Target", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Signature")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Signature", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Content-Sha256", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Date")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Date", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Credential")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Credential", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Security-Token")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Security-Token", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Algorithm")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Algorithm", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-SignedHeaders", valid_611560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611562: Call_CreatePresignedDomainUrl_611550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_611562.validator(path, query, header, formData, body)
  let scheme = call_611562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611562.url(scheme.get, call_611562.host, call_611562.base,
                         call_611562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611562, url, valid)

proc call*(call_611563: Call_CreatePresignedDomainUrl_611550; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_611564 = newJObject()
  if body != nil:
    body_611564 = body
  result = call_611563.call(nil, nil, nil, nil, body_611564)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_611550(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_611551, base: "/",
    url: url_CreatePresignedDomainUrl_611552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_611565 = ref object of OpenApiRestCall_610658
proc url_CreatePresignedNotebookInstanceUrl_611567(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedNotebookInstanceUrl_611566(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
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
  var valid_611568 = header.getOrDefault("X-Amz-Target")
  valid_611568 = validateParameter(valid_611568, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_611568 != nil:
    section.add "X-Amz-Target", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611577: Call_CreatePresignedNotebookInstanceUrl_611565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_611577.validator(path, query, header, formData, body)
  let scheme = call_611577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611577.url(scheme.get, call_611577.host, call_611577.base,
                         call_611577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611577, url, valid)

proc call*(call_611578: Call_CreatePresignedNotebookInstanceUrl_611565;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_611579 = newJObject()
  if body != nil:
    body_611579 = body
  result = call_611578.call(nil, nil, nil, nil, body_611579)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_611565(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_611566, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_611567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_611580 = ref object of OpenApiRestCall_610658
proc url_CreateProcessingJob_611582(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProcessingJob_611581(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a processing job.
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
  var valid_611583 = header.getOrDefault("X-Amz-Target")
  valid_611583 = validateParameter(valid_611583, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_611583 != nil:
    section.add "X-Amz-Target", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611592: Call_CreateProcessingJob_611580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_611592.validator(path, query, header, formData, body)
  let scheme = call_611592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611592.url(scheme.get, call_611592.host, call_611592.base,
                         call_611592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611592, url, valid)

proc call*(call_611593: Call_CreateProcessingJob_611580; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_611594 = newJObject()
  if body != nil:
    body_611594 = body
  result = call_611593.call(nil, nil, nil, nil, body_611594)

var createProcessingJob* = Call_CreateProcessingJob_611580(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_611581, base: "/",
    url: url_CreateProcessingJob_611582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_611595 = ref object of OpenApiRestCall_610658
proc url_CreateTrainingJob_611597(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrainingJob_611596(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
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
  var valid_611598 = header.getOrDefault("X-Amz-Target")
  valid_611598 = validateParameter(valid_611598, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_611598 != nil:
    section.add "X-Amz-Target", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_CreateTrainingJob_611595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_CreateTrainingJob_611595; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_611609 = newJObject()
  if body != nil:
    body_611609 = body
  result = call_611608.call(nil, nil, nil, nil, body_611609)

var createTrainingJob* = Call_CreateTrainingJob_611595(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_611596, base: "/",
    url: url_CreateTrainingJob_611597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_611610 = ref object of OpenApiRestCall_610658
proc url_CreateTransformJob_611612(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransformJob_611611(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
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
  var valid_611613 = header.getOrDefault("X-Amz-Target")
  valid_611613 = validateParameter(valid_611613, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_611613 != nil:
    section.add "X-Amz-Target", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Signature")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Signature", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Content-Sha256", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Date")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Date", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Credential")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Credential", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Security-Token")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Security-Token", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Algorithm")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Algorithm", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-SignedHeaders", valid_611620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611622: Call_CreateTransformJob_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_611622.validator(path, query, header, formData, body)
  let scheme = call_611622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611622.url(scheme.get, call_611622.host, call_611622.base,
                         call_611622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611622, url, valid)

proc call*(call_611623: Call_CreateTransformJob_611610; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_611624 = newJObject()
  if body != nil:
    body_611624 = body
  result = call_611623.call(nil, nil, nil, nil, body_611624)

var createTransformJob* = Call_CreateTransformJob_611610(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_611611, base: "/",
    url: url_CreateTransformJob_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_611625 = ref object of OpenApiRestCall_610658
proc url_CreateTrial_611627(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrial_611626(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
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
  var valid_611628 = header.getOrDefault("X-Amz-Target")
  valid_611628 = validateParameter(valid_611628, JString, required = true,
                                 default = newJString("SageMaker.CreateTrial"))
  if valid_611628 != nil:
    section.add "X-Amz-Target", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611637: Call_CreateTrial_611625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_611637.validator(path, query, header, formData, body)
  let scheme = call_611637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611637.url(scheme.get, call_611637.host, call_611637.base,
                         call_611637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611637, url, valid)

proc call*(call_611638: Call_CreateTrial_611625; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_611639 = newJObject()
  if body != nil:
    body_611639 = body
  result = call_611638.call(nil, nil, nil, nil, body_611639)

var createTrial* = Call_CreateTrial_611625(name: "createTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateTrial",
                                        validator: validate_CreateTrial_611626,
                                        base: "/", url: url_CreateTrial_611627,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_611640 = ref object of OpenApiRestCall_610658
proc url_CreateTrialComponent_611642(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrialComponent_611641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
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
  var valid_611643 = header.getOrDefault("X-Amz-Target")
  valid_611643 = validateParameter(valid_611643, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_611643 != nil:
    section.add "X-Amz-Target", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Signature")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Signature", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Content-Sha256", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Date")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Date", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Credential")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Credential", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Security-Token")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Security-Token", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Algorithm")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Algorithm", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-SignedHeaders", valid_611650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611652: Call_CreateTrialComponent_611640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ## 
  let valid = call_611652.validator(path, query, header, formData, body)
  let scheme = call_611652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611652.url(scheme.get, call_611652.host, call_611652.base,
                         call_611652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611652, url, valid)

proc call*(call_611653: Call_CreateTrialComponent_611640; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   body: JObject (required)
  var body_611654 = newJObject()
  if body != nil:
    body_611654 = body
  result = call_611653.call(nil, nil, nil, nil, body_611654)

var createTrialComponent* = Call_CreateTrialComponent_611640(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_611641, base: "/",
    url: url_CreateTrialComponent_611642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_611655 = ref object of OpenApiRestCall_610658
proc url_CreateUserProfile_611657(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserProfile_611656(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
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
  var valid_611658 = header.getOrDefault("X-Amz-Target")
  valid_611658 = validateParameter(valid_611658, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_611658 != nil:
    section.add "X-Amz-Target", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Signature")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Signature", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Content-Sha256", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Date")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Date", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Credential")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Credential", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Security-Token")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Security-Token", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Algorithm")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Algorithm", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-SignedHeaders", valid_611665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_CreateUserProfile_611655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_CreateUserProfile_611655; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_611669 = newJObject()
  if body != nil:
    body_611669 = body
  result = call_611668.call(nil, nil, nil, nil, body_611669)

var createUserProfile* = Call_CreateUserProfile_611655(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_611656, base: "/",
    url: url_CreateUserProfile_611657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_611670 = ref object of OpenApiRestCall_610658
proc url_CreateWorkteam_611672(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkteam_611671(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
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
  var valid_611673 = header.getOrDefault("X-Amz-Target")
  valid_611673 = validateParameter(valid_611673, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_611673 != nil:
    section.add "X-Amz-Target", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Signature")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Signature", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Content-Sha256", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Date")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Date", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Credential")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Credential", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Security-Token")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Security-Token", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Algorithm")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Algorithm", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-SignedHeaders", valid_611680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611682: Call_CreateWorkteam_611670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_611682.validator(path, query, header, formData, body)
  let scheme = call_611682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611682.url(scheme.get, call_611682.host, call_611682.base,
                         call_611682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611682, url, valid)

proc call*(call_611683: Call_CreateWorkteam_611670; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_611684 = newJObject()
  if body != nil:
    body_611684 = body
  result = call_611683.call(nil, nil, nil, nil, body_611684)

var createWorkteam* = Call_CreateWorkteam_611670(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_611671, base: "/", url: url_CreateWorkteam_611672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_611685 = ref object of OpenApiRestCall_610658
proc url_DeleteAlgorithm_611687(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlgorithm_611686(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Removes the specified algorithm from your account.
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
  var valid_611688 = header.getOrDefault("X-Amz-Target")
  valid_611688 = validateParameter(valid_611688, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_611688 != nil:
    section.add "X-Amz-Target", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Signature")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Signature", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Content-Sha256", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Date")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Date", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Credential")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Credential", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Security-Token")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Security-Token", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Algorithm")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Algorithm", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-SignedHeaders", valid_611695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611697: Call_DeleteAlgorithm_611685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_611697.validator(path, query, header, formData, body)
  let scheme = call_611697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611697.url(scheme.get, call_611697.host, call_611697.base,
                         call_611697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611697, url, valid)

proc call*(call_611698: Call_DeleteAlgorithm_611685; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_611699 = newJObject()
  if body != nil:
    body_611699 = body
  result = call_611698.call(nil, nil, nil, nil, body_611699)

var deleteAlgorithm* = Call_DeleteAlgorithm_611685(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_611686, base: "/", url: url_DeleteAlgorithm_611687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_611700 = ref object of OpenApiRestCall_610658
proc url_DeleteApp_611702(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_611701(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to stop and delete an app.
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
  var valid_611703 = header.getOrDefault("X-Amz-Target")
  valid_611703 = validateParameter(valid_611703, JString, required = true,
                                 default = newJString("SageMaker.DeleteApp"))
  if valid_611703 != nil:
    section.add "X-Amz-Target", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Signature")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Signature", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Content-Sha256", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Date")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Date", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Credential")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Credential", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Security-Token")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Security-Token", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Algorithm")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Algorithm", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-SignedHeaders", valid_611710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_DeleteApp_611700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_DeleteApp_611700; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_611714 = newJObject()
  if body != nil:
    body_611714 = body
  result = call_611713.call(nil, nil, nil, nil, body_611714)

var deleteApp* = Call_DeleteApp_611700(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                    validator: validate_DeleteApp_611701,
                                    base: "/", url: url_DeleteApp_611702,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_611715 = ref object of OpenApiRestCall_610658
proc url_DeleteCodeRepository_611717(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCodeRepository_611716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified Git repository from your account.
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
  var valid_611718 = header.getOrDefault("X-Amz-Target")
  valid_611718 = validateParameter(valid_611718, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_611718 != nil:
    section.add "X-Amz-Target", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Signature")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Signature", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Content-Sha256", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Date")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Date", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Credential")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Credential", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Security-Token")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Security-Token", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Algorithm")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Algorithm", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-SignedHeaders", valid_611725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611727: Call_DeleteCodeRepository_611715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_611727.validator(path, query, header, formData, body)
  let scheme = call_611727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611727.url(scheme.get, call_611727.host, call_611727.base,
                         call_611727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611727, url, valid)

proc call*(call_611728: Call_DeleteCodeRepository_611715; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_611729 = newJObject()
  if body != nil:
    body_611729 = body
  result = call_611728.call(nil, nil, nil, nil, body_611729)

var deleteCodeRepository* = Call_DeleteCodeRepository_611715(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_611716, base: "/",
    url: url_DeleteCodeRepository_611717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_611730 = ref object of OpenApiRestCall_610658
proc url_DeleteDomain_611732(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_611731(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
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
  var valid_611733 = header.getOrDefault("X-Amz-Target")
  valid_611733 = validateParameter(valid_611733, JString, required = true,
                                 default = newJString("SageMaker.DeleteDomain"))
  if valid_611733 != nil:
    section.add "X-Amz-Target", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Signature")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Signature", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Content-Sha256", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Date")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Date", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Credential")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Credential", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Security-Token")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Security-Token", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Algorithm")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Algorithm", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-SignedHeaders", valid_611740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611742: Call_DeleteDomain_611730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_611742.validator(path, query, header, formData, body)
  let scheme = call_611742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611742.url(scheme.get, call_611742.host, call_611742.base,
                         call_611742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611742, url, valid)

proc call*(call_611743: Call_DeleteDomain_611730; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_611744 = newJObject()
  if body != nil:
    body_611744 = body
  result = call_611743.call(nil, nil, nil, nil, body_611744)

var deleteDomain* = Call_DeleteDomain_611730(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_611731, base: "/", url: url_DeleteDomain_611732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_611745 = ref object of OpenApiRestCall_610658
proc url_DeleteEndpoint_611747(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_611746(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
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
  var valid_611748 = header.getOrDefault("X-Amz-Target")
  valid_611748 = validateParameter(valid_611748, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_611748 != nil:
    section.add "X-Amz-Target", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Signature")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Signature", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Content-Sha256", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Date")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Date", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Credential")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Credential", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-Security-Token")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-Security-Token", valid_611753
  var valid_611754 = header.getOrDefault("X-Amz-Algorithm")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Algorithm", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-SignedHeaders", valid_611755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611757: Call_DeleteEndpoint_611745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_611757.validator(path, query, header, formData, body)
  let scheme = call_611757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611757.url(scheme.get, call_611757.host, call_611757.base,
                         call_611757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611757, url, valid)

proc call*(call_611758: Call_DeleteEndpoint_611745; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_611759 = newJObject()
  if body != nil:
    body_611759 = body
  result = call_611758.call(nil, nil, nil, nil, body_611759)

var deleteEndpoint* = Call_DeleteEndpoint_611745(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_611746, base: "/", url: url_DeleteEndpoint_611747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_611760 = ref object of OpenApiRestCall_610658
proc url_DeleteEndpointConfig_611762(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpointConfig_611761(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
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
  var valid_611763 = header.getOrDefault("X-Amz-Target")
  valid_611763 = validateParameter(valid_611763, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_611763 != nil:
    section.add "X-Amz-Target", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611772: Call_DeleteEndpointConfig_611760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_611772.validator(path, query, header, formData, body)
  let scheme = call_611772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611772.url(scheme.get, call_611772.host, call_611772.base,
                         call_611772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611772, url, valid)

proc call*(call_611773: Call_DeleteEndpointConfig_611760; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_611774 = newJObject()
  if body != nil:
    body_611774 = body
  result = call_611773.call(nil, nil, nil, nil, body_611774)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_611760(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_611761, base: "/",
    url: url_DeleteEndpointConfig_611762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_611775 = ref object of OpenApiRestCall_610658
proc url_DeleteExperiment_611777(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteExperiment_611776(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
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
  var valid_611778 = header.getOrDefault("X-Amz-Target")
  valid_611778 = validateParameter(valid_611778, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_611778 != nil:
    section.add "X-Amz-Target", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Signature")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Signature", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Content-Sha256", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Date")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Date", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Credential")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Credential", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Security-Token")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Security-Token", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Algorithm")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Algorithm", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-SignedHeaders", valid_611785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611787: Call_DeleteExperiment_611775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_611787.validator(path, query, header, formData, body)
  let scheme = call_611787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611787.url(scheme.get, call_611787.host, call_611787.base,
                         call_611787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611787, url, valid)

proc call*(call_611788: Call_DeleteExperiment_611775; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_611789 = newJObject()
  if body != nil:
    body_611789 = body
  result = call_611788.call(nil, nil, nil, nil, body_611789)

var deleteExperiment* = Call_DeleteExperiment_611775(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_611776, base: "/",
    url: url_DeleteExperiment_611777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_611790 = ref object of OpenApiRestCall_610658
proc url_DeleteFlowDefinition_611792(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowDefinition_611791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified flow definition.
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
  var valid_611793 = header.getOrDefault("X-Amz-Target")
  valid_611793 = validateParameter(valid_611793, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_611793 != nil:
    section.add "X-Amz-Target", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Signature")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Signature", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Content-Sha256", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Date")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Date", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Credential")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Credential", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Security-Token")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Security-Token", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Algorithm")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Algorithm", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-SignedHeaders", valid_611800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611802: Call_DeleteFlowDefinition_611790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_611802.validator(path, query, header, formData, body)
  let scheme = call_611802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611802.url(scheme.get, call_611802.host, call_611802.base,
                         call_611802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611802, url, valid)

proc call*(call_611803: Call_DeleteFlowDefinition_611790; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_611804 = newJObject()
  if body != nil:
    body_611804 = body
  result = call_611803.call(nil, nil, nil, nil, body_611804)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_611790(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_611791, base: "/",
    url: url_DeleteFlowDefinition_611792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_611805 = ref object of OpenApiRestCall_610658
proc url_DeleteModel_611807(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModel_611806(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
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
  var valid_611808 = header.getOrDefault("X-Amz-Target")
  valid_611808 = validateParameter(valid_611808, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_611808 != nil:
    section.add "X-Amz-Target", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Signature")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Signature", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Content-Sha256", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Date")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Date", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Credential")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Credential", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Security-Token")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Security-Token", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Algorithm")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Algorithm", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-SignedHeaders", valid_611815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_DeleteModel_611805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_DeleteModel_611805; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_611819 = newJObject()
  if body != nil:
    body_611819 = body
  result = call_611818.call(nil, nil, nil, nil, body_611819)

var deleteModel* = Call_DeleteModel_611805(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_611806,
                                        base: "/", url: url_DeleteModel_611807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_611820 = ref object of OpenApiRestCall_610658
proc url_DeleteModelPackage_611822(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModelPackage_611821(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
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
  var valid_611823 = header.getOrDefault("X-Amz-Target")
  valid_611823 = validateParameter(valid_611823, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_611823 != nil:
    section.add "X-Amz-Target", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Signature")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Signature", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Content-Sha256", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Date")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Date", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Credential")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Credential", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Security-Token")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Security-Token", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Algorithm")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Algorithm", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-SignedHeaders", valid_611830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611832: Call_DeleteModelPackage_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_611832.validator(path, query, header, formData, body)
  let scheme = call_611832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611832.url(scheme.get, call_611832.host, call_611832.base,
                         call_611832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611832, url, valid)

proc call*(call_611833: Call_DeleteModelPackage_611820; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_611834 = newJObject()
  if body != nil:
    body_611834 = body
  result = call_611833.call(nil, nil, nil, nil, body_611834)

var deleteModelPackage* = Call_DeleteModelPackage_611820(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_611821, base: "/",
    url: url_DeleteModelPackage_611822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_611835 = ref object of OpenApiRestCall_610658
proc url_DeleteMonitoringSchedule_611837(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMonitoringSchedule_611836(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
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
  var valid_611838 = header.getOrDefault("X-Amz-Target")
  valid_611838 = validateParameter(valid_611838, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_611838 != nil:
    section.add "X-Amz-Target", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Signature")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Signature", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Content-Sha256", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Date")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Date", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Credential")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Credential", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-Security-Token")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Security-Token", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Algorithm")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Algorithm", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-SignedHeaders", valid_611845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611847: Call_DeleteMonitoringSchedule_611835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_611847.validator(path, query, header, formData, body)
  let scheme = call_611847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611847.url(scheme.get, call_611847.host, call_611847.base,
                         call_611847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611847, url, valid)

proc call*(call_611848: Call_DeleteMonitoringSchedule_611835; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_611849 = newJObject()
  if body != nil:
    body_611849 = body
  result = call_611848.call(nil, nil, nil, nil, body_611849)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_611835(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_611836, base: "/",
    url: url_DeleteMonitoringSchedule_611837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_611850 = ref object of OpenApiRestCall_610658
proc url_DeleteNotebookInstance_611852(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstance_611851(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
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
  var valid_611853 = header.getOrDefault("X-Amz-Target")
  valid_611853 = validateParameter(valid_611853, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_611853 != nil:
    section.add "X-Amz-Target", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-Signature")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-Signature", valid_611854
  var valid_611855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "X-Amz-Content-Sha256", valid_611855
  var valid_611856 = header.getOrDefault("X-Amz-Date")
  valid_611856 = validateParameter(valid_611856, JString, required = false,
                                 default = nil)
  if valid_611856 != nil:
    section.add "X-Amz-Date", valid_611856
  var valid_611857 = header.getOrDefault("X-Amz-Credential")
  valid_611857 = validateParameter(valid_611857, JString, required = false,
                                 default = nil)
  if valid_611857 != nil:
    section.add "X-Amz-Credential", valid_611857
  var valid_611858 = header.getOrDefault("X-Amz-Security-Token")
  valid_611858 = validateParameter(valid_611858, JString, required = false,
                                 default = nil)
  if valid_611858 != nil:
    section.add "X-Amz-Security-Token", valid_611858
  var valid_611859 = header.getOrDefault("X-Amz-Algorithm")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Algorithm", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-SignedHeaders", valid_611860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611862: Call_DeleteNotebookInstance_611850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_611862.validator(path, query, header, formData, body)
  let scheme = call_611862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611862.url(scheme.get, call_611862.host, call_611862.base,
                         call_611862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611862, url, valid)

proc call*(call_611863: Call_DeleteNotebookInstance_611850; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_611864 = newJObject()
  if body != nil:
    body_611864 = body
  result = call_611863.call(nil, nil, nil, nil, body_611864)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_611850(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_611851, base: "/",
    url: url_DeleteNotebookInstance_611852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_611865 = ref object of OpenApiRestCall_610658
proc url_DeleteNotebookInstanceLifecycleConfig_611867(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_611866(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a notebook instance lifecycle configuration.
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
  var valid_611868 = header.getOrDefault("X-Amz-Target")
  valid_611868 = validateParameter(valid_611868, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_611868 != nil:
    section.add "X-Amz-Target", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Signature")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Signature", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Content-Sha256", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-Date")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-Date", valid_611871
  var valid_611872 = header.getOrDefault("X-Amz-Credential")
  valid_611872 = validateParameter(valid_611872, JString, required = false,
                                 default = nil)
  if valid_611872 != nil:
    section.add "X-Amz-Credential", valid_611872
  var valid_611873 = header.getOrDefault("X-Amz-Security-Token")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Security-Token", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Algorithm")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Algorithm", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-SignedHeaders", valid_611875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611877: Call_DeleteNotebookInstanceLifecycleConfig_611865;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_611877.validator(path, query, header, formData, body)
  let scheme = call_611877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611877.url(scheme.get, call_611877.host, call_611877.base,
                         call_611877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611877, url, valid)

proc call*(call_611878: Call_DeleteNotebookInstanceLifecycleConfig_611865;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_611879 = newJObject()
  if body != nil:
    body_611879 = body
  result = call_611878.call(nil, nil, nil, nil, body_611879)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_611865(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_611866, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_611867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_611880 = ref object of OpenApiRestCall_610658
proc url_DeleteTags_611882(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_611881(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
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
  var valid_611883 = header.getOrDefault("X-Amz-Target")
  valid_611883 = validateParameter(valid_611883, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_611883 != nil:
    section.add "X-Amz-Target", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Signature")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Signature", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Content-Sha256", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-Date")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-Date", valid_611886
  var valid_611887 = header.getOrDefault("X-Amz-Credential")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Credential", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Security-Token")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Security-Token", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Algorithm")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Algorithm", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-SignedHeaders", valid_611890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611892: Call_DeleteTags_611880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_611892.validator(path, query, header, formData, body)
  let scheme = call_611892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611892.url(scheme.get, call_611892.host, call_611892.base,
                         call_611892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611892, url, valid)

proc call*(call_611893: Call_DeleteTags_611880; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_611894 = newJObject()
  if body != nil:
    body_611894 = body
  result = call_611893.call(nil, nil, nil, nil, body_611894)

var deleteTags* = Call_DeleteTags_611880(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_611881,
                                      base: "/", url: url_DeleteTags_611882,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_611895 = ref object of OpenApiRestCall_610658
proc url_DeleteTrial_611897(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrial_611896(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
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
  var valid_611898 = header.getOrDefault("X-Amz-Target")
  valid_611898 = validateParameter(valid_611898, JString, required = true,
                                 default = newJString("SageMaker.DeleteTrial"))
  if valid_611898 != nil:
    section.add "X-Amz-Target", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611907: Call_DeleteTrial_611895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_611907.validator(path, query, header, formData, body)
  let scheme = call_611907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611907.url(scheme.get, call_611907.host, call_611907.base,
                         call_611907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611907, url, valid)

proc call*(call_611908: Call_DeleteTrial_611895; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_611909 = newJObject()
  if body != nil:
    body_611909 = body
  result = call_611908.call(nil, nil, nil, nil, body_611909)

var deleteTrial* = Call_DeleteTrial_611895(name: "deleteTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTrial",
                                        validator: validate_DeleteTrial_611896,
                                        base: "/", url: url_DeleteTrial_611897,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_611910 = ref object of OpenApiRestCall_610658
proc url_DeleteTrialComponent_611912(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrialComponent_611911(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
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
  var valid_611913 = header.getOrDefault("X-Amz-Target")
  valid_611913 = validateParameter(valid_611913, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_611913 != nil:
    section.add "X-Amz-Target", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Signature")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Signature", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Content-Sha256", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Date")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Date", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Credential")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Credential", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Security-Token")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Security-Token", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Algorithm")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Algorithm", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-SignedHeaders", valid_611920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611922: Call_DeleteTrialComponent_611910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_611922.validator(path, query, header, formData, body)
  let scheme = call_611922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611922.url(scheme.get, call_611922.host, call_611922.base,
                         call_611922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611922, url, valid)

proc call*(call_611923: Call_DeleteTrialComponent_611910; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_611924 = newJObject()
  if body != nil:
    body_611924 = body
  result = call_611923.call(nil, nil, nil, nil, body_611924)

var deleteTrialComponent* = Call_DeleteTrialComponent_611910(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_611911, base: "/",
    url: url_DeleteTrialComponent_611912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_611925 = ref object of OpenApiRestCall_610658
proc url_DeleteUserProfile_611927(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserProfile_611926(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a user profile.
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
  var valid_611928 = header.getOrDefault("X-Amz-Target")
  valid_611928 = validateParameter(valid_611928, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_611928 != nil:
    section.add "X-Amz-Target", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Signature")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Signature", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Content-Sha256", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Date")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Date", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Credential")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Credential", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Security-Token")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Security-Token", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Algorithm")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Algorithm", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-SignedHeaders", valid_611935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611937: Call_DeleteUserProfile_611925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_611937.validator(path, query, header, formData, body)
  let scheme = call_611937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611937.url(scheme.get, call_611937.host, call_611937.base,
                         call_611937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611937, url, valid)

proc call*(call_611938: Call_DeleteUserProfile_611925; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_611939 = newJObject()
  if body != nil:
    body_611939 = body
  result = call_611938.call(nil, nil, nil, nil, body_611939)

var deleteUserProfile* = Call_DeleteUserProfile_611925(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_611926, base: "/",
    url: url_DeleteUserProfile_611927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_611940 = ref object of OpenApiRestCall_610658
proc url_DeleteWorkteam_611942(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkteam_611941(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes an existing work team. This operation can't be undone.
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
  var valid_611943 = header.getOrDefault("X-Amz-Target")
  valid_611943 = validateParameter(valid_611943, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_611943 != nil:
    section.add "X-Amz-Target", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Signature")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Signature", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Content-Sha256", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Date")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Date", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Credential")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Credential", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Security-Token")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Security-Token", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-Algorithm")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-Algorithm", valid_611949
  var valid_611950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-SignedHeaders", valid_611950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611952: Call_DeleteWorkteam_611940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_611952.validator(path, query, header, formData, body)
  let scheme = call_611952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611952.url(scheme.get, call_611952.host, call_611952.base,
                         call_611952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611952, url, valid)

proc call*(call_611953: Call_DeleteWorkteam_611940; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_611954 = newJObject()
  if body != nil:
    body_611954 = body
  result = call_611953.call(nil, nil, nil, nil, body_611954)

var deleteWorkteam* = Call_DeleteWorkteam_611940(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_611941, base: "/", url: url_DeleteWorkteam_611942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_611955 = ref object of OpenApiRestCall_610658
proc url_DescribeAlgorithm_611957(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAlgorithm_611956(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a description of the specified algorithm that is in your account.
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
  var valid_611958 = header.getOrDefault("X-Amz-Target")
  valid_611958 = validateParameter(valid_611958, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_611958 != nil:
    section.add "X-Amz-Target", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Signature")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Signature", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Content-Sha256", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Date")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Date", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Credential")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Credential", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-Security-Token")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-Security-Token", valid_611963
  var valid_611964 = header.getOrDefault("X-Amz-Algorithm")
  valid_611964 = validateParameter(valid_611964, JString, required = false,
                                 default = nil)
  if valid_611964 != nil:
    section.add "X-Amz-Algorithm", valid_611964
  var valid_611965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-SignedHeaders", valid_611965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611967: Call_DescribeAlgorithm_611955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_611967.validator(path, query, header, formData, body)
  let scheme = call_611967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611967.url(scheme.get, call_611967.host, call_611967.base,
                         call_611967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611967, url, valid)

proc call*(call_611968: Call_DescribeAlgorithm_611955; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_611969 = newJObject()
  if body != nil:
    body_611969 = body
  result = call_611968.call(nil, nil, nil, nil, body_611969)

var describeAlgorithm* = Call_DescribeAlgorithm_611955(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_611956, base: "/",
    url: url_DescribeAlgorithm_611957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_611970 = ref object of OpenApiRestCall_610658
proc url_DescribeApp_611972(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApp_611971(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the app.
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
  var valid_611973 = header.getOrDefault("X-Amz-Target")
  valid_611973 = validateParameter(valid_611973, JString, required = true,
                                 default = newJString("SageMaker.DescribeApp"))
  if valid_611973 != nil:
    section.add "X-Amz-Target", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Signature")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Signature", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Content-Sha256", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Date")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Date", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Credential")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Credential", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Security-Token")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Security-Token", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-Algorithm")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-Algorithm", valid_611979
  var valid_611980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611980 = validateParameter(valid_611980, JString, required = false,
                                 default = nil)
  if valid_611980 != nil:
    section.add "X-Amz-SignedHeaders", valid_611980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611982: Call_DescribeApp_611970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the app.
  ## 
  let valid = call_611982.validator(path, query, header, formData, body)
  let scheme = call_611982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611982.url(scheme.get, call_611982.host, call_611982.base,
                         call_611982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611982, url, valid)

proc call*(call_611983: Call_DescribeApp_611970; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_611984 = newJObject()
  if body != nil:
    body_611984 = body
  result = call_611983.call(nil, nil, nil, nil, body_611984)

var describeApp* = Call_DescribeApp_611970(name: "describeApp",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DescribeApp",
                                        validator: validate_DescribeApp_611971,
                                        base: "/", url: url_DescribeApp_611972,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_611985 = ref object of OpenApiRestCall_610658
proc url_DescribeAutoMLJob_611987(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutoMLJob_611986(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about an Amazon SageMaker job.
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
  var valid_611988 = header.getOrDefault("X-Amz-Target")
  valid_611988 = validateParameter(valid_611988, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_611988 != nil:
    section.add "X-Amz-Target", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Signature")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Signature", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Content-Sha256", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Date")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Date", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Credential")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Credential", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Security-Token")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Security-Token", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Algorithm")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Algorithm", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-SignedHeaders", valid_611995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_DescribeAutoMLJob_611985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_DescribeAutoMLJob_611985; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_611999 = newJObject()
  if body != nil:
    body_611999 = body
  result = call_611998.call(nil, nil, nil, nil, body_611999)

var describeAutoMLJob* = Call_DescribeAutoMLJob_611985(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_611986, base: "/",
    url: url_DescribeAutoMLJob_611987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_612000 = ref object of OpenApiRestCall_610658
proc url_DescribeCodeRepository_612002(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCodeRepository_612001(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details about the specified Git repository.
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
  var valid_612003 = header.getOrDefault("X-Amz-Target")
  valid_612003 = validateParameter(valid_612003, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_612003 != nil:
    section.add "X-Amz-Target", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Signature")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Signature", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Content-Sha256", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Date")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Date", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Credential")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Credential", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Security-Token")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Security-Token", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Algorithm")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Algorithm", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-SignedHeaders", valid_612010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612012: Call_DescribeCodeRepository_612000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_612012.validator(path, query, header, formData, body)
  let scheme = call_612012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612012.url(scheme.get, call_612012.host, call_612012.base,
                         call_612012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612012, url, valid)

proc call*(call_612013: Call_DescribeCodeRepository_612000; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_612014 = newJObject()
  if body != nil:
    body_612014 = body
  result = call_612013.call(nil, nil, nil, nil, body_612014)

var describeCodeRepository* = Call_DescribeCodeRepository_612000(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_612001, base: "/",
    url: url_DescribeCodeRepository_612002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_612015 = ref object of OpenApiRestCall_610658
proc url_DescribeCompilationJob_612017(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompilationJob_612016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
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
  var valid_612018 = header.getOrDefault("X-Amz-Target")
  valid_612018 = validateParameter(valid_612018, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_612018 != nil:
    section.add "X-Amz-Target", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-Signature")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-Signature", valid_612019
  var valid_612020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612020 = validateParameter(valid_612020, JString, required = false,
                                 default = nil)
  if valid_612020 != nil:
    section.add "X-Amz-Content-Sha256", valid_612020
  var valid_612021 = header.getOrDefault("X-Amz-Date")
  valid_612021 = validateParameter(valid_612021, JString, required = false,
                                 default = nil)
  if valid_612021 != nil:
    section.add "X-Amz-Date", valid_612021
  var valid_612022 = header.getOrDefault("X-Amz-Credential")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Credential", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Security-Token")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Security-Token", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Algorithm")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Algorithm", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-SignedHeaders", valid_612025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612027: Call_DescribeCompilationJob_612015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_612027.validator(path, query, header, formData, body)
  let scheme = call_612027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612027.url(scheme.get, call_612027.host, call_612027.base,
                         call_612027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612027, url, valid)

proc call*(call_612028: Call_DescribeCompilationJob_612015; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_612029 = newJObject()
  if body != nil:
    body_612029 = body
  result = call_612028.call(nil, nil, nil, nil, body_612029)

var describeCompilationJob* = Call_DescribeCompilationJob_612015(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_612016, base: "/",
    url: url_DescribeCompilationJob_612017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_612030 = ref object of OpenApiRestCall_610658
proc url_DescribeDomain_612032(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_612031(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## The desciption of the domain.
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
  var valid_612033 = header.getOrDefault("X-Amz-Target")
  valid_612033 = validateParameter(valid_612033, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_612033 != nil:
    section.add "X-Amz-Target", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-Signature")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-Signature", valid_612034
  var valid_612035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "X-Amz-Content-Sha256", valid_612035
  var valid_612036 = header.getOrDefault("X-Amz-Date")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "X-Amz-Date", valid_612036
  var valid_612037 = header.getOrDefault("X-Amz-Credential")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-Credential", valid_612037
  var valid_612038 = header.getOrDefault("X-Amz-Security-Token")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Security-Token", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Algorithm")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Algorithm", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-SignedHeaders", valid_612040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612042: Call_DescribeDomain_612030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_612042.validator(path, query, header, formData, body)
  let scheme = call_612042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612042.url(scheme.get, call_612042.host, call_612042.base,
                         call_612042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612042, url, valid)

proc call*(call_612043: Call_DescribeDomain_612030; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_612044 = newJObject()
  if body != nil:
    body_612044 = body
  result = call_612043.call(nil, nil, nil, nil, body_612044)

var describeDomain* = Call_DescribeDomain_612030(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_612031, base: "/", url: url_DescribeDomain_612032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_612045 = ref object of OpenApiRestCall_610658
proc url_DescribeEndpoint_612047(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_612046(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the description of an endpoint.
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
  var valid_612048 = header.getOrDefault("X-Amz-Target")
  valid_612048 = validateParameter(valid_612048, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_612048 != nil:
    section.add "X-Amz-Target", valid_612048
  var valid_612049 = header.getOrDefault("X-Amz-Signature")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "X-Amz-Signature", valid_612049
  var valid_612050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Content-Sha256", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Date")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Date", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Credential")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Credential", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Security-Token")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Security-Token", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Algorithm")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Algorithm", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-SignedHeaders", valid_612055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612057: Call_DescribeEndpoint_612045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_612057.validator(path, query, header, formData, body)
  let scheme = call_612057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612057.url(scheme.get, call_612057.host, call_612057.base,
                         call_612057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612057, url, valid)

proc call*(call_612058: Call_DescribeEndpoint_612045; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_612059 = newJObject()
  if body != nil:
    body_612059 = body
  result = call_612058.call(nil, nil, nil, nil, body_612059)

var describeEndpoint* = Call_DescribeEndpoint_612045(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_612046, base: "/",
    url: url_DescribeEndpoint_612047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_612060 = ref object of OpenApiRestCall_610658
proc url_DescribeEndpointConfig_612062(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointConfig_612061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
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
  var valid_612063 = header.getOrDefault("X-Amz-Target")
  valid_612063 = validateParameter(valid_612063, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_612063 != nil:
    section.add "X-Amz-Target", valid_612063
  var valid_612064 = header.getOrDefault("X-Amz-Signature")
  valid_612064 = validateParameter(valid_612064, JString, required = false,
                                 default = nil)
  if valid_612064 != nil:
    section.add "X-Amz-Signature", valid_612064
  var valid_612065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Content-Sha256", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Date")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Date", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Credential")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Credential", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Security-Token")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Security-Token", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Algorithm")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Algorithm", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-SignedHeaders", valid_612070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612072: Call_DescribeEndpointConfig_612060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_612072.validator(path, query, header, formData, body)
  let scheme = call_612072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612072.url(scheme.get, call_612072.host, call_612072.base,
                         call_612072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612072, url, valid)

proc call*(call_612073: Call_DescribeEndpointConfig_612060; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_612074 = newJObject()
  if body != nil:
    body_612074 = body
  result = call_612073.call(nil, nil, nil, nil, body_612074)

var describeEndpointConfig* = Call_DescribeEndpointConfig_612060(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_612061, base: "/",
    url: url_DescribeEndpointConfig_612062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_612075 = ref object of OpenApiRestCall_610658
proc url_DescribeExperiment_612077(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExperiment_612076(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Provides a list of an experiment's properties.
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
  var valid_612078 = header.getOrDefault("X-Amz-Target")
  valid_612078 = validateParameter(valid_612078, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_612078 != nil:
    section.add "X-Amz-Target", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-Signature")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-Signature", valid_612079
  var valid_612080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612080 = validateParameter(valid_612080, JString, required = false,
                                 default = nil)
  if valid_612080 != nil:
    section.add "X-Amz-Content-Sha256", valid_612080
  var valid_612081 = header.getOrDefault("X-Amz-Date")
  valid_612081 = validateParameter(valid_612081, JString, required = false,
                                 default = nil)
  if valid_612081 != nil:
    section.add "X-Amz-Date", valid_612081
  var valid_612082 = header.getOrDefault("X-Amz-Credential")
  valid_612082 = validateParameter(valid_612082, JString, required = false,
                                 default = nil)
  if valid_612082 != nil:
    section.add "X-Amz-Credential", valid_612082
  var valid_612083 = header.getOrDefault("X-Amz-Security-Token")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "X-Amz-Security-Token", valid_612083
  var valid_612084 = header.getOrDefault("X-Amz-Algorithm")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "X-Amz-Algorithm", valid_612084
  var valid_612085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612085 = validateParameter(valid_612085, JString, required = false,
                                 default = nil)
  if valid_612085 != nil:
    section.add "X-Amz-SignedHeaders", valid_612085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612087: Call_DescribeExperiment_612075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_612087.validator(path, query, header, formData, body)
  let scheme = call_612087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612087.url(scheme.get, call_612087.host, call_612087.base,
                         call_612087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612087, url, valid)

proc call*(call_612088: Call_DescribeExperiment_612075; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_612089 = newJObject()
  if body != nil:
    body_612089 = body
  result = call_612088.call(nil, nil, nil, nil, body_612089)

var describeExperiment* = Call_DescribeExperiment_612075(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_612076, base: "/",
    url: url_DescribeExperiment_612077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_612090 = ref object of OpenApiRestCall_610658
proc url_DescribeFlowDefinition_612092(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFlowDefinition_612091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the specified flow definition.
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
  var valid_612093 = header.getOrDefault("X-Amz-Target")
  valid_612093 = validateParameter(valid_612093, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_612093 != nil:
    section.add "X-Amz-Target", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Signature")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Signature", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Content-Sha256", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Date")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Date", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Credential")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Credential", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Security-Token")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Security-Token", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-Algorithm")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-Algorithm", valid_612099
  var valid_612100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612100 = validateParameter(valid_612100, JString, required = false,
                                 default = nil)
  if valid_612100 != nil:
    section.add "X-Amz-SignedHeaders", valid_612100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612102: Call_DescribeFlowDefinition_612090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_612102.validator(path, query, header, formData, body)
  let scheme = call_612102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612102.url(scheme.get, call_612102.host, call_612102.base,
                         call_612102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612102, url, valid)

proc call*(call_612103: Call_DescribeFlowDefinition_612090; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_612104 = newJObject()
  if body != nil:
    body_612104 = body
  result = call_612103.call(nil, nil, nil, nil, body_612104)

var describeFlowDefinition* = Call_DescribeFlowDefinition_612090(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_612091, base: "/",
    url: url_DescribeFlowDefinition_612092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_612105 = ref object of OpenApiRestCall_610658
proc url_DescribeHumanTaskUi_612107(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHumanTaskUi_612106(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about the requested human task user interface.
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
  var valid_612108 = header.getOrDefault("X-Amz-Target")
  valid_612108 = validateParameter(valid_612108, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_612108 != nil:
    section.add "X-Amz-Target", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-Signature")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-Signature", valid_612109
  var valid_612110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "X-Amz-Content-Sha256", valid_612110
  var valid_612111 = header.getOrDefault("X-Amz-Date")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "X-Amz-Date", valid_612111
  var valid_612112 = header.getOrDefault("X-Amz-Credential")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Credential", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Security-Token")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Security-Token", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Algorithm")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Algorithm", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-SignedHeaders", valid_612115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612117: Call_DescribeHumanTaskUi_612105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_612117.validator(path, query, header, formData, body)
  let scheme = call_612117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612117.url(scheme.get, call_612117.host, call_612117.base,
                         call_612117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612117, url, valid)

proc call*(call_612118: Call_DescribeHumanTaskUi_612105; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_612119 = newJObject()
  if body != nil:
    body_612119 = body
  result = call_612118.call(nil, nil, nil, nil, body_612119)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_612105(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_612106, base: "/",
    url: url_DescribeHumanTaskUi_612107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_612120 = ref object of OpenApiRestCall_610658
proc url_DescribeHyperParameterTuningJob_612122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHyperParameterTuningJob_612121(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a description of a hyperparameter tuning job.
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
  var valid_612123 = header.getOrDefault("X-Amz-Target")
  valid_612123 = validateParameter(valid_612123, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_612123 != nil:
    section.add "X-Amz-Target", valid_612123
  var valid_612124 = header.getOrDefault("X-Amz-Signature")
  valid_612124 = validateParameter(valid_612124, JString, required = false,
                                 default = nil)
  if valid_612124 != nil:
    section.add "X-Amz-Signature", valid_612124
  var valid_612125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "X-Amz-Content-Sha256", valid_612125
  var valid_612126 = header.getOrDefault("X-Amz-Date")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Date", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Credential")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Credential", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Security-Token")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Security-Token", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Algorithm")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Algorithm", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-SignedHeaders", valid_612130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612132: Call_DescribeHyperParameterTuningJob_612120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_612132.validator(path, query, header, formData, body)
  let scheme = call_612132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612132.url(scheme.get, call_612132.host, call_612132.base,
                         call_612132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612132, url, valid)

proc call*(call_612133: Call_DescribeHyperParameterTuningJob_612120; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_612134 = newJObject()
  if body != nil:
    body_612134 = body
  result = call_612133.call(nil, nil, nil, nil, body_612134)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_612120(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_612121, base: "/",
    url: url_DescribeHyperParameterTuningJob_612122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_612135 = ref object of OpenApiRestCall_610658
proc url_DescribeLabelingJob_612137(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLabelingJob_612136(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about a labeling job.
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
  var valid_612138 = header.getOrDefault("X-Amz-Target")
  valid_612138 = validateParameter(valid_612138, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_612138 != nil:
    section.add "X-Amz-Target", valid_612138
  var valid_612139 = header.getOrDefault("X-Amz-Signature")
  valid_612139 = validateParameter(valid_612139, JString, required = false,
                                 default = nil)
  if valid_612139 != nil:
    section.add "X-Amz-Signature", valid_612139
  var valid_612140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612140 = validateParameter(valid_612140, JString, required = false,
                                 default = nil)
  if valid_612140 != nil:
    section.add "X-Amz-Content-Sha256", valid_612140
  var valid_612141 = header.getOrDefault("X-Amz-Date")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Date", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Credential")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Credential", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Security-Token")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Security-Token", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Algorithm")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Algorithm", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-SignedHeaders", valid_612145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612147: Call_DescribeLabelingJob_612135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_612147.validator(path, query, header, formData, body)
  let scheme = call_612147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612147.url(scheme.get, call_612147.host, call_612147.base,
                         call_612147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612147, url, valid)

proc call*(call_612148: Call_DescribeLabelingJob_612135; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_612149 = newJObject()
  if body != nil:
    body_612149 = body
  result = call_612148.call(nil, nil, nil, nil, body_612149)

var describeLabelingJob* = Call_DescribeLabelingJob_612135(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_612136, base: "/",
    url: url_DescribeLabelingJob_612137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_612150 = ref object of OpenApiRestCall_610658
proc url_DescribeModel_612152(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModel_612151(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a model that you created using the <code>CreateModel</code> API.
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
  var valid_612153 = header.getOrDefault("X-Amz-Target")
  valid_612153 = validateParameter(valid_612153, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_612153 != nil:
    section.add "X-Amz-Target", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Signature")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Signature", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-Content-Sha256", valid_612155
  var valid_612156 = header.getOrDefault("X-Amz-Date")
  valid_612156 = validateParameter(valid_612156, JString, required = false,
                                 default = nil)
  if valid_612156 != nil:
    section.add "X-Amz-Date", valid_612156
  var valid_612157 = header.getOrDefault("X-Amz-Credential")
  valid_612157 = validateParameter(valid_612157, JString, required = false,
                                 default = nil)
  if valid_612157 != nil:
    section.add "X-Amz-Credential", valid_612157
  var valid_612158 = header.getOrDefault("X-Amz-Security-Token")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "X-Amz-Security-Token", valid_612158
  var valid_612159 = header.getOrDefault("X-Amz-Algorithm")
  valid_612159 = validateParameter(valid_612159, JString, required = false,
                                 default = nil)
  if valid_612159 != nil:
    section.add "X-Amz-Algorithm", valid_612159
  var valid_612160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612160 = validateParameter(valid_612160, JString, required = false,
                                 default = nil)
  if valid_612160 != nil:
    section.add "X-Amz-SignedHeaders", valid_612160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612162: Call_DescribeModel_612150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_612162.validator(path, query, header, formData, body)
  let scheme = call_612162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612162.url(scheme.get, call_612162.host, call_612162.base,
                         call_612162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612162, url, valid)

proc call*(call_612163: Call_DescribeModel_612150; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_612164 = newJObject()
  if body != nil:
    body_612164 = body
  result = call_612163.call(nil, nil, nil, nil, body_612164)

var describeModel* = Call_DescribeModel_612150(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_612151, base: "/", url: url_DescribeModel_612152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_612165 = ref object of OpenApiRestCall_610658
proc url_DescribeModelPackage_612167(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelPackage_612166(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
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
  var valid_612168 = header.getOrDefault("X-Amz-Target")
  valid_612168 = validateParameter(valid_612168, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_612168 != nil:
    section.add "X-Amz-Target", valid_612168
  var valid_612169 = header.getOrDefault("X-Amz-Signature")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "X-Amz-Signature", valid_612169
  var valid_612170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Content-Sha256", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Date")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Date", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Credential")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Credential", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-Security-Token")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-Security-Token", valid_612173
  var valid_612174 = header.getOrDefault("X-Amz-Algorithm")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-Algorithm", valid_612174
  var valid_612175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-SignedHeaders", valid_612175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612177: Call_DescribeModelPackage_612165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_612177.validator(path, query, header, formData, body)
  let scheme = call_612177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612177.url(scheme.get, call_612177.host, call_612177.base,
                         call_612177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612177, url, valid)

proc call*(call_612178: Call_DescribeModelPackage_612165; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_612179 = newJObject()
  if body != nil:
    body_612179 = body
  result = call_612178.call(nil, nil, nil, nil, body_612179)

var describeModelPackage* = Call_DescribeModelPackage_612165(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_612166, base: "/",
    url: url_DescribeModelPackage_612167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_612180 = ref object of OpenApiRestCall_610658
proc url_DescribeMonitoringSchedule_612182(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMonitoringSchedule_612181(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the schedule for a monitoring job.
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
  var valid_612183 = header.getOrDefault("X-Amz-Target")
  valid_612183 = validateParameter(valid_612183, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_612183 != nil:
    section.add "X-Amz-Target", valid_612183
  var valid_612184 = header.getOrDefault("X-Amz-Signature")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "X-Amz-Signature", valid_612184
  var valid_612185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "X-Amz-Content-Sha256", valid_612185
  var valid_612186 = header.getOrDefault("X-Amz-Date")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "X-Amz-Date", valid_612186
  var valid_612187 = header.getOrDefault("X-Amz-Credential")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "X-Amz-Credential", valid_612187
  var valid_612188 = header.getOrDefault("X-Amz-Security-Token")
  valid_612188 = validateParameter(valid_612188, JString, required = false,
                                 default = nil)
  if valid_612188 != nil:
    section.add "X-Amz-Security-Token", valid_612188
  var valid_612189 = header.getOrDefault("X-Amz-Algorithm")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "X-Amz-Algorithm", valid_612189
  var valid_612190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-SignedHeaders", valid_612190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612192: Call_DescribeMonitoringSchedule_612180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_612192.validator(path, query, header, formData, body)
  let scheme = call_612192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612192.url(scheme.get, call_612192.host, call_612192.base,
                         call_612192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612192, url, valid)

proc call*(call_612193: Call_DescribeMonitoringSchedule_612180; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_612194 = newJObject()
  if body != nil:
    body_612194 = body
  result = call_612193.call(nil, nil, nil, nil, body_612194)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_612180(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_612181, base: "/",
    url: url_DescribeMonitoringSchedule_612182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_612195 = ref object of OpenApiRestCall_610658
proc url_DescribeNotebookInstance_612197(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstance_612196(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a notebook instance.
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
  var valid_612198 = header.getOrDefault("X-Amz-Target")
  valid_612198 = validateParameter(valid_612198, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_612198 != nil:
    section.add "X-Amz-Target", valid_612198
  var valid_612199 = header.getOrDefault("X-Amz-Signature")
  valid_612199 = validateParameter(valid_612199, JString, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "X-Amz-Signature", valid_612199
  var valid_612200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "X-Amz-Content-Sha256", valid_612200
  var valid_612201 = header.getOrDefault("X-Amz-Date")
  valid_612201 = validateParameter(valid_612201, JString, required = false,
                                 default = nil)
  if valid_612201 != nil:
    section.add "X-Amz-Date", valid_612201
  var valid_612202 = header.getOrDefault("X-Amz-Credential")
  valid_612202 = validateParameter(valid_612202, JString, required = false,
                                 default = nil)
  if valid_612202 != nil:
    section.add "X-Amz-Credential", valid_612202
  var valid_612203 = header.getOrDefault("X-Amz-Security-Token")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Security-Token", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-Algorithm")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-Algorithm", valid_612204
  var valid_612205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-SignedHeaders", valid_612205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612207: Call_DescribeNotebookInstance_612195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_612207.validator(path, query, header, formData, body)
  let scheme = call_612207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612207.url(scheme.get, call_612207.host, call_612207.base,
                         call_612207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612207, url, valid)

proc call*(call_612208: Call_DescribeNotebookInstance_612195; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_612209 = newJObject()
  if body != nil:
    body_612209 = body
  result = call_612208.call(nil, nil, nil, nil, body_612209)

var describeNotebookInstance* = Call_DescribeNotebookInstance_612195(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_612196, base: "/",
    url: url_DescribeNotebookInstance_612197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_612210 = ref object of OpenApiRestCall_610658
proc url_DescribeNotebookInstanceLifecycleConfig_612212(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_612211(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
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
  var valid_612213 = header.getOrDefault("X-Amz-Target")
  valid_612213 = validateParameter(valid_612213, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_612213 != nil:
    section.add "X-Amz-Target", valid_612213
  var valid_612214 = header.getOrDefault("X-Amz-Signature")
  valid_612214 = validateParameter(valid_612214, JString, required = false,
                                 default = nil)
  if valid_612214 != nil:
    section.add "X-Amz-Signature", valid_612214
  var valid_612215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612215 = validateParameter(valid_612215, JString, required = false,
                                 default = nil)
  if valid_612215 != nil:
    section.add "X-Amz-Content-Sha256", valid_612215
  var valid_612216 = header.getOrDefault("X-Amz-Date")
  valid_612216 = validateParameter(valid_612216, JString, required = false,
                                 default = nil)
  if valid_612216 != nil:
    section.add "X-Amz-Date", valid_612216
  var valid_612217 = header.getOrDefault("X-Amz-Credential")
  valid_612217 = validateParameter(valid_612217, JString, required = false,
                                 default = nil)
  if valid_612217 != nil:
    section.add "X-Amz-Credential", valid_612217
  var valid_612218 = header.getOrDefault("X-Amz-Security-Token")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Security-Token", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Algorithm")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Algorithm", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-SignedHeaders", valid_612220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612222: Call_DescribeNotebookInstanceLifecycleConfig_612210;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_612222.validator(path, query, header, formData, body)
  let scheme = call_612222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612222.url(scheme.get, call_612222.host, call_612222.base,
                         call_612222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612222, url, valid)

proc call*(call_612223: Call_DescribeNotebookInstanceLifecycleConfig_612210;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_612224 = newJObject()
  if body != nil:
    body_612224 = body
  result = call_612223.call(nil, nil, nil, nil, body_612224)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_612210(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_612211, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_612212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_612225 = ref object of OpenApiRestCall_610658
proc url_DescribeProcessingJob_612227(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProcessingJob_612226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a description of a processing job.
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
  var valid_612228 = header.getOrDefault("X-Amz-Target")
  valid_612228 = validateParameter(valid_612228, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_612228 != nil:
    section.add "X-Amz-Target", valid_612228
  var valid_612229 = header.getOrDefault("X-Amz-Signature")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "X-Amz-Signature", valid_612229
  var valid_612230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "X-Amz-Content-Sha256", valid_612230
  var valid_612231 = header.getOrDefault("X-Amz-Date")
  valid_612231 = validateParameter(valid_612231, JString, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "X-Amz-Date", valid_612231
  var valid_612232 = header.getOrDefault("X-Amz-Credential")
  valid_612232 = validateParameter(valid_612232, JString, required = false,
                                 default = nil)
  if valid_612232 != nil:
    section.add "X-Amz-Credential", valid_612232
  var valid_612233 = header.getOrDefault("X-Amz-Security-Token")
  valid_612233 = validateParameter(valid_612233, JString, required = false,
                                 default = nil)
  if valid_612233 != nil:
    section.add "X-Amz-Security-Token", valid_612233
  var valid_612234 = header.getOrDefault("X-Amz-Algorithm")
  valid_612234 = validateParameter(valid_612234, JString, required = false,
                                 default = nil)
  if valid_612234 != nil:
    section.add "X-Amz-Algorithm", valid_612234
  var valid_612235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612235 = validateParameter(valid_612235, JString, required = false,
                                 default = nil)
  if valid_612235 != nil:
    section.add "X-Amz-SignedHeaders", valid_612235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612237: Call_DescribeProcessingJob_612225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_612237.validator(path, query, header, formData, body)
  let scheme = call_612237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612237.url(scheme.get, call_612237.host, call_612237.base,
                         call_612237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612237, url, valid)

proc call*(call_612238: Call_DescribeProcessingJob_612225; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_612239 = newJObject()
  if body != nil:
    body_612239 = body
  result = call_612238.call(nil, nil, nil, nil, body_612239)

var describeProcessingJob* = Call_DescribeProcessingJob_612225(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_612226, base: "/",
    url: url_DescribeProcessingJob_612227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_612240 = ref object of OpenApiRestCall_610658
proc url_DescribeSubscribedWorkteam_612242(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubscribedWorkteam_612241(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
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
  var valid_612243 = header.getOrDefault("X-Amz-Target")
  valid_612243 = validateParameter(valid_612243, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_612243 != nil:
    section.add "X-Amz-Target", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Signature")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Signature", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Content-Sha256", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-Date")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-Date", valid_612246
  var valid_612247 = header.getOrDefault("X-Amz-Credential")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "X-Amz-Credential", valid_612247
  var valid_612248 = header.getOrDefault("X-Amz-Security-Token")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "X-Amz-Security-Token", valid_612248
  var valid_612249 = header.getOrDefault("X-Amz-Algorithm")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "X-Amz-Algorithm", valid_612249
  var valid_612250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612250 = validateParameter(valid_612250, JString, required = false,
                                 default = nil)
  if valid_612250 != nil:
    section.add "X-Amz-SignedHeaders", valid_612250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612252: Call_DescribeSubscribedWorkteam_612240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_612252.validator(path, query, header, formData, body)
  let scheme = call_612252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612252.url(scheme.get, call_612252.host, call_612252.base,
                         call_612252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612252, url, valid)

proc call*(call_612253: Call_DescribeSubscribedWorkteam_612240; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_612254 = newJObject()
  if body != nil:
    body_612254 = body
  result = call_612253.call(nil, nil, nil, nil, body_612254)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_612240(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_612241, base: "/",
    url: url_DescribeSubscribedWorkteam_612242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_612255 = ref object of OpenApiRestCall_610658
proc url_DescribeTrainingJob_612257(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrainingJob_612256(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about a training job.
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
  var valid_612258 = header.getOrDefault("X-Amz-Target")
  valid_612258 = validateParameter(valid_612258, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_612258 != nil:
    section.add "X-Amz-Target", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Signature")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Signature", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Content-Sha256", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Date")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Date", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-Credential")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Credential", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-Security-Token")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-Security-Token", valid_612263
  var valid_612264 = header.getOrDefault("X-Amz-Algorithm")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Algorithm", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-SignedHeaders", valid_612265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612267: Call_DescribeTrainingJob_612255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_612267.validator(path, query, header, formData, body)
  let scheme = call_612267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612267.url(scheme.get, call_612267.host, call_612267.base,
                         call_612267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612267, url, valid)

proc call*(call_612268: Call_DescribeTrainingJob_612255; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_612269 = newJObject()
  if body != nil:
    body_612269 = body
  result = call_612268.call(nil, nil, nil, nil, body_612269)

var describeTrainingJob* = Call_DescribeTrainingJob_612255(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_612256, base: "/",
    url: url_DescribeTrainingJob_612257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_612270 = ref object of OpenApiRestCall_610658
proc url_DescribeTransformJob_612272(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTransformJob_612271(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a transform job.
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
  var valid_612273 = header.getOrDefault("X-Amz-Target")
  valid_612273 = validateParameter(valid_612273, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_612273 != nil:
    section.add "X-Amz-Target", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Signature")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Signature", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-Content-Sha256", valid_612275
  var valid_612276 = header.getOrDefault("X-Amz-Date")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "X-Amz-Date", valid_612276
  var valid_612277 = header.getOrDefault("X-Amz-Credential")
  valid_612277 = validateParameter(valid_612277, JString, required = false,
                                 default = nil)
  if valid_612277 != nil:
    section.add "X-Amz-Credential", valid_612277
  var valid_612278 = header.getOrDefault("X-Amz-Security-Token")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "X-Amz-Security-Token", valid_612278
  var valid_612279 = header.getOrDefault("X-Amz-Algorithm")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Algorithm", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-SignedHeaders", valid_612280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612282: Call_DescribeTransformJob_612270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_612282.validator(path, query, header, formData, body)
  let scheme = call_612282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612282.url(scheme.get, call_612282.host, call_612282.base,
                         call_612282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612282, url, valid)

proc call*(call_612283: Call_DescribeTransformJob_612270; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_612284 = newJObject()
  if body != nil:
    body_612284 = body
  result = call_612283.call(nil, nil, nil, nil, body_612284)

var describeTransformJob* = Call_DescribeTransformJob_612270(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_612271, base: "/",
    url: url_DescribeTransformJob_612272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_612285 = ref object of OpenApiRestCall_610658
proc url_DescribeTrial_612287(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrial_612286(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a list of a trial's properties.
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
  var valid_612288 = header.getOrDefault("X-Amz-Target")
  valid_612288 = validateParameter(valid_612288, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_612288 != nil:
    section.add "X-Amz-Target", valid_612288
  var valid_612289 = header.getOrDefault("X-Amz-Signature")
  valid_612289 = validateParameter(valid_612289, JString, required = false,
                                 default = nil)
  if valid_612289 != nil:
    section.add "X-Amz-Signature", valid_612289
  var valid_612290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612290 = validateParameter(valid_612290, JString, required = false,
                                 default = nil)
  if valid_612290 != nil:
    section.add "X-Amz-Content-Sha256", valid_612290
  var valid_612291 = header.getOrDefault("X-Amz-Date")
  valid_612291 = validateParameter(valid_612291, JString, required = false,
                                 default = nil)
  if valid_612291 != nil:
    section.add "X-Amz-Date", valid_612291
  var valid_612292 = header.getOrDefault("X-Amz-Credential")
  valid_612292 = validateParameter(valid_612292, JString, required = false,
                                 default = nil)
  if valid_612292 != nil:
    section.add "X-Amz-Credential", valid_612292
  var valid_612293 = header.getOrDefault("X-Amz-Security-Token")
  valid_612293 = validateParameter(valid_612293, JString, required = false,
                                 default = nil)
  if valid_612293 != nil:
    section.add "X-Amz-Security-Token", valid_612293
  var valid_612294 = header.getOrDefault("X-Amz-Algorithm")
  valid_612294 = validateParameter(valid_612294, JString, required = false,
                                 default = nil)
  if valid_612294 != nil:
    section.add "X-Amz-Algorithm", valid_612294
  var valid_612295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612295 = validateParameter(valid_612295, JString, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "X-Amz-SignedHeaders", valid_612295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612297: Call_DescribeTrial_612285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_612297.validator(path, query, header, formData, body)
  let scheme = call_612297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612297.url(scheme.get, call_612297.host, call_612297.base,
                         call_612297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612297, url, valid)

proc call*(call_612298: Call_DescribeTrial_612285; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_612299 = newJObject()
  if body != nil:
    body_612299 = body
  result = call_612298.call(nil, nil, nil, nil, body_612299)

var describeTrial* = Call_DescribeTrial_612285(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_612286, base: "/", url: url_DescribeTrial_612287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_612300 = ref object of OpenApiRestCall_610658
proc url_DescribeTrialComponent_612302(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrialComponent_612301(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a list of a trials component's properties.
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
  var valid_612303 = header.getOrDefault("X-Amz-Target")
  valid_612303 = validateParameter(valid_612303, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_612303 != nil:
    section.add "X-Amz-Target", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Signature")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Signature", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Content-Sha256", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Date")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Date", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-Credential")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-Credential", valid_612307
  var valid_612308 = header.getOrDefault("X-Amz-Security-Token")
  valid_612308 = validateParameter(valid_612308, JString, required = false,
                                 default = nil)
  if valid_612308 != nil:
    section.add "X-Amz-Security-Token", valid_612308
  var valid_612309 = header.getOrDefault("X-Amz-Algorithm")
  valid_612309 = validateParameter(valid_612309, JString, required = false,
                                 default = nil)
  if valid_612309 != nil:
    section.add "X-Amz-Algorithm", valid_612309
  var valid_612310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612310 = validateParameter(valid_612310, JString, required = false,
                                 default = nil)
  if valid_612310 != nil:
    section.add "X-Amz-SignedHeaders", valid_612310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612312: Call_DescribeTrialComponent_612300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_612312.validator(path, query, header, formData, body)
  let scheme = call_612312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612312.url(scheme.get, call_612312.host, call_612312.base,
                         call_612312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612312, url, valid)

proc call*(call_612313: Call_DescribeTrialComponent_612300; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_612314 = newJObject()
  if body != nil:
    body_612314 = body
  result = call_612313.call(nil, nil, nil, nil, body_612314)

var describeTrialComponent* = Call_DescribeTrialComponent_612300(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_612301, base: "/",
    url: url_DescribeTrialComponent_612302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_612315 = ref object of OpenApiRestCall_610658
proc url_DescribeUserProfile_612317(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserProfile_612316(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the user profile.
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
  var valid_612318 = header.getOrDefault("X-Amz-Target")
  valid_612318 = validateParameter(valid_612318, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_612318 != nil:
    section.add "X-Amz-Target", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Signature")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Signature", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Content-Sha256", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Date")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Date", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-Credential")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-Credential", valid_612322
  var valid_612323 = header.getOrDefault("X-Amz-Security-Token")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "X-Amz-Security-Token", valid_612323
  var valid_612324 = header.getOrDefault("X-Amz-Algorithm")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "X-Amz-Algorithm", valid_612324
  var valid_612325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612325 = validateParameter(valid_612325, JString, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "X-Amz-SignedHeaders", valid_612325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612327: Call_DescribeUserProfile_612315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_612327.validator(path, query, header, formData, body)
  let scheme = call_612327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612327.url(scheme.get, call_612327.host, call_612327.base,
                         call_612327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612327, url, valid)

proc call*(call_612328: Call_DescribeUserProfile_612315; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_612329 = newJObject()
  if body != nil:
    body_612329 = body
  result = call_612328.call(nil, nil, nil, nil, body_612329)

var describeUserProfile* = Call_DescribeUserProfile_612315(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_612316, base: "/",
    url: url_DescribeUserProfile_612317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkforce_612330 = ref object of OpenApiRestCall_610658
proc url_DescribeWorkforce_612332(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkforce_612331(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
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
  var valid_612333 = header.getOrDefault("X-Amz-Target")
  valid_612333 = validateParameter(valid_612333, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkforce"))
  if valid_612333 != nil:
    section.add "X-Amz-Target", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Signature")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Signature", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Content-Sha256", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Date")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Date", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Credential")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Credential", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Security-Token")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Security-Token", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Algorithm")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Algorithm", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-SignedHeaders", valid_612340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612342: Call_DescribeWorkforce_612330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_612342.validator(path, query, header, formData, body)
  let scheme = call_612342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612342.url(scheme.get, call_612342.host, call_612342.base,
                         call_612342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612342, url, valid)

proc call*(call_612343: Call_DescribeWorkforce_612330; body: JsonNode): Recallable =
  ## describeWorkforce
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_612344 = newJObject()
  if body != nil:
    body_612344 = body
  result = call_612343.call(nil, nil, nil, nil, body_612344)

var describeWorkforce* = Call_DescribeWorkforce_612330(name: "describeWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkforce",
    validator: validate_DescribeWorkforce_612331, base: "/",
    url: url_DescribeWorkforce_612332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_612345 = ref object of OpenApiRestCall_610658
proc url_DescribeWorkteam_612347(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkteam_612346(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
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
  var valid_612348 = header.getOrDefault("X-Amz-Target")
  valid_612348 = validateParameter(valid_612348, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_612348 != nil:
    section.add "X-Amz-Target", valid_612348
  var valid_612349 = header.getOrDefault("X-Amz-Signature")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Signature", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Content-Sha256", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Date")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Date", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Credential")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Credential", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Security-Token")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Security-Token", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Algorithm")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Algorithm", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-SignedHeaders", valid_612355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612357: Call_DescribeWorkteam_612345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_612357.validator(path, query, header, formData, body)
  let scheme = call_612357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612357.url(scheme.get, call_612357.host, call_612357.base,
                         call_612357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612357, url, valid)

proc call*(call_612358: Call_DescribeWorkteam_612345; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_612359 = newJObject()
  if body != nil:
    body_612359 = body
  result = call_612358.call(nil, nil, nil, nil, body_612359)

var describeWorkteam* = Call_DescribeWorkteam_612345(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_612346, base: "/",
    url: url_DescribeWorkteam_612347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_612360 = ref object of OpenApiRestCall_610658
proc url_DisassociateTrialComponent_612362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTrialComponent_612361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
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
  var valid_612363 = header.getOrDefault("X-Amz-Target")
  valid_612363 = validateParameter(valid_612363, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_612363 != nil:
    section.add "X-Amz-Target", valid_612363
  var valid_612364 = header.getOrDefault("X-Amz-Signature")
  valid_612364 = validateParameter(valid_612364, JString, required = false,
                                 default = nil)
  if valid_612364 != nil:
    section.add "X-Amz-Signature", valid_612364
  var valid_612365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612365 = validateParameter(valid_612365, JString, required = false,
                                 default = nil)
  if valid_612365 != nil:
    section.add "X-Amz-Content-Sha256", valid_612365
  var valid_612366 = header.getOrDefault("X-Amz-Date")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Date", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-Credential")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Credential", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-Security-Token")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Security-Token", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Algorithm")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Algorithm", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-SignedHeaders", valid_612370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612372: Call_DisassociateTrialComponent_612360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ## 
  let valid = call_612372.validator(path, query, header, formData, body)
  let scheme = call_612372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612372.url(scheme.get, call_612372.host, call_612372.base,
                         call_612372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612372, url, valid)

proc call*(call_612373: Call_DisassociateTrialComponent_612360; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_612374 = newJObject()
  if body != nil:
    body_612374 = body
  result = call_612373.call(nil, nil, nil, nil, body_612374)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_612360(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_612361, base: "/",
    url: url_DisassociateTrialComponent_612362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_612375 = ref object of OpenApiRestCall_610658
proc url_GetSearchSuggestions_612377(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSearchSuggestions_612376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
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
  var valid_612378 = header.getOrDefault("X-Amz-Target")
  valid_612378 = validateParameter(valid_612378, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_612378 != nil:
    section.add "X-Amz-Target", valid_612378
  var valid_612379 = header.getOrDefault("X-Amz-Signature")
  valid_612379 = validateParameter(valid_612379, JString, required = false,
                                 default = nil)
  if valid_612379 != nil:
    section.add "X-Amz-Signature", valid_612379
  var valid_612380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612380 = validateParameter(valid_612380, JString, required = false,
                                 default = nil)
  if valid_612380 != nil:
    section.add "X-Amz-Content-Sha256", valid_612380
  var valid_612381 = header.getOrDefault("X-Amz-Date")
  valid_612381 = validateParameter(valid_612381, JString, required = false,
                                 default = nil)
  if valid_612381 != nil:
    section.add "X-Amz-Date", valid_612381
  var valid_612382 = header.getOrDefault("X-Amz-Credential")
  valid_612382 = validateParameter(valid_612382, JString, required = false,
                                 default = nil)
  if valid_612382 != nil:
    section.add "X-Amz-Credential", valid_612382
  var valid_612383 = header.getOrDefault("X-Amz-Security-Token")
  valid_612383 = validateParameter(valid_612383, JString, required = false,
                                 default = nil)
  if valid_612383 != nil:
    section.add "X-Amz-Security-Token", valid_612383
  var valid_612384 = header.getOrDefault("X-Amz-Algorithm")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-Algorithm", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-SignedHeaders", valid_612385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612387: Call_GetSearchSuggestions_612375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_612387.validator(path, query, header, formData, body)
  let scheme = call_612387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612387.url(scheme.get, call_612387.host, call_612387.base,
                         call_612387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612387, url, valid)

proc call*(call_612388: Call_GetSearchSuggestions_612375; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_612389 = newJObject()
  if body != nil:
    body_612389 = body
  result = call_612388.call(nil, nil, nil, nil, body_612389)

var getSearchSuggestions* = Call_GetSearchSuggestions_612375(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_612376, base: "/",
    url: url_GetSearchSuggestions_612377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_612390 = ref object of OpenApiRestCall_610658
proc url_ListAlgorithms_612392(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAlgorithms_612391(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the machine learning algorithms that have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612393 = query.getOrDefault("MaxResults")
  valid_612393 = validateParameter(valid_612393, JString, required = false,
                                 default = nil)
  if valid_612393 != nil:
    section.add "MaxResults", valid_612393
  var valid_612394 = query.getOrDefault("NextToken")
  valid_612394 = validateParameter(valid_612394, JString, required = false,
                                 default = nil)
  if valid_612394 != nil:
    section.add "NextToken", valid_612394
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
  var valid_612395 = header.getOrDefault("X-Amz-Target")
  valid_612395 = validateParameter(valid_612395, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_612395 != nil:
    section.add "X-Amz-Target", valid_612395
  var valid_612396 = header.getOrDefault("X-Amz-Signature")
  valid_612396 = validateParameter(valid_612396, JString, required = false,
                                 default = nil)
  if valid_612396 != nil:
    section.add "X-Amz-Signature", valid_612396
  var valid_612397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "X-Amz-Content-Sha256", valid_612397
  var valid_612398 = header.getOrDefault("X-Amz-Date")
  valid_612398 = validateParameter(valid_612398, JString, required = false,
                                 default = nil)
  if valid_612398 != nil:
    section.add "X-Amz-Date", valid_612398
  var valid_612399 = header.getOrDefault("X-Amz-Credential")
  valid_612399 = validateParameter(valid_612399, JString, required = false,
                                 default = nil)
  if valid_612399 != nil:
    section.add "X-Amz-Credential", valid_612399
  var valid_612400 = header.getOrDefault("X-Amz-Security-Token")
  valid_612400 = validateParameter(valid_612400, JString, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "X-Amz-Security-Token", valid_612400
  var valid_612401 = header.getOrDefault("X-Amz-Algorithm")
  valid_612401 = validateParameter(valid_612401, JString, required = false,
                                 default = nil)
  if valid_612401 != nil:
    section.add "X-Amz-Algorithm", valid_612401
  var valid_612402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-SignedHeaders", valid_612402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612404: Call_ListAlgorithms_612390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_612404.validator(path, query, header, formData, body)
  let scheme = call_612404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612404.url(scheme.get, call_612404.host, call_612404.base,
                         call_612404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612404, url, valid)

proc call*(call_612405: Call_ListAlgorithms_612390; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612406 = newJObject()
  var body_612407 = newJObject()
  add(query_612406, "MaxResults", newJString(MaxResults))
  add(query_612406, "NextToken", newJString(NextToken))
  if body != nil:
    body_612407 = body
  result = call_612405.call(nil, query_612406, nil, nil, body_612407)

var listAlgorithms* = Call_ListAlgorithms_612390(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_612391, base: "/", url: url_ListAlgorithms_612392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_612409 = ref object of OpenApiRestCall_610658
proc url_ListApps_612411(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_612410(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists apps.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612412 = query.getOrDefault("MaxResults")
  valid_612412 = validateParameter(valid_612412, JString, required = false,
                                 default = nil)
  if valid_612412 != nil:
    section.add "MaxResults", valid_612412
  var valid_612413 = query.getOrDefault("NextToken")
  valid_612413 = validateParameter(valid_612413, JString, required = false,
                                 default = nil)
  if valid_612413 != nil:
    section.add "NextToken", valid_612413
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
  var valid_612414 = header.getOrDefault("X-Amz-Target")
  valid_612414 = validateParameter(valid_612414, JString, required = true,
                                 default = newJString("SageMaker.ListApps"))
  if valid_612414 != nil:
    section.add "X-Amz-Target", valid_612414
  var valid_612415 = header.getOrDefault("X-Amz-Signature")
  valid_612415 = validateParameter(valid_612415, JString, required = false,
                                 default = nil)
  if valid_612415 != nil:
    section.add "X-Amz-Signature", valid_612415
  var valid_612416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612416 = validateParameter(valid_612416, JString, required = false,
                                 default = nil)
  if valid_612416 != nil:
    section.add "X-Amz-Content-Sha256", valid_612416
  var valid_612417 = header.getOrDefault("X-Amz-Date")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Date", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Credential")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Credential", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Security-Token")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Security-Token", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Algorithm")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Algorithm", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-SignedHeaders", valid_612421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612423: Call_ListApps_612409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists apps.
  ## 
  let valid = call_612423.validator(path, query, header, formData, body)
  let scheme = call_612423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612423.url(scheme.get, call_612423.host, call_612423.base,
                         call_612423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612423, url, valid)

proc call*(call_612424: Call_ListApps_612409; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612425 = newJObject()
  var body_612426 = newJObject()
  add(query_612425, "MaxResults", newJString(MaxResults))
  add(query_612425, "NextToken", newJString(NextToken))
  if body != nil:
    body_612426 = body
  result = call_612424.call(nil, query_612425, nil, nil, body_612426)

var listApps* = Call_ListApps_612409(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListApps",
                                  validator: validate_ListApps_612410, base: "/",
                                  url: url_ListApps_612411,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_612427 = ref object of OpenApiRestCall_610658
proc url_ListAutoMLJobs_612429(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAutoMLJobs_612428(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Request a list of jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612430 = query.getOrDefault("MaxResults")
  valid_612430 = validateParameter(valid_612430, JString, required = false,
                                 default = nil)
  if valid_612430 != nil:
    section.add "MaxResults", valid_612430
  var valid_612431 = query.getOrDefault("NextToken")
  valid_612431 = validateParameter(valid_612431, JString, required = false,
                                 default = nil)
  if valid_612431 != nil:
    section.add "NextToken", valid_612431
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
  var valid_612432 = header.getOrDefault("X-Amz-Target")
  valid_612432 = validateParameter(valid_612432, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_612432 != nil:
    section.add "X-Amz-Target", valid_612432
  var valid_612433 = header.getOrDefault("X-Amz-Signature")
  valid_612433 = validateParameter(valid_612433, JString, required = false,
                                 default = nil)
  if valid_612433 != nil:
    section.add "X-Amz-Signature", valid_612433
  var valid_612434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612434 = validateParameter(valid_612434, JString, required = false,
                                 default = nil)
  if valid_612434 != nil:
    section.add "X-Amz-Content-Sha256", valid_612434
  var valid_612435 = header.getOrDefault("X-Amz-Date")
  valid_612435 = validateParameter(valid_612435, JString, required = false,
                                 default = nil)
  if valid_612435 != nil:
    section.add "X-Amz-Date", valid_612435
  var valid_612436 = header.getOrDefault("X-Amz-Credential")
  valid_612436 = validateParameter(valid_612436, JString, required = false,
                                 default = nil)
  if valid_612436 != nil:
    section.add "X-Amz-Credential", valid_612436
  var valid_612437 = header.getOrDefault("X-Amz-Security-Token")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Security-Token", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Algorithm")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Algorithm", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-SignedHeaders", valid_612439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612441: Call_ListAutoMLJobs_612427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_612441.validator(path, query, header, formData, body)
  let scheme = call_612441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612441.url(scheme.get, call_612441.host, call_612441.base,
                         call_612441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612441, url, valid)

proc call*(call_612442: Call_ListAutoMLJobs_612427; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612443 = newJObject()
  var body_612444 = newJObject()
  add(query_612443, "MaxResults", newJString(MaxResults))
  add(query_612443, "NextToken", newJString(NextToken))
  if body != nil:
    body_612444 = body
  result = call_612442.call(nil, query_612443, nil, nil, body_612444)

var listAutoMLJobs* = Call_ListAutoMLJobs_612427(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_612428, base: "/", url: url_ListAutoMLJobs_612429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_612445 = ref object of OpenApiRestCall_610658
proc url_ListCandidatesForAutoMLJob_612447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCandidatesForAutoMLJob_612446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the Candidates created for the job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612448 = query.getOrDefault("MaxResults")
  valid_612448 = validateParameter(valid_612448, JString, required = false,
                                 default = nil)
  if valid_612448 != nil:
    section.add "MaxResults", valid_612448
  var valid_612449 = query.getOrDefault("NextToken")
  valid_612449 = validateParameter(valid_612449, JString, required = false,
                                 default = nil)
  if valid_612449 != nil:
    section.add "NextToken", valid_612449
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
  var valid_612450 = header.getOrDefault("X-Amz-Target")
  valid_612450 = validateParameter(valid_612450, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_612450 != nil:
    section.add "X-Amz-Target", valid_612450
  var valid_612451 = header.getOrDefault("X-Amz-Signature")
  valid_612451 = validateParameter(valid_612451, JString, required = false,
                                 default = nil)
  if valid_612451 != nil:
    section.add "X-Amz-Signature", valid_612451
  var valid_612452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Content-Sha256", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Date")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Date", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Credential")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Credential", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Security-Token")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Security-Token", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Algorithm")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Algorithm", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-SignedHeaders", valid_612457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612459: Call_ListCandidatesForAutoMLJob_612445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_612459.validator(path, query, header, formData, body)
  let scheme = call_612459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612459.url(scheme.get, call_612459.host, call_612459.base,
                         call_612459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612459, url, valid)

proc call*(call_612460: Call_ListCandidatesForAutoMLJob_612445; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612461 = newJObject()
  var body_612462 = newJObject()
  add(query_612461, "MaxResults", newJString(MaxResults))
  add(query_612461, "NextToken", newJString(NextToken))
  if body != nil:
    body_612462 = body
  result = call_612460.call(nil, query_612461, nil, nil, body_612462)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_612445(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_612446, base: "/",
    url: url_ListCandidatesForAutoMLJob_612447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_612463 = ref object of OpenApiRestCall_610658
proc url_ListCodeRepositories_612465(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCodeRepositories_612464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the Git repositories in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612466 = query.getOrDefault("MaxResults")
  valid_612466 = validateParameter(valid_612466, JString, required = false,
                                 default = nil)
  if valid_612466 != nil:
    section.add "MaxResults", valid_612466
  var valid_612467 = query.getOrDefault("NextToken")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "NextToken", valid_612467
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
  var valid_612468 = header.getOrDefault("X-Amz-Target")
  valid_612468 = validateParameter(valid_612468, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_612468 != nil:
    section.add "X-Amz-Target", valid_612468
  var valid_612469 = header.getOrDefault("X-Amz-Signature")
  valid_612469 = validateParameter(valid_612469, JString, required = false,
                                 default = nil)
  if valid_612469 != nil:
    section.add "X-Amz-Signature", valid_612469
  var valid_612470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "X-Amz-Content-Sha256", valid_612470
  var valid_612471 = header.getOrDefault("X-Amz-Date")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Date", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Credential")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Credential", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Security-Token")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Security-Token", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Algorithm")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Algorithm", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-SignedHeaders", valid_612475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612477: Call_ListCodeRepositories_612463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_612477.validator(path, query, header, formData, body)
  let scheme = call_612477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612477.url(scheme.get, call_612477.host, call_612477.base,
                         call_612477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612477, url, valid)

proc call*(call_612478: Call_ListCodeRepositories_612463; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612479 = newJObject()
  var body_612480 = newJObject()
  add(query_612479, "MaxResults", newJString(MaxResults))
  add(query_612479, "NextToken", newJString(NextToken))
  if body != nil:
    body_612480 = body
  result = call_612478.call(nil, query_612479, nil, nil, body_612480)

var listCodeRepositories* = Call_ListCodeRepositories_612463(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_612464, base: "/",
    url: url_ListCodeRepositories_612465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_612481 = ref object of OpenApiRestCall_610658
proc url_ListCompilationJobs_612483(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompilationJobs_612482(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612484 = query.getOrDefault("MaxResults")
  valid_612484 = validateParameter(valid_612484, JString, required = false,
                                 default = nil)
  if valid_612484 != nil:
    section.add "MaxResults", valid_612484
  var valid_612485 = query.getOrDefault("NextToken")
  valid_612485 = validateParameter(valid_612485, JString, required = false,
                                 default = nil)
  if valid_612485 != nil:
    section.add "NextToken", valid_612485
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
  var valid_612486 = header.getOrDefault("X-Amz-Target")
  valid_612486 = validateParameter(valid_612486, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_612486 != nil:
    section.add "X-Amz-Target", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Signature")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Signature", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Content-Sha256", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Date")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Date", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Credential")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Credential", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Security-Token")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Security-Token", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-Algorithm")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-Algorithm", valid_612492
  var valid_612493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "X-Amz-SignedHeaders", valid_612493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612495: Call_ListCompilationJobs_612481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_612495.validator(path, query, header, formData, body)
  let scheme = call_612495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612495.url(scheme.get, call_612495.host, call_612495.base,
                         call_612495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612495, url, valid)

proc call*(call_612496: Call_ListCompilationJobs_612481; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612497 = newJObject()
  var body_612498 = newJObject()
  add(query_612497, "MaxResults", newJString(MaxResults))
  add(query_612497, "NextToken", newJString(NextToken))
  if body != nil:
    body_612498 = body
  result = call_612496.call(nil, query_612497, nil, nil, body_612498)

var listCompilationJobs* = Call_ListCompilationJobs_612481(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_612482, base: "/",
    url: url_ListCompilationJobs_612483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_612499 = ref object of OpenApiRestCall_610658
proc url_ListDomains_612501(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_612500(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the domains.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612502 = query.getOrDefault("MaxResults")
  valid_612502 = validateParameter(valid_612502, JString, required = false,
                                 default = nil)
  if valid_612502 != nil:
    section.add "MaxResults", valid_612502
  var valid_612503 = query.getOrDefault("NextToken")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "NextToken", valid_612503
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
  var valid_612504 = header.getOrDefault("X-Amz-Target")
  valid_612504 = validateParameter(valid_612504, JString, required = true,
                                 default = newJString("SageMaker.ListDomains"))
  if valid_612504 != nil:
    section.add "X-Amz-Target", valid_612504
  var valid_612505 = header.getOrDefault("X-Amz-Signature")
  valid_612505 = validateParameter(valid_612505, JString, required = false,
                                 default = nil)
  if valid_612505 != nil:
    section.add "X-Amz-Signature", valid_612505
  var valid_612506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "X-Amz-Content-Sha256", valid_612506
  var valid_612507 = header.getOrDefault("X-Amz-Date")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Date", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Credential")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Credential", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Security-Token")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Security-Token", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Algorithm")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Algorithm", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-SignedHeaders", valid_612511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612513: Call_ListDomains_612499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_612513.validator(path, query, header, formData, body)
  let scheme = call_612513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612513.url(scheme.get, call_612513.host, call_612513.base,
                         call_612513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612513, url, valid)

proc call*(call_612514: Call_ListDomains_612499; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612515 = newJObject()
  var body_612516 = newJObject()
  add(query_612515, "MaxResults", newJString(MaxResults))
  add(query_612515, "NextToken", newJString(NextToken))
  if body != nil:
    body_612516 = body
  result = call_612514.call(nil, query_612515, nil, nil, body_612516)

var listDomains* = Call_ListDomains_612499(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListDomains",
                                        validator: validate_ListDomains_612500,
                                        base: "/", url: url_ListDomains_612501,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_612517 = ref object of OpenApiRestCall_610658
proc url_ListEndpointConfigs_612519(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpointConfigs_612518(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists endpoint configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612520 = query.getOrDefault("MaxResults")
  valid_612520 = validateParameter(valid_612520, JString, required = false,
                                 default = nil)
  if valid_612520 != nil:
    section.add "MaxResults", valid_612520
  var valid_612521 = query.getOrDefault("NextToken")
  valid_612521 = validateParameter(valid_612521, JString, required = false,
                                 default = nil)
  if valid_612521 != nil:
    section.add "NextToken", valid_612521
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
  var valid_612522 = header.getOrDefault("X-Amz-Target")
  valid_612522 = validateParameter(valid_612522, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_612522 != nil:
    section.add "X-Amz-Target", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Signature")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Signature", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Content-Sha256", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Date")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Date", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Credential")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Credential", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Security-Token")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Security-Token", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-Algorithm")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-Algorithm", valid_612528
  var valid_612529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612529 = validateParameter(valid_612529, JString, required = false,
                                 default = nil)
  if valid_612529 != nil:
    section.add "X-Amz-SignedHeaders", valid_612529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612531: Call_ListEndpointConfigs_612517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_612531.validator(path, query, header, formData, body)
  let scheme = call_612531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612531.url(scheme.get, call_612531.host, call_612531.base,
                         call_612531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612531, url, valid)

proc call*(call_612532: Call_ListEndpointConfigs_612517; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612533 = newJObject()
  var body_612534 = newJObject()
  add(query_612533, "MaxResults", newJString(MaxResults))
  add(query_612533, "NextToken", newJString(NextToken))
  if body != nil:
    body_612534 = body
  result = call_612532.call(nil, query_612533, nil, nil, body_612534)

var listEndpointConfigs* = Call_ListEndpointConfigs_612517(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_612518, base: "/",
    url: url_ListEndpointConfigs_612519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_612535 = ref object of OpenApiRestCall_610658
proc url_ListEndpoints_612537(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_612536(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists endpoints.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612538 = query.getOrDefault("MaxResults")
  valid_612538 = validateParameter(valid_612538, JString, required = false,
                                 default = nil)
  if valid_612538 != nil:
    section.add "MaxResults", valid_612538
  var valid_612539 = query.getOrDefault("NextToken")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "NextToken", valid_612539
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
  var valid_612540 = header.getOrDefault("X-Amz-Target")
  valid_612540 = validateParameter(valid_612540, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_612540 != nil:
    section.add "X-Amz-Target", valid_612540
  var valid_612541 = header.getOrDefault("X-Amz-Signature")
  valid_612541 = validateParameter(valid_612541, JString, required = false,
                                 default = nil)
  if valid_612541 != nil:
    section.add "X-Amz-Signature", valid_612541
  var valid_612542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "X-Amz-Content-Sha256", valid_612542
  var valid_612543 = header.getOrDefault("X-Amz-Date")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Date", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Credential")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Credential", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-Security-Token")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-Security-Token", valid_612545
  var valid_612546 = header.getOrDefault("X-Amz-Algorithm")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-Algorithm", valid_612546
  var valid_612547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612547 = validateParameter(valid_612547, JString, required = false,
                                 default = nil)
  if valid_612547 != nil:
    section.add "X-Amz-SignedHeaders", valid_612547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612549: Call_ListEndpoints_612535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_612549.validator(path, query, header, formData, body)
  let scheme = call_612549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612549.url(scheme.get, call_612549.host, call_612549.base,
                         call_612549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612549, url, valid)

proc call*(call_612550: Call_ListEndpoints_612535; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612551 = newJObject()
  var body_612552 = newJObject()
  add(query_612551, "MaxResults", newJString(MaxResults))
  add(query_612551, "NextToken", newJString(NextToken))
  if body != nil:
    body_612552 = body
  result = call_612550.call(nil, query_612551, nil, nil, body_612552)

var listEndpoints* = Call_ListEndpoints_612535(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_612536, base: "/", url: url_ListEndpoints_612537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_612553 = ref object of OpenApiRestCall_610658
proc url_ListExperiments_612555(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExperiments_612554(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612556 = query.getOrDefault("MaxResults")
  valid_612556 = validateParameter(valid_612556, JString, required = false,
                                 default = nil)
  if valid_612556 != nil:
    section.add "MaxResults", valid_612556
  var valid_612557 = query.getOrDefault("NextToken")
  valid_612557 = validateParameter(valid_612557, JString, required = false,
                                 default = nil)
  if valid_612557 != nil:
    section.add "NextToken", valid_612557
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
  var valid_612558 = header.getOrDefault("X-Amz-Target")
  valid_612558 = validateParameter(valid_612558, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_612558 != nil:
    section.add "X-Amz-Target", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Signature")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Signature", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-Content-Sha256", valid_612560
  var valid_612561 = header.getOrDefault("X-Amz-Date")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-Date", valid_612561
  var valid_612562 = header.getOrDefault("X-Amz-Credential")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "X-Amz-Credential", valid_612562
  var valid_612563 = header.getOrDefault("X-Amz-Security-Token")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "X-Amz-Security-Token", valid_612563
  var valid_612564 = header.getOrDefault("X-Amz-Algorithm")
  valid_612564 = validateParameter(valid_612564, JString, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "X-Amz-Algorithm", valid_612564
  var valid_612565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "X-Amz-SignedHeaders", valid_612565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612567: Call_ListExperiments_612553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_612567.validator(path, query, header, formData, body)
  let scheme = call_612567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612567.url(scheme.get, call_612567.host, call_612567.base,
                         call_612567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612567, url, valid)

proc call*(call_612568: Call_ListExperiments_612553; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612569 = newJObject()
  var body_612570 = newJObject()
  add(query_612569, "MaxResults", newJString(MaxResults))
  add(query_612569, "NextToken", newJString(NextToken))
  if body != nil:
    body_612570 = body
  result = call_612568.call(nil, query_612569, nil, nil, body_612570)

var listExperiments* = Call_ListExperiments_612553(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_612554, base: "/", url: url_ListExperiments_612555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_612571 = ref object of OpenApiRestCall_610658
proc url_ListFlowDefinitions_612573(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowDefinitions_612572(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns information about the flow definitions in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612574 = query.getOrDefault("MaxResults")
  valid_612574 = validateParameter(valid_612574, JString, required = false,
                                 default = nil)
  if valid_612574 != nil:
    section.add "MaxResults", valid_612574
  var valid_612575 = query.getOrDefault("NextToken")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "NextToken", valid_612575
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
  var valid_612576 = header.getOrDefault("X-Amz-Target")
  valid_612576 = validateParameter(valid_612576, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_612576 != nil:
    section.add "X-Amz-Target", valid_612576
  var valid_612577 = header.getOrDefault("X-Amz-Signature")
  valid_612577 = validateParameter(valid_612577, JString, required = false,
                                 default = nil)
  if valid_612577 != nil:
    section.add "X-Amz-Signature", valid_612577
  var valid_612578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "X-Amz-Content-Sha256", valid_612578
  var valid_612579 = header.getOrDefault("X-Amz-Date")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "X-Amz-Date", valid_612579
  var valid_612580 = header.getOrDefault("X-Amz-Credential")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Credential", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Security-Token")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Security-Token", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Algorithm")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Algorithm", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-SignedHeaders", valid_612583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612585: Call_ListFlowDefinitions_612571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_612585.validator(path, query, header, formData, body)
  let scheme = call_612585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612585.url(scheme.get, call_612585.host, call_612585.base,
                         call_612585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612585, url, valid)

proc call*(call_612586: Call_ListFlowDefinitions_612571; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612587 = newJObject()
  var body_612588 = newJObject()
  add(query_612587, "MaxResults", newJString(MaxResults))
  add(query_612587, "NextToken", newJString(NextToken))
  if body != nil:
    body_612588 = body
  result = call_612586.call(nil, query_612587, nil, nil, body_612588)

var listFlowDefinitions* = Call_ListFlowDefinitions_612571(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_612572, base: "/",
    url: url_ListFlowDefinitions_612573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_612589 = ref object of OpenApiRestCall_610658
proc url_ListHumanTaskUis_612591(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanTaskUis_612590(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns information about the human task user interfaces in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612592 = query.getOrDefault("MaxResults")
  valid_612592 = validateParameter(valid_612592, JString, required = false,
                                 default = nil)
  if valid_612592 != nil:
    section.add "MaxResults", valid_612592
  var valid_612593 = query.getOrDefault("NextToken")
  valid_612593 = validateParameter(valid_612593, JString, required = false,
                                 default = nil)
  if valid_612593 != nil:
    section.add "NextToken", valid_612593
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
  var valid_612594 = header.getOrDefault("X-Amz-Target")
  valid_612594 = validateParameter(valid_612594, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_612594 != nil:
    section.add "X-Amz-Target", valid_612594
  var valid_612595 = header.getOrDefault("X-Amz-Signature")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Signature", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Content-Sha256", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Date")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Date", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Credential")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Credential", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Security-Token")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Security-Token", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-Algorithm")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-Algorithm", valid_612600
  var valid_612601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612601 = validateParameter(valid_612601, JString, required = false,
                                 default = nil)
  if valid_612601 != nil:
    section.add "X-Amz-SignedHeaders", valid_612601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612603: Call_ListHumanTaskUis_612589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_612603.validator(path, query, header, formData, body)
  let scheme = call_612603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612603.url(scheme.get, call_612603.host, call_612603.base,
                         call_612603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612603, url, valid)

proc call*(call_612604: Call_ListHumanTaskUis_612589; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612605 = newJObject()
  var body_612606 = newJObject()
  add(query_612605, "MaxResults", newJString(MaxResults))
  add(query_612605, "NextToken", newJString(NextToken))
  if body != nil:
    body_612606 = body
  result = call_612604.call(nil, query_612605, nil, nil, body_612606)

var listHumanTaskUis* = Call_ListHumanTaskUis_612589(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_612590, base: "/",
    url: url_ListHumanTaskUis_612591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_612607 = ref object of OpenApiRestCall_610658
proc url_ListHyperParameterTuningJobs_612609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHyperParameterTuningJobs_612608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612610 = query.getOrDefault("MaxResults")
  valid_612610 = validateParameter(valid_612610, JString, required = false,
                                 default = nil)
  if valid_612610 != nil:
    section.add "MaxResults", valid_612610
  var valid_612611 = query.getOrDefault("NextToken")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "NextToken", valid_612611
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
  var valid_612612 = header.getOrDefault("X-Amz-Target")
  valid_612612 = validateParameter(valid_612612, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_612612 != nil:
    section.add "X-Amz-Target", valid_612612
  var valid_612613 = header.getOrDefault("X-Amz-Signature")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "X-Amz-Signature", valid_612613
  var valid_612614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612614 = validateParameter(valid_612614, JString, required = false,
                                 default = nil)
  if valid_612614 != nil:
    section.add "X-Amz-Content-Sha256", valid_612614
  var valid_612615 = header.getOrDefault("X-Amz-Date")
  valid_612615 = validateParameter(valid_612615, JString, required = false,
                                 default = nil)
  if valid_612615 != nil:
    section.add "X-Amz-Date", valid_612615
  var valid_612616 = header.getOrDefault("X-Amz-Credential")
  valid_612616 = validateParameter(valid_612616, JString, required = false,
                                 default = nil)
  if valid_612616 != nil:
    section.add "X-Amz-Credential", valid_612616
  var valid_612617 = header.getOrDefault("X-Amz-Security-Token")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Security-Token", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Algorithm")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Algorithm", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-SignedHeaders", valid_612619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612621: Call_ListHyperParameterTuningJobs_612607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_612621.validator(path, query, header, formData, body)
  let scheme = call_612621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612621.url(scheme.get, call_612621.host, call_612621.base,
                         call_612621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612621, url, valid)

proc call*(call_612622: Call_ListHyperParameterTuningJobs_612607; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612623 = newJObject()
  var body_612624 = newJObject()
  add(query_612623, "MaxResults", newJString(MaxResults))
  add(query_612623, "NextToken", newJString(NextToken))
  if body != nil:
    body_612624 = body
  result = call_612622.call(nil, query_612623, nil, nil, body_612624)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_612607(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_612608, base: "/",
    url: url_ListHyperParameterTuningJobs_612609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_612625 = ref object of OpenApiRestCall_610658
proc url_ListLabelingJobs_612627(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobs_612626(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets a list of labeling jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612628 = query.getOrDefault("MaxResults")
  valid_612628 = validateParameter(valid_612628, JString, required = false,
                                 default = nil)
  if valid_612628 != nil:
    section.add "MaxResults", valid_612628
  var valid_612629 = query.getOrDefault("NextToken")
  valid_612629 = validateParameter(valid_612629, JString, required = false,
                                 default = nil)
  if valid_612629 != nil:
    section.add "NextToken", valid_612629
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
  var valid_612630 = header.getOrDefault("X-Amz-Target")
  valid_612630 = validateParameter(valid_612630, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_612630 != nil:
    section.add "X-Amz-Target", valid_612630
  var valid_612631 = header.getOrDefault("X-Amz-Signature")
  valid_612631 = validateParameter(valid_612631, JString, required = false,
                                 default = nil)
  if valid_612631 != nil:
    section.add "X-Amz-Signature", valid_612631
  var valid_612632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Content-Sha256", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Date")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Date", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Credential")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Credential", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Security-Token")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Security-Token", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Algorithm")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Algorithm", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-SignedHeaders", valid_612637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612639: Call_ListLabelingJobs_612625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_612639.validator(path, query, header, formData, body)
  let scheme = call_612639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612639.url(scheme.get, call_612639.host, call_612639.base,
                         call_612639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612639, url, valid)

proc call*(call_612640: Call_ListLabelingJobs_612625; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612641 = newJObject()
  var body_612642 = newJObject()
  add(query_612641, "MaxResults", newJString(MaxResults))
  add(query_612641, "NextToken", newJString(NextToken))
  if body != nil:
    body_612642 = body
  result = call_612640.call(nil, query_612641, nil, nil, body_612642)

var listLabelingJobs* = Call_ListLabelingJobs_612625(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_612626, base: "/",
    url: url_ListLabelingJobs_612627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_612643 = ref object of OpenApiRestCall_610658
proc url_ListLabelingJobsForWorkteam_612645(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobsForWorkteam_612644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612646 = query.getOrDefault("MaxResults")
  valid_612646 = validateParameter(valid_612646, JString, required = false,
                                 default = nil)
  if valid_612646 != nil:
    section.add "MaxResults", valid_612646
  var valid_612647 = query.getOrDefault("NextToken")
  valid_612647 = validateParameter(valid_612647, JString, required = false,
                                 default = nil)
  if valid_612647 != nil:
    section.add "NextToken", valid_612647
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
  var valid_612648 = header.getOrDefault("X-Amz-Target")
  valid_612648 = validateParameter(valid_612648, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_612648 != nil:
    section.add "X-Amz-Target", valid_612648
  var valid_612649 = header.getOrDefault("X-Amz-Signature")
  valid_612649 = validateParameter(valid_612649, JString, required = false,
                                 default = nil)
  if valid_612649 != nil:
    section.add "X-Amz-Signature", valid_612649
  var valid_612650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612650 = validateParameter(valid_612650, JString, required = false,
                                 default = nil)
  if valid_612650 != nil:
    section.add "X-Amz-Content-Sha256", valid_612650
  var valid_612651 = header.getOrDefault("X-Amz-Date")
  valid_612651 = validateParameter(valid_612651, JString, required = false,
                                 default = nil)
  if valid_612651 != nil:
    section.add "X-Amz-Date", valid_612651
  var valid_612652 = header.getOrDefault("X-Amz-Credential")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "X-Amz-Credential", valid_612652
  var valid_612653 = header.getOrDefault("X-Amz-Security-Token")
  valid_612653 = validateParameter(valid_612653, JString, required = false,
                                 default = nil)
  if valid_612653 != nil:
    section.add "X-Amz-Security-Token", valid_612653
  var valid_612654 = header.getOrDefault("X-Amz-Algorithm")
  valid_612654 = validateParameter(valid_612654, JString, required = false,
                                 default = nil)
  if valid_612654 != nil:
    section.add "X-Amz-Algorithm", valid_612654
  var valid_612655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "X-Amz-SignedHeaders", valid_612655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612657: Call_ListLabelingJobsForWorkteam_612643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_612657.validator(path, query, header, formData, body)
  let scheme = call_612657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612657.url(scheme.get, call_612657.host, call_612657.base,
                         call_612657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612657, url, valid)

proc call*(call_612658: Call_ListLabelingJobsForWorkteam_612643; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612659 = newJObject()
  var body_612660 = newJObject()
  add(query_612659, "MaxResults", newJString(MaxResults))
  add(query_612659, "NextToken", newJString(NextToken))
  if body != nil:
    body_612660 = body
  result = call_612658.call(nil, query_612659, nil, nil, body_612660)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_612643(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_612644, base: "/",
    url: url_ListLabelingJobsForWorkteam_612645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_612661 = ref object of OpenApiRestCall_610658
proc url_ListModelPackages_612663(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModelPackages_612662(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the model packages that have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612664 = query.getOrDefault("MaxResults")
  valid_612664 = validateParameter(valid_612664, JString, required = false,
                                 default = nil)
  if valid_612664 != nil:
    section.add "MaxResults", valid_612664
  var valid_612665 = query.getOrDefault("NextToken")
  valid_612665 = validateParameter(valid_612665, JString, required = false,
                                 default = nil)
  if valid_612665 != nil:
    section.add "NextToken", valid_612665
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
  var valid_612666 = header.getOrDefault("X-Amz-Target")
  valid_612666 = validateParameter(valid_612666, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_612666 != nil:
    section.add "X-Amz-Target", valid_612666
  var valid_612667 = header.getOrDefault("X-Amz-Signature")
  valid_612667 = validateParameter(valid_612667, JString, required = false,
                                 default = nil)
  if valid_612667 != nil:
    section.add "X-Amz-Signature", valid_612667
  var valid_612668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612668 = validateParameter(valid_612668, JString, required = false,
                                 default = nil)
  if valid_612668 != nil:
    section.add "X-Amz-Content-Sha256", valid_612668
  var valid_612669 = header.getOrDefault("X-Amz-Date")
  valid_612669 = validateParameter(valid_612669, JString, required = false,
                                 default = nil)
  if valid_612669 != nil:
    section.add "X-Amz-Date", valid_612669
  var valid_612670 = header.getOrDefault("X-Amz-Credential")
  valid_612670 = validateParameter(valid_612670, JString, required = false,
                                 default = nil)
  if valid_612670 != nil:
    section.add "X-Amz-Credential", valid_612670
  var valid_612671 = header.getOrDefault("X-Amz-Security-Token")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "X-Amz-Security-Token", valid_612671
  var valid_612672 = header.getOrDefault("X-Amz-Algorithm")
  valid_612672 = validateParameter(valid_612672, JString, required = false,
                                 default = nil)
  if valid_612672 != nil:
    section.add "X-Amz-Algorithm", valid_612672
  var valid_612673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-SignedHeaders", valid_612673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612675: Call_ListModelPackages_612661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_612675.validator(path, query, header, formData, body)
  let scheme = call_612675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612675.url(scheme.get, call_612675.host, call_612675.base,
                         call_612675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612675, url, valid)

proc call*(call_612676: Call_ListModelPackages_612661; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612677 = newJObject()
  var body_612678 = newJObject()
  add(query_612677, "MaxResults", newJString(MaxResults))
  add(query_612677, "NextToken", newJString(NextToken))
  if body != nil:
    body_612678 = body
  result = call_612676.call(nil, query_612677, nil, nil, body_612678)

var listModelPackages* = Call_ListModelPackages_612661(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_612662, base: "/",
    url: url_ListModelPackages_612663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_612679 = ref object of OpenApiRestCall_610658
proc url_ListModels_612681(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModels_612680(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612682 = query.getOrDefault("MaxResults")
  valid_612682 = validateParameter(valid_612682, JString, required = false,
                                 default = nil)
  if valid_612682 != nil:
    section.add "MaxResults", valid_612682
  var valid_612683 = query.getOrDefault("NextToken")
  valid_612683 = validateParameter(valid_612683, JString, required = false,
                                 default = nil)
  if valid_612683 != nil:
    section.add "NextToken", valid_612683
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
  var valid_612684 = header.getOrDefault("X-Amz-Target")
  valid_612684 = validateParameter(valid_612684, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_612684 != nil:
    section.add "X-Amz-Target", valid_612684
  var valid_612685 = header.getOrDefault("X-Amz-Signature")
  valid_612685 = validateParameter(valid_612685, JString, required = false,
                                 default = nil)
  if valid_612685 != nil:
    section.add "X-Amz-Signature", valid_612685
  var valid_612686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612686 = validateParameter(valid_612686, JString, required = false,
                                 default = nil)
  if valid_612686 != nil:
    section.add "X-Amz-Content-Sha256", valid_612686
  var valid_612687 = header.getOrDefault("X-Amz-Date")
  valid_612687 = validateParameter(valid_612687, JString, required = false,
                                 default = nil)
  if valid_612687 != nil:
    section.add "X-Amz-Date", valid_612687
  var valid_612688 = header.getOrDefault("X-Amz-Credential")
  valid_612688 = validateParameter(valid_612688, JString, required = false,
                                 default = nil)
  if valid_612688 != nil:
    section.add "X-Amz-Credential", valid_612688
  var valid_612689 = header.getOrDefault("X-Amz-Security-Token")
  valid_612689 = validateParameter(valid_612689, JString, required = false,
                                 default = nil)
  if valid_612689 != nil:
    section.add "X-Amz-Security-Token", valid_612689
  var valid_612690 = header.getOrDefault("X-Amz-Algorithm")
  valid_612690 = validateParameter(valid_612690, JString, required = false,
                                 default = nil)
  if valid_612690 != nil:
    section.add "X-Amz-Algorithm", valid_612690
  var valid_612691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "X-Amz-SignedHeaders", valid_612691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612693: Call_ListModels_612679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_612693.validator(path, query, header, formData, body)
  let scheme = call_612693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612693.url(scheme.get, call_612693.host, call_612693.base,
                         call_612693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612693, url, valid)

proc call*(call_612694: Call_ListModels_612679; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612695 = newJObject()
  var body_612696 = newJObject()
  add(query_612695, "MaxResults", newJString(MaxResults))
  add(query_612695, "NextToken", newJString(NextToken))
  if body != nil:
    body_612696 = body
  result = call_612694.call(nil, query_612695, nil, nil, body_612696)

var listModels* = Call_ListModels_612679(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_612680,
                                      base: "/", url: url_ListModels_612681,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_612697 = ref object of OpenApiRestCall_610658
proc url_ListMonitoringExecutions_612699(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringExecutions_612698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns list of all monitoring job executions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612700 = query.getOrDefault("MaxResults")
  valid_612700 = validateParameter(valid_612700, JString, required = false,
                                 default = nil)
  if valid_612700 != nil:
    section.add "MaxResults", valid_612700
  var valid_612701 = query.getOrDefault("NextToken")
  valid_612701 = validateParameter(valid_612701, JString, required = false,
                                 default = nil)
  if valid_612701 != nil:
    section.add "NextToken", valid_612701
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
  var valid_612702 = header.getOrDefault("X-Amz-Target")
  valid_612702 = validateParameter(valid_612702, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_612702 != nil:
    section.add "X-Amz-Target", valid_612702
  var valid_612703 = header.getOrDefault("X-Amz-Signature")
  valid_612703 = validateParameter(valid_612703, JString, required = false,
                                 default = nil)
  if valid_612703 != nil:
    section.add "X-Amz-Signature", valid_612703
  var valid_612704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612704 = validateParameter(valid_612704, JString, required = false,
                                 default = nil)
  if valid_612704 != nil:
    section.add "X-Amz-Content-Sha256", valid_612704
  var valid_612705 = header.getOrDefault("X-Amz-Date")
  valid_612705 = validateParameter(valid_612705, JString, required = false,
                                 default = nil)
  if valid_612705 != nil:
    section.add "X-Amz-Date", valid_612705
  var valid_612706 = header.getOrDefault("X-Amz-Credential")
  valid_612706 = validateParameter(valid_612706, JString, required = false,
                                 default = nil)
  if valid_612706 != nil:
    section.add "X-Amz-Credential", valid_612706
  var valid_612707 = header.getOrDefault("X-Amz-Security-Token")
  valid_612707 = validateParameter(valid_612707, JString, required = false,
                                 default = nil)
  if valid_612707 != nil:
    section.add "X-Amz-Security-Token", valid_612707
  var valid_612708 = header.getOrDefault("X-Amz-Algorithm")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Algorithm", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-SignedHeaders", valid_612709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612711: Call_ListMonitoringExecutions_612697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_612711.validator(path, query, header, formData, body)
  let scheme = call_612711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612711.url(scheme.get, call_612711.host, call_612711.base,
                         call_612711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612711, url, valid)

proc call*(call_612712: Call_ListMonitoringExecutions_612697; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612713 = newJObject()
  var body_612714 = newJObject()
  add(query_612713, "MaxResults", newJString(MaxResults))
  add(query_612713, "NextToken", newJString(NextToken))
  if body != nil:
    body_612714 = body
  result = call_612712.call(nil, query_612713, nil, nil, body_612714)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_612697(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_612698, base: "/",
    url: url_ListMonitoringExecutions_612699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_612715 = ref object of OpenApiRestCall_610658
proc url_ListMonitoringSchedules_612717(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringSchedules_612716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns list of all monitoring schedules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612718 = query.getOrDefault("MaxResults")
  valid_612718 = validateParameter(valid_612718, JString, required = false,
                                 default = nil)
  if valid_612718 != nil:
    section.add "MaxResults", valid_612718
  var valid_612719 = query.getOrDefault("NextToken")
  valid_612719 = validateParameter(valid_612719, JString, required = false,
                                 default = nil)
  if valid_612719 != nil:
    section.add "NextToken", valid_612719
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
  var valid_612720 = header.getOrDefault("X-Amz-Target")
  valid_612720 = validateParameter(valid_612720, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_612720 != nil:
    section.add "X-Amz-Target", valid_612720
  var valid_612721 = header.getOrDefault("X-Amz-Signature")
  valid_612721 = validateParameter(valid_612721, JString, required = false,
                                 default = nil)
  if valid_612721 != nil:
    section.add "X-Amz-Signature", valid_612721
  var valid_612722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612722 = validateParameter(valid_612722, JString, required = false,
                                 default = nil)
  if valid_612722 != nil:
    section.add "X-Amz-Content-Sha256", valid_612722
  var valid_612723 = header.getOrDefault("X-Amz-Date")
  valid_612723 = validateParameter(valid_612723, JString, required = false,
                                 default = nil)
  if valid_612723 != nil:
    section.add "X-Amz-Date", valid_612723
  var valid_612724 = header.getOrDefault("X-Amz-Credential")
  valid_612724 = validateParameter(valid_612724, JString, required = false,
                                 default = nil)
  if valid_612724 != nil:
    section.add "X-Amz-Credential", valid_612724
  var valid_612725 = header.getOrDefault("X-Amz-Security-Token")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "X-Amz-Security-Token", valid_612725
  var valid_612726 = header.getOrDefault("X-Amz-Algorithm")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "X-Amz-Algorithm", valid_612726
  var valid_612727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612727 = validateParameter(valid_612727, JString, required = false,
                                 default = nil)
  if valid_612727 != nil:
    section.add "X-Amz-SignedHeaders", valid_612727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612729: Call_ListMonitoringSchedules_612715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_612729.validator(path, query, header, formData, body)
  let scheme = call_612729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612729.url(scheme.get, call_612729.host, call_612729.base,
                         call_612729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612729, url, valid)

proc call*(call_612730: Call_ListMonitoringSchedules_612715; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612731 = newJObject()
  var body_612732 = newJObject()
  add(query_612731, "MaxResults", newJString(MaxResults))
  add(query_612731, "NextToken", newJString(NextToken))
  if body != nil:
    body_612732 = body
  result = call_612730.call(nil, query_612731, nil, nil, body_612732)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_612715(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_612716, base: "/",
    url: url_ListMonitoringSchedules_612717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_612733 = ref object of OpenApiRestCall_610658
proc url_ListNotebookInstanceLifecycleConfigs_612735(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_612734(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612736 = query.getOrDefault("MaxResults")
  valid_612736 = validateParameter(valid_612736, JString, required = false,
                                 default = nil)
  if valid_612736 != nil:
    section.add "MaxResults", valid_612736
  var valid_612737 = query.getOrDefault("NextToken")
  valid_612737 = validateParameter(valid_612737, JString, required = false,
                                 default = nil)
  if valid_612737 != nil:
    section.add "NextToken", valid_612737
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
  var valid_612738 = header.getOrDefault("X-Amz-Target")
  valid_612738 = validateParameter(valid_612738, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_612738 != nil:
    section.add "X-Amz-Target", valid_612738
  var valid_612739 = header.getOrDefault("X-Amz-Signature")
  valid_612739 = validateParameter(valid_612739, JString, required = false,
                                 default = nil)
  if valid_612739 != nil:
    section.add "X-Amz-Signature", valid_612739
  var valid_612740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612740 = validateParameter(valid_612740, JString, required = false,
                                 default = nil)
  if valid_612740 != nil:
    section.add "X-Amz-Content-Sha256", valid_612740
  var valid_612741 = header.getOrDefault("X-Amz-Date")
  valid_612741 = validateParameter(valid_612741, JString, required = false,
                                 default = nil)
  if valid_612741 != nil:
    section.add "X-Amz-Date", valid_612741
  var valid_612742 = header.getOrDefault("X-Amz-Credential")
  valid_612742 = validateParameter(valid_612742, JString, required = false,
                                 default = nil)
  if valid_612742 != nil:
    section.add "X-Amz-Credential", valid_612742
  var valid_612743 = header.getOrDefault("X-Amz-Security-Token")
  valid_612743 = validateParameter(valid_612743, JString, required = false,
                                 default = nil)
  if valid_612743 != nil:
    section.add "X-Amz-Security-Token", valid_612743
  var valid_612744 = header.getOrDefault("X-Amz-Algorithm")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Algorithm", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-SignedHeaders", valid_612745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612747: Call_ListNotebookInstanceLifecycleConfigs_612733;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_612747.validator(path, query, header, formData, body)
  let scheme = call_612747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612747.url(scheme.get, call_612747.host, call_612747.base,
                         call_612747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612747, url, valid)

proc call*(call_612748: Call_ListNotebookInstanceLifecycleConfigs_612733;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612749 = newJObject()
  var body_612750 = newJObject()
  add(query_612749, "MaxResults", newJString(MaxResults))
  add(query_612749, "NextToken", newJString(NextToken))
  if body != nil:
    body_612750 = body
  result = call_612748.call(nil, query_612749, nil, nil, body_612750)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_612733(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_612734, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_612735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_612751 = ref object of OpenApiRestCall_610658
proc url_ListNotebookInstances_612753(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstances_612752(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612754 = query.getOrDefault("MaxResults")
  valid_612754 = validateParameter(valid_612754, JString, required = false,
                                 default = nil)
  if valid_612754 != nil:
    section.add "MaxResults", valid_612754
  var valid_612755 = query.getOrDefault("NextToken")
  valid_612755 = validateParameter(valid_612755, JString, required = false,
                                 default = nil)
  if valid_612755 != nil:
    section.add "NextToken", valid_612755
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
  var valid_612756 = header.getOrDefault("X-Amz-Target")
  valid_612756 = validateParameter(valid_612756, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_612756 != nil:
    section.add "X-Amz-Target", valid_612756
  var valid_612757 = header.getOrDefault("X-Amz-Signature")
  valid_612757 = validateParameter(valid_612757, JString, required = false,
                                 default = nil)
  if valid_612757 != nil:
    section.add "X-Amz-Signature", valid_612757
  var valid_612758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612758 = validateParameter(valid_612758, JString, required = false,
                                 default = nil)
  if valid_612758 != nil:
    section.add "X-Amz-Content-Sha256", valid_612758
  var valid_612759 = header.getOrDefault("X-Amz-Date")
  valid_612759 = validateParameter(valid_612759, JString, required = false,
                                 default = nil)
  if valid_612759 != nil:
    section.add "X-Amz-Date", valid_612759
  var valid_612760 = header.getOrDefault("X-Amz-Credential")
  valid_612760 = validateParameter(valid_612760, JString, required = false,
                                 default = nil)
  if valid_612760 != nil:
    section.add "X-Amz-Credential", valid_612760
  var valid_612761 = header.getOrDefault("X-Amz-Security-Token")
  valid_612761 = validateParameter(valid_612761, JString, required = false,
                                 default = nil)
  if valid_612761 != nil:
    section.add "X-Amz-Security-Token", valid_612761
  var valid_612762 = header.getOrDefault("X-Amz-Algorithm")
  valid_612762 = validateParameter(valid_612762, JString, required = false,
                                 default = nil)
  if valid_612762 != nil:
    section.add "X-Amz-Algorithm", valid_612762
  var valid_612763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612763 = validateParameter(valid_612763, JString, required = false,
                                 default = nil)
  if valid_612763 != nil:
    section.add "X-Amz-SignedHeaders", valid_612763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612765: Call_ListNotebookInstances_612751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_612765.validator(path, query, header, formData, body)
  let scheme = call_612765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612765.url(scheme.get, call_612765.host, call_612765.base,
                         call_612765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612765, url, valid)

proc call*(call_612766: Call_ListNotebookInstances_612751; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612767 = newJObject()
  var body_612768 = newJObject()
  add(query_612767, "MaxResults", newJString(MaxResults))
  add(query_612767, "NextToken", newJString(NextToken))
  if body != nil:
    body_612768 = body
  result = call_612766.call(nil, query_612767, nil, nil, body_612768)

var listNotebookInstances* = Call_ListNotebookInstances_612751(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_612752, base: "/",
    url: url_ListNotebookInstances_612753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_612769 = ref object of OpenApiRestCall_610658
proc url_ListProcessingJobs_612771(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProcessingJobs_612770(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists processing jobs that satisfy various filters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612772 = query.getOrDefault("MaxResults")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "MaxResults", valid_612772
  var valid_612773 = query.getOrDefault("NextToken")
  valid_612773 = validateParameter(valid_612773, JString, required = false,
                                 default = nil)
  if valid_612773 != nil:
    section.add "NextToken", valid_612773
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
  var valid_612774 = header.getOrDefault("X-Amz-Target")
  valid_612774 = validateParameter(valid_612774, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_612774 != nil:
    section.add "X-Amz-Target", valid_612774
  var valid_612775 = header.getOrDefault("X-Amz-Signature")
  valid_612775 = validateParameter(valid_612775, JString, required = false,
                                 default = nil)
  if valid_612775 != nil:
    section.add "X-Amz-Signature", valid_612775
  var valid_612776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612776 = validateParameter(valid_612776, JString, required = false,
                                 default = nil)
  if valid_612776 != nil:
    section.add "X-Amz-Content-Sha256", valid_612776
  var valid_612777 = header.getOrDefault("X-Amz-Date")
  valid_612777 = validateParameter(valid_612777, JString, required = false,
                                 default = nil)
  if valid_612777 != nil:
    section.add "X-Amz-Date", valid_612777
  var valid_612778 = header.getOrDefault("X-Amz-Credential")
  valid_612778 = validateParameter(valid_612778, JString, required = false,
                                 default = nil)
  if valid_612778 != nil:
    section.add "X-Amz-Credential", valid_612778
  var valid_612779 = header.getOrDefault("X-Amz-Security-Token")
  valid_612779 = validateParameter(valid_612779, JString, required = false,
                                 default = nil)
  if valid_612779 != nil:
    section.add "X-Amz-Security-Token", valid_612779
  var valid_612780 = header.getOrDefault("X-Amz-Algorithm")
  valid_612780 = validateParameter(valid_612780, JString, required = false,
                                 default = nil)
  if valid_612780 != nil:
    section.add "X-Amz-Algorithm", valid_612780
  var valid_612781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-SignedHeaders", valid_612781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612783: Call_ListProcessingJobs_612769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_612783.validator(path, query, header, formData, body)
  let scheme = call_612783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612783.url(scheme.get, call_612783.host, call_612783.base,
                         call_612783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612783, url, valid)

proc call*(call_612784: Call_ListProcessingJobs_612769; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612785 = newJObject()
  var body_612786 = newJObject()
  add(query_612785, "MaxResults", newJString(MaxResults))
  add(query_612785, "NextToken", newJString(NextToken))
  if body != nil:
    body_612786 = body
  result = call_612784.call(nil, query_612785, nil, nil, body_612786)

var listProcessingJobs* = Call_ListProcessingJobs_612769(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_612770, base: "/",
    url: url_ListProcessingJobs_612771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_612787 = ref object of OpenApiRestCall_610658
proc url_ListSubscribedWorkteams_612789(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscribedWorkteams_612788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612790 = query.getOrDefault("MaxResults")
  valid_612790 = validateParameter(valid_612790, JString, required = false,
                                 default = nil)
  if valid_612790 != nil:
    section.add "MaxResults", valid_612790
  var valid_612791 = query.getOrDefault("NextToken")
  valid_612791 = validateParameter(valid_612791, JString, required = false,
                                 default = nil)
  if valid_612791 != nil:
    section.add "NextToken", valid_612791
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
  var valid_612792 = header.getOrDefault("X-Amz-Target")
  valid_612792 = validateParameter(valid_612792, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_612792 != nil:
    section.add "X-Amz-Target", valid_612792
  var valid_612793 = header.getOrDefault("X-Amz-Signature")
  valid_612793 = validateParameter(valid_612793, JString, required = false,
                                 default = nil)
  if valid_612793 != nil:
    section.add "X-Amz-Signature", valid_612793
  var valid_612794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612794 = validateParameter(valid_612794, JString, required = false,
                                 default = nil)
  if valid_612794 != nil:
    section.add "X-Amz-Content-Sha256", valid_612794
  var valid_612795 = header.getOrDefault("X-Amz-Date")
  valid_612795 = validateParameter(valid_612795, JString, required = false,
                                 default = nil)
  if valid_612795 != nil:
    section.add "X-Amz-Date", valid_612795
  var valid_612796 = header.getOrDefault("X-Amz-Credential")
  valid_612796 = validateParameter(valid_612796, JString, required = false,
                                 default = nil)
  if valid_612796 != nil:
    section.add "X-Amz-Credential", valid_612796
  var valid_612797 = header.getOrDefault("X-Amz-Security-Token")
  valid_612797 = validateParameter(valid_612797, JString, required = false,
                                 default = nil)
  if valid_612797 != nil:
    section.add "X-Amz-Security-Token", valid_612797
  var valid_612798 = header.getOrDefault("X-Amz-Algorithm")
  valid_612798 = validateParameter(valid_612798, JString, required = false,
                                 default = nil)
  if valid_612798 != nil:
    section.add "X-Amz-Algorithm", valid_612798
  var valid_612799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612799 = validateParameter(valid_612799, JString, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "X-Amz-SignedHeaders", valid_612799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612801: Call_ListSubscribedWorkteams_612787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_612801.validator(path, query, header, formData, body)
  let scheme = call_612801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612801.url(scheme.get, call_612801.host, call_612801.base,
                         call_612801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612801, url, valid)

proc call*(call_612802: Call_ListSubscribedWorkteams_612787; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612803 = newJObject()
  var body_612804 = newJObject()
  add(query_612803, "MaxResults", newJString(MaxResults))
  add(query_612803, "NextToken", newJString(NextToken))
  if body != nil:
    body_612804 = body
  result = call_612802.call(nil, query_612803, nil, nil, body_612804)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_612787(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_612788, base: "/",
    url: url_ListSubscribedWorkteams_612789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_612805 = ref object of OpenApiRestCall_610658
proc url_ListTags_612807(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_612806(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612808 = query.getOrDefault("MaxResults")
  valid_612808 = validateParameter(valid_612808, JString, required = false,
                                 default = nil)
  if valid_612808 != nil:
    section.add "MaxResults", valid_612808
  var valid_612809 = query.getOrDefault("NextToken")
  valid_612809 = validateParameter(valid_612809, JString, required = false,
                                 default = nil)
  if valid_612809 != nil:
    section.add "NextToken", valid_612809
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
  var valid_612810 = header.getOrDefault("X-Amz-Target")
  valid_612810 = validateParameter(valid_612810, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_612810 != nil:
    section.add "X-Amz-Target", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-Signature")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-Signature", valid_612811
  var valid_612812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612812 = validateParameter(valid_612812, JString, required = false,
                                 default = nil)
  if valid_612812 != nil:
    section.add "X-Amz-Content-Sha256", valid_612812
  var valid_612813 = header.getOrDefault("X-Amz-Date")
  valid_612813 = validateParameter(valid_612813, JString, required = false,
                                 default = nil)
  if valid_612813 != nil:
    section.add "X-Amz-Date", valid_612813
  var valid_612814 = header.getOrDefault("X-Amz-Credential")
  valid_612814 = validateParameter(valid_612814, JString, required = false,
                                 default = nil)
  if valid_612814 != nil:
    section.add "X-Amz-Credential", valid_612814
  var valid_612815 = header.getOrDefault("X-Amz-Security-Token")
  valid_612815 = validateParameter(valid_612815, JString, required = false,
                                 default = nil)
  if valid_612815 != nil:
    section.add "X-Amz-Security-Token", valid_612815
  var valid_612816 = header.getOrDefault("X-Amz-Algorithm")
  valid_612816 = validateParameter(valid_612816, JString, required = false,
                                 default = nil)
  if valid_612816 != nil:
    section.add "X-Amz-Algorithm", valid_612816
  var valid_612817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612817 = validateParameter(valid_612817, JString, required = false,
                                 default = nil)
  if valid_612817 != nil:
    section.add "X-Amz-SignedHeaders", valid_612817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612819: Call_ListTags_612805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_612819.validator(path, query, header, formData, body)
  let scheme = call_612819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612819.url(scheme.get, call_612819.host, call_612819.base,
                         call_612819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612819, url, valid)

proc call*(call_612820: Call_ListTags_612805; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612821 = newJObject()
  var body_612822 = newJObject()
  add(query_612821, "MaxResults", newJString(MaxResults))
  add(query_612821, "NextToken", newJString(NextToken))
  if body != nil:
    body_612822 = body
  result = call_612820.call(nil, query_612821, nil, nil, body_612822)

var listTags* = Call_ListTags_612805(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_612806, base: "/",
                                  url: url_ListTags_612807,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_612823 = ref object of OpenApiRestCall_610658
proc url_ListTrainingJobs_612825(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobs_612824(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists training jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612826 = query.getOrDefault("MaxResults")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "MaxResults", valid_612826
  var valid_612827 = query.getOrDefault("NextToken")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "NextToken", valid_612827
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
  var valid_612828 = header.getOrDefault("X-Amz-Target")
  valid_612828 = validateParameter(valid_612828, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_612828 != nil:
    section.add "X-Amz-Target", valid_612828
  var valid_612829 = header.getOrDefault("X-Amz-Signature")
  valid_612829 = validateParameter(valid_612829, JString, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "X-Amz-Signature", valid_612829
  var valid_612830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612830 = validateParameter(valid_612830, JString, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "X-Amz-Content-Sha256", valid_612830
  var valid_612831 = header.getOrDefault("X-Amz-Date")
  valid_612831 = validateParameter(valid_612831, JString, required = false,
                                 default = nil)
  if valid_612831 != nil:
    section.add "X-Amz-Date", valid_612831
  var valid_612832 = header.getOrDefault("X-Amz-Credential")
  valid_612832 = validateParameter(valid_612832, JString, required = false,
                                 default = nil)
  if valid_612832 != nil:
    section.add "X-Amz-Credential", valid_612832
  var valid_612833 = header.getOrDefault("X-Amz-Security-Token")
  valid_612833 = validateParameter(valid_612833, JString, required = false,
                                 default = nil)
  if valid_612833 != nil:
    section.add "X-Amz-Security-Token", valid_612833
  var valid_612834 = header.getOrDefault("X-Amz-Algorithm")
  valid_612834 = validateParameter(valid_612834, JString, required = false,
                                 default = nil)
  if valid_612834 != nil:
    section.add "X-Amz-Algorithm", valid_612834
  var valid_612835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612835 = validateParameter(valid_612835, JString, required = false,
                                 default = nil)
  if valid_612835 != nil:
    section.add "X-Amz-SignedHeaders", valid_612835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612837: Call_ListTrainingJobs_612823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_612837.validator(path, query, header, formData, body)
  let scheme = call_612837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612837.url(scheme.get, call_612837.host, call_612837.base,
                         call_612837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612837, url, valid)

proc call*(call_612838: Call_ListTrainingJobs_612823; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612839 = newJObject()
  var body_612840 = newJObject()
  add(query_612839, "MaxResults", newJString(MaxResults))
  add(query_612839, "NextToken", newJString(NextToken))
  if body != nil:
    body_612840 = body
  result = call_612838.call(nil, query_612839, nil, nil, body_612840)

var listTrainingJobs* = Call_ListTrainingJobs_612823(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_612824, base: "/",
    url: url_ListTrainingJobs_612825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_612841 = ref object of OpenApiRestCall_610658
proc url_ListTrainingJobsForHyperParameterTuningJob_612843(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_612842(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612844 = query.getOrDefault("MaxResults")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "MaxResults", valid_612844
  var valid_612845 = query.getOrDefault("NextToken")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "NextToken", valid_612845
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
  var valid_612846 = header.getOrDefault("X-Amz-Target")
  valid_612846 = validateParameter(valid_612846, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_612846 != nil:
    section.add "X-Amz-Target", valid_612846
  var valid_612847 = header.getOrDefault("X-Amz-Signature")
  valid_612847 = validateParameter(valid_612847, JString, required = false,
                                 default = nil)
  if valid_612847 != nil:
    section.add "X-Amz-Signature", valid_612847
  var valid_612848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "X-Amz-Content-Sha256", valid_612848
  var valid_612849 = header.getOrDefault("X-Amz-Date")
  valid_612849 = validateParameter(valid_612849, JString, required = false,
                                 default = nil)
  if valid_612849 != nil:
    section.add "X-Amz-Date", valid_612849
  var valid_612850 = header.getOrDefault("X-Amz-Credential")
  valid_612850 = validateParameter(valid_612850, JString, required = false,
                                 default = nil)
  if valid_612850 != nil:
    section.add "X-Amz-Credential", valid_612850
  var valid_612851 = header.getOrDefault("X-Amz-Security-Token")
  valid_612851 = validateParameter(valid_612851, JString, required = false,
                                 default = nil)
  if valid_612851 != nil:
    section.add "X-Amz-Security-Token", valid_612851
  var valid_612852 = header.getOrDefault("X-Amz-Algorithm")
  valid_612852 = validateParameter(valid_612852, JString, required = false,
                                 default = nil)
  if valid_612852 != nil:
    section.add "X-Amz-Algorithm", valid_612852
  var valid_612853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612853 = validateParameter(valid_612853, JString, required = false,
                                 default = nil)
  if valid_612853 != nil:
    section.add "X-Amz-SignedHeaders", valid_612853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612855: Call_ListTrainingJobsForHyperParameterTuningJob_612841;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_612855.validator(path, query, header, formData, body)
  let scheme = call_612855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612855.url(scheme.get, call_612855.host, call_612855.base,
                         call_612855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612855, url, valid)

proc call*(call_612856: Call_ListTrainingJobsForHyperParameterTuningJob_612841;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612857 = newJObject()
  var body_612858 = newJObject()
  add(query_612857, "MaxResults", newJString(MaxResults))
  add(query_612857, "NextToken", newJString(NextToken))
  if body != nil:
    body_612858 = body
  result = call_612856.call(nil, query_612857, nil, nil, body_612858)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_612841(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_612842,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_612843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_612859 = ref object of OpenApiRestCall_610658
proc url_ListTransformJobs_612861(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTransformJobs_612860(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists transform jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612862 = query.getOrDefault("MaxResults")
  valid_612862 = validateParameter(valid_612862, JString, required = false,
                                 default = nil)
  if valid_612862 != nil:
    section.add "MaxResults", valid_612862
  var valid_612863 = query.getOrDefault("NextToken")
  valid_612863 = validateParameter(valid_612863, JString, required = false,
                                 default = nil)
  if valid_612863 != nil:
    section.add "NextToken", valid_612863
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
  var valid_612864 = header.getOrDefault("X-Amz-Target")
  valid_612864 = validateParameter(valid_612864, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_612864 != nil:
    section.add "X-Amz-Target", valid_612864
  var valid_612865 = header.getOrDefault("X-Amz-Signature")
  valid_612865 = validateParameter(valid_612865, JString, required = false,
                                 default = nil)
  if valid_612865 != nil:
    section.add "X-Amz-Signature", valid_612865
  var valid_612866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612866 = validateParameter(valid_612866, JString, required = false,
                                 default = nil)
  if valid_612866 != nil:
    section.add "X-Amz-Content-Sha256", valid_612866
  var valid_612867 = header.getOrDefault("X-Amz-Date")
  valid_612867 = validateParameter(valid_612867, JString, required = false,
                                 default = nil)
  if valid_612867 != nil:
    section.add "X-Amz-Date", valid_612867
  var valid_612868 = header.getOrDefault("X-Amz-Credential")
  valid_612868 = validateParameter(valid_612868, JString, required = false,
                                 default = nil)
  if valid_612868 != nil:
    section.add "X-Amz-Credential", valid_612868
  var valid_612869 = header.getOrDefault("X-Amz-Security-Token")
  valid_612869 = validateParameter(valid_612869, JString, required = false,
                                 default = nil)
  if valid_612869 != nil:
    section.add "X-Amz-Security-Token", valid_612869
  var valid_612870 = header.getOrDefault("X-Amz-Algorithm")
  valid_612870 = validateParameter(valid_612870, JString, required = false,
                                 default = nil)
  if valid_612870 != nil:
    section.add "X-Amz-Algorithm", valid_612870
  var valid_612871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612871 = validateParameter(valid_612871, JString, required = false,
                                 default = nil)
  if valid_612871 != nil:
    section.add "X-Amz-SignedHeaders", valid_612871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612873: Call_ListTransformJobs_612859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_612873.validator(path, query, header, formData, body)
  let scheme = call_612873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612873.url(scheme.get, call_612873.host, call_612873.base,
                         call_612873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612873, url, valid)

proc call*(call_612874: Call_ListTransformJobs_612859; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612875 = newJObject()
  var body_612876 = newJObject()
  add(query_612875, "MaxResults", newJString(MaxResults))
  add(query_612875, "NextToken", newJString(NextToken))
  if body != nil:
    body_612876 = body
  result = call_612874.call(nil, query_612875, nil, nil, body_612876)

var listTransformJobs* = Call_ListTransformJobs_612859(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_612860, base: "/",
    url: url_ListTransformJobs_612861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_612877 = ref object of OpenApiRestCall_610658
proc url_ListTrialComponents_612879(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrialComponents_612878(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612880 = query.getOrDefault("MaxResults")
  valid_612880 = validateParameter(valid_612880, JString, required = false,
                                 default = nil)
  if valid_612880 != nil:
    section.add "MaxResults", valid_612880
  var valid_612881 = query.getOrDefault("NextToken")
  valid_612881 = validateParameter(valid_612881, JString, required = false,
                                 default = nil)
  if valid_612881 != nil:
    section.add "NextToken", valid_612881
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
  var valid_612882 = header.getOrDefault("X-Amz-Target")
  valid_612882 = validateParameter(valid_612882, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_612882 != nil:
    section.add "X-Amz-Target", valid_612882
  var valid_612883 = header.getOrDefault("X-Amz-Signature")
  valid_612883 = validateParameter(valid_612883, JString, required = false,
                                 default = nil)
  if valid_612883 != nil:
    section.add "X-Amz-Signature", valid_612883
  var valid_612884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "X-Amz-Content-Sha256", valid_612884
  var valid_612885 = header.getOrDefault("X-Amz-Date")
  valid_612885 = validateParameter(valid_612885, JString, required = false,
                                 default = nil)
  if valid_612885 != nil:
    section.add "X-Amz-Date", valid_612885
  var valid_612886 = header.getOrDefault("X-Amz-Credential")
  valid_612886 = validateParameter(valid_612886, JString, required = false,
                                 default = nil)
  if valid_612886 != nil:
    section.add "X-Amz-Credential", valid_612886
  var valid_612887 = header.getOrDefault("X-Amz-Security-Token")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "X-Amz-Security-Token", valid_612887
  var valid_612888 = header.getOrDefault("X-Amz-Algorithm")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "X-Amz-Algorithm", valid_612888
  var valid_612889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "X-Amz-SignedHeaders", valid_612889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612891: Call_ListTrialComponents_612877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ## 
  let valid = call_612891.validator(path, query, header, formData, body)
  let scheme = call_612891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612891.url(scheme.get, call_612891.host, call_612891.base,
                         call_612891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612891, url, valid)

proc call*(call_612892: Call_ListTrialComponents_612877; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612893 = newJObject()
  var body_612894 = newJObject()
  add(query_612893, "MaxResults", newJString(MaxResults))
  add(query_612893, "NextToken", newJString(NextToken))
  if body != nil:
    body_612894 = body
  result = call_612892.call(nil, query_612893, nil, nil, body_612894)

var listTrialComponents* = Call_ListTrialComponents_612877(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_612878, base: "/",
    url: url_ListTrialComponents_612879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_612895 = ref object of OpenApiRestCall_610658
proc url_ListTrials_612897(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrials_612896(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612898 = query.getOrDefault("MaxResults")
  valid_612898 = validateParameter(valid_612898, JString, required = false,
                                 default = nil)
  if valid_612898 != nil:
    section.add "MaxResults", valid_612898
  var valid_612899 = query.getOrDefault("NextToken")
  valid_612899 = validateParameter(valid_612899, JString, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "NextToken", valid_612899
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
  var valid_612900 = header.getOrDefault("X-Amz-Target")
  valid_612900 = validateParameter(valid_612900, JString, required = true,
                                 default = newJString("SageMaker.ListTrials"))
  if valid_612900 != nil:
    section.add "X-Amz-Target", valid_612900
  var valid_612901 = header.getOrDefault("X-Amz-Signature")
  valid_612901 = validateParameter(valid_612901, JString, required = false,
                                 default = nil)
  if valid_612901 != nil:
    section.add "X-Amz-Signature", valid_612901
  var valid_612902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612902 = validateParameter(valid_612902, JString, required = false,
                                 default = nil)
  if valid_612902 != nil:
    section.add "X-Amz-Content-Sha256", valid_612902
  var valid_612903 = header.getOrDefault("X-Amz-Date")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Date", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Credential")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Credential", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Security-Token")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Security-Token", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Algorithm")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Algorithm", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-SignedHeaders", valid_612907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612909: Call_ListTrials_612895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_612909.validator(path, query, header, formData, body)
  let scheme = call_612909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612909.url(scheme.get, call_612909.host, call_612909.base,
                         call_612909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612909, url, valid)

proc call*(call_612910: Call_ListTrials_612895; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612911 = newJObject()
  var body_612912 = newJObject()
  add(query_612911, "MaxResults", newJString(MaxResults))
  add(query_612911, "NextToken", newJString(NextToken))
  if body != nil:
    body_612912 = body
  result = call_612910.call(nil, query_612911, nil, nil, body_612912)

var listTrials* = Call_ListTrials_612895(name: "listTrials",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                      validator: validate_ListTrials_612896,
                                      base: "/", url: url_ListTrials_612897,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_612913 = ref object of OpenApiRestCall_610658
proc url_ListUserProfiles_612915(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserProfiles_612914(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists user profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612916 = query.getOrDefault("MaxResults")
  valid_612916 = validateParameter(valid_612916, JString, required = false,
                                 default = nil)
  if valid_612916 != nil:
    section.add "MaxResults", valid_612916
  var valid_612917 = query.getOrDefault("NextToken")
  valid_612917 = validateParameter(valid_612917, JString, required = false,
                                 default = nil)
  if valid_612917 != nil:
    section.add "NextToken", valid_612917
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
  var valid_612918 = header.getOrDefault("X-Amz-Target")
  valid_612918 = validateParameter(valid_612918, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_612918 != nil:
    section.add "X-Amz-Target", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Signature")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Signature", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Content-Sha256", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-Date")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Date", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-Credential")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-Credential", valid_612922
  var valid_612923 = header.getOrDefault("X-Amz-Security-Token")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "X-Amz-Security-Token", valid_612923
  var valid_612924 = header.getOrDefault("X-Amz-Algorithm")
  valid_612924 = validateParameter(valid_612924, JString, required = false,
                                 default = nil)
  if valid_612924 != nil:
    section.add "X-Amz-Algorithm", valid_612924
  var valid_612925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612925 = validateParameter(valid_612925, JString, required = false,
                                 default = nil)
  if valid_612925 != nil:
    section.add "X-Amz-SignedHeaders", valid_612925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612927: Call_ListUserProfiles_612913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_612927.validator(path, query, header, formData, body)
  let scheme = call_612927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612927.url(scheme.get, call_612927.host, call_612927.base,
                         call_612927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612927, url, valid)

proc call*(call_612928: Call_ListUserProfiles_612913; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612929 = newJObject()
  var body_612930 = newJObject()
  add(query_612929, "MaxResults", newJString(MaxResults))
  add(query_612929, "NextToken", newJString(NextToken))
  if body != nil:
    body_612930 = body
  result = call_612928.call(nil, query_612929, nil, nil, body_612930)

var listUserProfiles* = Call_ListUserProfiles_612913(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_612914, base: "/",
    url: url_ListUserProfiles_612915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_612931 = ref object of OpenApiRestCall_610658
proc url_ListWorkteams_612933(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkteams_612932(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612934 = query.getOrDefault("MaxResults")
  valid_612934 = validateParameter(valid_612934, JString, required = false,
                                 default = nil)
  if valid_612934 != nil:
    section.add "MaxResults", valid_612934
  var valid_612935 = query.getOrDefault("NextToken")
  valid_612935 = validateParameter(valid_612935, JString, required = false,
                                 default = nil)
  if valid_612935 != nil:
    section.add "NextToken", valid_612935
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
  var valid_612936 = header.getOrDefault("X-Amz-Target")
  valid_612936 = validateParameter(valid_612936, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_612936 != nil:
    section.add "X-Amz-Target", valid_612936
  var valid_612937 = header.getOrDefault("X-Amz-Signature")
  valid_612937 = validateParameter(valid_612937, JString, required = false,
                                 default = nil)
  if valid_612937 != nil:
    section.add "X-Amz-Signature", valid_612937
  var valid_612938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612938 = validateParameter(valid_612938, JString, required = false,
                                 default = nil)
  if valid_612938 != nil:
    section.add "X-Amz-Content-Sha256", valid_612938
  var valid_612939 = header.getOrDefault("X-Amz-Date")
  valid_612939 = validateParameter(valid_612939, JString, required = false,
                                 default = nil)
  if valid_612939 != nil:
    section.add "X-Amz-Date", valid_612939
  var valid_612940 = header.getOrDefault("X-Amz-Credential")
  valid_612940 = validateParameter(valid_612940, JString, required = false,
                                 default = nil)
  if valid_612940 != nil:
    section.add "X-Amz-Credential", valid_612940
  var valid_612941 = header.getOrDefault("X-Amz-Security-Token")
  valid_612941 = validateParameter(valid_612941, JString, required = false,
                                 default = nil)
  if valid_612941 != nil:
    section.add "X-Amz-Security-Token", valid_612941
  var valid_612942 = header.getOrDefault("X-Amz-Algorithm")
  valid_612942 = validateParameter(valid_612942, JString, required = false,
                                 default = nil)
  if valid_612942 != nil:
    section.add "X-Amz-Algorithm", valid_612942
  var valid_612943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612943 = validateParameter(valid_612943, JString, required = false,
                                 default = nil)
  if valid_612943 != nil:
    section.add "X-Amz-SignedHeaders", valid_612943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612945: Call_ListWorkteams_612931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_612945.validator(path, query, header, formData, body)
  let scheme = call_612945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612945.url(scheme.get, call_612945.host, call_612945.base,
                         call_612945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612945, url, valid)

proc call*(call_612946: Call_ListWorkteams_612931; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612947 = newJObject()
  var body_612948 = newJObject()
  add(query_612947, "MaxResults", newJString(MaxResults))
  add(query_612947, "NextToken", newJString(NextToken))
  if body != nil:
    body_612948 = body
  result = call_612946.call(nil, query_612947, nil, nil, body_612948)

var listWorkteams* = Call_ListWorkteams_612931(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_612932, base: "/", url: url_ListWorkteams_612933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_612949 = ref object of OpenApiRestCall_610658
proc url_RenderUiTemplate_612951(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenderUiTemplate_612950(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Renders the UI template so that you can preview the worker's experience. 
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
  var valid_612952 = header.getOrDefault("X-Amz-Target")
  valid_612952 = validateParameter(valid_612952, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_612952 != nil:
    section.add "X-Amz-Target", valid_612952
  var valid_612953 = header.getOrDefault("X-Amz-Signature")
  valid_612953 = validateParameter(valid_612953, JString, required = false,
                                 default = nil)
  if valid_612953 != nil:
    section.add "X-Amz-Signature", valid_612953
  var valid_612954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612954 = validateParameter(valid_612954, JString, required = false,
                                 default = nil)
  if valid_612954 != nil:
    section.add "X-Amz-Content-Sha256", valid_612954
  var valid_612955 = header.getOrDefault("X-Amz-Date")
  valid_612955 = validateParameter(valid_612955, JString, required = false,
                                 default = nil)
  if valid_612955 != nil:
    section.add "X-Amz-Date", valid_612955
  var valid_612956 = header.getOrDefault("X-Amz-Credential")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "X-Amz-Credential", valid_612956
  var valid_612957 = header.getOrDefault("X-Amz-Security-Token")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "X-Amz-Security-Token", valid_612957
  var valid_612958 = header.getOrDefault("X-Amz-Algorithm")
  valid_612958 = validateParameter(valid_612958, JString, required = false,
                                 default = nil)
  if valid_612958 != nil:
    section.add "X-Amz-Algorithm", valid_612958
  var valid_612959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "X-Amz-SignedHeaders", valid_612959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612961: Call_RenderUiTemplate_612949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_612961.validator(path, query, header, formData, body)
  let scheme = call_612961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612961.url(scheme.get, call_612961.host, call_612961.base,
                         call_612961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612961, url, valid)

proc call*(call_612962: Call_RenderUiTemplate_612949; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_612963 = newJObject()
  if body != nil:
    body_612963 = body
  result = call_612962.call(nil, nil, nil, nil, body_612963)

var renderUiTemplate* = Call_RenderUiTemplate_612949(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_612950, base: "/",
    url: url_RenderUiTemplate_612951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_612964 = ref object of OpenApiRestCall_610658
proc url_Search_612966(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Search_612965(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_612967 = query.getOrDefault("MaxResults")
  valid_612967 = validateParameter(valid_612967, JString, required = false,
                                 default = nil)
  if valid_612967 != nil:
    section.add "MaxResults", valid_612967
  var valid_612968 = query.getOrDefault("NextToken")
  valid_612968 = validateParameter(valid_612968, JString, required = false,
                                 default = nil)
  if valid_612968 != nil:
    section.add "NextToken", valid_612968
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
  var valid_612969 = header.getOrDefault("X-Amz-Target")
  valid_612969 = validateParameter(valid_612969, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_612969 != nil:
    section.add "X-Amz-Target", valid_612969
  var valid_612970 = header.getOrDefault("X-Amz-Signature")
  valid_612970 = validateParameter(valid_612970, JString, required = false,
                                 default = nil)
  if valid_612970 != nil:
    section.add "X-Amz-Signature", valid_612970
  var valid_612971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612971 = validateParameter(valid_612971, JString, required = false,
                                 default = nil)
  if valid_612971 != nil:
    section.add "X-Amz-Content-Sha256", valid_612971
  var valid_612972 = header.getOrDefault("X-Amz-Date")
  valid_612972 = validateParameter(valid_612972, JString, required = false,
                                 default = nil)
  if valid_612972 != nil:
    section.add "X-Amz-Date", valid_612972
  var valid_612973 = header.getOrDefault("X-Amz-Credential")
  valid_612973 = validateParameter(valid_612973, JString, required = false,
                                 default = nil)
  if valid_612973 != nil:
    section.add "X-Amz-Credential", valid_612973
  var valid_612974 = header.getOrDefault("X-Amz-Security-Token")
  valid_612974 = validateParameter(valid_612974, JString, required = false,
                                 default = nil)
  if valid_612974 != nil:
    section.add "X-Amz-Security-Token", valid_612974
  var valid_612975 = header.getOrDefault("X-Amz-Algorithm")
  valid_612975 = validateParameter(valid_612975, JString, required = false,
                                 default = nil)
  if valid_612975 != nil:
    section.add "X-Amz-Algorithm", valid_612975
  var valid_612976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612976 = validateParameter(valid_612976, JString, required = false,
                                 default = nil)
  if valid_612976 != nil:
    section.add "X-Amz-SignedHeaders", valid_612976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612978: Call_Search_612964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  let valid = call_612978.validator(path, query, header, formData, body)
  let scheme = call_612978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612978.url(scheme.get, call_612978.host, call_612978.base,
                         call_612978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612978, url, valid)

proc call*(call_612979: Call_Search_612964; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_612980 = newJObject()
  var body_612981 = newJObject()
  add(query_612980, "MaxResults", newJString(MaxResults))
  add(query_612980, "NextToken", newJString(NextToken))
  if body != nil:
    body_612981 = body
  result = call_612979.call(nil, query_612980, nil, nil, body_612981)

var search* = Call_Search_612964(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_612965, base: "/",
                              url: url_Search_612966,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_612982 = ref object of OpenApiRestCall_610658
proc url_StartMonitoringSchedule_612984(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMonitoringSchedule_612983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
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
  var valid_612985 = header.getOrDefault("X-Amz-Target")
  valid_612985 = validateParameter(valid_612985, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_612985 != nil:
    section.add "X-Amz-Target", valid_612985
  var valid_612986 = header.getOrDefault("X-Amz-Signature")
  valid_612986 = validateParameter(valid_612986, JString, required = false,
                                 default = nil)
  if valid_612986 != nil:
    section.add "X-Amz-Signature", valid_612986
  var valid_612987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612987 = validateParameter(valid_612987, JString, required = false,
                                 default = nil)
  if valid_612987 != nil:
    section.add "X-Amz-Content-Sha256", valid_612987
  var valid_612988 = header.getOrDefault("X-Amz-Date")
  valid_612988 = validateParameter(valid_612988, JString, required = false,
                                 default = nil)
  if valid_612988 != nil:
    section.add "X-Amz-Date", valid_612988
  var valid_612989 = header.getOrDefault("X-Amz-Credential")
  valid_612989 = validateParameter(valid_612989, JString, required = false,
                                 default = nil)
  if valid_612989 != nil:
    section.add "X-Amz-Credential", valid_612989
  var valid_612990 = header.getOrDefault("X-Amz-Security-Token")
  valid_612990 = validateParameter(valid_612990, JString, required = false,
                                 default = nil)
  if valid_612990 != nil:
    section.add "X-Amz-Security-Token", valid_612990
  var valid_612991 = header.getOrDefault("X-Amz-Algorithm")
  valid_612991 = validateParameter(valid_612991, JString, required = false,
                                 default = nil)
  if valid_612991 != nil:
    section.add "X-Amz-Algorithm", valid_612991
  var valid_612992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612992 = validateParameter(valid_612992, JString, required = false,
                                 default = nil)
  if valid_612992 != nil:
    section.add "X-Amz-SignedHeaders", valid_612992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612994: Call_StartMonitoringSchedule_612982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_612994.validator(path, query, header, formData, body)
  let scheme = call_612994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612994.url(scheme.get, call_612994.host, call_612994.base,
                         call_612994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612994, url, valid)

proc call*(call_612995: Call_StartMonitoringSchedule_612982; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_612996 = newJObject()
  if body != nil:
    body_612996 = body
  result = call_612995.call(nil, nil, nil, nil, body_612996)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_612982(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_612983, base: "/",
    url: url_StartMonitoringSchedule_612984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_612997 = ref object of OpenApiRestCall_610658
proc url_StartNotebookInstance_612999(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartNotebookInstance_612998(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
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
  var valid_613000 = header.getOrDefault("X-Amz-Target")
  valid_613000 = validateParameter(valid_613000, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_613000 != nil:
    section.add "X-Amz-Target", valid_613000
  var valid_613001 = header.getOrDefault("X-Amz-Signature")
  valid_613001 = validateParameter(valid_613001, JString, required = false,
                                 default = nil)
  if valid_613001 != nil:
    section.add "X-Amz-Signature", valid_613001
  var valid_613002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613002 = validateParameter(valid_613002, JString, required = false,
                                 default = nil)
  if valid_613002 != nil:
    section.add "X-Amz-Content-Sha256", valid_613002
  var valid_613003 = header.getOrDefault("X-Amz-Date")
  valid_613003 = validateParameter(valid_613003, JString, required = false,
                                 default = nil)
  if valid_613003 != nil:
    section.add "X-Amz-Date", valid_613003
  var valid_613004 = header.getOrDefault("X-Amz-Credential")
  valid_613004 = validateParameter(valid_613004, JString, required = false,
                                 default = nil)
  if valid_613004 != nil:
    section.add "X-Amz-Credential", valid_613004
  var valid_613005 = header.getOrDefault("X-Amz-Security-Token")
  valid_613005 = validateParameter(valid_613005, JString, required = false,
                                 default = nil)
  if valid_613005 != nil:
    section.add "X-Amz-Security-Token", valid_613005
  var valid_613006 = header.getOrDefault("X-Amz-Algorithm")
  valid_613006 = validateParameter(valid_613006, JString, required = false,
                                 default = nil)
  if valid_613006 != nil:
    section.add "X-Amz-Algorithm", valid_613006
  var valid_613007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613007 = validateParameter(valid_613007, JString, required = false,
                                 default = nil)
  if valid_613007 != nil:
    section.add "X-Amz-SignedHeaders", valid_613007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613009: Call_StartNotebookInstance_612997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_613009.validator(path, query, header, formData, body)
  let scheme = call_613009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613009.url(scheme.get, call_613009.host, call_613009.base,
                         call_613009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613009, url, valid)

proc call*(call_613010: Call_StartNotebookInstance_612997; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_613011 = newJObject()
  if body != nil:
    body_613011 = body
  result = call_613010.call(nil, nil, nil, nil, body_613011)

var startNotebookInstance* = Call_StartNotebookInstance_612997(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_612998, base: "/",
    url: url_StartNotebookInstance_612999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_613012 = ref object of OpenApiRestCall_610658
proc url_StopAutoMLJob_613014(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutoMLJob_613013(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## A method for forcing the termination of a running job.
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
  var valid_613015 = header.getOrDefault("X-Amz-Target")
  valid_613015 = validateParameter(valid_613015, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_613015 != nil:
    section.add "X-Amz-Target", valid_613015
  var valid_613016 = header.getOrDefault("X-Amz-Signature")
  valid_613016 = validateParameter(valid_613016, JString, required = false,
                                 default = nil)
  if valid_613016 != nil:
    section.add "X-Amz-Signature", valid_613016
  var valid_613017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613017 = validateParameter(valid_613017, JString, required = false,
                                 default = nil)
  if valid_613017 != nil:
    section.add "X-Amz-Content-Sha256", valid_613017
  var valid_613018 = header.getOrDefault("X-Amz-Date")
  valid_613018 = validateParameter(valid_613018, JString, required = false,
                                 default = nil)
  if valid_613018 != nil:
    section.add "X-Amz-Date", valid_613018
  var valid_613019 = header.getOrDefault("X-Amz-Credential")
  valid_613019 = validateParameter(valid_613019, JString, required = false,
                                 default = nil)
  if valid_613019 != nil:
    section.add "X-Amz-Credential", valid_613019
  var valid_613020 = header.getOrDefault("X-Amz-Security-Token")
  valid_613020 = validateParameter(valid_613020, JString, required = false,
                                 default = nil)
  if valid_613020 != nil:
    section.add "X-Amz-Security-Token", valid_613020
  var valid_613021 = header.getOrDefault("X-Amz-Algorithm")
  valid_613021 = validateParameter(valid_613021, JString, required = false,
                                 default = nil)
  if valid_613021 != nil:
    section.add "X-Amz-Algorithm", valid_613021
  var valid_613022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613022 = validateParameter(valid_613022, JString, required = false,
                                 default = nil)
  if valid_613022 != nil:
    section.add "X-Amz-SignedHeaders", valid_613022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613024: Call_StopAutoMLJob_613012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_613024.validator(path, query, header, formData, body)
  let scheme = call_613024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613024.url(scheme.get, call_613024.host, call_613024.base,
                         call_613024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613024, url, valid)

proc call*(call_613025: Call_StopAutoMLJob_613012; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_613026 = newJObject()
  if body != nil:
    body_613026 = body
  result = call_613025.call(nil, nil, nil, nil, body_613026)

var stopAutoMLJob* = Call_StopAutoMLJob_613012(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_613013, base: "/", url: url_StopAutoMLJob_613014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_613027 = ref object of OpenApiRestCall_610658
proc url_StopCompilationJob_613029(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCompilationJob_613028(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
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
  var valid_613030 = header.getOrDefault("X-Amz-Target")
  valid_613030 = validateParameter(valid_613030, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_613030 != nil:
    section.add "X-Amz-Target", valid_613030
  var valid_613031 = header.getOrDefault("X-Amz-Signature")
  valid_613031 = validateParameter(valid_613031, JString, required = false,
                                 default = nil)
  if valid_613031 != nil:
    section.add "X-Amz-Signature", valid_613031
  var valid_613032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613032 = validateParameter(valid_613032, JString, required = false,
                                 default = nil)
  if valid_613032 != nil:
    section.add "X-Amz-Content-Sha256", valid_613032
  var valid_613033 = header.getOrDefault("X-Amz-Date")
  valid_613033 = validateParameter(valid_613033, JString, required = false,
                                 default = nil)
  if valid_613033 != nil:
    section.add "X-Amz-Date", valid_613033
  var valid_613034 = header.getOrDefault("X-Amz-Credential")
  valid_613034 = validateParameter(valid_613034, JString, required = false,
                                 default = nil)
  if valid_613034 != nil:
    section.add "X-Amz-Credential", valid_613034
  var valid_613035 = header.getOrDefault("X-Amz-Security-Token")
  valid_613035 = validateParameter(valid_613035, JString, required = false,
                                 default = nil)
  if valid_613035 != nil:
    section.add "X-Amz-Security-Token", valid_613035
  var valid_613036 = header.getOrDefault("X-Amz-Algorithm")
  valid_613036 = validateParameter(valid_613036, JString, required = false,
                                 default = nil)
  if valid_613036 != nil:
    section.add "X-Amz-Algorithm", valid_613036
  var valid_613037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613037 = validateParameter(valid_613037, JString, required = false,
                                 default = nil)
  if valid_613037 != nil:
    section.add "X-Amz-SignedHeaders", valid_613037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613039: Call_StopCompilationJob_613027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_613039.validator(path, query, header, formData, body)
  let scheme = call_613039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613039.url(scheme.get, call_613039.host, call_613039.base,
                         call_613039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613039, url, valid)

proc call*(call_613040: Call_StopCompilationJob_613027; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_613041 = newJObject()
  if body != nil:
    body_613041 = body
  result = call_613040.call(nil, nil, nil, nil, body_613041)

var stopCompilationJob* = Call_StopCompilationJob_613027(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_613028, base: "/",
    url: url_StopCompilationJob_613029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_613042 = ref object of OpenApiRestCall_610658
proc url_StopHyperParameterTuningJob_613044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopHyperParameterTuningJob_613043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
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
  var valid_613045 = header.getOrDefault("X-Amz-Target")
  valid_613045 = validateParameter(valid_613045, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_613045 != nil:
    section.add "X-Amz-Target", valid_613045
  var valid_613046 = header.getOrDefault("X-Amz-Signature")
  valid_613046 = validateParameter(valid_613046, JString, required = false,
                                 default = nil)
  if valid_613046 != nil:
    section.add "X-Amz-Signature", valid_613046
  var valid_613047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613047 = validateParameter(valid_613047, JString, required = false,
                                 default = nil)
  if valid_613047 != nil:
    section.add "X-Amz-Content-Sha256", valid_613047
  var valid_613048 = header.getOrDefault("X-Amz-Date")
  valid_613048 = validateParameter(valid_613048, JString, required = false,
                                 default = nil)
  if valid_613048 != nil:
    section.add "X-Amz-Date", valid_613048
  var valid_613049 = header.getOrDefault("X-Amz-Credential")
  valid_613049 = validateParameter(valid_613049, JString, required = false,
                                 default = nil)
  if valid_613049 != nil:
    section.add "X-Amz-Credential", valid_613049
  var valid_613050 = header.getOrDefault("X-Amz-Security-Token")
  valid_613050 = validateParameter(valid_613050, JString, required = false,
                                 default = nil)
  if valid_613050 != nil:
    section.add "X-Amz-Security-Token", valid_613050
  var valid_613051 = header.getOrDefault("X-Amz-Algorithm")
  valid_613051 = validateParameter(valid_613051, JString, required = false,
                                 default = nil)
  if valid_613051 != nil:
    section.add "X-Amz-Algorithm", valid_613051
  var valid_613052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613052 = validateParameter(valid_613052, JString, required = false,
                                 default = nil)
  if valid_613052 != nil:
    section.add "X-Amz-SignedHeaders", valid_613052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613054: Call_StopHyperParameterTuningJob_613042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_613054.validator(path, query, header, formData, body)
  let scheme = call_613054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613054.url(scheme.get, call_613054.host, call_613054.base,
                         call_613054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613054, url, valid)

proc call*(call_613055: Call_StopHyperParameterTuningJob_613042; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_613056 = newJObject()
  if body != nil:
    body_613056 = body
  result = call_613055.call(nil, nil, nil, nil, body_613056)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_613042(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_613043, base: "/",
    url: url_StopHyperParameterTuningJob_613044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_613057 = ref object of OpenApiRestCall_610658
proc url_StopLabelingJob_613059(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLabelingJob_613058(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
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
  var valid_613060 = header.getOrDefault("X-Amz-Target")
  valid_613060 = validateParameter(valid_613060, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_613060 != nil:
    section.add "X-Amz-Target", valid_613060
  var valid_613061 = header.getOrDefault("X-Amz-Signature")
  valid_613061 = validateParameter(valid_613061, JString, required = false,
                                 default = nil)
  if valid_613061 != nil:
    section.add "X-Amz-Signature", valid_613061
  var valid_613062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613062 = validateParameter(valid_613062, JString, required = false,
                                 default = nil)
  if valid_613062 != nil:
    section.add "X-Amz-Content-Sha256", valid_613062
  var valid_613063 = header.getOrDefault("X-Amz-Date")
  valid_613063 = validateParameter(valid_613063, JString, required = false,
                                 default = nil)
  if valid_613063 != nil:
    section.add "X-Amz-Date", valid_613063
  var valid_613064 = header.getOrDefault("X-Amz-Credential")
  valid_613064 = validateParameter(valid_613064, JString, required = false,
                                 default = nil)
  if valid_613064 != nil:
    section.add "X-Amz-Credential", valid_613064
  var valid_613065 = header.getOrDefault("X-Amz-Security-Token")
  valid_613065 = validateParameter(valid_613065, JString, required = false,
                                 default = nil)
  if valid_613065 != nil:
    section.add "X-Amz-Security-Token", valid_613065
  var valid_613066 = header.getOrDefault("X-Amz-Algorithm")
  valid_613066 = validateParameter(valid_613066, JString, required = false,
                                 default = nil)
  if valid_613066 != nil:
    section.add "X-Amz-Algorithm", valid_613066
  var valid_613067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613067 = validateParameter(valid_613067, JString, required = false,
                                 default = nil)
  if valid_613067 != nil:
    section.add "X-Amz-SignedHeaders", valid_613067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613069: Call_StopLabelingJob_613057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_613069.validator(path, query, header, formData, body)
  let scheme = call_613069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613069.url(scheme.get, call_613069.host, call_613069.base,
                         call_613069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613069, url, valid)

proc call*(call_613070: Call_StopLabelingJob_613057; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_613071 = newJObject()
  if body != nil:
    body_613071 = body
  result = call_613070.call(nil, nil, nil, nil, body_613071)

var stopLabelingJob* = Call_StopLabelingJob_613057(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_613058, base: "/", url: url_StopLabelingJob_613059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_613072 = ref object of OpenApiRestCall_610658
proc url_StopMonitoringSchedule_613074(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopMonitoringSchedule_613073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a previously started monitoring schedule.
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
  var valid_613075 = header.getOrDefault("X-Amz-Target")
  valid_613075 = validateParameter(valid_613075, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_613075 != nil:
    section.add "X-Amz-Target", valid_613075
  var valid_613076 = header.getOrDefault("X-Amz-Signature")
  valid_613076 = validateParameter(valid_613076, JString, required = false,
                                 default = nil)
  if valid_613076 != nil:
    section.add "X-Amz-Signature", valid_613076
  var valid_613077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613077 = validateParameter(valid_613077, JString, required = false,
                                 default = nil)
  if valid_613077 != nil:
    section.add "X-Amz-Content-Sha256", valid_613077
  var valid_613078 = header.getOrDefault("X-Amz-Date")
  valid_613078 = validateParameter(valid_613078, JString, required = false,
                                 default = nil)
  if valid_613078 != nil:
    section.add "X-Amz-Date", valid_613078
  var valid_613079 = header.getOrDefault("X-Amz-Credential")
  valid_613079 = validateParameter(valid_613079, JString, required = false,
                                 default = nil)
  if valid_613079 != nil:
    section.add "X-Amz-Credential", valid_613079
  var valid_613080 = header.getOrDefault("X-Amz-Security-Token")
  valid_613080 = validateParameter(valid_613080, JString, required = false,
                                 default = nil)
  if valid_613080 != nil:
    section.add "X-Amz-Security-Token", valid_613080
  var valid_613081 = header.getOrDefault("X-Amz-Algorithm")
  valid_613081 = validateParameter(valid_613081, JString, required = false,
                                 default = nil)
  if valid_613081 != nil:
    section.add "X-Amz-Algorithm", valid_613081
  var valid_613082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613082 = validateParameter(valid_613082, JString, required = false,
                                 default = nil)
  if valid_613082 != nil:
    section.add "X-Amz-SignedHeaders", valid_613082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613084: Call_StopMonitoringSchedule_613072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_613084.validator(path, query, header, formData, body)
  let scheme = call_613084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613084.url(scheme.get, call_613084.host, call_613084.base,
                         call_613084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613084, url, valid)

proc call*(call_613085: Call_StopMonitoringSchedule_613072; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_613086 = newJObject()
  if body != nil:
    body_613086 = body
  result = call_613085.call(nil, nil, nil, nil, body_613086)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_613072(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_613073, base: "/",
    url: url_StopMonitoringSchedule_613074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_613087 = ref object of OpenApiRestCall_610658
proc url_StopNotebookInstance_613089(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopNotebookInstance_613088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
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
  var valid_613090 = header.getOrDefault("X-Amz-Target")
  valid_613090 = validateParameter(valid_613090, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_613090 != nil:
    section.add "X-Amz-Target", valid_613090
  var valid_613091 = header.getOrDefault("X-Amz-Signature")
  valid_613091 = validateParameter(valid_613091, JString, required = false,
                                 default = nil)
  if valid_613091 != nil:
    section.add "X-Amz-Signature", valid_613091
  var valid_613092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613092 = validateParameter(valid_613092, JString, required = false,
                                 default = nil)
  if valid_613092 != nil:
    section.add "X-Amz-Content-Sha256", valid_613092
  var valid_613093 = header.getOrDefault("X-Amz-Date")
  valid_613093 = validateParameter(valid_613093, JString, required = false,
                                 default = nil)
  if valid_613093 != nil:
    section.add "X-Amz-Date", valid_613093
  var valid_613094 = header.getOrDefault("X-Amz-Credential")
  valid_613094 = validateParameter(valid_613094, JString, required = false,
                                 default = nil)
  if valid_613094 != nil:
    section.add "X-Amz-Credential", valid_613094
  var valid_613095 = header.getOrDefault("X-Amz-Security-Token")
  valid_613095 = validateParameter(valid_613095, JString, required = false,
                                 default = nil)
  if valid_613095 != nil:
    section.add "X-Amz-Security-Token", valid_613095
  var valid_613096 = header.getOrDefault("X-Amz-Algorithm")
  valid_613096 = validateParameter(valid_613096, JString, required = false,
                                 default = nil)
  if valid_613096 != nil:
    section.add "X-Amz-Algorithm", valid_613096
  var valid_613097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613097 = validateParameter(valid_613097, JString, required = false,
                                 default = nil)
  if valid_613097 != nil:
    section.add "X-Amz-SignedHeaders", valid_613097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613099: Call_StopNotebookInstance_613087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_613099.validator(path, query, header, formData, body)
  let scheme = call_613099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613099.url(scheme.get, call_613099.host, call_613099.base,
                         call_613099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613099, url, valid)

proc call*(call_613100: Call_StopNotebookInstance_613087; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_613101 = newJObject()
  if body != nil:
    body_613101 = body
  result = call_613100.call(nil, nil, nil, nil, body_613101)

var stopNotebookInstance* = Call_StopNotebookInstance_613087(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_613088, base: "/",
    url: url_StopNotebookInstance_613089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_613102 = ref object of OpenApiRestCall_610658
proc url_StopProcessingJob_613104(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopProcessingJob_613103(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Stops a processing job.
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
  var valid_613105 = header.getOrDefault("X-Amz-Target")
  valid_613105 = validateParameter(valid_613105, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_613105 != nil:
    section.add "X-Amz-Target", valid_613105
  var valid_613106 = header.getOrDefault("X-Amz-Signature")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Signature", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Content-Sha256", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Date")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Date", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Credential")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Credential", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Security-Token")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Security-Token", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Algorithm")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Algorithm", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-SignedHeaders", valid_613112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613114: Call_StopProcessingJob_613102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_613114.validator(path, query, header, formData, body)
  let scheme = call_613114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613114.url(scheme.get, call_613114.host, call_613114.base,
                         call_613114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613114, url, valid)

proc call*(call_613115: Call_StopProcessingJob_613102; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_613116 = newJObject()
  if body != nil:
    body_613116 = body
  result = call_613115.call(nil, nil, nil, nil, body_613116)

var stopProcessingJob* = Call_StopProcessingJob_613102(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_613103, base: "/",
    url: url_StopProcessingJob_613104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_613117 = ref object of OpenApiRestCall_610658
proc url_StopTrainingJob_613119(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingJob_613118(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
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
  var valid_613120 = header.getOrDefault("X-Amz-Target")
  valid_613120 = validateParameter(valid_613120, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_613120 != nil:
    section.add "X-Amz-Target", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Signature")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Signature", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-Content-Sha256", valid_613122
  var valid_613123 = header.getOrDefault("X-Amz-Date")
  valid_613123 = validateParameter(valid_613123, JString, required = false,
                                 default = nil)
  if valid_613123 != nil:
    section.add "X-Amz-Date", valid_613123
  var valid_613124 = header.getOrDefault("X-Amz-Credential")
  valid_613124 = validateParameter(valid_613124, JString, required = false,
                                 default = nil)
  if valid_613124 != nil:
    section.add "X-Amz-Credential", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Security-Token")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Security-Token", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Algorithm")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Algorithm", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-SignedHeaders", valid_613127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613129: Call_StopTrainingJob_613117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_613129.validator(path, query, header, formData, body)
  let scheme = call_613129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613129.url(scheme.get, call_613129.host, call_613129.base,
                         call_613129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613129, url, valid)

proc call*(call_613130: Call_StopTrainingJob_613117; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_613131 = newJObject()
  if body != nil:
    body_613131 = body
  result = call_613130.call(nil, nil, nil, nil, body_613131)

var stopTrainingJob* = Call_StopTrainingJob_613117(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_613118, base: "/", url: url_StopTrainingJob_613119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_613132 = ref object of OpenApiRestCall_610658
proc url_StopTransformJob_613134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTransformJob_613133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
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
  var valid_613135 = header.getOrDefault("X-Amz-Target")
  valid_613135 = validateParameter(valid_613135, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_613135 != nil:
    section.add "X-Amz-Target", valid_613135
  var valid_613136 = header.getOrDefault("X-Amz-Signature")
  valid_613136 = validateParameter(valid_613136, JString, required = false,
                                 default = nil)
  if valid_613136 != nil:
    section.add "X-Amz-Signature", valid_613136
  var valid_613137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613137 = validateParameter(valid_613137, JString, required = false,
                                 default = nil)
  if valid_613137 != nil:
    section.add "X-Amz-Content-Sha256", valid_613137
  var valid_613138 = header.getOrDefault("X-Amz-Date")
  valid_613138 = validateParameter(valid_613138, JString, required = false,
                                 default = nil)
  if valid_613138 != nil:
    section.add "X-Amz-Date", valid_613138
  var valid_613139 = header.getOrDefault("X-Amz-Credential")
  valid_613139 = validateParameter(valid_613139, JString, required = false,
                                 default = nil)
  if valid_613139 != nil:
    section.add "X-Amz-Credential", valid_613139
  var valid_613140 = header.getOrDefault("X-Amz-Security-Token")
  valid_613140 = validateParameter(valid_613140, JString, required = false,
                                 default = nil)
  if valid_613140 != nil:
    section.add "X-Amz-Security-Token", valid_613140
  var valid_613141 = header.getOrDefault("X-Amz-Algorithm")
  valid_613141 = validateParameter(valid_613141, JString, required = false,
                                 default = nil)
  if valid_613141 != nil:
    section.add "X-Amz-Algorithm", valid_613141
  var valid_613142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613142 = validateParameter(valid_613142, JString, required = false,
                                 default = nil)
  if valid_613142 != nil:
    section.add "X-Amz-SignedHeaders", valid_613142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613144: Call_StopTransformJob_613132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_613144.validator(path, query, header, formData, body)
  let scheme = call_613144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613144.url(scheme.get, call_613144.host, call_613144.base,
                         call_613144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613144, url, valid)

proc call*(call_613145: Call_StopTransformJob_613132; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_613146 = newJObject()
  if body != nil:
    body_613146 = body
  result = call_613145.call(nil, nil, nil, nil, body_613146)

var stopTransformJob* = Call_StopTransformJob_613132(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_613133, base: "/",
    url: url_StopTransformJob_613134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_613147 = ref object of OpenApiRestCall_610658
proc url_UpdateCodeRepository_613149(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCodeRepository_613148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the specified Git repository with the specified values.
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
  var valid_613150 = header.getOrDefault("X-Amz-Target")
  valid_613150 = validateParameter(valid_613150, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_613150 != nil:
    section.add "X-Amz-Target", valid_613150
  var valid_613151 = header.getOrDefault("X-Amz-Signature")
  valid_613151 = validateParameter(valid_613151, JString, required = false,
                                 default = nil)
  if valid_613151 != nil:
    section.add "X-Amz-Signature", valid_613151
  var valid_613152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613152 = validateParameter(valid_613152, JString, required = false,
                                 default = nil)
  if valid_613152 != nil:
    section.add "X-Amz-Content-Sha256", valid_613152
  var valid_613153 = header.getOrDefault("X-Amz-Date")
  valid_613153 = validateParameter(valid_613153, JString, required = false,
                                 default = nil)
  if valid_613153 != nil:
    section.add "X-Amz-Date", valid_613153
  var valid_613154 = header.getOrDefault("X-Amz-Credential")
  valid_613154 = validateParameter(valid_613154, JString, required = false,
                                 default = nil)
  if valid_613154 != nil:
    section.add "X-Amz-Credential", valid_613154
  var valid_613155 = header.getOrDefault("X-Amz-Security-Token")
  valid_613155 = validateParameter(valid_613155, JString, required = false,
                                 default = nil)
  if valid_613155 != nil:
    section.add "X-Amz-Security-Token", valid_613155
  var valid_613156 = header.getOrDefault("X-Amz-Algorithm")
  valid_613156 = validateParameter(valid_613156, JString, required = false,
                                 default = nil)
  if valid_613156 != nil:
    section.add "X-Amz-Algorithm", valid_613156
  var valid_613157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613157 = validateParameter(valid_613157, JString, required = false,
                                 default = nil)
  if valid_613157 != nil:
    section.add "X-Amz-SignedHeaders", valid_613157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613159: Call_UpdateCodeRepository_613147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_613159.validator(path, query, header, formData, body)
  let scheme = call_613159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613159.url(scheme.get, call_613159.host, call_613159.base,
                         call_613159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613159, url, valid)

proc call*(call_613160: Call_UpdateCodeRepository_613147; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_613161 = newJObject()
  if body != nil:
    body_613161 = body
  result = call_613160.call(nil, nil, nil, nil, body_613161)

var updateCodeRepository* = Call_UpdateCodeRepository_613147(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_613148, base: "/",
    url: url_UpdateCodeRepository_613149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_613162 = ref object of OpenApiRestCall_610658
proc url_UpdateDomain_613164(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomain_613163(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a domain. Changes will impact all of the people in the domain.
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
  var valid_613165 = header.getOrDefault("X-Amz-Target")
  valid_613165 = validateParameter(valid_613165, JString, required = true,
                                 default = newJString("SageMaker.UpdateDomain"))
  if valid_613165 != nil:
    section.add "X-Amz-Target", valid_613165
  var valid_613166 = header.getOrDefault("X-Amz-Signature")
  valid_613166 = validateParameter(valid_613166, JString, required = false,
                                 default = nil)
  if valid_613166 != nil:
    section.add "X-Amz-Signature", valid_613166
  var valid_613167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613167 = validateParameter(valid_613167, JString, required = false,
                                 default = nil)
  if valid_613167 != nil:
    section.add "X-Amz-Content-Sha256", valid_613167
  var valid_613168 = header.getOrDefault("X-Amz-Date")
  valid_613168 = validateParameter(valid_613168, JString, required = false,
                                 default = nil)
  if valid_613168 != nil:
    section.add "X-Amz-Date", valid_613168
  var valid_613169 = header.getOrDefault("X-Amz-Credential")
  valid_613169 = validateParameter(valid_613169, JString, required = false,
                                 default = nil)
  if valid_613169 != nil:
    section.add "X-Amz-Credential", valid_613169
  var valid_613170 = header.getOrDefault("X-Amz-Security-Token")
  valid_613170 = validateParameter(valid_613170, JString, required = false,
                                 default = nil)
  if valid_613170 != nil:
    section.add "X-Amz-Security-Token", valid_613170
  var valid_613171 = header.getOrDefault("X-Amz-Algorithm")
  valid_613171 = validateParameter(valid_613171, JString, required = false,
                                 default = nil)
  if valid_613171 != nil:
    section.add "X-Amz-Algorithm", valid_613171
  var valid_613172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613172 = validateParameter(valid_613172, JString, required = false,
                                 default = nil)
  if valid_613172 != nil:
    section.add "X-Amz-SignedHeaders", valid_613172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613174: Call_UpdateDomain_613162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_613174.validator(path, query, header, formData, body)
  let scheme = call_613174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613174.url(scheme.get, call_613174.host, call_613174.base,
                         call_613174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613174, url, valid)

proc call*(call_613175: Call_UpdateDomain_613162; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_613176 = newJObject()
  if body != nil:
    body_613176 = body
  result = call_613175.call(nil, nil, nil, nil, body_613176)

var updateDomain* = Call_UpdateDomain_613162(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_613163, base: "/", url: url_UpdateDomain_613164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_613177 = ref object of OpenApiRestCall_610658
proc url_UpdateEndpoint_613179(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_613178(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
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
  var valid_613180 = header.getOrDefault("X-Amz-Target")
  valid_613180 = validateParameter(valid_613180, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_613180 != nil:
    section.add "X-Amz-Target", valid_613180
  var valid_613181 = header.getOrDefault("X-Amz-Signature")
  valid_613181 = validateParameter(valid_613181, JString, required = false,
                                 default = nil)
  if valid_613181 != nil:
    section.add "X-Amz-Signature", valid_613181
  var valid_613182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613182 = validateParameter(valid_613182, JString, required = false,
                                 default = nil)
  if valid_613182 != nil:
    section.add "X-Amz-Content-Sha256", valid_613182
  var valid_613183 = header.getOrDefault("X-Amz-Date")
  valid_613183 = validateParameter(valid_613183, JString, required = false,
                                 default = nil)
  if valid_613183 != nil:
    section.add "X-Amz-Date", valid_613183
  var valid_613184 = header.getOrDefault("X-Amz-Credential")
  valid_613184 = validateParameter(valid_613184, JString, required = false,
                                 default = nil)
  if valid_613184 != nil:
    section.add "X-Amz-Credential", valid_613184
  var valid_613185 = header.getOrDefault("X-Amz-Security-Token")
  valid_613185 = validateParameter(valid_613185, JString, required = false,
                                 default = nil)
  if valid_613185 != nil:
    section.add "X-Amz-Security-Token", valid_613185
  var valid_613186 = header.getOrDefault("X-Amz-Algorithm")
  valid_613186 = validateParameter(valid_613186, JString, required = false,
                                 default = nil)
  if valid_613186 != nil:
    section.add "X-Amz-Algorithm", valid_613186
  var valid_613187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613187 = validateParameter(valid_613187, JString, required = false,
                                 default = nil)
  if valid_613187 != nil:
    section.add "X-Amz-SignedHeaders", valid_613187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613189: Call_UpdateEndpoint_613177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_613189.validator(path, query, header, formData, body)
  let scheme = call_613189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613189.url(scheme.get, call_613189.host, call_613189.base,
                         call_613189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613189, url, valid)

proc call*(call_613190: Call_UpdateEndpoint_613177; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_613191 = newJObject()
  if body != nil:
    body_613191 = body
  result = call_613190.call(nil, nil, nil, nil, body_613191)

var updateEndpoint* = Call_UpdateEndpoint_613177(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_613178, base: "/", url: url_UpdateEndpoint_613179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_613192 = ref object of OpenApiRestCall_610658
proc url_UpdateEndpointWeightsAndCapacities_613194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpointWeightsAndCapacities_613193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
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
  var valid_613195 = header.getOrDefault("X-Amz-Target")
  valid_613195 = validateParameter(valid_613195, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_613195 != nil:
    section.add "X-Amz-Target", valid_613195
  var valid_613196 = header.getOrDefault("X-Amz-Signature")
  valid_613196 = validateParameter(valid_613196, JString, required = false,
                                 default = nil)
  if valid_613196 != nil:
    section.add "X-Amz-Signature", valid_613196
  var valid_613197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613197 = validateParameter(valid_613197, JString, required = false,
                                 default = nil)
  if valid_613197 != nil:
    section.add "X-Amz-Content-Sha256", valid_613197
  var valid_613198 = header.getOrDefault("X-Amz-Date")
  valid_613198 = validateParameter(valid_613198, JString, required = false,
                                 default = nil)
  if valid_613198 != nil:
    section.add "X-Amz-Date", valid_613198
  var valid_613199 = header.getOrDefault("X-Amz-Credential")
  valid_613199 = validateParameter(valid_613199, JString, required = false,
                                 default = nil)
  if valid_613199 != nil:
    section.add "X-Amz-Credential", valid_613199
  var valid_613200 = header.getOrDefault("X-Amz-Security-Token")
  valid_613200 = validateParameter(valid_613200, JString, required = false,
                                 default = nil)
  if valid_613200 != nil:
    section.add "X-Amz-Security-Token", valid_613200
  var valid_613201 = header.getOrDefault("X-Amz-Algorithm")
  valid_613201 = validateParameter(valid_613201, JString, required = false,
                                 default = nil)
  if valid_613201 != nil:
    section.add "X-Amz-Algorithm", valid_613201
  var valid_613202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613202 = validateParameter(valid_613202, JString, required = false,
                                 default = nil)
  if valid_613202 != nil:
    section.add "X-Amz-SignedHeaders", valid_613202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613204: Call_UpdateEndpointWeightsAndCapacities_613192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_613204.validator(path, query, header, formData, body)
  let scheme = call_613204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613204.url(scheme.get, call_613204.host, call_613204.base,
                         call_613204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613204, url, valid)

proc call*(call_613205: Call_UpdateEndpointWeightsAndCapacities_613192;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_613206 = newJObject()
  if body != nil:
    body_613206 = body
  result = call_613205.call(nil, nil, nil, nil, body_613206)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_613192(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_613193, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_613194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_613207 = ref object of OpenApiRestCall_610658
proc url_UpdateExperiment_613209(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateExperiment_613208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
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
  var valid_613210 = header.getOrDefault("X-Amz-Target")
  valid_613210 = validateParameter(valid_613210, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_613210 != nil:
    section.add "X-Amz-Target", valid_613210
  var valid_613211 = header.getOrDefault("X-Amz-Signature")
  valid_613211 = validateParameter(valid_613211, JString, required = false,
                                 default = nil)
  if valid_613211 != nil:
    section.add "X-Amz-Signature", valid_613211
  var valid_613212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613212 = validateParameter(valid_613212, JString, required = false,
                                 default = nil)
  if valid_613212 != nil:
    section.add "X-Amz-Content-Sha256", valid_613212
  var valid_613213 = header.getOrDefault("X-Amz-Date")
  valid_613213 = validateParameter(valid_613213, JString, required = false,
                                 default = nil)
  if valid_613213 != nil:
    section.add "X-Amz-Date", valid_613213
  var valid_613214 = header.getOrDefault("X-Amz-Credential")
  valid_613214 = validateParameter(valid_613214, JString, required = false,
                                 default = nil)
  if valid_613214 != nil:
    section.add "X-Amz-Credential", valid_613214
  var valid_613215 = header.getOrDefault("X-Amz-Security-Token")
  valid_613215 = validateParameter(valid_613215, JString, required = false,
                                 default = nil)
  if valid_613215 != nil:
    section.add "X-Amz-Security-Token", valid_613215
  var valid_613216 = header.getOrDefault("X-Amz-Algorithm")
  valid_613216 = validateParameter(valid_613216, JString, required = false,
                                 default = nil)
  if valid_613216 != nil:
    section.add "X-Amz-Algorithm", valid_613216
  var valid_613217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613217 = validateParameter(valid_613217, JString, required = false,
                                 default = nil)
  if valid_613217 != nil:
    section.add "X-Amz-SignedHeaders", valid_613217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613219: Call_UpdateExperiment_613207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_613219.validator(path, query, header, formData, body)
  let scheme = call_613219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613219.url(scheme.get, call_613219.host, call_613219.base,
                         call_613219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613219, url, valid)

proc call*(call_613220: Call_UpdateExperiment_613207; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_613221 = newJObject()
  if body != nil:
    body_613221 = body
  result = call_613220.call(nil, nil, nil, nil, body_613221)

var updateExperiment* = Call_UpdateExperiment_613207(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_613208, base: "/",
    url: url_UpdateExperiment_613209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_613222 = ref object of OpenApiRestCall_610658
proc url_UpdateMonitoringSchedule_613224(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMonitoringSchedule_613223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a previously created schedule.
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
  var valid_613225 = header.getOrDefault("X-Amz-Target")
  valid_613225 = validateParameter(valid_613225, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_613225 != nil:
    section.add "X-Amz-Target", valid_613225
  var valid_613226 = header.getOrDefault("X-Amz-Signature")
  valid_613226 = validateParameter(valid_613226, JString, required = false,
                                 default = nil)
  if valid_613226 != nil:
    section.add "X-Amz-Signature", valid_613226
  var valid_613227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613227 = validateParameter(valid_613227, JString, required = false,
                                 default = nil)
  if valid_613227 != nil:
    section.add "X-Amz-Content-Sha256", valid_613227
  var valid_613228 = header.getOrDefault("X-Amz-Date")
  valid_613228 = validateParameter(valid_613228, JString, required = false,
                                 default = nil)
  if valid_613228 != nil:
    section.add "X-Amz-Date", valid_613228
  var valid_613229 = header.getOrDefault("X-Amz-Credential")
  valid_613229 = validateParameter(valid_613229, JString, required = false,
                                 default = nil)
  if valid_613229 != nil:
    section.add "X-Amz-Credential", valid_613229
  var valid_613230 = header.getOrDefault("X-Amz-Security-Token")
  valid_613230 = validateParameter(valid_613230, JString, required = false,
                                 default = nil)
  if valid_613230 != nil:
    section.add "X-Amz-Security-Token", valid_613230
  var valid_613231 = header.getOrDefault("X-Amz-Algorithm")
  valid_613231 = validateParameter(valid_613231, JString, required = false,
                                 default = nil)
  if valid_613231 != nil:
    section.add "X-Amz-Algorithm", valid_613231
  var valid_613232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613232 = validateParameter(valid_613232, JString, required = false,
                                 default = nil)
  if valid_613232 != nil:
    section.add "X-Amz-SignedHeaders", valid_613232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613234: Call_UpdateMonitoringSchedule_613222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_613234.validator(path, query, header, formData, body)
  let scheme = call_613234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613234.url(scheme.get, call_613234.host, call_613234.base,
                         call_613234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613234, url, valid)

proc call*(call_613235: Call_UpdateMonitoringSchedule_613222; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_613236 = newJObject()
  if body != nil:
    body_613236 = body
  result = call_613235.call(nil, nil, nil, nil, body_613236)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_613222(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_613223, base: "/",
    url: url_UpdateMonitoringSchedule_613224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_613237 = ref object of OpenApiRestCall_610658
proc url_UpdateNotebookInstance_613239(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstance_613238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
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
  var valid_613240 = header.getOrDefault("X-Amz-Target")
  valid_613240 = validateParameter(valid_613240, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_613240 != nil:
    section.add "X-Amz-Target", valid_613240
  var valid_613241 = header.getOrDefault("X-Amz-Signature")
  valid_613241 = validateParameter(valid_613241, JString, required = false,
                                 default = nil)
  if valid_613241 != nil:
    section.add "X-Amz-Signature", valid_613241
  var valid_613242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613242 = validateParameter(valid_613242, JString, required = false,
                                 default = nil)
  if valid_613242 != nil:
    section.add "X-Amz-Content-Sha256", valid_613242
  var valid_613243 = header.getOrDefault("X-Amz-Date")
  valid_613243 = validateParameter(valid_613243, JString, required = false,
                                 default = nil)
  if valid_613243 != nil:
    section.add "X-Amz-Date", valid_613243
  var valid_613244 = header.getOrDefault("X-Amz-Credential")
  valid_613244 = validateParameter(valid_613244, JString, required = false,
                                 default = nil)
  if valid_613244 != nil:
    section.add "X-Amz-Credential", valid_613244
  var valid_613245 = header.getOrDefault("X-Amz-Security-Token")
  valid_613245 = validateParameter(valid_613245, JString, required = false,
                                 default = nil)
  if valid_613245 != nil:
    section.add "X-Amz-Security-Token", valid_613245
  var valid_613246 = header.getOrDefault("X-Amz-Algorithm")
  valid_613246 = validateParameter(valid_613246, JString, required = false,
                                 default = nil)
  if valid_613246 != nil:
    section.add "X-Amz-Algorithm", valid_613246
  var valid_613247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613247 = validateParameter(valid_613247, JString, required = false,
                                 default = nil)
  if valid_613247 != nil:
    section.add "X-Amz-SignedHeaders", valid_613247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613249: Call_UpdateNotebookInstance_613237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_613249.validator(path, query, header, formData, body)
  let scheme = call_613249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613249.url(scheme.get, call_613249.host, call_613249.base,
                         call_613249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613249, url, valid)

proc call*(call_613250: Call_UpdateNotebookInstance_613237; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_613251 = newJObject()
  if body != nil:
    body_613251 = body
  result = call_613250.call(nil, nil, nil, nil, body_613251)

var updateNotebookInstance* = Call_UpdateNotebookInstance_613237(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_613238, base: "/",
    url: url_UpdateNotebookInstance_613239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_613252 = ref object of OpenApiRestCall_610658
proc url_UpdateNotebookInstanceLifecycleConfig_613254(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_613253(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
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
  var valid_613255 = header.getOrDefault("X-Amz-Target")
  valid_613255 = validateParameter(valid_613255, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_613255 != nil:
    section.add "X-Amz-Target", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Signature")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Signature", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Content-Sha256", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Date")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Date", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Credential")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Credential", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Security-Token")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Security-Token", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Algorithm")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Algorithm", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-SignedHeaders", valid_613262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_UpdateNotebookInstanceLifecycleConfig_613252;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_UpdateNotebookInstanceLifecycleConfig_613252;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_613266 = newJObject()
  if body != nil:
    body_613266 = body
  result = call_613265.call(nil, nil, nil, nil, body_613266)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_613252(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_613253, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_613254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_613267 = ref object of OpenApiRestCall_610658
proc url_UpdateTrial_613269(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrial_613268(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the display name of a trial.
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
  var valid_613270 = header.getOrDefault("X-Amz-Target")
  valid_613270 = validateParameter(valid_613270, JString, required = true,
                                 default = newJString("SageMaker.UpdateTrial"))
  if valid_613270 != nil:
    section.add "X-Amz-Target", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Signature", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Content-Sha256", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Date")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Date", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Credential")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Credential", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Security-Token")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Security-Token", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Algorithm")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Algorithm", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-SignedHeaders", valid_613277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_UpdateTrial_613267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_UpdateTrial_613267; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_613281 = newJObject()
  if body != nil:
    body_613281 = body
  result = call_613280.call(nil, nil, nil, nil, body_613281)

var updateTrial* = Call_UpdateTrial_613267(name: "updateTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.UpdateTrial",
                                        validator: validate_UpdateTrial_613268,
                                        base: "/", url: url_UpdateTrial_613269,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_613282 = ref object of OpenApiRestCall_610658
proc url_UpdateTrialComponent_613284(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrialComponent_613283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates one or more properties of a trial component.
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
  var valid_613285 = header.getOrDefault("X-Amz-Target")
  valid_613285 = validateParameter(valid_613285, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_613285 != nil:
    section.add "X-Amz-Target", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Signature")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Signature", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Content-Sha256", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Date")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Date", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Credential")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Credential", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Security-Token")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Security-Token", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Algorithm")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Algorithm", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613294: Call_UpdateTrialComponent_613282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_613294.validator(path, query, header, formData, body)
  let scheme = call_613294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613294.url(scheme.get, call_613294.host, call_613294.base,
                         call_613294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613294, url, valid)

proc call*(call_613295: Call_UpdateTrialComponent_613282; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_613296 = newJObject()
  if body != nil:
    body_613296 = body
  result = call_613295.call(nil, nil, nil, nil, body_613296)

var updateTrialComponent* = Call_UpdateTrialComponent_613282(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_613283, base: "/",
    url: url_UpdateTrialComponent_613284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_613297 = ref object of OpenApiRestCall_610658
proc url_UpdateUserProfile_613299(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserProfile_613298(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a user profile.
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
  var valid_613300 = header.getOrDefault("X-Amz-Target")
  valid_613300 = validateParameter(valid_613300, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_613300 != nil:
    section.add "X-Amz-Target", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Signature")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Signature", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Content-Sha256", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Date")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Date", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Credential")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Credential", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Security-Token")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Security-Token", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Algorithm")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Algorithm", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-SignedHeaders", valid_613307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613309: Call_UpdateUserProfile_613297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_613309.validator(path, query, header, formData, body)
  let scheme = call_613309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613309.url(scheme.get, call_613309.host, call_613309.base,
                         call_613309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613309, url, valid)

proc call*(call_613310: Call_UpdateUserProfile_613297; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_613311 = newJObject()
  if body != nil:
    body_613311 = body
  result = call_613310.call(nil, nil, nil, nil, body_613311)

var updateUserProfile* = Call_UpdateUserProfile_613297(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_613298, base: "/",
    url: url_UpdateUserProfile_613299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkforce_613312 = ref object of OpenApiRestCall_610658
proc url_UpdateWorkforce_613314(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkforce_613313(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
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
  var valid_613315 = header.getOrDefault("X-Amz-Target")
  valid_613315 = validateParameter(valid_613315, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkforce"))
  if valid_613315 != nil:
    section.add "X-Amz-Target", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Signature")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Signature", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Content-Sha256", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Date")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Date", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Credential")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Credential", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Security-Token")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Security-Token", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Algorithm")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Algorithm", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-SignedHeaders", valid_613322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613324: Call_UpdateWorkforce_613312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_613324.validator(path, query, header, formData, body)
  let scheme = call_613324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613324.url(scheme.get, call_613324.host, call_613324.base,
                         call_613324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613324, url, valid)

proc call*(call_613325: Call_UpdateWorkforce_613312; body: JsonNode): Recallable =
  ## updateWorkforce
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_613326 = newJObject()
  if body != nil:
    body_613326 = body
  result = call_613325.call(nil, nil, nil, nil, body_613326)

var updateWorkforce* = Call_UpdateWorkforce_613312(name: "updateWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkforce",
    validator: validate_UpdateWorkforce_613313, base: "/", url: url_UpdateWorkforce_613314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_613327 = ref object of OpenApiRestCall_610658
proc url_UpdateWorkteam_613329(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkteam_613328(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing work team with new member definitions or description.
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
  var valid_613330 = header.getOrDefault("X-Amz-Target")
  valid_613330 = validateParameter(valid_613330, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_613330 != nil:
    section.add "X-Amz-Target", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Signature")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Signature", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Content-Sha256", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Date")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Date", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Credential")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Credential", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Security-Token")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Security-Token", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Algorithm")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Algorithm", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-SignedHeaders", valid_613337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613339: Call_UpdateWorkteam_613327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_613339.validator(path, query, header, formData, body)
  let scheme = call_613339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613339.url(scheme.get, call_613339.host, call_613339.base,
                         call_613339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613339, url, valid)

proc call*(call_613340: Call_UpdateWorkteam_613327; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_613341 = newJObject()
  if body != nil:
    body_613341 = body
  result = call_613340.call(nil, nil, nil, nil, body_613341)

var updateWorkteam* = Call_UpdateWorkteam_613327(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_613328, base: "/", url: url_UpdateWorkteam_613329,
    schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
