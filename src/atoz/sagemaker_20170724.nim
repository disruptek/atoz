
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
  Call_AddTags_612996 = ref object of OpenApiRestCall_612658
proc url_AddTags_612998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_612997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613123 = header.getOrDefault("X-Amz-Target")
  valid_613123 = validateParameter(valid_613123, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
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

proc call*(call_613154: Call_AddTags_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_AddTags_612996; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_613226 = newJObject()
  if body != nil:
    body_613226 = body
  result = call_613225.call(nil, nil, nil, nil, body_613226)

var addTags* = Call_AddTags_612996(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_612997, base: "/",
                                url: url_AddTags_612998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_613265 = ref object of OpenApiRestCall_612658
proc url_AssociateTrialComponent_613267(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateTrialComponent_613266(path: JsonNode; query: JsonNode;
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
  var valid_613268 = header.getOrDefault("X-Amz-Target")
  valid_613268 = validateParameter(valid_613268, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
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

proc call*(call_613277: Call_AssociateTrialComponent_613265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_613277.validator(path, query, header, formData, body)
  let scheme = call_613277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613277.url(scheme.get, call_613277.host, call_613277.base,
                         call_613277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613277, url, valid)

proc call*(call_613278: Call_AssociateTrialComponent_613265; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_613279 = newJObject()
  if body != nil:
    body_613279 = body
  result = call_613278.call(nil, nil, nil, nil, body_613279)

var associateTrialComponent* = Call_AssociateTrialComponent_613265(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_613266, base: "/",
    url: url_AssociateTrialComponent_613267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_613280 = ref object of OpenApiRestCall_612658
proc url_CreateAlgorithm_613282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlgorithm_613281(path: JsonNode; query: JsonNode;
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
  var valid_613283 = header.getOrDefault("X-Amz-Target")
  valid_613283 = validateParameter(valid_613283, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
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

proc call*(call_613292: Call_CreateAlgorithm_613280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_613292.validator(path, query, header, formData, body)
  let scheme = call_613292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613292.url(scheme.get, call_613292.host, call_613292.base,
                         call_613292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613292, url, valid)

proc call*(call_613293: Call_CreateAlgorithm_613280; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_613294 = newJObject()
  if body != nil:
    body_613294 = body
  result = call_613293.call(nil, nil, nil, nil, body_613294)

var createAlgorithm* = Call_CreateAlgorithm_613280(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_613281, base: "/", url: url_CreateAlgorithm_613282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_613295 = ref object of OpenApiRestCall_612658
proc url_CreateApp_613297(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_613296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613298 = header.getOrDefault("X-Amz-Target")
  valid_613298 = validateParameter(valid_613298, JString, required = true,
                                 default = newJString("SageMaker.CreateApp"))
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

proc call*(call_613307: Call_CreateApp_613295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_CreateApp_613295; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var createApp* = Call_CreateApp_613295(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                    validator: validate_CreateApp_613296,
                                    base: "/", url: url_CreateApp_613297,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_613310 = ref object of OpenApiRestCall_612658
proc url_CreateAutoMLJob_613312(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAutoMLJob_613311(path: JsonNode; query: JsonNode;
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
  var valid_613313 = header.getOrDefault("X-Amz-Target")
  valid_613313 = validateParameter(valid_613313, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
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

proc call*(call_613322: Call_CreateAutoMLJob_613310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_613322.validator(path, query, header, formData, body)
  let scheme = call_613322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613322.url(scheme.get, call_613322.host, call_613322.base,
                         call_613322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613322, url, valid)

proc call*(call_613323: Call_CreateAutoMLJob_613310; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_613324 = newJObject()
  if body != nil:
    body_613324 = body
  result = call_613323.call(nil, nil, nil, nil, body_613324)

var createAutoMLJob* = Call_CreateAutoMLJob_613310(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_613311, base: "/", url: url_CreateAutoMLJob_613312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_613325 = ref object of OpenApiRestCall_612658
proc url_CreateCodeRepository_613327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCodeRepository_613326(path: JsonNode; query: JsonNode;
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
  var valid_613328 = header.getOrDefault("X-Amz-Target")
  valid_613328 = validateParameter(valid_613328, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
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

proc call*(call_613337: Call_CreateCodeRepository_613325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_CreateCodeRepository_613325; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_613339 = newJObject()
  if body != nil:
    body_613339 = body
  result = call_613338.call(nil, nil, nil, nil, body_613339)

var createCodeRepository* = Call_CreateCodeRepository_613325(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_613326, base: "/",
    url: url_CreateCodeRepository_613327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_613340 = ref object of OpenApiRestCall_612658
proc url_CreateCompilationJob_613342(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCompilationJob_613341(path: JsonNode; query: JsonNode;
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
  var valid_613343 = header.getOrDefault("X-Amz-Target")
  valid_613343 = validateParameter(valid_613343, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
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

proc call*(call_613352: Call_CreateCompilationJob_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_613352.validator(path, query, header, formData, body)
  let scheme = call_613352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613352.url(scheme.get, call_613352.host, call_613352.base,
                         call_613352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613352, url, valid)

proc call*(call_613353: Call_CreateCompilationJob_613340; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_613354 = newJObject()
  if body != nil:
    body_613354 = body
  result = call_613353.call(nil, nil, nil, nil, body_613354)

var createCompilationJob* = Call_CreateCompilationJob_613340(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_613341, base: "/",
    url: url_CreateCompilationJob_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_613355 = ref object of OpenApiRestCall_612658
proc url_CreateDomain_613357(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomain_613356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613358 = header.getOrDefault("X-Amz-Target")
  valid_613358 = validateParameter(valid_613358, JString, required = true,
                                 default = newJString("SageMaker.CreateDomain"))
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

proc call*(call_613367: Call_CreateDomain_613355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_613367.validator(path, query, header, formData, body)
  let scheme = call_613367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613367.url(scheme.get, call_613367.host, call_613367.base,
                         call_613367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613367, url, valid)

proc call*(call_613368: Call_CreateDomain_613355; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_613369 = newJObject()
  if body != nil:
    body_613369 = body
  result = call_613368.call(nil, nil, nil, nil, body_613369)

var createDomain* = Call_CreateDomain_613355(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_613356, base: "/", url: url_CreateDomain_613357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_613370 = ref object of OpenApiRestCall_612658
proc url_CreateEndpoint_613372(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEndpoint_613371(path: JsonNode; query: JsonNode;
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
  var valid_613373 = header.getOrDefault("X-Amz-Target")
  valid_613373 = validateParameter(valid_613373, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
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

proc call*(call_613382: Call_CreateEndpoint_613370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_613382.validator(path, query, header, formData, body)
  let scheme = call_613382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613382.url(scheme.get, call_613382.host, call_613382.base,
                         call_613382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613382, url, valid)

proc call*(call_613383: Call_CreateEndpoint_613370; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_613384 = newJObject()
  if body != nil:
    body_613384 = body
  result = call_613383.call(nil, nil, nil, nil, body_613384)

var createEndpoint* = Call_CreateEndpoint_613370(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_613371, base: "/", url: url_CreateEndpoint_613372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_613385 = ref object of OpenApiRestCall_612658
proc url_CreateEndpointConfig_613387(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEndpointConfig_613386(path: JsonNode; query: JsonNode;
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
  var valid_613388 = header.getOrDefault("X-Amz-Target")
  valid_613388 = validateParameter(valid_613388, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
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

proc call*(call_613397: Call_CreateEndpointConfig_613385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_613397.validator(path, query, header, formData, body)
  let scheme = call_613397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613397.url(scheme.get, call_613397.host, call_613397.base,
                         call_613397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613397, url, valid)

proc call*(call_613398: Call_CreateEndpointConfig_613385; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_613399 = newJObject()
  if body != nil:
    body_613399 = body
  result = call_613398.call(nil, nil, nil, nil, body_613399)

var createEndpointConfig* = Call_CreateEndpointConfig_613385(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_613386, base: "/",
    url: url_CreateEndpointConfig_613387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_613400 = ref object of OpenApiRestCall_612658
proc url_CreateExperiment_613402(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExperiment_613401(path: JsonNode; query: JsonNode;
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
  var valid_613403 = header.getOrDefault("X-Amz-Target")
  valid_613403 = validateParameter(valid_613403, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
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

proc call*(call_613412: Call_CreateExperiment_613400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_613412.validator(path, query, header, formData, body)
  let scheme = call_613412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613412.url(scheme.get, call_613412.host, call_613412.base,
                         call_613412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613412, url, valid)

proc call*(call_613413: Call_CreateExperiment_613400; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_613414 = newJObject()
  if body != nil:
    body_613414 = body
  result = call_613413.call(nil, nil, nil, nil, body_613414)

var createExperiment* = Call_CreateExperiment_613400(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_613401, base: "/",
    url: url_CreateExperiment_613402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_613415 = ref object of OpenApiRestCall_612658
proc url_CreateFlowDefinition_613417(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFlowDefinition_613416(path: JsonNode; query: JsonNode;
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
  var valid_613418 = header.getOrDefault("X-Amz-Target")
  valid_613418 = validateParameter(valid_613418, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_CreateFlowDefinition_613415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_CreateFlowDefinition_613415; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_613429 = newJObject()
  if body != nil:
    body_613429 = body
  result = call_613428.call(nil, nil, nil, nil, body_613429)

var createFlowDefinition* = Call_CreateFlowDefinition_613415(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_613416, base: "/",
    url: url_CreateFlowDefinition_613417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_613430 = ref object of OpenApiRestCall_612658
proc url_CreateHumanTaskUi_613432(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHumanTaskUi_613431(path: JsonNode; query: JsonNode;
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
  var valid_613433 = header.getOrDefault("X-Amz-Target")
  valid_613433 = validateParameter(valid_613433, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_613433 != nil:
    section.add "X-Amz-Target", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_CreateHumanTaskUi_613430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_CreateHumanTaskUi_613430; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_613444 = newJObject()
  if body != nil:
    body_613444 = body
  result = call_613443.call(nil, nil, nil, nil, body_613444)

var createHumanTaskUi* = Call_CreateHumanTaskUi_613430(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_613431, base: "/",
    url: url_CreateHumanTaskUi_613432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_613445 = ref object of OpenApiRestCall_612658
proc url_CreateHyperParameterTuningJob_613447(protocol: Scheme; host: string;
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

proc validate_CreateHyperParameterTuningJob_613446(path: JsonNode; query: JsonNode;
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
  var valid_613448 = header.getOrDefault("X-Amz-Target")
  valid_613448 = validateParameter(valid_613448, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_613448 != nil:
    section.add "X-Amz-Target", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Signature")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Signature", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Content-Sha256", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Date")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Date", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Credential")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Credential", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Security-Token")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Security-Token", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Algorithm")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Algorithm", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-SignedHeaders", valid_613455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613457: Call_CreateHyperParameterTuningJob_613445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_613457.validator(path, query, header, formData, body)
  let scheme = call_613457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613457.url(scheme.get, call_613457.host, call_613457.base,
                         call_613457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613457, url, valid)

proc call*(call_613458: Call_CreateHyperParameterTuningJob_613445; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  result = call_613458.call(nil, nil, nil, nil, body_613459)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_613445(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_613446, base: "/",
    url: url_CreateHyperParameterTuningJob_613447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_613460 = ref object of OpenApiRestCall_612658
proc url_CreateLabelingJob_613462(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabelingJob_613461(path: JsonNode; query: JsonNode;
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
  var valid_613463 = header.getOrDefault("X-Amz-Target")
  valid_613463 = validateParameter(valid_613463, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_613463 != nil:
    section.add "X-Amz-Target", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613472: Call_CreateLabelingJob_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_613472.validator(path, query, header, formData, body)
  let scheme = call_613472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613472.url(scheme.get, call_613472.host, call_613472.base,
                         call_613472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613472, url, valid)

proc call*(call_613473: Call_CreateLabelingJob_613460; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_613474 = newJObject()
  if body != nil:
    body_613474 = body
  result = call_613473.call(nil, nil, nil, nil, body_613474)

var createLabelingJob* = Call_CreateLabelingJob_613460(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_613461, base: "/",
    url: url_CreateLabelingJob_613462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_613475 = ref object of OpenApiRestCall_612658
proc url_CreateModel_613477(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_613476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613478 = header.getOrDefault("X-Amz-Target")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_613478 != nil:
    section.add "X-Amz-Target", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_CreateModel_613475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_CreateModel_613475; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var createModel* = Call_CreateModel_613475(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_613476,
                                        base: "/", url: url_CreateModel_613477,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_613490 = ref object of OpenApiRestCall_612658
proc url_CreateModelPackage_613492(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModelPackage_613491(path: JsonNode; query: JsonNode;
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
  var valid_613493 = header.getOrDefault("X-Amz-Target")
  valid_613493 = validateParameter(valid_613493, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_613493 != nil:
    section.add "X-Amz-Target", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613502: Call_CreateModelPackage_613490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_613502.validator(path, query, header, formData, body)
  let scheme = call_613502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613502.url(scheme.get, call_613502.host, call_613502.base,
                         call_613502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613502, url, valid)

proc call*(call_613503: Call_CreateModelPackage_613490; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_613504 = newJObject()
  if body != nil:
    body_613504 = body
  result = call_613503.call(nil, nil, nil, nil, body_613504)

var createModelPackage* = Call_CreateModelPackage_613490(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_613491, base: "/",
    url: url_CreateModelPackage_613492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_613505 = ref object of OpenApiRestCall_612658
proc url_CreateMonitoringSchedule_613507(protocol: Scheme; host: string;
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

proc validate_CreateMonitoringSchedule_613506(path: JsonNode; query: JsonNode;
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
  var valid_613508 = header.getOrDefault("X-Amz-Target")
  valid_613508 = validateParameter(valid_613508, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
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

proc call*(call_613517: Call_CreateMonitoringSchedule_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_CreateMonitoringSchedule_613505; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_613519 = newJObject()
  if body != nil:
    body_613519 = body
  result = call_613518.call(nil, nil, nil, nil, body_613519)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_613505(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_613506, base: "/",
    url: url_CreateMonitoringSchedule_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_613520 = ref object of OpenApiRestCall_612658
proc url_CreateNotebookInstance_613522(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNotebookInstance_613521(path: JsonNode; query: JsonNode;
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
  var valid_613523 = header.getOrDefault("X-Amz-Target")
  valid_613523 = validateParameter(valid_613523, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_613523 != nil:
    section.add "X-Amz-Target", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_CreateNotebookInstance_613520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_CreateNotebookInstance_613520; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var createNotebookInstance* = Call_CreateNotebookInstance_613520(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_613521, base: "/",
    url: url_CreateNotebookInstance_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_613535 = ref object of OpenApiRestCall_612658
proc url_CreateNotebookInstanceLifecycleConfig_613537(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_613536(path: JsonNode;
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
  var valid_613538 = header.getOrDefault("X-Amz-Target")
  valid_613538 = validateParameter(valid_613538, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_613538 != nil:
    section.add "X-Amz-Target", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613547: Call_CreateNotebookInstanceLifecycleConfig_613535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_613547.validator(path, query, header, formData, body)
  let scheme = call_613547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613547.url(scheme.get, call_613547.host, call_613547.base,
                         call_613547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613547, url, valid)

proc call*(call_613548: Call_CreateNotebookInstanceLifecycleConfig_613535;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_613549 = newJObject()
  if body != nil:
    body_613549 = body
  result = call_613548.call(nil, nil, nil, nil, body_613549)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_613535(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_613536, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_613537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_613550 = ref object of OpenApiRestCall_612658
proc url_CreatePresignedDomainUrl_613552(protocol: Scheme; host: string;
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

proc validate_CreatePresignedDomainUrl_613551(path: JsonNode; query: JsonNode;
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
  var valid_613553 = header.getOrDefault("X-Amz-Target")
  valid_613553 = validateParameter(valid_613553, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_613553 != nil:
    section.add "X-Amz-Target", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Signature")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Signature", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Content-Sha256", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Date")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Date", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Credential")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Credential", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Security-Token")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Security-Token", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Algorithm")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Algorithm", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-SignedHeaders", valid_613560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_CreatePresignedDomainUrl_613550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_CreatePresignedDomainUrl_613550; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_613564 = newJObject()
  if body != nil:
    body_613564 = body
  result = call_613563.call(nil, nil, nil, nil, body_613564)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_613550(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_613551, base: "/",
    url: url_CreatePresignedDomainUrl_613552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_613565 = ref object of OpenApiRestCall_612658
proc url_CreatePresignedNotebookInstanceUrl_613567(protocol: Scheme; host: string;
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

proc validate_CreatePresignedNotebookInstanceUrl_613566(path: JsonNode;
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
  var valid_613568 = header.getOrDefault("X-Amz-Target")
  valid_613568 = validateParameter(valid_613568, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_613568 != nil:
    section.add "X-Amz-Target", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613577: Call_CreatePresignedNotebookInstanceUrl_613565;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_613577.validator(path, query, header, formData, body)
  let scheme = call_613577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613577.url(scheme.get, call_613577.host, call_613577.base,
                         call_613577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613577, url, valid)

proc call*(call_613578: Call_CreatePresignedNotebookInstanceUrl_613565;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_613579 = newJObject()
  if body != nil:
    body_613579 = body
  result = call_613578.call(nil, nil, nil, nil, body_613579)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_613565(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_613566, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_613567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_613580 = ref object of OpenApiRestCall_612658
proc url_CreateProcessingJob_613582(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProcessingJob_613581(path: JsonNode; query: JsonNode;
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
  var valid_613583 = header.getOrDefault("X-Amz-Target")
  valid_613583 = validateParameter(valid_613583, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_613583 != nil:
    section.add "X-Amz-Target", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613592: Call_CreateProcessingJob_613580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_613592.validator(path, query, header, formData, body)
  let scheme = call_613592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613592.url(scheme.get, call_613592.host, call_613592.base,
                         call_613592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613592, url, valid)

proc call*(call_613593: Call_CreateProcessingJob_613580; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_613594 = newJObject()
  if body != nil:
    body_613594 = body
  result = call_613593.call(nil, nil, nil, nil, body_613594)

var createProcessingJob* = Call_CreateProcessingJob_613580(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_613581, base: "/",
    url: url_CreateProcessingJob_613582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_613595 = ref object of OpenApiRestCall_612658
proc url_CreateTrainingJob_613597(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrainingJob_613596(path: JsonNode; query: JsonNode;
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
  var valid_613598 = header.getOrDefault("X-Amz-Target")
  valid_613598 = validateParameter(valid_613598, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_613598 != nil:
    section.add "X-Amz-Target", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_CreateTrainingJob_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_CreateTrainingJob_613595; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_613609 = newJObject()
  if body != nil:
    body_613609 = body
  result = call_613608.call(nil, nil, nil, nil, body_613609)

var createTrainingJob* = Call_CreateTrainingJob_613595(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_613596, base: "/",
    url: url_CreateTrainingJob_613597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_613610 = ref object of OpenApiRestCall_612658
proc url_CreateTransformJob_613612(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTransformJob_613611(path: JsonNode; query: JsonNode;
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
  var valid_613613 = header.getOrDefault("X-Amz-Target")
  valid_613613 = validateParameter(valid_613613, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_613613 != nil:
    section.add "X-Amz-Target", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613622: Call_CreateTransformJob_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_613622.validator(path, query, header, formData, body)
  let scheme = call_613622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613622.url(scheme.get, call_613622.host, call_613622.base,
                         call_613622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613622, url, valid)

proc call*(call_613623: Call_CreateTransformJob_613610; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_613624 = newJObject()
  if body != nil:
    body_613624 = body
  result = call_613623.call(nil, nil, nil, nil, body_613624)

var createTransformJob* = Call_CreateTransformJob_613610(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_613611, base: "/",
    url: url_CreateTransformJob_613612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_613625 = ref object of OpenApiRestCall_612658
proc url_CreateTrial_613627(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrial_613626(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613628 = header.getOrDefault("X-Amz-Target")
  valid_613628 = validateParameter(valid_613628, JString, required = true,
                                 default = newJString("SageMaker.CreateTrial"))
  if valid_613628 != nil:
    section.add "X-Amz-Target", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Signature")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Signature", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Content-Sha256", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Date")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Date", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Credential")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Credential", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Security-Token")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Security-Token", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Algorithm")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Algorithm", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-SignedHeaders", valid_613635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613637: Call_CreateTrial_613625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_613637.validator(path, query, header, formData, body)
  let scheme = call_613637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613637.url(scheme.get, call_613637.host, call_613637.base,
                         call_613637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613637, url, valid)

proc call*(call_613638: Call_CreateTrial_613625; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_613639 = newJObject()
  if body != nil:
    body_613639 = body
  result = call_613638.call(nil, nil, nil, nil, body_613639)

var createTrial* = Call_CreateTrial_613625(name: "createTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateTrial",
                                        validator: validate_CreateTrial_613626,
                                        base: "/", url: url_CreateTrial_613627,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_613640 = ref object of OpenApiRestCall_612658
proc url_CreateTrialComponent_613642(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrialComponent_613641(path: JsonNode; query: JsonNode;
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
  var valid_613643 = header.getOrDefault("X-Amz-Target")
  valid_613643 = validateParameter(valid_613643, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_613643 != nil:
    section.add "X-Amz-Target", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Signature")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Signature", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Content-Sha256", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Date")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Date", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Credential")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Credential", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Security-Token")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Security-Token", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Algorithm")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Algorithm", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-SignedHeaders", valid_613650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613652: Call_CreateTrialComponent_613640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ## 
  let valid = call_613652.validator(path, query, header, formData, body)
  let scheme = call_613652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613652.url(scheme.get, call_613652.host, call_613652.base,
                         call_613652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613652, url, valid)

proc call*(call_613653: Call_CreateTrialComponent_613640; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   body: JObject (required)
  var body_613654 = newJObject()
  if body != nil:
    body_613654 = body
  result = call_613653.call(nil, nil, nil, nil, body_613654)

var createTrialComponent* = Call_CreateTrialComponent_613640(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_613641, base: "/",
    url: url_CreateTrialComponent_613642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_613655 = ref object of OpenApiRestCall_612658
proc url_CreateUserProfile_613657(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserProfile_613656(path: JsonNode; query: JsonNode;
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
  var valid_613658 = header.getOrDefault("X-Amz-Target")
  valid_613658 = validateParameter(valid_613658, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_613658 != nil:
    section.add "X-Amz-Target", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Signature")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Signature", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Content-Sha256", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Date")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Date", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Credential")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Credential", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Security-Token")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Security-Token", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Algorithm")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Algorithm", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-SignedHeaders", valid_613665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_CreateUserProfile_613655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_CreateUserProfile_613655; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_613669 = newJObject()
  if body != nil:
    body_613669 = body
  result = call_613668.call(nil, nil, nil, nil, body_613669)

var createUserProfile* = Call_CreateUserProfile_613655(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_613656, base: "/",
    url: url_CreateUserProfile_613657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_613670 = ref object of OpenApiRestCall_612658
proc url_CreateWorkteam_613672(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkteam_613671(path: JsonNode; query: JsonNode;
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
  var valid_613673 = header.getOrDefault("X-Amz-Target")
  valid_613673 = validateParameter(valid_613673, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_613673 != nil:
    section.add "X-Amz-Target", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_CreateWorkteam_613670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_CreateWorkteam_613670; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_613684 = newJObject()
  if body != nil:
    body_613684 = body
  result = call_613683.call(nil, nil, nil, nil, body_613684)

var createWorkteam* = Call_CreateWorkteam_613670(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_613671, base: "/", url: url_CreateWorkteam_613672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_613685 = ref object of OpenApiRestCall_612658
proc url_DeleteAlgorithm_613687(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlgorithm_613686(path: JsonNode; query: JsonNode;
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
  var valid_613688 = header.getOrDefault("X-Amz-Target")
  valid_613688 = validateParameter(valid_613688, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_613688 != nil:
    section.add "X-Amz-Target", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_DeleteAlgorithm_613685; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_DeleteAlgorithm_613685; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_613699 = newJObject()
  if body != nil:
    body_613699 = body
  result = call_613698.call(nil, nil, nil, nil, body_613699)

var deleteAlgorithm* = Call_DeleteAlgorithm_613685(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_613686, base: "/", url: url_DeleteAlgorithm_613687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_613700 = ref object of OpenApiRestCall_612658
proc url_DeleteApp_613702(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_613701(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613703 = header.getOrDefault("X-Amz-Target")
  valid_613703 = validateParameter(valid_613703, JString, required = true,
                                 default = newJString("SageMaker.DeleteApp"))
  if valid_613703 != nil:
    section.add "X-Amz-Target", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Signature")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Signature", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Content-Sha256", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Date")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Date", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Credential")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Credential", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Security-Token")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Security-Token", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Algorithm")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Algorithm", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-SignedHeaders", valid_613710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613712: Call_DeleteApp_613700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_613712.validator(path, query, header, formData, body)
  let scheme = call_613712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613712.url(scheme.get, call_613712.host, call_613712.base,
                         call_613712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613712, url, valid)

proc call*(call_613713: Call_DeleteApp_613700; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_613714 = newJObject()
  if body != nil:
    body_613714 = body
  result = call_613713.call(nil, nil, nil, nil, body_613714)

var deleteApp* = Call_DeleteApp_613700(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                    validator: validate_DeleteApp_613701,
                                    base: "/", url: url_DeleteApp_613702,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_613715 = ref object of OpenApiRestCall_612658
proc url_DeleteCodeRepository_613717(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCodeRepository_613716(path: JsonNode; query: JsonNode;
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
  var valid_613718 = header.getOrDefault("X-Amz-Target")
  valid_613718 = validateParameter(valid_613718, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_613718 != nil:
    section.add "X-Amz-Target", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Signature")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Signature", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Content-Sha256", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Date")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Date", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Credential")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Credential", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Security-Token")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Security-Token", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Algorithm")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Algorithm", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-SignedHeaders", valid_613725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613727: Call_DeleteCodeRepository_613715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_613727.validator(path, query, header, formData, body)
  let scheme = call_613727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613727.url(scheme.get, call_613727.host, call_613727.base,
                         call_613727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613727, url, valid)

proc call*(call_613728: Call_DeleteCodeRepository_613715; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_613729 = newJObject()
  if body != nil:
    body_613729 = body
  result = call_613728.call(nil, nil, nil, nil, body_613729)

var deleteCodeRepository* = Call_DeleteCodeRepository_613715(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_613716, base: "/",
    url: url_DeleteCodeRepository_613717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_613730 = ref object of OpenApiRestCall_612658
proc url_DeleteDomain_613732(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomain_613731(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613733 = header.getOrDefault("X-Amz-Target")
  valid_613733 = validateParameter(valid_613733, JString, required = true,
                                 default = newJString("SageMaker.DeleteDomain"))
  if valid_613733 != nil:
    section.add "X-Amz-Target", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Signature")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Signature", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Content-Sha256", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Date")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Date", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-Credential")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-Credential", valid_613737
  var valid_613738 = header.getOrDefault("X-Amz-Security-Token")
  valid_613738 = validateParameter(valid_613738, JString, required = false,
                                 default = nil)
  if valid_613738 != nil:
    section.add "X-Amz-Security-Token", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Algorithm")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Algorithm", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-SignedHeaders", valid_613740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613742: Call_DeleteDomain_613730; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_613742.validator(path, query, header, formData, body)
  let scheme = call_613742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613742.url(scheme.get, call_613742.host, call_613742.base,
                         call_613742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613742, url, valid)

proc call*(call_613743: Call_DeleteDomain_613730; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_613744 = newJObject()
  if body != nil:
    body_613744 = body
  result = call_613743.call(nil, nil, nil, nil, body_613744)

var deleteDomain* = Call_DeleteDomain_613730(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_613731, base: "/", url: url_DeleteDomain_613732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_613745 = ref object of OpenApiRestCall_612658
proc url_DeleteEndpoint_613747(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_613746(path: JsonNode; query: JsonNode;
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
  var valid_613748 = header.getOrDefault("X-Amz-Target")
  valid_613748 = validateParameter(valid_613748, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_613748 != nil:
    section.add "X-Amz-Target", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Signature")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Signature", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Content-Sha256", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Date")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Date", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Credential")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Credential", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-Security-Token")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-Security-Token", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Algorithm")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Algorithm", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-SignedHeaders", valid_613755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613757: Call_DeleteEndpoint_613745; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_613757.validator(path, query, header, formData, body)
  let scheme = call_613757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613757.url(scheme.get, call_613757.host, call_613757.base,
                         call_613757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613757, url, valid)

proc call*(call_613758: Call_DeleteEndpoint_613745; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_613759 = newJObject()
  if body != nil:
    body_613759 = body
  result = call_613758.call(nil, nil, nil, nil, body_613759)

var deleteEndpoint* = Call_DeleteEndpoint_613745(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_613746, base: "/", url: url_DeleteEndpoint_613747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_613760 = ref object of OpenApiRestCall_612658
proc url_DeleteEndpointConfig_613762(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpointConfig_613761(path: JsonNode; query: JsonNode;
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
  var valid_613763 = header.getOrDefault("X-Amz-Target")
  valid_613763 = validateParameter(valid_613763, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_613763 != nil:
    section.add "X-Amz-Target", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613772: Call_DeleteEndpointConfig_613760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_613772.validator(path, query, header, formData, body)
  let scheme = call_613772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613772.url(scheme.get, call_613772.host, call_613772.base,
                         call_613772.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613772, url, valid)

proc call*(call_613773: Call_DeleteEndpointConfig_613760; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_613774 = newJObject()
  if body != nil:
    body_613774 = body
  result = call_613773.call(nil, nil, nil, nil, body_613774)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_613760(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_613761, base: "/",
    url: url_DeleteEndpointConfig_613762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_613775 = ref object of OpenApiRestCall_612658
proc url_DeleteExperiment_613777(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteExperiment_613776(path: JsonNode; query: JsonNode;
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
  var valid_613778 = header.getOrDefault("X-Amz-Target")
  valid_613778 = validateParameter(valid_613778, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_613778 != nil:
    section.add "X-Amz-Target", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Signature")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Signature", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Content-Sha256", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Date")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Date", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Credential")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Credential", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Security-Token")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Security-Token", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Algorithm")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Algorithm", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-SignedHeaders", valid_613785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613787: Call_DeleteExperiment_613775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_613787.validator(path, query, header, formData, body)
  let scheme = call_613787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613787.url(scheme.get, call_613787.host, call_613787.base,
                         call_613787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613787, url, valid)

proc call*(call_613788: Call_DeleteExperiment_613775; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_613789 = newJObject()
  if body != nil:
    body_613789 = body
  result = call_613788.call(nil, nil, nil, nil, body_613789)

var deleteExperiment* = Call_DeleteExperiment_613775(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_613776, base: "/",
    url: url_DeleteExperiment_613777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_613790 = ref object of OpenApiRestCall_612658
proc url_DeleteFlowDefinition_613792(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFlowDefinition_613791(path: JsonNode; query: JsonNode;
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
  var valid_613793 = header.getOrDefault("X-Amz-Target")
  valid_613793 = validateParameter(valid_613793, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_613793 != nil:
    section.add "X-Amz-Target", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Signature")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Signature", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Content-Sha256", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Date")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Date", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Credential")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Credential", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Security-Token")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Security-Token", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Algorithm")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Algorithm", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-SignedHeaders", valid_613800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613802: Call_DeleteFlowDefinition_613790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_613802.validator(path, query, header, formData, body)
  let scheme = call_613802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613802.url(scheme.get, call_613802.host, call_613802.base,
                         call_613802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613802, url, valid)

proc call*(call_613803: Call_DeleteFlowDefinition_613790; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_613804 = newJObject()
  if body != nil:
    body_613804 = body
  result = call_613803.call(nil, nil, nil, nil, body_613804)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_613790(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_613791, base: "/",
    url: url_DeleteFlowDefinition_613792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_613805 = ref object of OpenApiRestCall_612658
proc url_DeleteModel_613807(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_613806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613808 = header.getOrDefault("X-Amz-Target")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_613808 != nil:
    section.add "X-Amz-Target", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Security-Token")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Security-Token", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Algorithm")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Algorithm", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-SignedHeaders", valid_613815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_DeleteModel_613805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_DeleteModel_613805; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_613819 = newJObject()
  if body != nil:
    body_613819 = body
  result = call_613818.call(nil, nil, nil, nil, body_613819)

var deleteModel* = Call_DeleteModel_613805(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_613806,
                                        base: "/", url: url_DeleteModel_613807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_613820 = ref object of OpenApiRestCall_612658
proc url_DeleteModelPackage_613822(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModelPackage_613821(path: JsonNode; query: JsonNode;
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
  var valid_613823 = header.getOrDefault("X-Amz-Target")
  valid_613823 = validateParameter(valid_613823, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_613823 != nil:
    section.add "X-Amz-Target", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Signature")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Signature", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Content-Sha256", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Date")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Date", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Credential")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Credential", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Security-Token")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Security-Token", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Algorithm")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Algorithm", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-SignedHeaders", valid_613830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_DeleteModelPackage_613820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_DeleteModelPackage_613820; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  result = call_613833.call(nil, nil, nil, nil, body_613834)

var deleteModelPackage* = Call_DeleteModelPackage_613820(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_613821, base: "/",
    url: url_DeleteModelPackage_613822, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_613835 = ref object of OpenApiRestCall_612658
proc url_DeleteMonitoringSchedule_613837(protocol: Scheme; host: string;
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

proc validate_DeleteMonitoringSchedule_613836(path: JsonNode; query: JsonNode;
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
  var valid_613838 = header.getOrDefault("X-Amz-Target")
  valid_613838 = validateParameter(valid_613838, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_613838 != nil:
    section.add "X-Amz-Target", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-Signature")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-Signature", valid_613839
  var valid_613840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613840 = validateParameter(valid_613840, JString, required = false,
                                 default = nil)
  if valid_613840 != nil:
    section.add "X-Amz-Content-Sha256", valid_613840
  var valid_613841 = header.getOrDefault("X-Amz-Date")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Date", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Credential")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Credential", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Security-Token")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Security-Token", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Algorithm")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Algorithm", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-SignedHeaders", valid_613845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613847: Call_DeleteMonitoringSchedule_613835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_613847.validator(path, query, header, formData, body)
  let scheme = call_613847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613847.url(scheme.get, call_613847.host, call_613847.base,
                         call_613847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613847, url, valid)

proc call*(call_613848: Call_DeleteMonitoringSchedule_613835; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_613849 = newJObject()
  if body != nil:
    body_613849 = body
  result = call_613848.call(nil, nil, nil, nil, body_613849)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_613835(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_613836, base: "/",
    url: url_DeleteMonitoringSchedule_613837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_613850 = ref object of OpenApiRestCall_612658
proc url_DeleteNotebookInstance_613852(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNotebookInstance_613851(path: JsonNode; query: JsonNode;
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
  var valid_613853 = header.getOrDefault("X-Amz-Target")
  valid_613853 = validateParameter(valid_613853, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_613853 != nil:
    section.add "X-Amz-Target", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-Signature")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-Signature", valid_613854
  var valid_613855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "X-Amz-Content-Sha256", valid_613855
  var valid_613856 = header.getOrDefault("X-Amz-Date")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Date", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Credential")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Credential", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Security-Token")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Security-Token", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Algorithm")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Algorithm", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-SignedHeaders", valid_613860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613862: Call_DeleteNotebookInstance_613850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_613862.validator(path, query, header, formData, body)
  let scheme = call_613862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613862.url(scheme.get, call_613862.host, call_613862.base,
                         call_613862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613862, url, valid)

proc call*(call_613863: Call_DeleteNotebookInstance_613850; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_613864 = newJObject()
  if body != nil:
    body_613864 = body
  result = call_613863.call(nil, nil, nil, nil, body_613864)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_613850(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_613851, base: "/",
    url: url_DeleteNotebookInstance_613852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_613865 = ref object of OpenApiRestCall_612658
proc url_DeleteNotebookInstanceLifecycleConfig_613867(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_613866(path: JsonNode;
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
  var valid_613868 = header.getOrDefault("X-Amz-Target")
  valid_613868 = validateParameter(valid_613868, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_613868 != nil:
    section.add "X-Amz-Target", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Signature")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Signature", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Content-Sha256", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-Date")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-Date", valid_613871
  var valid_613872 = header.getOrDefault("X-Amz-Credential")
  valid_613872 = validateParameter(valid_613872, JString, required = false,
                                 default = nil)
  if valid_613872 != nil:
    section.add "X-Amz-Credential", valid_613872
  var valid_613873 = header.getOrDefault("X-Amz-Security-Token")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Security-Token", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Algorithm")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Algorithm", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-SignedHeaders", valid_613875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613877: Call_DeleteNotebookInstanceLifecycleConfig_613865;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_613877.validator(path, query, header, formData, body)
  let scheme = call_613877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613877.url(scheme.get, call_613877.host, call_613877.base,
                         call_613877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613877, url, valid)

proc call*(call_613878: Call_DeleteNotebookInstanceLifecycleConfig_613865;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_613879 = newJObject()
  if body != nil:
    body_613879 = body
  result = call_613878.call(nil, nil, nil, nil, body_613879)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_613865(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_613866, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_613867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_613880 = ref object of OpenApiRestCall_612658
proc url_DeleteTags_613882(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_613881(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613883 = header.getOrDefault("X-Amz-Target")
  valid_613883 = validateParameter(valid_613883, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_613883 != nil:
    section.add "X-Amz-Target", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Signature")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Signature", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Content-Sha256", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-Date")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-Date", valid_613886
  var valid_613887 = header.getOrDefault("X-Amz-Credential")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Credential", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Security-Token")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Security-Token", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Algorithm")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Algorithm", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-SignedHeaders", valid_613890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613892: Call_DeleteTags_613880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_613892.validator(path, query, header, formData, body)
  let scheme = call_613892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613892.url(scheme.get, call_613892.host, call_613892.base,
                         call_613892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613892, url, valid)

proc call*(call_613893: Call_DeleteTags_613880; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_613894 = newJObject()
  if body != nil:
    body_613894 = body
  result = call_613893.call(nil, nil, nil, nil, body_613894)

var deleteTags* = Call_DeleteTags_613880(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_613881,
                                      base: "/", url: url_DeleteTags_613882,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_613895 = ref object of OpenApiRestCall_612658
proc url_DeleteTrial_613897(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrial_613896(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613898 = header.getOrDefault("X-Amz-Target")
  valid_613898 = validateParameter(valid_613898, JString, required = true,
                                 default = newJString("SageMaker.DeleteTrial"))
  if valid_613898 != nil:
    section.add "X-Amz-Target", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613907: Call_DeleteTrial_613895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_613907.validator(path, query, header, formData, body)
  let scheme = call_613907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613907.url(scheme.get, call_613907.host, call_613907.base,
                         call_613907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613907, url, valid)

proc call*(call_613908: Call_DeleteTrial_613895; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_613909 = newJObject()
  if body != nil:
    body_613909 = body
  result = call_613908.call(nil, nil, nil, nil, body_613909)

var deleteTrial* = Call_DeleteTrial_613895(name: "deleteTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTrial",
                                        validator: validate_DeleteTrial_613896,
                                        base: "/", url: url_DeleteTrial_613897,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_613910 = ref object of OpenApiRestCall_612658
proc url_DeleteTrialComponent_613912(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrialComponent_613911(path: JsonNode; query: JsonNode;
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
  var valid_613913 = header.getOrDefault("X-Amz-Target")
  valid_613913 = validateParameter(valid_613913, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_613913 != nil:
    section.add "X-Amz-Target", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613922: Call_DeleteTrialComponent_613910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_613922.validator(path, query, header, formData, body)
  let scheme = call_613922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613922.url(scheme.get, call_613922.host, call_613922.base,
                         call_613922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613922, url, valid)

proc call*(call_613923: Call_DeleteTrialComponent_613910; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_613924 = newJObject()
  if body != nil:
    body_613924 = body
  result = call_613923.call(nil, nil, nil, nil, body_613924)

var deleteTrialComponent* = Call_DeleteTrialComponent_613910(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_613911, base: "/",
    url: url_DeleteTrialComponent_613912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_613925 = ref object of OpenApiRestCall_612658
proc url_DeleteUserProfile_613927(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserProfile_613926(path: JsonNode; query: JsonNode;
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
  var valid_613928 = header.getOrDefault("X-Amz-Target")
  valid_613928 = validateParameter(valid_613928, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_613928 != nil:
    section.add "X-Amz-Target", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613937: Call_DeleteUserProfile_613925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_613937.validator(path, query, header, formData, body)
  let scheme = call_613937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613937.url(scheme.get, call_613937.host, call_613937.base,
                         call_613937.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613937, url, valid)

proc call*(call_613938: Call_DeleteUserProfile_613925; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_613939 = newJObject()
  if body != nil:
    body_613939 = body
  result = call_613938.call(nil, nil, nil, nil, body_613939)

var deleteUserProfile* = Call_DeleteUserProfile_613925(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_613926, base: "/",
    url: url_DeleteUserProfile_613927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_613940 = ref object of OpenApiRestCall_612658
proc url_DeleteWorkteam_613942(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkteam_613941(path: JsonNode; query: JsonNode;
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
  var valid_613943 = header.getOrDefault("X-Amz-Target")
  valid_613943 = validateParameter(valid_613943, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_613943 != nil:
    section.add "X-Amz-Target", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Signature")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Signature", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Content-Sha256", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Date")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Date", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Credential")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Credential", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Security-Token")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Security-Token", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-Algorithm")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-Algorithm", valid_613949
  var valid_613950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-SignedHeaders", valid_613950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613952: Call_DeleteWorkteam_613940; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_613952.validator(path, query, header, formData, body)
  let scheme = call_613952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613952.url(scheme.get, call_613952.host, call_613952.base,
                         call_613952.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613952, url, valid)

proc call*(call_613953: Call_DeleteWorkteam_613940; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_613954 = newJObject()
  if body != nil:
    body_613954 = body
  result = call_613953.call(nil, nil, nil, nil, body_613954)

var deleteWorkteam* = Call_DeleteWorkteam_613940(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_613941, base: "/", url: url_DeleteWorkteam_613942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_613955 = ref object of OpenApiRestCall_612658
proc url_DescribeAlgorithm_613957(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAlgorithm_613956(path: JsonNode; query: JsonNode;
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
  var valid_613958 = header.getOrDefault("X-Amz-Target")
  valid_613958 = validateParameter(valid_613958, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_613958 != nil:
    section.add "X-Amz-Target", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Signature")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Signature", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Content-Sha256", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Date")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Date", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Credential")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Credential", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-Security-Token")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-Security-Token", valid_613963
  var valid_613964 = header.getOrDefault("X-Amz-Algorithm")
  valid_613964 = validateParameter(valid_613964, JString, required = false,
                                 default = nil)
  if valid_613964 != nil:
    section.add "X-Amz-Algorithm", valid_613964
  var valid_613965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "X-Amz-SignedHeaders", valid_613965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613967: Call_DescribeAlgorithm_613955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_613967.validator(path, query, header, formData, body)
  let scheme = call_613967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613967.url(scheme.get, call_613967.host, call_613967.base,
                         call_613967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613967, url, valid)

proc call*(call_613968: Call_DescribeAlgorithm_613955; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_613969 = newJObject()
  if body != nil:
    body_613969 = body
  result = call_613968.call(nil, nil, nil, nil, body_613969)

var describeAlgorithm* = Call_DescribeAlgorithm_613955(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_613956, base: "/",
    url: url_DescribeAlgorithm_613957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_613970 = ref object of OpenApiRestCall_612658
proc url_DescribeApp_613972(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeApp_613971(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613973 = header.getOrDefault("X-Amz-Target")
  valid_613973 = validateParameter(valid_613973, JString, required = true,
                                 default = newJString("SageMaker.DescribeApp"))
  if valid_613973 != nil:
    section.add "X-Amz-Target", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Signature")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Signature", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Content-Sha256", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Date")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Date", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Credential")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Credential", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Security-Token")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Security-Token", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Algorithm")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Algorithm", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-SignedHeaders", valid_613980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613982: Call_DescribeApp_613970; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the app.
  ## 
  let valid = call_613982.validator(path, query, header, formData, body)
  let scheme = call_613982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613982.url(scheme.get, call_613982.host, call_613982.base,
                         call_613982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613982, url, valid)

proc call*(call_613983: Call_DescribeApp_613970; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_613984 = newJObject()
  if body != nil:
    body_613984 = body
  result = call_613983.call(nil, nil, nil, nil, body_613984)

var describeApp* = Call_DescribeApp_613970(name: "describeApp",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DescribeApp",
                                        validator: validate_DescribeApp_613971,
                                        base: "/", url: url_DescribeApp_613972,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_613985 = ref object of OpenApiRestCall_612658
proc url_DescribeAutoMLJob_613987(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAutoMLJob_613986(path: JsonNode; query: JsonNode;
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
  var valid_613988 = header.getOrDefault("X-Amz-Target")
  valid_613988 = validateParameter(valid_613988, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_613988 != nil:
    section.add "X-Amz-Target", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Signature")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Signature", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Content-Sha256", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Date")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Date", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Credential")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Credential", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Security-Token")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Security-Token", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Algorithm")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Algorithm", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-SignedHeaders", valid_613995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_DescribeAutoMLJob_613985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_DescribeAutoMLJob_613985; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_613999 = newJObject()
  if body != nil:
    body_613999 = body
  result = call_613998.call(nil, nil, nil, nil, body_613999)

var describeAutoMLJob* = Call_DescribeAutoMLJob_613985(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_613986, base: "/",
    url: url_DescribeAutoMLJob_613987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_614000 = ref object of OpenApiRestCall_612658
proc url_DescribeCodeRepository_614002(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeRepository_614001(path: JsonNode; query: JsonNode;
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
  var valid_614003 = header.getOrDefault("X-Amz-Target")
  valid_614003 = validateParameter(valid_614003, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_614003 != nil:
    section.add "X-Amz-Target", valid_614003
  var valid_614004 = header.getOrDefault("X-Amz-Signature")
  valid_614004 = validateParameter(valid_614004, JString, required = false,
                                 default = nil)
  if valid_614004 != nil:
    section.add "X-Amz-Signature", valid_614004
  var valid_614005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Content-Sha256", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Date")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Date", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Credential")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Credential", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Security-Token")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Security-Token", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Algorithm")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Algorithm", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-SignedHeaders", valid_614010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614012: Call_DescribeCodeRepository_614000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_614012.validator(path, query, header, formData, body)
  let scheme = call_614012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614012.url(scheme.get, call_614012.host, call_614012.base,
                         call_614012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614012, url, valid)

proc call*(call_614013: Call_DescribeCodeRepository_614000; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_614014 = newJObject()
  if body != nil:
    body_614014 = body
  result = call_614013.call(nil, nil, nil, nil, body_614014)

var describeCodeRepository* = Call_DescribeCodeRepository_614000(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_614001, base: "/",
    url: url_DescribeCodeRepository_614002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_614015 = ref object of OpenApiRestCall_612658
proc url_DescribeCompilationJob_614017(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCompilationJob_614016(path: JsonNode; query: JsonNode;
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
  var valid_614018 = header.getOrDefault("X-Amz-Target")
  valid_614018 = validateParameter(valid_614018, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_614018 != nil:
    section.add "X-Amz-Target", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-Signature")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-Signature", valid_614019
  var valid_614020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614020 = validateParameter(valid_614020, JString, required = false,
                                 default = nil)
  if valid_614020 != nil:
    section.add "X-Amz-Content-Sha256", valid_614020
  var valid_614021 = header.getOrDefault("X-Amz-Date")
  valid_614021 = validateParameter(valid_614021, JString, required = false,
                                 default = nil)
  if valid_614021 != nil:
    section.add "X-Amz-Date", valid_614021
  var valid_614022 = header.getOrDefault("X-Amz-Credential")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Credential", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Security-Token")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Security-Token", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Algorithm")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Algorithm", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-SignedHeaders", valid_614025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614027: Call_DescribeCompilationJob_614015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_614027.validator(path, query, header, formData, body)
  let scheme = call_614027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614027.url(scheme.get, call_614027.host, call_614027.base,
                         call_614027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614027, url, valid)

proc call*(call_614028: Call_DescribeCompilationJob_614015; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_614029 = newJObject()
  if body != nil:
    body_614029 = body
  result = call_614028.call(nil, nil, nil, nil, body_614029)

var describeCompilationJob* = Call_DescribeCompilationJob_614015(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_614016, base: "/",
    url: url_DescribeCompilationJob_614017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_614030 = ref object of OpenApiRestCall_612658
proc url_DescribeDomain_614032(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDomain_614031(path: JsonNode; query: JsonNode;
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
  var valid_614033 = header.getOrDefault("X-Amz-Target")
  valid_614033 = validateParameter(valid_614033, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_614033 != nil:
    section.add "X-Amz-Target", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-Signature")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-Signature", valid_614034
  var valid_614035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "X-Amz-Content-Sha256", valid_614035
  var valid_614036 = header.getOrDefault("X-Amz-Date")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "X-Amz-Date", valid_614036
  var valid_614037 = header.getOrDefault("X-Amz-Credential")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Credential", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Security-Token")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Security-Token", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Algorithm")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Algorithm", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-SignedHeaders", valid_614040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614042: Call_DescribeDomain_614030; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_614042.validator(path, query, header, formData, body)
  let scheme = call_614042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614042.url(scheme.get, call_614042.host, call_614042.base,
                         call_614042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614042, url, valid)

proc call*(call_614043: Call_DescribeDomain_614030; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_614044 = newJObject()
  if body != nil:
    body_614044 = body
  result = call_614043.call(nil, nil, nil, nil, body_614044)

var describeDomain* = Call_DescribeDomain_614030(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_614031, base: "/", url: url_DescribeDomain_614032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_614045 = ref object of OpenApiRestCall_612658
proc url_DescribeEndpoint_614047(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpoint_614046(path: JsonNode; query: JsonNode;
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
  var valid_614048 = header.getOrDefault("X-Amz-Target")
  valid_614048 = validateParameter(valid_614048, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_614048 != nil:
    section.add "X-Amz-Target", valid_614048
  var valid_614049 = header.getOrDefault("X-Amz-Signature")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "X-Amz-Signature", valid_614049
  var valid_614050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Content-Sha256", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Date")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Date", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Credential")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Credential", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Security-Token")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Security-Token", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Algorithm")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Algorithm", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-SignedHeaders", valid_614055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614057: Call_DescribeEndpoint_614045; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_614057.validator(path, query, header, formData, body)
  let scheme = call_614057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614057.url(scheme.get, call_614057.host, call_614057.base,
                         call_614057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614057, url, valid)

proc call*(call_614058: Call_DescribeEndpoint_614045; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_614059 = newJObject()
  if body != nil:
    body_614059 = body
  result = call_614058.call(nil, nil, nil, nil, body_614059)

var describeEndpoint* = Call_DescribeEndpoint_614045(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_614046, base: "/",
    url: url_DescribeEndpoint_614047, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_614060 = ref object of OpenApiRestCall_612658
proc url_DescribeEndpointConfig_614062(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpointConfig_614061(path: JsonNode; query: JsonNode;
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
  var valid_614063 = header.getOrDefault("X-Amz-Target")
  valid_614063 = validateParameter(valid_614063, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_614063 != nil:
    section.add "X-Amz-Target", valid_614063
  var valid_614064 = header.getOrDefault("X-Amz-Signature")
  valid_614064 = validateParameter(valid_614064, JString, required = false,
                                 default = nil)
  if valid_614064 != nil:
    section.add "X-Amz-Signature", valid_614064
  var valid_614065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Content-Sha256", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Date")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Date", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Credential")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Credential", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Security-Token")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Security-Token", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Algorithm")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Algorithm", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-SignedHeaders", valid_614070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614072: Call_DescribeEndpointConfig_614060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_614072.validator(path, query, header, formData, body)
  let scheme = call_614072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614072.url(scheme.get, call_614072.host, call_614072.base,
                         call_614072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614072, url, valid)

proc call*(call_614073: Call_DescribeEndpointConfig_614060; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_614074 = newJObject()
  if body != nil:
    body_614074 = body
  result = call_614073.call(nil, nil, nil, nil, body_614074)

var describeEndpointConfig* = Call_DescribeEndpointConfig_614060(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_614061, base: "/",
    url: url_DescribeEndpointConfig_614062, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_614075 = ref object of OpenApiRestCall_612658
proc url_DescribeExperiment_614077(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExperiment_614076(path: JsonNode; query: JsonNode;
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
  var valid_614078 = header.getOrDefault("X-Amz-Target")
  valid_614078 = validateParameter(valid_614078, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_614078 != nil:
    section.add "X-Amz-Target", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-Signature")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-Signature", valid_614079
  var valid_614080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "X-Amz-Content-Sha256", valid_614080
  var valid_614081 = header.getOrDefault("X-Amz-Date")
  valid_614081 = validateParameter(valid_614081, JString, required = false,
                                 default = nil)
  if valid_614081 != nil:
    section.add "X-Amz-Date", valid_614081
  var valid_614082 = header.getOrDefault("X-Amz-Credential")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "X-Amz-Credential", valid_614082
  var valid_614083 = header.getOrDefault("X-Amz-Security-Token")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "X-Amz-Security-Token", valid_614083
  var valid_614084 = header.getOrDefault("X-Amz-Algorithm")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "X-Amz-Algorithm", valid_614084
  var valid_614085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "X-Amz-SignedHeaders", valid_614085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614087: Call_DescribeExperiment_614075; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_614087.validator(path, query, header, formData, body)
  let scheme = call_614087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614087.url(scheme.get, call_614087.host, call_614087.base,
                         call_614087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614087, url, valid)

proc call*(call_614088: Call_DescribeExperiment_614075; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_614089 = newJObject()
  if body != nil:
    body_614089 = body
  result = call_614088.call(nil, nil, nil, nil, body_614089)

var describeExperiment* = Call_DescribeExperiment_614075(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_614076, base: "/",
    url: url_DescribeExperiment_614077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_614090 = ref object of OpenApiRestCall_612658
proc url_DescribeFlowDefinition_614092(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFlowDefinition_614091(path: JsonNode; query: JsonNode;
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
  var valid_614093 = header.getOrDefault("X-Amz-Target")
  valid_614093 = validateParameter(valid_614093, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_614093 != nil:
    section.add "X-Amz-Target", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Signature")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Signature", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Content-Sha256", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Date")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Date", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Credential")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Credential", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Security-Token")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Security-Token", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Algorithm")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Algorithm", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-SignedHeaders", valid_614100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614102: Call_DescribeFlowDefinition_614090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_614102.validator(path, query, header, formData, body)
  let scheme = call_614102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614102.url(scheme.get, call_614102.host, call_614102.base,
                         call_614102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614102, url, valid)

proc call*(call_614103: Call_DescribeFlowDefinition_614090; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_614104 = newJObject()
  if body != nil:
    body_614104 = body
  result = call_614103.call(nil, nil, nil, nil, body_614104)

var describeFlowDefinition* = Call_DescribeFlowDefinition_614090(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_614091, base: "/",
    url: url_DescribeFlowDefinition_614092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_614105 = ref object of OpenApiRestCall_612658
proc url_DescribeHumanTaskUi_614107(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHumanTaskUi_614106(path: JsonNode; query: JsonNode;
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
  var valid_614108 = header.getOrDefault("X-Amz-Target")
  valid_614108 = validateParameter(valid_614108, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_614108 != nil:
    section.add "X-Amz-Target", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-Signature")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-Signature", valid_614109
  var valid_614110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "X-Amz-Content-Sha256", valid_614110
  var valid_614111 = header.getOrDefault("X-Amz-Date")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "X-Amz-Date", valid_614111
  var valid_614112 = header.getOrDefault("X-Amz-Credential")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Credential", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Security-Token")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Security-Token", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Algorithm")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Algorithm", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-SignedHeaders", valid_614115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614117: Call_DescribeHumanTaskUi_614105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_614117.validator(path, query, header, formData, body)
  let scheme = call_614117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614117.url(scheme.get, call_614117.host, call_614117.base,
                         call_614117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614117, url, valid)

proc call*(call_614118: Call_DescribeHumanTaskUi_614105; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_614119 = newJObject()
  if body != nil:
    body_614119 = body
  result = call_614118.call(nil, nil, nil, nil, body_614119)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_614105(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_614106, base: "/",
    url: url_DescribeHumanTaskUi_614107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_614120 = ref object of OpenApiRestCall_612658
proc url_DescribeHyperParameterTuningJob_614122(protocol: Scheme; host: string;
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

proc validate_DescribeHyperParameterTuningJob_614121(path: JsonNode;
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
  var valid_614123 = header.getOrDefault("X-Amz-Target")
  valid_614123 = validateParameter(valid_614123, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_614123 != nil:
    section.add "X-Amz-Target", valid_614123
  var valid_614124 = header.getOrDefault("X-Amz-Signature")
  valid_614124 = validateParameter(valid_614124, JString, required = false,
                                 default = nil)
  if valid_614124 != nil:
    section.add "X-Amz-Signature", valid_614124
  var valid_614125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "X-Amz-Content-Sha256", valid_614125
  var valid_614126 = header.getOrDefault("X-Amz-Date")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Date", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Credential")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Credential", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Security-Token")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Security-Token", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Algorithm")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Algorithm", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-SignedHeaders", valid_614130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614132: Call_DescribeHyperParameterTuningJob_614120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_614132.validator(path, query, header, formData, body)
  let scheme = call_614132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614132.url(scheme.get, call_614132.host, call_614132.base,
                         call_614132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614132, url, valid)

proc call*(call_614133: Call_DescribeHyperParameterTuningJob_614120; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_614134 = newJObject()
  if body != nil:
    body_614134 = body
  result = call_614133.call(nil, nil, nil, nil, body_614134)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_614120(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_614121, base: "/",
    url: url_DescribeHyperParameterTuningJob_614122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_614135 = ref object of OpenApiRestCall_612658
proc url_DescribeLabelingJob_614137(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLabelingJob_614136(path: JsonNode; query: JsonNode;
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
  var valid_614138 = header.getOrDefault("X-Amz-Target")
  valid_614138 = validateParameter(valid_614138, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_614138 != nil:
    section.add "X-Amz-Target", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Signature")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Signature", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Content-Sha256", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Date")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Date", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Credential")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Credential", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Security-Token")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Security-Token", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Algorithm")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Algorithm", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-SignedHeaders", valid_614145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614147: Call_DescribeLabelingJob_614135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_614147.validator(path, query, header, formData, body)
  let scheme = call_614147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614147.url(scheme.get, call_614147.host, call_614147.base,
                         call_614147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614147, url, valid)

proc call*(call_614148: Call_DescribeLabelingJob_614135; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_614149 = newJObject()
  if body != nil:
    body_614149 = body
  result = call_614148.call(nil, nil, nil, nil, body_614149)

var describeLabelingJob* = Call_DescribeLabelingJob_614135(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_614136, base: "/",
    url: url_DescribeLabelingJob_614137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_614150 = ref object of OpenApiRestCall_612658
proc url_DescribeModel_614152(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModel_614151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614153 = header.getOrDefault("X-Amz-Target")
  valid_614153 = validateParameter(valid_614153, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_614153 != nil:
    section.add "X-Amz-Target", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Signature")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Signature", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-Content-Sha256", valid_614155
  var valid_614156 = header.getOrDefault("X-Amz-Date")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-Date", valid_614156
  var valid_614157 = header.getOrDefault("X-Amz-Credential")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "X-Amz-Credential", valid_614157
  var valid_614158 = header.getOrDefault("X-Amz-Security-Token")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "X-Amz-Security-Token", valid_614158
  var valid_614159 = header.getOrDefault("X-Amz-Algorithm")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "X-Amz-Algorithm", valid_614159
  var valid_614160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614160 = validateParameter(valid_614160, JString, required = false,
                                 default = nil)
  if valid_614160 != nil:
    section.add "X-Amz-SignedHeaders", valid_614160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614162: Call_DescribeModel_614150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_614162.validator(path, query, header, formData, body)
  let scheme = call_614162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614162.url(scheme.get, call_614162.host, call_614162.base,
                         call_614162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614162, url, valid)

proc call*(call_614163: Call_DescribeModel_614150; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_614164 = newJObject()
  if body != nil:
    body_614164 = body
  result = call_614163.call(nil, nil, nil, nil, body_614164)

var describeModel* = Call_DescribeModel_614150(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_614151, base: "/", url: url_DescribeModel_614152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_614165 = ref object of OpenApiRestCall_612658
proc url_DescribeModelPackage_614167(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModelPackage_614166(path: JsonNode; query: JsonNode;
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
  var valid_614168 = header.getOrDefault("X-Amz-Target")
  valid_614168 = validateParameter(valid_614168, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_614168 != nil:
    section.add "X-Amz-Target", valid_614168
  var valid_614169 = header.getOrDefault("X-Amz-Signature")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "X-Amz-Signature", valid_614169
  var valid_614170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-Content-Sha256", valid_614170
  var valid_614171 = header.getOrDefault("X-Amz-Date")
  valid_614171 = validateParameter(valid_614171, JString, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "X-Amz-Date", valid_614171
  var valid_614172 = header.getOrDefault("X-Amz-Credential")
  valid_614172 = validateParameter(valid_614172, JString, required = false,
                                 default = nil)
  if valid_614172 != nil:
    section.add "X-Amz-Credential", valid_614172
  var valid_614173 = header.getOrDefault("X-Amz-Security-Token")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "X-Amz-Security-Token", valid_614173
  var valid_614174 = header.getOrDefault("X-Amz-Algorithm")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Algorithm", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-SignedHeaders", valid_614175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614177: Call_DescribeModelPackage_614165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_614177.validator(path, query, header, formData, body)
  let scheme = call_614177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614177.url(scheme.get, call_614177.host, call_614177.base,
                         call_614177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614177, url, valid)

proc call*(call_614178: Call_DescribeModelPackage_614165; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_614179 = newJObject()
  if body != nil:
    body_614179 = body
  result = call_614178.call(nil, nil, nil, nil, body_614179)

var describeModelPackage* = Call_DescribeModelPackage_614165(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_614166, base: "/",
    url: url_DescribeModelPackage_614167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_614180 = ref object of OpenApiRestCall_612658
proc url_DescribeMonitoringSchedule_614182(protocol: Scheme; host: string;
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

proc validate_DescribeMonitoringSchedule_614181(path: JsonNode; query: JsonNode;
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
  var valid_614183 = header.getOrDefault("X-Amz-Target")
  valid_614183 = validateParameter(valid_614183, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_614183 != nil:
    section.add "X-Amz-Target", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Signature")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Signature", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Content-Sha256", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Date")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Date", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Credential")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Credential", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-Security-Token")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-Security-Token", valid_614188
  var valid_614189 = header.getOrDefault("X-Amz-Algorithm")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "X-Amz-Algorithm", valid_614189
  var valid_614190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-SignedHeaders", valid_614190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614192: Call_DescribeMonitoringSchedule_614180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_614192.validator(path, query, header, formData, body)
  let scheme = call_614192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614192.url(scheme.get, call_614192.host, call_614192.base,
                         call_614192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614192, url, valid)

proc call*(call_614193: Call_DescribeMonitoringSchedule_614180; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_614194 = newJObject()
  if body != nil:
    body_614194 = body
  result = call_614193.call(nil, nil, nil, nil, body_614194)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_614180(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_614181, base: "/",
    url: url_DescribeMonitoringSchedule_614182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_614195 = ref object of OpenApiRestCall_612658
proc url_DescribeNotebookInstance_614197(protocol: Scheme; host: string;
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

proc validate_DescribeNotebookInstance_614196(path: JsonNode; query: JsonNode;
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
  var valid_614198 = header.getOrDefault("X-Amz-Target")
  valid_614198 = validateParameter(valid_614198, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_614198 != nil:
    section.add "X-Amz-Target", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Signature")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Signature", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Content-Sha256", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Date")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Date", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Credential")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Credential", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-Security-Token")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-Security-Token", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Algorithm")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Algorithm", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-SignedHeaders", valid_614205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614207: Call_DescribeNotebookInstance_614195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_614207.validator(path, query, header, formData, body)
  let scheme = call_614207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614207.url(scheme.get, call_614207.host, call_614207.base,
                         call_614207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614207, url, valid)

proc call*(call_614208: Call_DescribeNotebookInstance_614195; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_614209 = newJObject()
  if body != nil:
    body_614209 = body
  result = call_614208.call(nil, nil, nil, nil, body_614209)

var describeNotebookInstance* = Call_DescribeNotebookInstance_614195(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_614196, base: "/",
    url: url_DescribeNotebookInstance_614197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_614210 = ref object of OpenApiRestCall_612658
proc url_DescribeNotebookInstanceLifecycleConfig_614212(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_614211(path: JsonNode;
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
  var valid_614213 = header.getOrDefault("X-Amz-Target")
  valid_614213 = validateParameter(valid_614213, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_614213 != nil:
    section.add "X-Amz-Target", valid_614213
  var valid_614214 = header.getOrDefault("X-Amz-Signature")
  valid_614214 = validateParameter(valid_614214, JString, required = false,
                                 default = nil)
  if valid_614214 != nil:
    section.add "X-Amz-Signature", valid_614214
  var valid_614215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614215 = validateParameter(valid_614215, JString, required = false,
                                 default = nil)
  if valid_614215 != nil:
    section.add "X-Amz-Content-Sha256", valid_614215
  var valid_614216 = header.getOrDefault("X-Amz-Date")
  valid_614216 = validateParameter(valid_614216, JString, required = false,
                                 default = nil)
  if valid_614216 != nil:
    section.add "X-Amz-Date", valid_614216
  var valid_614217 = header.getOrDefault("X-Amz-Credential")
  valid_614217 = validateParameter(valid_614217, JString, required = false,
                                 default = nil)
  if valid_614217 != nil:
    section.add "X-Amz-Credential", valid_614217
  var valid_614218 = header.getOrDefault("X-Amz-Security-Token")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Security-Token", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Algorithm")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Algorithm", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-SignedHeaders", valid_614220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614222: Call_DescribeNotebookInstanceLifecycleConfig_614210;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_614222.validator(path, query, header, formData, body)
  let scheme = call_614222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614222.url(scheme.get, call_614222.host, call_614222.base,
                         call_614222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614222, url, valid)

proc call*(call_614223: Call_DescribeNotebookInstanceLifecycleConfig_614210;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_614224 = newJObject()
  if body != nil:
    body_614224 = body
  result = call_614223.call(nil, nil, nil, nil, body_614224)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_614210(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_614211, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_614212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_614225 = ref object of OpenApiRestCall_612658
proc url_DescribeProcessingJob_614227(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProcessingJob_614226(path: JsonNode; query: JsonNode;
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
  var valid_614228 = header.getOrDefault("X-Amz-Target")
  valid_614228 = validateParameter(valid_614228, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_614228 != nil:
    section.add "X-Amz-Target", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Signature")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Signature", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Content-Sha256", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Date")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Date", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-Credential")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-Credential", valid_614232
  var valid_614233 = header.getOrDefault("X-Amz-Security-Token")
  valid_614233 = validateParameter(valid_614233, JString, required = false,
                                 default = nil)
  if valid_614233 != nil:
    section.add "X-Amz-Security-Token", valid_614233
  var valid_614234 = header.getOrDefault("X-Amz-Algorithm")
  valid_614234 = validateParameter(valid_614234, JString, required = false,
                                 default = nil)
  if valid_614234 != nil:
    section.add "X-Amz-Algorithm", valid_614234
  var valid_614235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614235 = validateParameter(valid_614235, JString, required = false,
                                 default = nil)
  if valid_614235 != nil:
    section.add "X-Amz-SignedHeaders", valid_614235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614237: Call_DescribeProcessingJob_614225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_614237.validator(path, query, header, formData, body)
  let scheme = call_614237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614237.url(scheme.get, call_614237.host, call_614237.base,
                         call_614237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614237, url, valid)

proc call*(call_614238: Call_DescribeProcessingJob_614225; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_614239 = newJObject()
  if body != nil:
    body_614239 = body
  result = call_614238.call(nil, nil, nil, nil, body_614239)

var describeProcessingJob* = Call_DescribeProcessingJob_614225(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_614226, base: "/",
    url: url_DescribeProcessingJob_614227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_614240 = ref object of OpenApiRestCall_612658
proc url_DescribeSubscribedWorkteam_614242(protocol: Scheme; host: string;
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

proc validate_DescribeSubscribedWorkteam_614241(path: JsonNode; query: JsonNode;
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
  var valid_614243 = header.getOrDefault("X-Amz-Target")
  valid_614243 = validateParameter(valid_614243, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_614243 != nil:
    section.add "X-Amz-Target", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Signature")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Signature", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Content-Sha256", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Date")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Date", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-Credential")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-Credential", valid_614247
  var valid_614248 = header.getOrDefault("X-Amz-Security-Token")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "X-Amz-Security-Token", valid_614248
  var valid_614249 = header.getOrDefault("X-Amz-Algorithm")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "X-Amz-Algorithm", valid_614249
  var valid_614250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "X-Amz-SignedHeaders", valid_614250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614252: Call_DescribeSubscribedWorkteam_614240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_614252.validator(path, query, header, formData, body)
  let scheme = call_614252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614252.url(scheme.get, call_614252.host, call_614252.base,
                         call_614252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614252, url, valid)

proc call*(call_614253: Call_DescribeSubscribedWorkteam_614240; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_614254 = newJObject()
  if body != nil:
    body_614254 = body
  result = call_614253.call(nil, nil, nil, nil, body_614254)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_614240(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_614241, base: "/",
    url: url_DescribeSubscribedWorkteam_614242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_614255 = ref object of OpenApiRestCall_612658
proc url_DescribeTrainingJob_614257(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrainingJob_614256(path: JsonNode; query: JsonNode;
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
  var valid_614258 = header.getOrDefault("X-Amz-Target")
  valid_614258 = validateParameter(valid_614258, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_614258 != nil:
    section.add "X-Amz-Target", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Signature")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Signature", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Content-Sha256", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Date")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Date", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Credential")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Credential", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-Security-Token")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-Security-Token", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Algorithm")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Algorithm", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-SignedHeaders", valid_614265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614267: Call_DescribeTrainingJob_614255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_614267.validator(path, query, header, formData, body)
  let scheme = call_614267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614267.url(scheme.get, call_614267.host, call_614267.base,
                         call_614267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614267, url, valid)

proc call*(call_614268: Call_DescribeTrainingJob_614255; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_614269 = newJObject()
  if body != nil:
    body_614269 = body
  result = call_614268.call(nil, nil, nil, nil, body_614269)

var describeTrainingJob* = Call_DescribeTrainingJob_614255(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_614256, base: "/",
    url: url_DescribeTrainingJob_614257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_614270 = ref object of OpenApiRestCall_612658
proc url_DescribeTransformJob_614272(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTransformJob_614271(path: JsonNode; query: JsonNode;
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
  var valid_614273 = header.getOrDefault("X-Amz-Target")
  valid_614273 = validateParameter(valid_614273, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_614273 != nil:
    section.add "X-Amz-Target", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Signature")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Signature", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-Content-Sha256", valid_614275
  var valid_614276 = header.getOrDefault("X-Amz-Date")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "X-Amz-Date", valid_614276
  var valid_614277 = header.getOrDefault("X-Amz-Credential")
  valid_614277 = validateParameter(valid_614277, JString, required = false,
                                 default = nil)
  if valid_614277 != nil:
    section.add "X-Amz-Credential", valid_614277
  var valid_614278 = header.getOrDefault("X-Amz-Security-Token")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "X-Amz-Security-Token", valid_614278
  var valid_614279 = header.getOrDefault("X-Amz-Algorithm")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Algorithm", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-SignedHeaders", valid_614280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614282: Call_DescribeTransformJob_614270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_614282.validator(path, query, header, formData, body)
  let scheme = call_614282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614282.url(scheme.get, call_614282.host, call_614282.base,
                         call_614282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614282, url, valid)

proc call*(call_614283: Call_DescribeTransformJob_614270; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_614284 = newJObject()
  if body != nil:
    body_614284 = body
  result = call_614283.call(nil, nil, nil, nil, body_614284)

var describeTransformJob* = Call_DescribeTransformJob_614270(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_614271, base: "/",
    url: url_DescribeTransformJob_614272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_614285 = ref object of OpenApiRestCall_612658
proc url_DescribeTrial_614287(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrial_614286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614288 = header.getOrDefault("X-Amz-Target")
  valid_614288 = validateParameter(valid_614288, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_614288 != nil:
    section.add "X-Amz-Target", valid_614288
  var valid_614289 = header.getOrDefault("X-Amz-Signature")
  valid_614289 = validateParameter(valid_614289, JString, required = false,
                                 default = nil)
  if valid_614289 != nil:
    section.add "X-Amz-Signature", valid_614289
  var valid_614290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "X-Amz-Content-Sha256", valid_614290
  var valid_614291 = header.getOrDefault("X-Amz-Date")
  valid_614291 = validateParameter(valid_614291, JString, required = false,
                                 default = nil)
  if valid_614291 != nil:
    section.add "X-Amz-Date", valid_614291
  var valid_614292 = header.getOrDefault("X-Amz-Credential")
  valid_614292 = validateParameter(valid_614292, JString, required = false,
                                 default = nil)
  if valid_614292 != nil:
    section.add "X-Amz-Credential", valid_614292
  var valid_614293 = header.getOrDefault("X-Amz-Security-Token")
  valid_614293 = validateParameter(valid_614293, JString, required = false,
                                 default = nil)
  if valid_614293 != nil:
    section.add "X-Amz-Security-Token", valid_614293
  var valid_614294 = header.getOrDefault("X-Amz-Algorithm")
  valid_614294 = validateParameter(valid_614294, JString, required = false,
                                 default = nil)
  if valid_614294 != nil:
    section.add "X-Amz-Algorithm", valid_614294
  var valid_614295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614295 = validateParameter(valid_614295, JString, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "X-Amz-SignedHeaders", valid_614295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614297: Call_DescribeTrial_614285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_614297.validator(path, query, header, formData, body)
  let scheme = call_614297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614297.url(scheme.get, call_614297.host, call_614297.base,
                         call_614297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614297, url, valid)

proc call*(call_614298: Call_DescribeTrial_614285; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_614299 = newJObject()
  if body != nil:
    body_614299 = body
  result = call_614298.call(nil, nil, nil, nil, body_614299)

var describeTrial* = Call_DescribeTrial_614285(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_614286, base: "/", url: url_DescribeTrial_614287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_614300 = ref object of OpenApiRestCall_612658
proc url_DescribeTrialComponent_614302(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrialComponent_614301(path: JsonNode; query: JsonNode;
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
  var valid_614303 = header.getOrDefault("X-Amz-Target")
  valid_614303 = validateParameter(valid_614303, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_614303 != nil:
    section.add "X-Amz-Target", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Signature")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Signature", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Content-Sha256", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Date")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Date", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-Credential")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-Credential", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Security-Token")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Security-Token", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-Algorithm")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-Algorithm", valid_614309
  var valid_614310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614310 = validateParameter(valid_614310, JString, required = false,
                                 default = nil)
  if valid_614310 != nil:
    section.add "X-Amz-SignedHeaders", valid_614310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614312: Call_DescribeTrialComponent_614300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_614312.validator(path, query, header, formData, body)
  let scheme = call_614312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614312.url(scheme.get, call_614312.host, call_614312.base,
                         call_614312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614312, url, valid)

proc call*(call_614313: Call_DescribeTrialComponent_614300; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_614314 = newJObject()
  if body != nil:
    body_614314 = body
  result = call_614313.call(nil, nil, nil, nil, body_614314)

var describeTrialComponent* = Call_DescribeTrialComponent_614300(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_614301, base: "/",
    url: url_DescribeTrialComponent_614302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_614315 = ref object of OpenApiRestCall_612658
proc url_DescribeUserProfile_614317(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserProfile_614316(path: JsonNode; query: JsonNode;
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
  var valid_614318 = header.getOrDefault("X-Amz-Target")
  valid_614318 = validateParameter(valid_614318, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_614318 != nil:
    section.add "X-Amz-Target", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Signature")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Signature", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Content-Sha256", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Date")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Date", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-Credential")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-Credential", valid_614322
  var valid_614323 = header.getOrDefault("X-Amz-Security-Token")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "X-Amz-Security-Token", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-Algorithm")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-Algorithm", valid_614324
  var valid_614325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614325 = validateParameter(valid_614325, JString, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "X-Amz-SignedHeaders", valid_614325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614327: Call_DescribeUserProfile_614315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_614327.validator(path, query, header, formData, body)
  let scheme = call_614327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614327.url(scheme.get, call_614327.host, call_614327.base,
                         call_614327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614327, url, valid)

proc call*(call_614328: Call_DescribeUserProfile_614315; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_614329 = newJObject()
  if body != nil:
    body_614329 = body
  result = call_614328.call(nil, nil, nil, nil, body_614329)

var describeUserProfile* = Call_DescribeUserProfile_614315(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_614316, base: "/",
    url: url_DescribeUserProfile_614317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkforce_614330 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkforce_614332(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkforce_614331(path: JsonNode; query: JsonNode;
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
  var valid_614333 = header.getOrDefault("X-Amz-Target")
  valid_614333 = validateParameter(valid_614333, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkforce"))
  if valid_614333 != nil:
    section.add "X-Amz-Target", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Signature")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Signature", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Content-Sha256", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Date")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Date", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Credential")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Credential", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Security-Token")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Security-Token", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Algorithm")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Algorithm", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-SignedHeaders", valid_614340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614342: Call_DescribeWorkforce_614330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_614342.validator(path, query, header, formData, body)
  let scheme = call_614342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614342.url(scheme.get, call_614342.host, call_614342.base,
                         call_614342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614342, url, valid)

proc call*(call_614343: Call_DescribeWorkforce_614330; body: JsonNode): Recallable =
  ## describeWorkforce
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_614344 = newJObject()
  if body != nil:
    body_614344 = body
  result = call_614343.call(nil, nil, nil, nil, body_614344)

var describeWorkforce* = Call_DescribeWorkforce_614330(name: "describeWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkforce",
    validator: validate_DescribeWorkforce_614331, base: "/",
    url: url_DescribeWorkforce_614332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_614345 = ref object of OpenApiRestCall_612658
proc url_DescribeWorkteam_614347(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkteam_614346(path: JsonNode; query: JsonNode;
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
  var valid_614348 = header.getOrDefault("X-Amz-Target")
  valid_614348 = validateParameter(valid_614348, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_614348 != nil:
    section.add "X-Amz-Target", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Signature")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Signature", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Content-Sha256", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Date")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Date", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Credential")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Credential", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Security-Token")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Security-Token", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Algorithm")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Algorithm", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-SignedHeaders", valid_614355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614357: Call_DescribeWorkteam_614345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_614357.validator(path, query, header, formData, body)
  let scheme = call_614357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614357.url(scheme.get, call_614357.host, call_614357.base,
                         call_614357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614357, url, valid)

proc call*(call_614358: Call_DescribeWorkteam_614345; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_614359 = newJObject()
  if body != nil:
    body_614359 = body
  result = call_614358.call(nil, nil, nil, nil, body_614359)

var describeWorkteam* = Call_DescribeWorkteam_614345(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_614346, base: "/",
    url: url_DescribeWorkteam_614347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_614360 = ref object of OpenApiRestCall_612658
proc url_DisassociateTrialComponent_614362(protocol: Scheme; host: string;
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

proc validate_DisassociateTrialComponent_614361(path: JsonNode; query: JsonNode;
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
  var valid_614363 = header.getOrDefault("X-Amz-Target")
  valid_614363 = validateParameter(valid_614363, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_614363 != nil:
    section.add "X-Amz-Target", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Signature")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Signature", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Content-Sha256", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Date")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Date", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-Credential")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Credential", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-Security-Token")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Security-Token", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Algorithm")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Algorithm", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-SignedHeaders", valid_614370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614372: Call_DisassociateTrialComponent_614360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ## 
  let valid = call_614372.validator(path, query, header, formData, body)
  let scheme = call_614372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614372.url(scheme.get, call_614372.host, call_614372.base,
                         call_614372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614372, url, valid)

proc call*(call_614373: Call_DisassociateTrialComponent_614360; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_614374 = newJObject()
  if body != nil:
    body_614374 = body
  result = call_614373.call(nil, nil, nil, nil, body_614374)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_614360(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_614361, base: "/",
    url: url_DisassociateTrialComponent_614362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_614375 = ref object of OpenApiRestCall_612658
proc url_GetSearchSuggestions_614377(protocol: Scheme; host: string; base: string;
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

proc validate_GetSearchSuggestions_614376(path: JsonNode; query: JsonNode;
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
  var valid_614378 = header.getOrDefault("X-Amz-Target")
  valid_614378 = validateParameter(valid_614378, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_614378 != nil:
    section.add "X-Amz-Target", valid_614378
  var valid_614379 = header.getOrDefault("X-Amz-Signature")
  valid_614379 = validateParameter(valid_614379, JString, required = false,
                                 default = nil)
  if valid_614379 != nil:
    section.add "X-Amz-Signature", valid_614379
  var valid_614380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614380 = validateParameter(valid_614380, JString, required = false,
                                 default = nil)
  if valid_614380 != nil:
    section.add "X-Amz-Content-Sha256", valid_614380
  var valid_614381 = header.getOrDefault("X-Amz-Date")
  valid_614381 = validateParameter(valid_614381, JString, required = false,
                                 default = nil)
  if valid_614381 != nil:
    section.add "X-Amz-Date", valid_614381
  var valid_614382 = header.getOrDefault("X-Amz-Credential")
  valid_614382 = validateParameter(valid_614382, JString, required = false,
                                 default = nil)
  if valid_614382 != nil:
    section.add "X-Amz-Credential", valid_614382
  var valid_614383 = header.getOrDefault("X-Amz-Security-Token")
  valid_614383 = validateParameter(valid_614383, JString, required = false,
                                 default = nil)
  if valid_614383 != nil:
    section.add "X-Amz-Security-Token", valid_614383
  var valid_614384 = header.getOrDefault("X-Amz-Algorithm")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Algorithm", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-SignedHeaders", valid_614385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614387: Call_GetSearchSuggestions_614375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_614387.validator(path, query, header, formData, body)
  let scheme = call_614387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614387.url(scheme.get, call_614387.host, call_614387.base,
                         call_614387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614387, url, valid)

proc call*(call_614388: Call_GetSearchSuggestions_614375; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_614389 = newJObject()
  if body != nil:
    body_614389 = body
  result = call_614388.call(nil, nil, nil, nil, body_614389)

var getSearchSuggestions* = Call_GetSearchSuggestions_614375(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_614376, base: "/",
    url: url_GetSearchSuggestions_614377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_614390 = ref object of OpenApiRestCall_612658
proc url_ListAlgorithms_614392(protocol: Scheme; host: string; base: string;
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

proc validate_ListAlgorithms_614391(path: JsonNode; query: JsonNode;
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
  var valid_614393 = query.getOrDefault("MaxResults")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "MaxResults", valid_614393
  var valid_614394 = query.getOrDefault("NextToken")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "NextToken", valid_614394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614395 = header.getOrDefault("X-Amz-Target")
  valid_614395 = validateParameter(valid_614395, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_614395 != nil:
    section.add "X-Amz-Target", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-Signature")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-Signature", valid_614396
  var valid_614397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "X-Amz-Content-Sha256", valid_614397
  var valid_614398 = header.getOrDefault("X-Amz-Date")
  valid_614398 = validateParameter(valid_614398, JString, required = false,
                                 default = nil)
  if valid_614398 != nil:
    section.add "X-Amz-Date", valid_614398
  var valid_614399 = header.getOrDefault("X-Amz-Credential")
  valid_614399 = validateParameter(valid_614399, JString, required = false,
                                 default = nil)
  if valid_614399 != nil:
    section.add "X-Amz-Credential", valid_614399
  var valid_614400 = header.getOrDefault("X-Amz-Security-Token")
  valid_614400 = validateParameter(valid_614400, JString, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "X-Amz-Security-Token", valid_614400
  var valid_614401 = header.getOrDefault("X-Amz-Algorithm")
  valid_614401 = validateParameter(valid_614401, JString, required = false,
                                 default = nil)
  if valid_614401 != nil:
    section.add "X-Amz-Algorithm", valid_614401
  var valid_614402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-SignedHeaders", valid_614402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614404: Call_ListAlgorithms_614390; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_614404.validator(path, query, header, formData, body)
  let scheme = call_614404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614404.url(scheme.get, call_614404.host, call_614404.base,
                         call_614404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614404, url, valid)

proc call*(call_614405: Call_ListAlgorithms_614390; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614406 = newJObject()
  var body_614407 = newJObject()
  add(query_614406, "MaxResults", newJString(MaxResults))
  add(query_614406, "NextToken", newJString(NextToken))
  if body != nil:
    body_614407 = body
  result = call_614405.call(nil, query_614406, nil, nil, body_614407)

var listAlgorithms* = Call_ListAlgorithms_614390(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_614391, base: "/", url: url_ListAlgorithms_614392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_614409 = ref object of OpenApiRestCall_612658
proc url_ListApps_614411(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_614410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614412 = query.getOrDefault("MaxResults")
  valid_614412 = validateParameter(valid_614412, JString, required = false,
                                 default = nil)
  if valid_614412 != nil:
    section.add "MaxResults", valid_614412
  var valid_614413 = query.getOrDefault("NextToken")
  valid_614413 = validateParameter(valid_614413, JString, required = false,
                                 default = nil)
  if valid_614413 != nil:
    section.add "NextToken", valid_614413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614414 = header.getOrDefault("X-Amz-Target")
  valid_614414 = validateParameter(valid_614414, JString, required = true,
                                 default = newJString("SageMaker.ListApps"))
  if valid_614414 != nil:
    section.add "X-Amz-Target", valid_614414
  var valid_614415 = header.getOrDefault("X-Amz-Signature")
  valid_614415 = validateParameter(valid_614415, JString, required = false,
                                 default = nil)
  if valid_614415 != nil:
    section.add "X-Amz-Signature", valid_614415
  var valid_614416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614416 = validateParameter(valid_614416, JString, required = false,
                                 default = nil)
  if valid_614416 != nil:
    section.add "X-Amz-Content-Sha256", valid_614416
  var valid_614417 = header.getOrDefault("X-Amz-Date")
  valid_614417 = validateParameter(valid_614417, JString, required = false,
                                 default = nil)
  if valid_614417 != nil:
    section.add "X-Amz-Date", valid_614417
  var valid_614418 = header.getOrDefault("X-Amz-Credential")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Credential", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Security-Token")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Security-Token", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Algorithm")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Algorithm", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-SignedHeaders", valid_614421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614423: Call_ListApps_614409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists apps.
  ## 
  let valid = call_614423.validator(path, query, header, formData, body)
  let scheme = call_614423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614423.url(scheme.get, call_614423.host, call_614423.base,
                         call_614423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614423, url, valid)

proc call*(call_614424: Call_ListApps_614409; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614425 = newJObject()
  var body_614426 = newJObject()
  add(query_614425, "MaxResults", newJString(MaxResults))
  add(query_614425, "NextToken", newJString(NextToken))
  if body != nil:
    body_614426 = body
  result = call_614424.call(nil, query_614425, nil, nil, body_614426)

var listApps* = Call_ListApps_614409(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListApps",
                                  validator: validate_ListApps_614410, base: "/",
                                  url: url_ListApps_614411,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_614427 = ref object of OpenApiRestCall_612658
proc url_ListAutoMLJobs_614429(protocol: Scheme; host: string; base: string;
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

proc validate_ListAutoMLJobs_614428(path: JsonNode; query: JsonNode;
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
  var valid_614430 = query.getOrDefault("MaxResults")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "MaxResults", valid_614430
  var valid_614431 = query.getOrDefault("NextToken")
  valid_614431 = validateParameter(valid_614431, JString, required = false,
                                 default = nil)
  if valid_614431 != nil:
    section.add "NextToken", valid_614431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614432 = header.getOrDefault("X-Amz-Target")
  valid_614432 = validateParameter(valid_614432, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_614432 != nil:
    section.add "X-Amz-Target", valid_614432
  var valid_614433 = header.getOrDefault("X-Amz-Signature")
  valid_614433 = validateParameter(valid_614433, JString, required = false,
                                 default = nil)
  if valid_614433 != nil:
    section.add "X-Amz-Signature", valid_614433
  var valid_614434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614434 = validateParameter(valid_614434, JString, required = false,
                                 default = nil)
  if valid_614434 != nil:
    section.add "X-Amz-Content-Sha256", valid_614434
  var valid_614435 = header.getOrDefault("X-Amz-Date")
  valid_614435 = validateParameter(valid_614435, JString, required = false,
                                 default = nil)
  if valid_614435 != nil:
    section.add "X-Amz-Date", valid_614435
  var valid_614436 = header.getOrDefault("X-Amz-Credential")
  valid_614436 = validateParameter(valid_614436, JString, required = false,
                                 default = nil)
  if valid_614436 != nil:
    section.add "X-Amz-Credential", valid_614436
  var valid_614437 = header.getOrDefault("X-Amz-Security-Token")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Security-Token", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Algorithm")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Algorithm", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-SignedHeaders", valid_614439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614441: Call_ListAutoMLJobs_614427; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_614441.validator(path, query, header, formData, body)
  let scheme = call_614441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614441.url(scheme.get, call_614441.host, call_614441.base,
                         call_614441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614441, url, valid)

proc call*(call_614442: Call_ListAutoMLJobs_614427; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614443 = newJObject()
  var body_614444 = newJObject()
  add(query_614443, "MaxResults", newJString(MaxResults))
  add(query_614443, "NextToken", newJString(NextToken))
  if body != nil:
    body_614444 = body
  result = call_614442.call(nil, query_614443, nil, nil, body_614444)

var listAutoMLJobs* = Call_ListAutoMLJobs_614427(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_614428, base: "/", url: url_ListAutoMLJobs_614429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_614445 = ref object of OpenApiRestCall_612658
proc url_ListCandidatesForAutoMLJob_614447(protocol: Scheme; host: string;
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

proc validate_ListCandidatesForAutoMLJob_614446(path: JsonNode; query: JsonNode;
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
  var valid_614448 = query.getOrDefault("MaxResults")
  valid_614448 = validateParameter(valid_614448, JString, required = false,
                                 default = nil)
  if valid_614448 != nil:
    section.add "MaxResults", valid_614448
  var valid_614449 = query.getOrDefault("NextToken")
  valid_614449 = validateParameter(valid_614449, JString, required = false,
                                 default = nil)
  if valid_614449 != nil:
    section.add "NextToken", valid_614449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614450 = header.getOrDefault("X-Amz-Target")
  valid_614450 = validateParameter(valid_614450, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_614450 != nil:
    section.add "X-Amz-Target", valid_614450
  var valid_614451 = header.getOrDefault("X-Amz-Signature")
  valid_614451 = validateParameter(valid_614451, JString, required = false,
                                 default = nil)
  if valid_614451 != nil:
    section.add "X-Amz-Signature", valid_614451
  var valid_614452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Content-Sha256", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Date")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Date", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Credential")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Credential", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Security-Token")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Security-Token", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Algorithm")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Algorithm", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-SignedHeaders", valid_614457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614459: Call_ListCandidatesForAutoMLJob_614445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_614459.validator(path, query, header, formData, body)
  let scheme = call_614459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614459.url(scheme.get, call_614459.host, call_614459.base,
                         call_614459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614459, url, valid)

proc call*(call_614460: Call_ListCandidatesForAutoMLJob_614445; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614461 = newJObject()
  var body_614462 = newJObject()
  add(query_614461, "MaxResults", newJString(MaxResults))
  add(query_614461, "NextToken", newJString(NextToken))
  if body != nil:
    body_614462 = body
  result = call_614460.call(nil, query_614461, nil, nil, body_614462)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_614445(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_614446, base: "/",
    url: url_ListCandidatesForAutoMLJob_614447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_614463 = ref object of OpenApiRestCall_612658
proc url_ListCodeRepositories_614465(protocol: Scheme; host: string; base: string;
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

proc validate_ListCodeRepositories_614464(path: JsonNode; query: JsonNode;
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
  var valid_614466 = query.getOrDefault("MaxResults")
  valid_614466 = validateParameter(valid_614466, JString, required = false,
                                 default = nil)
  if valid_614466 != nil:
    section.add "MaxResults", valid_614466
  var valid_614467 = query.getOrDefault("NextToken")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "NextToken", valid_614467
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614468 = header.getOrDefault("X-Amz-Target")
  valid_614468 = validateParameter(valid_614468, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_614468 != nil:
    section.add "X-Amz-Target", valid_614468
  var valid_614469 = header.getOrDefault("X-Amz-Signature")
  valid_614469 = validateParameter(valid_614469, JString, required = false,
                                 default = nil)
  if valid_614469 != nil:
    section.add "X-Amz-Signature", valid_614469
  var valid_614470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "X-Amz-Content-Sha256", valid_614470
  var valid_614471 = header.getOrDefault("X-Amz-Date")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Date", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Credential")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Credential", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Security-Token")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Security-Token", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Algorithm")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Algorithm", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-SignedHeaders", valid_614475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614477: Call_ListCodeRepositories_614463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_614477.validator(path, query, header, formData, body)
  let scheme = call_614477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614477.url(scheme.get, call_614477.host, call_614477.base,
                         call_614477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614477, url, valid)

proc call*(call_614478: Call_ListCodeRepositories_614463; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614479 = newJObject()
  var body_614480 = newJObject()
  add(query_614479, "MaxResults", newJString(MaxResults))
  add(query_614479, "NextToken", newJString(NextToken))
  if body != nil:
    body_614480 = body
  result = call_614478.call(nil, query_614479, nil, nil, body_614480)

var listCodeRepositories* = Call_ListCodeRepositories_614463(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_614464, base: "/",
    url: url_ListCodeRepositories_614465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_614481 = ref object of OpenApiRestCall_612658
proc url_ListCompilationJobs_614483(protocol: Scheme; host: string; base: string;
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

proc validate_ListCompilationJobs_614482(path: JsonNode; query: JsonNode;
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
  var valid_614484 = query.getOrDefault("MaxResults")
  valid_614484 = validateParameter(valid_614484, JString, required = false,
                                 default = nil)
  if valid_614484 != nil:
    section.add "MaxResults", valid_614484
  var valid_614485 = query.getOrDefault("NextToken")
  valid_614485 = validateParameter(valid_614485, JString, required = false,
                                 default = nil)
  if valid_614485 != nil:
    section.add "NextToken", valid_614485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614486 = header.getOrDefault("X-Amz-Target")
  valid_614486 = validateParameter(valid_614486, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_614486 != nil:
    section.add "X-Amz-Target", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Signature")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Signature", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Content-Sha256", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Date")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Date", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Credential")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Credential", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Security-Token")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Security-Token", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-Algorithm")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-Algorithm", valid_614492
  var valid_614493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "X-Amz-SignedHeaders", valid_614493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614495: Call_ListCompilationJobs_614481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_614495.validator(path, query, header, formData, body)
  let scheme = call_614495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614495.url(scheme.get, call_614495.host, call_614495.base,
                         call_614495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614495, url, valid)

proc call*(call_614496: Call_ListCompilationJobs_614481; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614497 = newJObject()
  var body_614498 = newJObject()
  add(query_614497, "MaxResults", newJString(MaxResults))
  add(query_614497, "NextToken", newJString(NextToken))
  if body != nil:
    body_614498 = body
  result = call_614496.call(nil, query_614497, nil, nil, body_614498)

var listCompilationJobs* = Call_ListCompilationJobs_614481(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_614482, base: "/",
    url: url_ListCompilationJobs_614483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_614499 = ref object of OpenApiRestCall_612658
proc url_ListDomains_614501(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomains_614500(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614502 = query.getOrDefault("MaxResults")
  valid_614502 = validateParameter(valid_614502, JString, required = false,
                                 default = nil)
  if valid_614502 != nil:
    section.add "MaxResults", valid_614502
  var valid_614503 = query.getOrDefault("NextToken")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "NextToken", valid_614503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614504 = header.getOrDefault("X-Amz-Target")
  valid_614504 = validateParameter(valid_614504, JString, required = true,
                                 default = newJString("SageMaker.ListDomains"))
  if valid_614504 != nil:
    section.add "X-Amz-Target", valid_614504
  var valid_614505 = header.getOrDefault("X-Amz-Signature")
  valid_614505 = validateParameter(valid_614505, JString, required = false,
                                 default = nil)
  if valid_614505 != nil:
    section.add "X-Amz-Signature", valid_614505
  var valid_614506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "X-Amz-Content-Sha256", valid_614506
  var valid_614507 = header.getOrDefault("X-Amz-Date")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Date", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Credential")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Credential", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Security-Token")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Security-Token", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Algorithm")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Algorithm", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-SignedHeaders", valid_614511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614513: Call_ListDomains_614499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_614513.validator(path, query, header, formData, body)
  let scheme = call_614513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614513.url(scheme.get, call_614513.host, call_614513.base,
                         call_614513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614513, url, valid)

proc call*(call_614514: Call_ListDomains_614499; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614515 = newJObject()
  var body_614516 = newJObject()
  add(query_614515, "MaxResults", newJString(MaxResults))
  add(query_614515, "NextToken", newJString(NextToken))
  if body != nil:
    body_614516 = body
  result = call_614514.call(nil, query_614515, nil, nil, body_614516)

var listDomains* = Call_ListDomains_614499(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListDomains",
                                        validator: validate_ListDomains_614500,
                                        base: "/", url: url_ListDomains_614501,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_614517 = ref object of OpenApiRestCall_612658
proc url_ListEndpointConfigs_614519(protocol: Scheme; host: string; base: string;
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

proc validate_ListEndpointConfigs_614518(path: JsonNode; query: JsonNode;
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
  var valid_614520 = query.getOrDefault("MaxResults")
  valid_614520 = validateParameter(valid_614520, JString, required = false,
                                 default = nil)
  if valid_614520 != nil:
    section.add "MaxResults", valid_614520
  var valid_614521 = query.getOrDefault("NextToken")
  valid_614521 = validateParameter(valid_614521, JString, required = false,
                                 default = nil)
  if valid_614521 != nil:
    section.add "NextToken", valid_614521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614522 = header.getOrDefault("X-Amz-Target")
  valid_614522 = validateParameter(valid_614522, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_614522 != nil:
    section.add "X-Amz-Target", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Signature")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Signature", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-Content-Sha256", valid_614524
  var valid_614525 = header.getOrDefault("X-Amz-Date")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "X-Amz-Date", valid_614525
  var valid_614526 = header.getOrDefault("X-Amz-Credential")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "X-Amz-Credential", valid_614526
  var valid_614527 = header.getOrDefault("X-Amz-Security-Token")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "X-Amz-Security-Token", valid_614527
  var valid_614528 = header.getOrDefault("X-Amz-Algorithm")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "X-Amz-Algorithm", valid_614528
  var valid_614529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614529 = validateParameter(valid_614529, JString, required = false,
                                 default = nil)
  if valid_614529 != nil:
    section.add "X-Amz-SignedHeaders", valid_614529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614531: Call_ListEndpointConfigs_614517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_614531.validator(path, query, header, formData, body)
  let scheme = call_614531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614531.url(scheme.get, call_614531.host, call_614531.base,
                         call_614531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614531, url, valid)

proc call*(call_614532: Call_ListEndpointConfigs_614517; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614533 = newJObject()
  var body_614534 = newJObject()
  add(query_614533, "MaxResults", newJString(MaxResults))
  add(query_614533, "NextToken", newJString(NextToken))
  if body != nil:
    body_614534 = body
  result = call_614532.call(nil, query_614533, nil, nil, body_614534)

var listEndpointConfigs* = Call_ListEndpointConfigs_614517(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_614518, base: "/",
    url: url_ListEndpointConfigs_614519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_614535 = ref object of OpenApiRestCall_612658
proc url_ListEndpoints_614537(protocol: Scheme; host: string; base: string;
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

proc validate_ListEndpoints_614536(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614538 = query.getOrDefault("MaxResults")
  valid_614538 = validateParameter(valid_614538, JString, required = false,
                                 default = nil)
  if valid_614538 != nil:
    section.add "MaxResults", valid_614538
  var valid_614539 = query.getOrDefault("NextToken")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "NextToken", valid_614539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614540 = header.getOrDefault("X-Amz-Target")
  valid_614540 = validateParameter(valid_614540, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_614540 != nil:
    section.add "X-Amz-Target", valid_614540
  var valid_614541 = header.getOrDefault("X-Amz-Signature")
  valid_614541 = validateParameter(valid_614541, JString, required = false,
                                 default = nil)
  if valid_614541 != nil:
    section.add "X-Amz-Signature", valid_614541
  var valid_614542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "X-Amz-Content-Sha256", valid_614542
  var valid_614543 = header.getOrDefault("X-Amz-Date")
  valid_614543 = validateParameter(valid_614543, JString, required = false,
                                 default = nil)
  if valid_614543 != nil:
    section.add "X-Amz-Date", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Credential")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Credential", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-Security-Token")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-Security-Token", valid_614545
  var valid_614546 = header.getOrDefault("X-Amz-Algorithm")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-Algorithm", valid_614546
  var valid_614547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-SignedHeaders", valid_614547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614549: Call_ListEndpoints_614535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_614549.validator(path, query, header, formData, body)
  let scheme = call_614549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614549.url(scheme.get, call_614549.host, call_614549.base,
                         call_614549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614549, url, valid)

proc call*(call_614550: Call_ListEndpoints_614535; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614551 = newJObject()
  var body_614552 = newJObject()
  add(query_614551, "MaxResults", newJString(MaxResults))
  add(query_614551, "NextToken", newJString(NextToken))
  if body != nil:
    body_614552 = body
  result = call_614550.call(nil, query_614551, nil, nil, body_614552)

var listEndpoints* = Call_ListEndpoints_614535(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_614536, base: "/", url: url_ListEndpoints_614537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_614553 = ref object of OpenApiRestCall_612658
proc url_ListExperiments_614555(protocol: Scheme; host: string; base: string;
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

proc validate_ListExperiments_614554(path: JsonNode; query: JsonNode;
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
  var valid_614556 = query.getOrDefault("MaxResults")
  valid_614556 = validateParameter(valid_614556, JString, required = false,
                                 default = nil)
  if valid_614556 != nil:
    section.add "MaxResults", valid_614556
  var valid_614557 = query.getOrDefault("NextToken")
  valid_614557 = validateParameter(valid_614557, JString, required = false,
                                 default = nil)
  if valid_614557 != nil:
    section.add "NextToken", valid_614557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614558 = header.getOrDefault("X-Amz-Target")
  valid_614558 = validateParameter(valid_614558, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_614558 != nil:
    section.add "X-Amz-Target", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Signature")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Signature", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-Content-Sha256", valid_614560
  var valid_614561 = header.getOrDefault("X-Amz-Date")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-Date", valid_614561
  var valid_614562 = header.getOrDefault("X-Amz-Credential")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "X-Amz-Credential", valid_614562
  var valid_614563 = header.getOrDefault("X-Amz-Security-Token")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "X-Amz-Security-Token", valid_614563
  var valid_614564 = header.getOrDefault("X-Amz-Algorithm")
  valid_614564 = validateParameter(valid_614564, JString, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "X-Amz-Algorithm", valid_614564
  var valid_614565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "X-Amz-SignedHeaders", valid_614565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614567: Call_ListExperiments_614553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_614567.validator(path, query, header, formData, body)
  let scheme = call_614567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614567.url(scheme.get, call_614567.host, call_614567.base,
                         call_614567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614567, url, valid)

proc call*(call_614568: Call_ListExperiments_614553; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614569 = newJObject()
  var body_614570 = newJObject()
  add(query_614569, "MaxResults", newJString(MaxResults))
  add(query_614569, "NextToken", newJString(NextToken))
  if body != nil:
    body_614570 = body
  result = call_614568.call(nil, query_614569, nil, nil, body_614570)

var listExperiments* = Call_ListExperiments_614553(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_614554, base: "/", url: url_ListExperiments_614555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_614571 = ref object of OpenApiRestCall_612658
proc url_ListFlowDefinitions_614573(protocol: Scheme; host: string; base: string;
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

proc validate_ListFlowDefinitions_614572(path: JsonNode; query: JsonNode;
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
  var valid_614574 = query.getOrDefault("MaxResults")
  valid_614574 = validateParameter(valid_614574, JString, required = false,
                                 default = nil)
  if valid_614574 != nil:
    section.add "MaxResults", valid_614574
  var valid_614575 = query.getOrDefault("NextToken")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "NextToken", valid_614575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614576 = header.getOrDefault("X-Amz-Target")
  valid_614576 = validateParameter(valid_614576, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_614576 != nil:
    section.add "X-Amz-Target", valid_614576
  var valid_614577 = header.getOrDefault("X-Amz-Signature")
  valid_614577 = validateParameter(valid_614577, JString, required = false,
                                 default = nil)
  if valid_614577 != nil:
    section.add "X-Amz-Signature", valid_614577
  var valid_614578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "X-Amz-Content-Sha256", valid_614578
  var valid_614579 = header.getOrDefault("X-Amz-Date")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Date", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Credential")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Credential", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Security-Token")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Security-Token", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Algorithm")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Algorithm", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-SignedHeaders", valid_614583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614585: Call_ListFlowDefinitions_614571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_614585.validator(path, query, header, formData, body)
  let scheme = call_614585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614585.url(scheme.get, call_614585.host, call_614585.base,
                         call_614585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614585, url, valid)

proc call*(call_614586: Call_ListFlowDefinitions_614571; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614587 = newJObject()
  var body_614588 = newJObject()
  add(query_614587, "MaxResults", newJString(MaxResults))
  add(query_614587, "NextToken", newJString(NextToken))
  if body != nil:
    body_614588 = body
  result = call_614586.call(nil, query_614587, nil, nil, body_614588)

var listFlowDefinitions* = Call_ListFlowDefinitions_614571(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_614572, base: "/",
    url: url_ListFlowDefinitions_614573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_614589 = ref object of OpenApiRestCall_612658
proc url_ListHumanTaskUis_614591(protocol: Scheme; host: string; base: string;
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

proc validate_ListHumanTaskUis_614590(path: JsonNode; query: JsonNode;
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
  var valid_614592 = query.getOrDefault("MaxResults")
  valid_614592 = validateParameter(valid_614592, JString, required = false,
                                 default = nil)
  if valid_614592 != nil:
    section.add "MaxResults", valid_614592
  var valid_614593 = query.getOrDefault("NextToken")
  valid_614593 = validateParameter(valid_614593, JString, required = false,
                                 default = nil)
  if valid_614593 != nil:
    section.add "NextToken", valid_614593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614594 = header.getOrDefault("X-Amz-Target")
  valid_614594 = validateParameter(valid_614594, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_614594 != nil:
    section.add "X-Amz-Target", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Signature")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Signature", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Content-Sha256", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Date")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Date", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Credential")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Credential", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Security-Token")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Security-Token", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-Algorithm")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-Algorithm", valid_614600
  var valid_614601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614601 = validateParameter(valid_614601, JString, required = false,
                                 default = nil)
  if valid_614601 != nil:
    section.add "X-Amz-SignedHeaders", valid_614601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614603: Call_ListHumanTaskUis_614589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_614603.validator(path, query, header, formData, body)
  let scheme = call_614603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614603.url(scheme.get, call_614603.host, call_614603.base,
                         call_614603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614603, url, valid)

proc call*(call_614604: Call_ListHumanTaskUis_614589; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614605 = newJObject()
  var body_614606 = newJObject()
  add(query_614605, "MaxResults", newJString(MaxResults))
  add(query_614605, "NextToken", newJString(NextToken))
  if body != nil:
    body_614606 = body
  result = call_614604.call(nil, query_614605, nil, nil, body_614606)

var listHumanTaskUis* = Call_ListHumanTaskUis_614589(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_614590, base: "/",
    url: url_ListHumanTaskUis_614591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_614607 = ref object of OpenApiRestCall_612658
proc url_ListHyperParameterTuningJobs_614609(protocol: Scheme; host: string;
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

proc validate_ListHyperParameterTuningJobs_614608(path: JsonNode; query: JsonNode;
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
  var valid_614610 = query.getOrDefault("MaxResults")
  valid_614610 = validateParameter(valid_614610, JString, required = false,
                                 default = nil)
  if valid_614610 != nil:
    section.add "MaxResults", valid_614610
  var valid_614611 = query.getOrDefault("NextToken")
  valid_614611 = validateParameter(valid_614611, JString, required = false,
                                 default = nil)
  if valid_614611 != nil:
    section.add "NextToken", valid_614611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614612 = header.getOrDefault("X-Amz-Target")
  valid_614612 = validateParameter(valid_614612, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_614612 != nil:
    section.add "X-Amz-Target", valid_614612
  var valid_614613 = header.getOrDefault("X-Amz-Signature")
  valid_614613 = validateParameter(valid_614613, JString, required = false,
                                 default = nil)
  if valid_614613 != nil:
    section.add "X-Amz-Signature", valid_614613
  var valid_614614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614614 = validateParameter(valid_614614, JString, required = false,
                                 default = nil)
  if valid_614614 != nil:
    section.add "X-Amz-Content-Sha256", valid_614614
  var valid_614615 = header.getOrDefault("X-Amz-Date")
  valid_614615 = validateParameter(valid_614615, JString, required = false,
                                 default = nil)
  if valid_614615 != nil:
    section.add "X-Amz-Date", valid_614615
  var valid_614616 = header.getOrDefault("X-Amz-Credential")
  valid_614616 = validateParameter(valid_614616, JString, required = false,
                                 default = nil)
  if valid_614616 != nil:
    section.add "X-Amz-Credential", valid_614616
  var valid_614617 = header.getOrDefault("X-Amz-Security-Token")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "X-Amz-Security-Token", valid_614617
  var valid_614618 = header.getOrDefault("X-Amz-Algorithm")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "X-Amz-Algorithm", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-SignedHeaders", valid_614619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614621: Call_ListHyperParameterTuningJobs_614607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_614621.validator(path, query, header, formData, body)
  let scheme = call_614621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614621.url(scheme.get, call_614621.host, call_614621.base,
                         call_614621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614621, url, valid)

proc call*(call_614622: Call_ListHyperParameterTuningJobs_614607; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614623 = newJObject()
  var body_614624 = newJObject()
  add(query_614623, "MaxResults", newJString(MaxResults))
  add(query_614623, "NextToken", newJString(NextToken))
  if body != nil:
    body_614624 = body
  result = call_614622.call(nil, query_614623, nil, nil, body_614624)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_614607(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_614608, base: "/",
    url: url_ListHyperParameterTuningJobs_614609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_614625 = ref object of OpenApiRestCall_612658
proc url_ListLabelingJobs_614627(protocol: Scheme; host: string; base: string;
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

proc validate_ListLabelingJobs_614626(path: JsonNode; query: JsonNode;
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
  var valid_614628 = query.getOrDefault("MaxResults")
  valid_614628 = validateParameter(valid_614628, JString, required = false,
                                 default = nil)
  if valid_614628 != nil:
    section.add "MaxResults", valid_614628
  var valid_614629 = query.getOrDefault("NextToken")
  valid_614629 = validateParameter(valid_614629, JString, required = false,
                                 default = nil)
  if valid_614629 != nil:
    section.add "NextToken", valid_614629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614630 = header.getOrDefault("X-Amz-Target")
  valid_614630 = validateParameter(valid_614630, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_614630 != nil:
    section.add "X-Amz-Target", valid_614630
  var valid_614631 = header.getOrDefault("X-Amz-Signature")
  valid_614631 = validateParameter(valid_614631, JString, required = false,
                                 default = nil)
  if valid_614631 != nil:
    section.add "X-Amz-Signature", valid_614631
  var valid_614632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "X-Amz-Content-Sha256", valid_614632
  var valid_614633 = header.getOrDefault("X-Amz-Date")
  valid_614633 = validateParameter(valid_614633, JString, required = false,
                                 default = nil)
  if valid_614633 != nil:
    section.add "X-Amz-Date", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Credential")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Credential", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Security-Token")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Security-Token", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Algorithm")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Algorithm", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-SignedHeaders", valid_614637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614639: Call_ListLabelingJobs_614625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_614639.validator(path, query, header, formData, body)
  let scheme = call_614639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614639.url(scheme.get, call_614639.host, call_614639.base,
                         call_614639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614639, url, valid)

proc call*(call_614640: Call_ListLabelingJobs_614625; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614641 = newJObject()
  var body_614642 = newJObject()
  add(query_614641, "MaxResults", newJString(MaxResults))
  add(query_614641, "NextToken", newJString(NextToken))
  if body != nil:
    body_614642 = body
  result = call_614640.call(nil, query_614641, nil, nil, body_614642)

var listLabelingJobs* = Call_ListLabelingJobs_614625(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_614626, base: "/",
    url: url_ListLabelingJobs_614627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_614643 = ref object of OpenApiRestCall_612658
proc url_ListLabelingJobsForWorkteam_614645(protocol: Scheme; host: string;
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

proc validate_ListLabelingJobsForWorkteam_614644(path: JsonNode; query: JsonNode;
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
  var valid_614646 = query.getOrDefault("MaxResults")
  valid_614646 = validateParameter(valid_614646, JString, required = false,
                                 default = nil)
  if valid_614646 != nil:
    section.add "MaxResults", valid_614646
  var valid_614647 = query.getOrDefault("NextToken")
  valid_614647 = validateParameter(valid_614647, JString, required = false,
                                 default = nil)
  if valid_614647 != nil:
    section.add "NextToken", valid_614647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614648 = header.getOrDefault("X-Amz-Target")
  valid_614648 = validateParameter(valid_614648, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_614648 != nil:
    section.add "X-Amz-Target", valid_614648
  var valid_614649 = header.getOrDefault("X-Amz-Signature")
  valid_614649 = validateParameter(valid_614649, JString, required = false,
                                 default = nil)
  if valid_614649 != nil:
    section.add "X-Amz-Signature", valid_614649
  var valid_614650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614650 = validateParameter(valid_614650, JString, required = false,
                                 default = nil)
  if valid_614650 != nil:
    section.add "X-Amz-Content-Sha256", valid_614650
  var valid_614651 = header.getOrDefault("X-Amz-Date")
  valid_614651 = validateParameter(valid_614651, JString, required = false,
                                 default = nil)
  if valid_614651 != nil:
    section.add "X-Amz-Date", valid_614651
  var valid_614652 = header.getOrDefault("X-Amz-Credential")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "X-Amz-Credential", valid_614652
  var valid_614653 = header.getOrDefault("X-Amz-Security-Token")
  valid_614653 = validateParameter(valid_614653, JString, required = false,
                                 default = nil)
  if valid_614653 != nil:
    section.add "X-Amz-Security-Token", valid_614653
  var valid_614654 = header.getOrDefault("X-Amz-Algorithm")
  valid_614654 = validateParameter(valid_614654, JString, required = false,
                                 default = nil)
  if valid_614654 != nil:
    section.add "X-Amz-Algorithm", valid_614654
  var valid_614655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "X-Amz-SignedHeaders", valid_614655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614657: Call_ListLabelingJobsForWorkteam_614643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_614657.validator(path, query, header, formData, body)
  let scheme = call_614657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614657.url(scheme.get, call_614657.host, call_614657.base,
                         call_614657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614657, url, valid)

proc call*(call_614658: Call_ListLabelingJobsForWorkteam_614643; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614659 = newJObject()
  var body_614660 = newJObject()
  add(query_614659, "MaxResults", newJString(MaxResults))
  add(query_614659, "NextToken", newJString(NextToken))
  if body != nil:
    body_614660 = body
  result = call_614658.call(nil, query_614659, nil, nil, body_614660)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_614643(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_614644, base: "/",
    url: url_ListLabelingJobsForWorkteam_614645,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_614661 = ref object of OpenApiRestCall_612658
proc url_ListModelPackages_614663(protocol: Scheme; host: string; base: string;
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

proc validate_ListModelPackages_614662(path: JsonNode; query: JsonNode;
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
  var valid_614664 = query.getOrDefault("MaxResults")
  valid_614664 = validateParameter(valid_614664, JString, required = false,
                                 default = nil)
  if valid_614664 != nil:
    section.add "MaxResults", valid_614664
  var valid_614665 = query.getOrDefault("NextToken")
  valid_614665 = validateParameter(valid_614665, JString, required = false,
                                 default = nil)
  if valid_614665 != nil:
    section.add "NextToken", valid_614665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614666 = header.getOrDefault("X-Amz-Target")
  valid_614666 = validateParameter(valid_614666, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_614666 != nil:
    section.add "X-Amz-Target", valid_614666
  var valid_614667 = header.getOrDefault("X-Amz-Signature")
  valid_614667 = validateParameter(valid_614667, JString, required = false,
                                 default = nil)
  if valid_614667 != nil:
    section.add "X-Amz-Signature", valid_614667
  var valid_614668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614668 = validateParameter(valid_614668, JString, required = false,
                                 default = nil)
  if valid_614668 != nil:
    section.add "X-Amz-Content-Sha256", valid_614668
  var valid_614669 = header.getOrDefault("X-Amz-Date")
  valid_614669 = validateParameter(valid_614669, JString, required = false,
                                 default = nil)
  if valid_614669 != nil:
    section.add "X-Amz-Date", valid_614669
  var valid_614670 = header.getOrDefault("X-Amz-Credential")
  valid_614670 = validateParameter(valid_614670, JString, required = false,
                                 default = nil)
  if valid_614670 != nil:
    section.add "X-Amz-Credential", valid_614670
  var valid_614671 = header.getOrDefault("X-Amz-Security-Token")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "X-Amz-Security-Token", valid_614671
  var valid_614672 = header.getOrDefault("X-Amz-Algorithm")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Algorithm", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-SignedHeaders", valid_614673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614675: Call_ListModelPackages_614661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_614675.validator(path, query, header, formData, body)
  let scheme = call_614675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614675.url(scheme.get, call_614675.host, call_614675.base,
                         call_614675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614675, url, valid)

proc call*(call_614676: Call_ListModelPackages_614661; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614677 = newJObject()
  var body_614678 = newJObject()
  add(query_614677, "MaxResults", newJString(MaxResults))
  add(query_614677, "NextToken", newJString(NextToken))
  if body != nil:
    body_614678 = body
  result = call_614676.call(nil, query_614677, nil, nil, body_614678)

var listModelPackages* = Call_ListModelPackages_614661(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_614662, base: "/",
    url: url_ListModelPackages_614663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_614679 = ref object of OpenApiRestCall_612658
proc url_ListModels_614681(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModels_614680(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614682 = query.getOrDefault("MaxResults")
  valid_614682 = validateParameter(valid_614682, JString, required = false,
                                 default = nil)
  if valid_614682 != nil:
    section.add "MaxResults", valid_614682
  var valid_614683 = query.getOrDefault("NextToken")
  valid_614683 = validateParameter(valid_614683, JString, required = false,
                                 default = nil)
  if valid_614683 != nil:
    section.add "NextToken", valid_614683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614684 = header.getOrDefault("X-Amz-Target")
  valid_614684 = validateParameter(valid_614684, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_614684 != nil:
    section.add "X-Amz-Target", valid_614684
  var valid_614685 = header.getOrDefault("X-Amz-Signature")
  valid_614685 = validateParameter(valid_614685, JString, required = false,
                                 default = nil)
  if valid_614685 != nil:
    section.add "X-Amz-Signature", valid_614685
  var valid_614686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614686 = validateParameter(valid_614686, JString, required = false,
                                 default = nil)
  if valid_614686 != nil:
    section.add "X-Amz-Content-Sha256", valid_614686
  var valid_614687 = header.getOrDefault("X-Amz-Date")
  valid_614687 = validateParameter(valid_614687, JString, required = false,
                                 default = nil)
  if valid_614687 != nil:
    section.add "X-Amz-Date", valid_614687
  var valid_614688 = header.getOrDefault("X-Amz-Credential")
  valid_614688 = validateParameter(valid_614688, JString, required = false,
                                 default = nil)
  if valid_614688 != nil:
    section.add "X-Amz-Credential", valid_614688
  var valid_614689 = header.getOrDefault("X-Amz-Security-Token")
  valid_614689 = validateParameter(valid_614689, JString, required = false,
                                 default = nil)
  if valid_614689 != nil:
    section.add "X-Amz-Security-Token", valid_614689
  var valid_614690 = header.getOrDefault("X-Amz-Algorithm")
  valid_614690 = validateParameter(valid_614690, JString, required = false,
                                 default = nil)
  if valid_614690 != nil:
    section.add "X-Amz-Algorithm", valid_614690
  var valid_614691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "X-Amz-SignedHeaders", valid_614691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614693: Call_ListModels_614679; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_614693.validator(path, query, header, formData, body)
  let scheme = call_614693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614693.url(scheme.get, call_614693.host, call_614693.base,
                         call_614693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614693, url, valid)

proc call*(call_614694: Call_ListModels_614679; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614695 = newJObject()
  var body_614696 = newJObject()
  add(query_614695, "MaxResults", newJString(MaxResults))
  add(query_614695, "NextToken", newJString(NextToken))
  if body != nil:
    body_614696 = body
  result = call_614694.call(nil, query_614695, nil, nil, body_614696)

var listModels* = Call_ListModels_614679(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_614680,
                                      base: "/", url: url_ListModels_614681,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_614697 = ref object of OpenApiRestCall_612658
proc url_ListMonitoringExecutions_614699(protocol: Scheme; host: string;
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

proc validate_ListMonitoringExecutions_614698(path: JsonNode; query: JsonNode;
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
  var valid_614700 = query.getOrDefault("MaxResults")
  valid_614700 = validateParameter(valid_614700, JString, required = false,
                                 default = nil)
  if valid_614700 != nil:
    section.add "MaxResults", valid_614700
  var valid_614701 = query.getOrDefault("NextToken")
  valid_614701 = validateParameter(valid_614701, JString, required = false,
                                 default = nil)
  if valid_614701 != nil:
    section.add "NextToken", valid_614701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614702 = header.getOrDefault("X-Amz-Target")
  valid_614702 = validateParameter(valid_614702, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_614702 != nil:
    section.add "X-Amz-Target", valid_614702
  var valid_614703 = header.getOrDefault("X-Amz-Signature")
  valid_614703 = validateParameter(valid_614703, JString, required = false,
                                 default = nil)
  if valid_614703 != nil:
    section.add "X-Amz-Signature", valid_614703
  var valid_614704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614704 = validateParameter(valid_614704, JString, required = false,
                                 default = nil)
  if valid_614704 != nil:
    section.add "X-Amz-Content-Sha256", valid_614704
  var valid_614705 = header.getOrDefault("X-Amz-Date")
  valid_614705 = validateParameter(valid_614705, JString, required = false,
                                 default = nil)
  if valid_614705 != nil:
    section.add "X-Amz-Date", valid_614705
  var valid_614706 = header.getOrDefault("X-Amz-Credential")
  valid_614706 = validateParameter(valid_614706, JString, required = false,
                                 default = nil)
  if valid_614706 != nil:
    section.add "X-Amz-Credential", valid_614706
  var valid_614707 = header.getOrDefault("X-Amz-Security-Token")
  valid_614707 = validateParameter(valid_614707, JString, required = false,
                                 default = nil)
  if valid_614707 != nil:
    section.add "X-Amz-Security-Token", valid_614707
  var valid_614708 = header.getOrDefault("X-Amz-Algorithm")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Algorithm", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-SignedHeaders", valid_614709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614711: Call_ListMonitoringExecutions_614697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_614711.validator(path, query, header, formData, body)
  let scheme = call_614711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614711.url(scheme.get, call_614711.host, call_614711.base,
                         call_614711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614711, url, valid)

proc call*(call_614712: Call_ListMonitoringExecutions_614697; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614713 = newJObject()
  var body_614714 = newJObject()
  add(query_614713, "MaxResults", newJString(MaxResults))
  add(query_614713, "NextToken", newJString(NextToken))
  if body != nil:
    body_614714 = body
  result = call_614712.call(nil, query_614713, nil, nil, body_614714)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_614697(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_614698, base: "/",
    url: url_ListMonitoringExecutions_614699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_614715 = ref object of OpenApiRestCall_612658
proc url_ListMonitoringSchedules_614717(protocol: Scheme; host: string; base: string;
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

proc validate_ListMonitoringSchedules_614716(path: JsonNode; query: JsonNode;
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
  var valid_614718 = query.getOrDefault("MaxResults")
  valid_614718 = validateParameter(valid_614718, JString, required = false,
                                 default = nil)
  if valid_614718 != nil:
    section.add "MaxResults", valid_614718
  var valid_614719 = query.getOrDefault("NextToken")
  valid_614719 = validateParameter(valid_614719, JString, required = false,
                                 default = nil)
  if valid_614719 != nil:
    section.add "NextToken", valid_614719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614720 = header.getOrDefault("X-Amz-Target")
  valid_614720 = validateParameter(valid_614720, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_614720 != nil:
    section.add "X-Amz-Target", valid_614720
  var valid_614721 = header.getOrDefault("X-Amz-Signature")
  valid_614721 = validateParameter(valid_614721, JString, required = false,
                                 default = nil)
  if valid_614721 != nil:
    section.add "X-Amz-Signature", valid_614721
  var valid_614722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614722 = validateParameter(valid_614722, JString, required = false,
                                 default = nil)
  if valid_614722 != nil:
    section.add "X-Amz-Content-Sha256", valid_614722
  var valid_614723 = header.getOrDefault("X-Amz-Date")
  valid_614723 = validateParameter(valid_614723, JString, required = false,
                                 default = nil)
  if valid_614723 != nil:
    section.add "X-Amz-Date", valid_614723
  var valid_614724 = header.getOrDefault("X-Amz-Credential")
  valid_614724 = validateParameter(valid_614724, JString, required = false,
                                 default = nil)
  if valid_614724 != nil:
    section.add "X-Amz-Credential", valid_614724
  var valid_614725 = header.getOrDefault("X-Amz-Security-Token")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "X-Amz-Security-Token", valid_614725
  var valid_614726 = header.getOrDefault("X-Amz-Algorithm")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "X-Amz-Algorithm", valid_614726
  var valid_614727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614727 = validateParameter(valid_614727, JString, required = false,
                                 default = nil)
  if valid_614727 != nil:
    section.add "X-Amz-SignedHeaders", valid_614727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614729: Call_ListMonitoringSchedules_614715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_614729.validator(path, query, header, formData, body)
  let scheme = call_614729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614729.url(scheme.get, call_614729.host, call_614729.base,
                         call_614729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614729, url, valid)

proc call*(call_614730: Call_ListMonitoringSchedules_614715; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614731 = newJObject()
  var body_614732 = newJObject()
  add(query_614731, "MaxResults", newJString(MaxResults))
  add(query_614731, "NextToken", newJString(NextToken))
  if body != nil:
    body_614732 = body
  result = call_614730.call(nil, query_614731, nil, nil, body_614732)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_614715(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_614716, base: "/",
    url: url_ListMonitoringSchedules_614717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_614733 = ref object of OpenApiRestCall_612658
proc url_ListNotebookInstanceLifecycleConfigs_614735(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_614734(path: JsonNode;
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
  var valid_614736 = query.getOrDefault("MaxResults")
  valid_614736 = validateParameter(valid_614736, JString, required = false,
                                 default = nil)
  if valid_614736 != nil:
    section.add "MaxResults", valid_614736
  var valid_614737 = query.getOrDefault("NextToken")
  valid_614737 = validateParameter(valid_614737, JString, required = false,
                                 default = nil)
  if valid_614737 != nil:
    section.add "NextToken", valid_614737
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614738 = header.getOrDefault("X-Amz-Target")
  valid_614738 = validateParameter(valid_614738, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_614738 != nil:
    section.add "X-Amz-Target", valid_614738
  var valid_614739 = header.getOrDefault("X-Amz-Signature")
  valid_614739 = validateParameter(valid_614739, JString, required = false,
                                 default = nil)
  if valid_614739 != nil:
    section.add "X-Amz-Signature", valid_614739
  var valid_614740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614740 = validateParameter(valid_614740, JString, required = false,
                                 default = nil)
  if valid_614740 != nil:
    section.add "X-Amz-Content-Sha256", valid_614740
  var valid_614741 = header.getOrDefault("X-Amz-Date")
  valid_614741 = validateParameter(valid_614741, JString, required = false,
                                 default = nil)
  if valid_614741 != nil:
    section.add "X-Amz-Date", valid_614741
  var valid_614742 = header.getOrDefault("X-Amz-Credential")
  valid_614742 = validateParameter(valid_614742, JString, required = false,
                                 default = nil)
  if valid_614742 != nil:
    section.add "X-Amz-Credential", valid_614742
  var valid_614743 = header.getOrDefault("X-Amz-Security-Token")
  valid_614743 = validateParameter(valid_614743, JString, required = false,
                                 default = nil)
  if valid_614743 != nil:
    section.add "X-Amz-Security-Token", valid_614743
  var valid_614744 = header.getOrDefault("X-Amz-Algorithm")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Algorithm", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-SignedHeaders", valid_614745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614747: Call_ListNotebookInstanceLifecycleConfigs_614733;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_614747.validator(path, query, header, formData, body)
  let scheme = call_614747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614747.url(scheme.get, call_614747.host, call_614747.base,
                         call_614747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614747, url, valid)

proc call*(call_614748: Call_ListNotebookInstanceLifecycleConfigs_614733;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614749 = newJObject()
  var body_614750 = newJObject()
  add(query_614749, "MaxResults", newJString(MaxResults))
  add(query_614749, "NextToken", newJString(NextToken))
  if body != nil:
    body_614750 = body
  result = call_614748.call(nil, query_614749, nil, nil, body_614750)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_614733(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_614734, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_614735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_614751 = ref object of OpenApiRestCall_612658
proc url_ListNotebookInstances_614753(protocol: Scheme; host: string; base: string;
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

proc validate_ListNotebookInstances_614752(path: JsonNode; query: JsonNode;
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
  var valid_614754 = query.getOrDefault("MaxResults")
  valid_614754 = validateParameter(valid_614754, JString, required = false,
                                 default = nil)
  if valid_614754 != nil:
    section.add "MaxResults", valid_614754
  var valid_614755 = query.getOrDefault("NextToken")
  valid_614755 = validateParameter(valid_614755, JString, required = false,
                                 default = nil)
  if valid_614755 != nil:
    section.add "NextToken", valid_614755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614756 = header.getOrDefault("X-Amz-Target")
  valid_614756 = validateParameter(valid_614756, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_614756 != nil:
    section.add "X-Amz-Target", valid_614756
  var valid_614757 = header.getOrDefault("X-Amz-Signature")
  valid_614757 = validateParameter(valid_614757, JString, required = false,
                                 default = nil)
  if valid_614757 != nil:
    section.add "X-Amz-Signature", valid_614757
  var valid_614758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614758 = validateParameter(valid_614758, JString, required = false,
                                 default = nil)
  if valid_614758 != nil:
    section.add "X-Amz-Content-Sha256", valid_614758
  var valid_614759 = header.getOrDefault("X-Amz-Date")
  valid_614759 = validateParameter(valid_614759, JString, required = false,
                                 default = nil)
  if valid_614759 != nil:
    section.add "X-Amz-Date", valid_614759
  var valid_614760 = header.getOrDefault("X-Amz-Credential")
  valid_614760 = validateParameter(valid_614760, JString, required = false,
                                 default = nil)
  if valid_614760 != nil:
    section.add "X-Amz-Credential", valid_614760
  var valid_614761 = header.getOrDefault("X-Amz-Security-Token")
  valid_614761 = validateParameter(valid_614761, JString, required = false,
                                 default = nil)
  if valid_614761 != nil:
    section.add "X-Amz-Security-Token", valid_614761
  var valid_614762 = header.getOrDefault("X-Amz-Algorithm")
  valid_614762 = validateParameter(valid_614762, JString, required = false,
                                 default = nil)
  if valid_614762 != nil:
    section.add "X-Amz-Algorithm", valid_614762
  var valid_614763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614763 = validateParameter(valid_614763, JString, required = false,
                                 default = nil)
  if valid_614763 != nil:
    section.add "X-Amz-SignedHeaders", valid_614763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614765: Call_ListNotebookInstances_614751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_614765.validator(path, query, header, formData, body)
  let scheme = call_614765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614765.url(scheme.get, call_614765.host, call_614765.base,
                         call_614765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614765, url, valid)

proc call*(call_614766: Call_ListNotebookInstances_614751; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614767 = newJObject()
  var body_614768 = newJObject()
  add(query_614767, "MaxResults", newJString(MaxResults))
  add(query_614767, "NextToken", newJString(NextToken))
  if body != nil:
    body_614768 = body
  result = call_614766.call(nil, query_614767, nil, nil, body_614768)

var listNotebookInstances* = Call_ListNotebookInstances_614751(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_614752, base: "/",
    url: url_ListNotebookInstances_614753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_614769 = ref object of OpenApiRestCall_612658
proc url_ListProcessingJobs_614771(protocol: Scheme; host: string; base: string;
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

proc validate_ListProcessingJobs_614770(path: JsonNode; query: JsonNode;
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
  var valid_614772 = query.getOrDefault("MaxResults")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "MaxResults", valid_614772
  var valid_614773 = query.getOrDefault("NextToken")
  valid_614773 = validateParameter(valid_614773, JString, required = false,
                                 default = nil)
  if valid_614773 != nil:
    section.add "NextToken", valid_614773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614774 = header.getOrDefault("X-Amz-Target")
  valid_614774 = validateParameter(valid_614774, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_614774 != nil:
    section.add "X-Amz-Target", valid_614774
  var valid_614775 = header.getOrDefault("X-Amz-Signature")
  valid_614775 = validateParameter(valid_614775, JString, required = false,
                                 default = nil)
  if valid_614775 != nil:
    section.add "X-Amz-Signature", valid_614775
  var valid_614776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614776 = validateParameter(valid_614776, JString, required = false,
                                 default = nil)
  if valid_614776 != nil:
    section.add "X-Amz-Content-Sha256", valid_614776
  var valid_614777 = header.getOrDefault("X-Amz-Date")
  valid_614777 = validateParameter(valid_614777, JString, required = false,
                                 default = nil)
  if valid_614777 != nil:
    section.add "X-Amz-Date", valid_614777
  var valid_614778 = header.getOrDefault("X-Amz-Credential")
  valid_614778 = validateParameter(valid_614778, JString, required = false,
                                 default = nil)
  if valid_614778 != nil:
    section.add "X-Amz-Credential", valid_614778
  var valid_614779 = header.getOrDefault("X-Amz-Security-Token")
  valid_614779 = validateParameter(valid_614779, JString, required = false,
                                 default = nil)
  if valid_614779 != nil:
    section.add "X-Amz-Security-Token", valid_614779
  var valid_614780 = header.getOrDefault("X-Amz-Algorithm")
  valid_614780 = validateParameter(valid_614780, JString, required = false,
                                 default = nil)
  if valid_614780 != nil:
    section.add "X-Amz-Algorithm", valid_614780
  var valid_614781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-SignedHeaders", valid_614781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614783: Call_ListProcessingJobs_614769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_614783.validator(path, query, header, formData, body)
  let scheme = call_614783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614783.url(scheme.get, call_614783.host, call_614783.base,
                         call_614783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614783, url, valid)

proc call*(call_614784: Call_ListProcessingJobs_614769; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614785 = newJObject()
  var body_614786 = newJObject()
  add(query_614785, "MaxResults", newJString(MaxResults))
  add(query_614785, "NextToken", newJString(NextToken))
  if body != nil:
    body_614786 = body
  result = call_614784.call(nil, query_614785, nil, nil, body_614786)

var listProcessingJobs* = Call_ListProcessingJobs_614769(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_614770, base: "/",
    url: url_ListProcessingJobs_614771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_614787 = ref object of OpenApiRestCall_612658
proc url_ListSubscribedWorkteams_614789(protocol: Scheme; host: string; base: string;
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

proc validate_ListSubscribedWorkteams_614788(path: JsonNode; query: JsonNode;
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
  var valid_614790 = query.getOrDefault("MaxResults")
  valid_614790 = validateParameter(valid_614790, JString, required = false,
                                 default = nil)
  if valid_614790 != nil:
    section.add "MaxResults", valid_614790
  var valid_614791 = query.getOrDefault("NextToken")
  valid_614791 = validateParameter(valid_614791, JString, required = false,
                                 default = nil)
  if valid_614791 != nil:
    section.add "NextToken", valid_614791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614792 = header.getOrDefault("X-Amz-Target")
  valid_614792 = validateParameter(valid_614792, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_614792 != nil:
    section.add "X-Amz-Target", valid_614792
  var valid_614793 = header.getOrDefault("X-Amz-Signature")
  valid_614793 = validateParameter(valid_614793, JString, required = false,
                                 default = nil)
  if valid_614793 != nil:
    section.add "X-Amz-Signature", valid_614793
  var valid_614794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614794 = validateParameter(valid_614794, JString, required = false,
                                 default = nil)
  if valid_614794 != nil:
    section.add "X-Amz-Content-Sha256", valid_614794
  var valid_614795 = header.getOrDefault("X-Amz-Date")
  valid_614795 = validateParameter(valid_614795, JString, required = false,
                                 default = nil)
  if valid_614795 != nil:
    section.add "X-Amz-Date", valid_614795
  var valid_614796 = header.getOrDefault("X-Amz-Credential")
  valid_614796 = validateParameter(valid_614796, JString, required = false,
                                 default = nil)
  if valid_614796 != nil:
    section.add "X-Amz-Credential", valid_614796
  var valid_614797 = header.getOrDefault("X-Amz-Security-Token")
  valid_614797 = validateParameter(valid_614797, JString, required = false,
                                 default = nil)
  if valid_614797 != nil:
    section.add "X-Amz-Security-Token", valid_614797
  var valid_614798 = header.getOrDefault("X-Amz-Algorithm")
  valid_614798 = validateParameter(valid_614798, JString, required = false,
                                 default = nil)
  if valid_614798 != nil:
    section.add "X-Amz-Algorithm", valid_614798
  var valid_614799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614799 = validateParameter(valid_614799, JString, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "X-Amz-SignedHeaders", valid_614799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614801: Call_ListSubscribedWorkteams_614787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_614801.validator(path, query, header, formData, body)
  let scheme = call_614801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614801.url(scheme.get, call_614801.host, call_614801.base,
                         call_614801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614801, url, valid)

proc call*(call_614802: Call_ListSubscribedWorkteams_614787; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614803 = newJObject()
  var body_614804 = newJObject()
  add(query_614803, "MaxResults", newJString(MaxResults))
  add(query_614803, "NextToken", newJString(NextToken))
  if body != nil:
    body_614804 = body
  result = call_614802.call(nil, query_614803, nil, nil, body_614804)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_614787(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_614788, base: "/",
    url: url_ListSubscribedWorkteams_614789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_614805 = ref object of OpenApiRestCall_612658
proc url_ListTags_614807(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_614806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614808 = query.getOrDefault("MaxResults")
  valid_614808 = validateParameter(valid_614808, JString, required = false,
                                 default = nil)
  if valid_614808 != nil:
    section.add "MaxResults", valid_614808
  var valid_614809 = query.getOrDefault("NextToken")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "NextToken", valid_614809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614810 = header.getOrDefault("X-Amz-Target")
  valid_614810 = validateParameter(valid_614810, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_614810 != nil:
    section.add "X-Amz-Target", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-Signature")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-Signature", valid_614811
  var valid_614812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614812 = validateParameter(valid_614812, JString, required = false,
                                 default = nil)
  if valid_614812 != nil:
    section.add "X-Amz-Content-Sha256", valid_614812
  var valid_614813 = header.getOrDefault("X-Amz-Date")
  valid_614813 = validateParameter(valid_614813, JString, required = false,
                                 default = nil)
  if valid_614813 != nil:
    section.add "X-Amz-Date", valid_614813
  var valid_614814 = header.getOrDefault("X-Amz-Credential")
  valid_614814 = validateParameter(valid_614814, JString, required = false,
                                 default = nil)
  if valid_614814 != nil:
    section.add "X-Amz-Credential", valid_614814
  var valid_614815 = header.getOrDefault("X-Amz-Security-Token")
  valid_614815 = validateParameter(valid_614815, JString, required = false,
                                 default = nil)
  if valid_614815 != nil:
    section.add "X-Amz-Security-Token", valid_614815
  var valid_614816 = header.getOrDefault("X-Amz-Algorithm")
  valid_614816 = validateParameter(valid_614816, JString, required = false,
                                 default = nil)
  if valid_614816 != nil:
    section.add "X-Amz-Algorithm", valid_614816
  var valid_614817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614817 = validateParameter(valid_614817, JString, required = false,
                                 default = nil)
  if valid_614817 != nil:
    section.add "X-Amz-SignedHeaders", valid_614817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614819: Call_ListTags_614805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_614819.validator(path, query, header, formData, body)
  let scheme = call_614819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614819.url(scheme.get, call_614819.host, call_614819.base,
                         call_614819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614819, url, valid)

proc call*(call_614820: Call_ListTags_614805; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614821 = newJObject()
  var body_614822 = newJObject()
  add(query_614821, "MaxResults", newJString(MaxResults))
  add(query_614821, "NextToken", newJString(NextToken))
  if body != nil:
    body_614822 = body
  result = call_614820.call(nil, query_614821, nil, nil, body_614822)

var listTags* = Call_ListTags_614805(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_614806, base: "/",
                                  url: url_ListTags_614807,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_614823 = ref object of OpenApiRestCall_612658
proc url_ListTrainingJobs_614825(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrainingJobs_614824(path: JsonNode; query: JsonNode;
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
  var valid_614826 = query.getOrDefault("MaxResults")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "MaxResults", valid_614826
  var valid_614827 = query.getOrDefault("NextToken")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "NextToken", valid_614827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614828 = header.getOrDefault("X-Amz-Target")
  valid_614828 = validateParameter(valid_614828, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_614828 != nil:
    section.add "X-Amz-Target", valid_614828
  var valid_614829 = header.getOrDefault("X-Amz-Signature")
  valid_614829 = validateParameter(valid_614829, JString, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "X-Amz-Signature", valid_614829
  var valid_614830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614830 = validateParameter(valid_614830, JString, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "X-Amz-Content-Sha256", valid_614830
  var valid_614831 = header.getOrDefault("X-Amz-Date")
  valid_614831 = validateParameter(valid_614831, JString, required = false,
                                 default = nil)
  if valid_614831 != nil:
    section.add "X-Amz-Date", valid_614831
  var valid_614832 = header.getOrDefault("X-Amz-Credential")
  valid_614832 = validateParameter(valid_614832, JString, required = false,
                                 default = nil)
  if valid_614832 != nil:
    section.add "X-Amz-Credential", valid_614832
  var valid_614833 = header.getOrDefault("X-Amz-Security-Token")
  valid_614833 = validateParameter(valid_614833, JString, required = false,
                                 default = nil)
  if valid_614833 != nil:
    section.add "X-Amz-Security-Token", valid_614833
  var valid_614834 = header.getOrDefault("X-Amz-Algorithm")
  valid_614834 = validateParameter(valid_614834, JString, required = false,
                                 default = nil)
  if valid_614834 != nil:
    section.add "X-Amz-Algorithm", valid_614834
  var valid_614835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614835 = validateParameter(valid_614835, JString, required = false,
                                 default = nil)
  if valid_614835 != nil:
    section.add "X-Amz-SignedHeaders", valid_614835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614837: Call_ListTrainingJobs_614823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_614837.validator(path, query, header, formData, body)
  let scheme = call_614837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614837.url(scheme.get, call_614837.host, call_614837.base,
                         call_614837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614837, url, valid)

proc call*(call_614838: Call_ListTrainingJobs_614823; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614839 = newJObject()
  var body_614840 = newJObject()
  add(query_614839, "MaxResults", newJString(MaxResults))
  add(query_614839, "NextToken", newJString(NextToken))
  if body != nil:
    body_614840 = body
  result = call_614838.call(nil, query_614839, nil, nil, body_614840)

var listTrainingJobs* = Call_ListTrainingJobs_614823(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_614824, base: "/",
    url: url_ListTrainingJobs_614825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_614841 = ref object of OpenApiRestCall_612658
proc url_ListTrainingJobsForHyperParameterTuningJob_614843(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_614842(path: JsonNode;
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
  var valid_614844 = query.getOrDefault("MaxResults")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "MaxResults", valid_614844
  var valid_614845 = query.getOrDefault("NextToken")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "NextToken", valid_614845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614846 = header.getOrDefault("X-Amz-Target")
  valid_614846 = validateParameter(valid_614846, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_614846 != nil:
    section.add "X-Amz-Target", valid_614846
  var valid_614847 = header.getOrDefault("X-Amz-Signature")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "X-Amz-Signature", valid_614847
  var valid_614848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "X-Amz-Content-Sha256", valid_614848
  var valid_614849 = header.getOrDefault("X-Amz-Date")
  valid_614849 = validateParameter(valid_614849, JString, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "X-Amz-Date", valid_614849
  var valid_614850 = header.getOrDefault("X-Amz-Credential")
  valid_614850 = validateParameter(valid_614850, JString, required = false,
                                 default = nil)
  if valid_614850 != nil:
    section.add "X-Amz-Credential", valid_614850
  var valid_614851 = header.getOrDefault("X-Amz-Security-Token")
  valid_614851 = validateParameter(valid_614851, JString, required = false,
                                 default = nil)
  if valid_614851 != nil:
    section.add "X-Amz-Security-Token", valid_614851
  var valid_614852 = header.getOrDefault("X-Amz-Algorithm")
  valid_614852 = validateParameter(valid_614852, JString, required = false,
                                 default = nil)
  if valid_614852 != nil:
    section.add "X-Amz-Algorithm", valid_614852
  var valid_614853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614853 = validateParameter(valid_614853, JString, required = false,
                                 default = nil)
  if valid_614853 != nil:
    section.add "X-Amz-SignedHeaders", valid_614853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614855: Call_ListTrainingJobsForHyperParameterTuningJob_614841;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_614855.validator(path, query, header, formData, body)
  let scheme = call_614855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614855.url(scheme.get, call_614855.host, call_614855.base,
                         call_614855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614855, url, valid)

proc call*(call_614856: Call_ListTrainingJobsForHyperParameterTuningJob_614841;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614857 = newJObject()
  var body_614858 = newJObject()
  add(query_614857, "MaxResults", newJString(MaxResults))
  add(query_614857, "NextToken", newJString(NextToken))
  if body != nil:
    body_614858 = body
  result = call_614856.call(nil, query_614857, nil, nil, body_614858)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_614841(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_614842,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_614843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_614859 = ref object of OpenApiRestCall_612658
proc url_ListTransformJobs_614861(protocol: Scheme; host: string; base: string;
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

proc validate_ListTransformJobs_614860(path: JsonNode; query: JsonNode;
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
  var valid_614862 = query.getOrDefault("MaxResults")
  valid_614862 = validateParameter(valid_614862, JString, required = false,
                                 default = nil)
  if valid_614862 != nil:
    section.add "MaxResults", valid_614862
  var valid_614863 = query.getOrDefault("NextToken")
  valid_614863 = validateParameter(valid_614863, JString, required = false,
                                 default = nil)
  if valid_614863 != nil:
    section.add "NextToken", valid_614863
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614864 = header.getOrDefault("X-Amz-Target")
  valid_614864 = validateParameter(valid_614864, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_614864 != nil:
    section.add "X-Amz-Target", valid_614864
  var valid_614865 = header.getOrDefault("X-Amz-Signature")
  valid_614865 = validateParameter(valid_614865, JString, required = false,
                                 default = nil)
  if valid_614865 != nil:
    section.add "X-Amz-Signature", valid_614865
  var valid_614866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614866 = validateParameter(valid_614866, JString, required = false,
                                 default = nil)
  if valid_614866 != nil:
    section.add "X-Amz-Content-Sha256", valid_614866
  var valid_614867 = header.getOrDefault("X-Amz-Date")
  valid_614867 = validateParameter(valid_614867, JString, required = false,
                                 default = nil)
  if valid_614867 != nil:
    section.add "X-Amz-Date", valid_614867
  var valid_614868 = header.getOrDefault("X-Amz-Credential")
  valid_614868 = validateParameter(valid_614868, JString, required = false,
                                 default = nil)
  if valid_614868 != nil:
    section.add "X-Amz-Credential", valid_614868
  var valid_614869 = header.getOrDefault("X-Amz-Security-Token")
  valid_614869 = validateParameter(valid_614869, JString, required = false,
                                 default = nil)
  if valid_614869 != nil:
    section.add "X-Amz-Security-Token", valid_614869
  var valid_614870 = header.getOrDefault("X-Amz-Algorithm")
  valid_614870 = validateParameter(valid_614870, JString, required = false,
                                 default = nil)
  if valid_614870 != nil:
    section.add "X-Amz-Algorithm", valid_614870
  var valid_614871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614871 = validateParameter(valid_614871, JString, required = false,
                                 default = nil)
  if valid_614871 != nil:
    section.add "X-Amz-SignedHeaders", valid_614871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614873: Call_ListTransformJobs_614859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_614873.validator(path, query, header, formData, body)
  let scheme = call_614873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614873.url(scheme.get, call_614873.host, call_614873.base,
                         call_614873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614873, url, valid)

proc call*(call_614874: Call_ListTransformJobs_614859; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614875 = newJObject()
  var body_614876 = newJObject()
  add(query_614875, "MaxResults", newJString(MaxResults))
  add(query_614875, "NextToken", newJString(NextToken))
  if body != nil:
    body_614876 = body
  result = call_614874.call(nil, query_614875, nil, nil, body_614876)

var listTransformJobs* = Call_ListTransformJobs_614859(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_614860, base: "/",
    url: url_ListTransformJobs_614861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_614877 = ref object of OpenApiRestCall_612658
proc url_ListTrialComponents_614879(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrialComponents_614878(path: JsonNode; query: JsonNode;
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
  var valid_614880 = query.getOrDefault("MaxResults")
  valid_614880 = validateParameter(valid_614880, JString, required = false,
                                 default = nil)
  if valid_614880 != nil:
    section.add "MaxResults", valid_614880
  var valid_614881 = query.getOrDefault("NextToken")
  valid_614881 = validateParameter(valid_614881, JString, required = false,
                                 default = nil)
  if valid_614881 != nil:
    section.add "NextToken", valid_614881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614882 = header.getOrDefault("X-Amz-Target")
  valid_614882 = validateParameter(valid_614882, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_614882 != nil:
    section.add "X-Amz-Target", valid_614882
  var valid_614883 = header.getOrDefault("X-Amz-Signature")
  valid_614883 = validateParameter(valid_614883, JString, required = false,
                                 default = nil)
  if valid_614883 != nil:
    section.add "X-Amz-Signature", valid_614883
  var valid_614884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "X-Amz-Content-Sha256", valid_614884
  var valid_614885 = header.getOrDefault("X-Amz-Date")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "X-Amz-Date", valid_614885
  var valid_614886 = header.getOrDefault("X-Amz-Credential")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "X-Amz-Credential", valid_614886
  var valid_614887 = header.getOrDefault("X-Amz-Security-Token")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "X-Amz-Security-Token", valid_614887
  var valid_614888 = header.getOrDefault("X-Amz-Algorithm")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "X-Amz-Algorithm", valid_614888
  var valid_614889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "X-Amz-SignedHeaders", valid_614889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614891: Call_ListTrialComponents_614877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ## 
  let valid = call_614891.validator(path, query, header, formData, body)
  let scheme = call_614891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614891.url(scheme.get, call_614891.host, call_614891.base,
                         call_614891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614891, url, valid)

proc call*(call_614892: Call_ListTrialComponents_614877; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614893 = newJObject()
  var body_614894 = newJObject()
  add(query_614893, "MaxResults", newJString(MaxResults))
  add(query_614893, "NextToken", newJString(NextToken))
  if body != nil:
    body_614894 = body
  result = call_614892.call(nil, query_614893, nil, nil, body_614894)

var listTrialComponents* = Call_ListTrialComponents_614877(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_614878, base: "/",
    url: url_ListTrialComponents_614879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_614895 = ref object of OpenApiRestCall_612658
proc url_ListTrials_614897(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrials_614896(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614898 = query.getOrDefault("MaxResults")
  valid_614898 = validateParameter(valid_614898, JString, required = false,
                                 default = nil)
  if valid_614898 != nil:
    section.add "MaxResults", valid_614898
  var valid_614899 = query.getOrDefault("NextToken")
  valid_614899 = validateParameter(valid_614899, JString, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "NextToken", valid_614899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614900 = header.getOrDefault("X-Amz-Target")
  valid_614900 = validateParameter(valid_614900, JString, required = true,
                                 default = newJString("SageMaker.ListTrials"))
  if valid_614900 != nil:
    section.add "X-Amz-Target", valid_614900
  var valid_614901 = header.getOrDefault("X-Amz-Signature")
  valid_614901 = validateParameter(valid_614901, JString, required = false,
                                 default = nil)
  if valid_614901 != nil:
    section.add "X-Amz-Signature", valid_614901
  var valid_614902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614902 = validateParameter(valid_614902, JString, required = false,
                                 default = nil)
  if valid_614902 != nil:
    section.add "X-Amz-Content-Sha256", valid_614902
  var valid_614903 = header.getOrDefault("X-Amz-Date")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Date", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Credential")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Credential", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Security-Token")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Security-Token", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Algorithm")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Algorithm", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-SignedHeaders", valid_614907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614909: Call_ListTrials_614895; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_614909.validator(path, query, header, formData, body)
  let scheme = call_614909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614909.url(scheme.get, call_614909.host, call_614909.base,
                         call_614909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614909, url, valid)

proc call*(call_614910: Call_ListTrials_614895; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614911 = newJObject()
  var body_614912 = newJObject()
  add(query_614911, "MaxResults", newJString(MaxResults))
  add(query_614911, "NextToken", newJString(NextToken))
  if body != nil:
    body_614912 = body
  result = call_614910.call(nil, query_614911, nil, nil, body_614912)

var listTrials* = Call_ListTrials_614895(name: "listTrials",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                      validator: validate_ListTrials_614896,
                                      base: "/", url: url_ListTrials_614897,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_614913 = ref object of OpenApiRestCall_612658
proc url_ListUserProfiles_614915(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserProfiles_614914(path: JsonNode; query: JsonNode;
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
  var valid_614916 = query.getOrDefault("MaxResults")
  valid_614916 = validateParameter(valid_614916, JString, required = false,
                                 default = nil)
  if valid_614916 != nil:
    section.add "MaxResults", valid_614916
  var valid_614917 = query.getOrDefault("NextToken")
  valid_614917 = validateParameter(valid_614917, JString, required = false,
                                 default = nil)
  if valid_614917 != nil:
    section.add "NextToken", valid_614917
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614918 = header.getOrDefault("X-Amz-Target")
  valid_614918 = validateParameter(valid_614918, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_614918 != nil:
    section.add "X-Amz-Target", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Signature")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Signature", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-Content-Sha256", valid_614920
  var valid_614921 = header.getOrDefault("X-Amz-Date")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Date", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-Credential")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Credential", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-Security-Token")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-Security-Token", valid_614923
  var valid_614924 = header.getOrDefault("X-Amz-Algorithm")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "X-Amz-Algorithm", valid_614924
  var valid_614925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614925 = validateParameter(valid_614925, JString, required = false,
                                 default = nil)
  if valid_614925 != nil:
    section.add "X-Amz-SignedHeaders", valid_614925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614927: Call_ListUserProfiles_614913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_614927.validator(path, query, header, formData, body)
  let scheme = call_614927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614927.url(scheme.get, call_614927.host, call_614927.base,
                         call_614927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614927, url, valid)

proc call*(call_614928: Call_ListUserProfiles_614913; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614929 = newJObject()
  var body_614930 = newJObject()
  add(query_614929, "MaxResults", newJString(MaxResults))
  add(query_614929, "NextToken", newJString(NextToken))
  if body != nil:
    body_614930 = body
  result = call_614928.call(nil, query_614929, nil, nil, body_614930)

var listUserProfiles* = Call_ListUserProfiles_614913(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_614914, base: "/",
    url: url_ListUserProfiles_614915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_614931 = ref object of OpenApiRestCall_612658
proc url_ListWorkteams_614933(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkteams_614932(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614934 = query.getOrDefault("MaxResults")
  valid_614934 = validateParameter(valid_614934, JString, required = false,
                                 default = nil)
  if valid_614934 != nil:
    section.add "MaxResults", valid_614934
  var valid_614935 = query.getOrDefault("NextToken")
  valid_614935 = validateParameter(valid_614935, JString, required = false,
                                 default = nil)
  if valid_614935 != nil:
    section.add "NextToken", valid_614935
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614936 = header.getOrDefault("X-Amz-Target")
  valid_614936 = validateParameter(valid_614936, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_614936 != nil:
    section.add "X-Amz-Target", valid_614936
  var valid_614937 = header.getOrDefault("X-Amz-Signature")
  valid_614937 = validateParameter(valid_614937, JString, required = false,
                                 default = nil)
  if valid_614937 != nil:
    section.add "X-Amz-Signature", valid_614937
  var valid_614938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614938 = validateParameter(valid_614938, JString, required = false,
                                 default = nil)
  if valid_614938 != nil:
    section.add "X-Amz-Content-Sha256", valid_614938
  var valid_614939 = header.getOrDefault("X-Amz-Date")
  valid_614939 = validateParameter(valid_614939, JString, required = false,
                                 default = nil)
  if valid_614939 != nil:
    section.add "X-Amz-Date", valid_614939
  var valid_614940 = header.getOrDefault("X-Amz-Credential")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "X-Amz-Credential", valid_614940
  var valid_614941 = header.getOrDefault("X-Amz-Security-Token")
  valid_614941 = validateParameter(valid_614941, JString, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "X-Amz-Security-Token", valid_614941
  var valid_614942 = header.getOrDefault("X-Amz-Algorithm")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "X-Amz-Algorithm", valid_614942
  var valid_614943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614943 = validateParameter(valid_614943, JString, required = false,
                                 default = nil)
  if valid_614943 != nil:
    section.add "X-Amz-SignedHeaders", valid_614943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614945: Call_ListWorkteams_614931; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_614945.validator(path, query, header, formData, body)
  let scheme = call_614945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614945.url(scheme.get, call_614945.host, call_614945.base,
                         call_614945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614945, url, valid)

proc call*(call_614946: Call_ListWorkteams_614931; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614947 = newJObject()
  var body_614948 = newJObject()
  add(query_614947, "MaxResults", newJString(MaxResults))
  add(query_614947, "NextToken", newJString(NextToken))
  if body != nil:
    body_614948 = body
  result = call_614946.call(nil, query_614947, nil, nil, body_614948)

var listWorkteams* = Call_ListWorkteams_614931(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_614932, base: "/", url: url_ListWorkteams_614933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_614949 = ref object of OpenApiRestCall_612658
proc url_RenderUiTemplate_614951(protocol: Scheme; host: string; base: string;
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

proc validate_RenderUiTemplate_614950(path: JsonNode; query: JsonNode;
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
  var valid_614952 = header.getOrDefault("X-Amz-Target")
  valid_614952 = validateParameter(valid_614952, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_614952 != nil:
    section.add "X-Amz-Target", valid_614952
  var valid_614953 = header.getOrDefault("X-Amz-Signature")
  valid_614953 = validateParameter(valid_614953, JString, required = false,
                                 default = nil)
  if valid_614953 != nil:
    section.add "X-Amz-Signature", valid_614953
  var valid_614954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614954 = validateParameter(valid_614954, JString, required = false,
                                 default = nil)
  if valid_614954 != nil:
    section.add "X-Amz-Content-Sha256", valid_614954
  var valid_614955 = header.getOrDefault("X-Amz-Date")
  valid_614955 = validateParameter(valid_614955, JString, required = false,
                                 default = nil)
  if valid_614955 != nil:
    section.add "X-Amz-Date", valid_614955
  var valid_614956 = header.getOrDefault("X-Amz-Credential")
  valid_614956 = validateParameter(valid_614956, JString, required = false,
                                 default = nil)
  if valid_614956 != nil:
    section.add "X-Amz-Credential", valid_614956
  var valid_614957 = header.getOrDefault("X-Amz-Security-Token")
  valid_614957 = validateParameter(valid_614957, JString, required = false,
                                 default = nil)
  if valid_614957 != nil:
    section.add "X-Amz-Security-Token", valid_614957
  var valid_614958 = header.getOrDefault("X-Amz-Algorithm")
  valid_614958 = validateParameter(valid_614958, JString, required = false,
                                 default = nil)
  if valid_614958 != nil:
    section.add "X-Amz-Algorithm", valid_614958
  var valid_614959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "X-Amz-SignedHeaders", valid_614959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614961: Call_RenderUiTemplate_614949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_614961.validator(path, query, header, formData, body)
  let scheme = call_614961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614961.url(scheme.get, call_614961.host, call_614961.base,
                         call_614961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614961, url, valid)

proc call*(call_614962: Call_RenderUiTemplate_614949; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_614963 = newJObject()
  if body != nil:
    body_614963 = body
  result = call_614962.call(nil, nil, nil, nil, body_614963)

var renderUiTemplate* = Call_RenderUiTemplate_614949(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_614950, base: "/",
    url: url_RenderUiTemplate_614951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_614964 = ref object of OpenApiRestCall_612658
proc url_Search_614966(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Search_614965(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614967 = query.getOrDefault("MaxResults")
  valid_614967 = validateParameter(valid_614967, JString, required = false,
                                 default = nil)
  if valid_614967 != nil:
    section.add "MaxResults", valid_614967
  var valid_614968 = query.getOrDefault("NextToken")
  valid_614968 = validateParameter(valid_614968, JString, required = false,
                                 default = nil)
  if valid_614968 != nil:
    section.add "NextToken", valid_614968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614969 = header.getOrDefault("X-Amz-Target")
  valid_614969 = validateParameter(valid_614969, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_614969 != nil:
    section.add "X-Amz-Target", valid_614969
  var valid_614970 = header.getOrDefault("X-Amz-Signature")
  valid_614970 = validateParameter(valid_614970, JString, required = false,
                                 default = nil)
  if valid_614970 != nil:
    section.add "X-Amz-Signature", valid_614970
  var valid_614971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614971 = validateParameter(valid_614971, JString, required = false,
                                 default = nil)
  if valid_614971 != nil:
    section.add "X-Amz-Content-Sha256", valid_614971
  var valid_614972 = header.getOrDefault("X-Amz-Date")
  valid_614972 = validateParameter(valid_614972, JString, required = false,
                                 default = nil)
  if valid_614972 != nil:
    section.add "X-Amz-Date", valid_614972
  var valid_614973 = header.getOrDefault("X-Amz-Credential")
  valid_614973 = validateParameter(valid_614973, JString, required = false,
                                 default = nil)
  if valid_614973 != nil:
    section.add "X-Amz-Credential", valid_614973
  var valid_614974 = header.getOrDefault("X-Amz-Security-Token")
  valid_614974 = validateParameter(valid_614974, JString, required = false,
                                 default = nil)
  if valid_614974 != nil:
    section.add "X-Amz-Security-Token", valid_614974
  var valid_614975 = header.getOrDefault("X-Amz-Algorithm")
  valid_614975 = validateParameter(valid_614975, JString, required = false,
                                 default = nil)
  if valid_614975 != nil:
    section.add "X-Amz-Algorithm", valid_614975
  var valid_614976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614976 = validateParameter(valid_614976, JString, required = false,
                                 default = nil)
  if valid_614976 != nil:
    section.add "X-Amz-SignedHeaders", valid_614976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614978: Call_Search_614964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  let valid = call_614978.validator(path, query, header, formData, body)
  let scheme = call_614978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614978.url(scheme.get, call_614978.host, call_614978.base,
                         call_614978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614978, url, valid)

proc call*(call_614979: Call_Search_614964; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_614980 = newJObject()
  var body_614981 = newJObject()
  add(query_614980, "MaxResults", newJString(MaxResults))
  add(query_614980, "NextToken", newJString(NextToken))
  if body != nil:
    body_614981 = body
  result = call_614979.call(nil, query_614980, nil, nil, body_614981)

var search* = Call_Search_614964(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_614965, base: "/",
                              url: url_Search_614966,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_614982 = ref object of OpenApiRestCall_612658
proc url_StartMonitoringSchedule_614984(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringSchedule_614983(path: JsonNode; query: JsonNode;
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
  var valid_614985 = header.getOrDefault("X-Amz-Target")
  valid_614985 = validateParameter(valid_614985, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_614985 != nil:
    section.add "X-Amz-Target", valid_614985
  var valid_614986 = header.getOrDefault("X-Amz-Signature")
  valid_614986 = validateParameter(valid_614986, JString, required = false,
                                 default = nil)
  if valid_614986 != nil:
    section.add "X-Amz-Signature", valid_614986
  var valid_614987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614987 = validateParameter(valid_614987, JString, required = false,
                                 default = nil)
  if valid_614987 != nil:
    section.add "X-Amz-Content-Sha256", valid_614987
  var valid_614988 = header.getOrDefault("X-Amz-Date")
  valid_614988 = validateParameter(valid_614988, JString, required = false,
                                 default = nil)
  if valid_614988 != nil:
    section.add "X-Amz-Date", valid_614988
  var valid_614989 = header.getOrDefault("X-Amz-Credential")
  valid_614989 = validateParameter(valid_614989, JString, required = false,
                                 default = nil)
  if valid_614989 != nil:
    section.add "X-Amz-Credential", valid_614989
  var valid_614990 = header.getOrDefault("X-Amz-Security-Token")
  valid_614990 = validateParameter(valid_614990, JString, required = false,
                                 default = nil)
  if valid_614990 != nil:
    section.add "X-Amz-Security-Token", valid_614990
  var valid_614991 = header.getOrDefault("X-Amz-Algorithm")
  valid_614991 = validateParameter(valid_614991, JString, required = false,
                                 default = nil)
  if valid_614991 != nil:
    section.add "X-Amz-Algorithm", valid_614991
  var valid_614992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614992 = validateParameter(valid_614992, JString, required = false,
                                 default = nil)
  if valid_614992 != nil:
    section.add "X-Amz-SignedHeaders", valid_614992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614994: Call_StartMonitoringSchedule_614982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_614994.validator(path, query, header, formData, body)
  let scheme = call_614994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614994.url(scheme.get, call_614994.host, call_614994.base,
                         call_614994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614994, url, valid)

proc call*(call_614995: Call_StartMonitoringSchedule_614982; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_614996 = newJObject()
  if body != nil:
    body_614996 = body
  result = call_614995.call(nil, nil, nil, nil, body_614996)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_614982(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_614983, base: "/",
    url: url_StartMonitoringSchedule_614984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_614997 = ref object of OpenApiRestCall_612658
proc url_StartNotebookInstance_614999(protocol: Scheme; host: string; base: string;
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

proc validate_StartNotebookInstance_614998(path: JsonNode; query: JsonNode;
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
  var valid_615000 = header.getOrDefault("X-Amz-Target")
  valid_615000 = validateParameter(valid_615000, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_615000 != nil:
    section.add "X-Amz-Target", valid_615000
  var valid_615001 = header.getOrDefault("X-Amz-Signature")
  valid_615001 = validateParameter(valid_615001, JString, required = false,
                                 default = nil)
  if valid_615001 != nil:
    section.add "X-Amz-Signature", valid_615001
  var valid_615002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615002 = validateParameter(valid_615002, JString, required = false,
                                 default = nil)
  if valid_615002 != nil:
    section.add "X-Amz-Content-Sha256", valid_615002
  var valid_615003 = header.getOrDefault("X-Amz-Date")
  valid_615003 = validateParameter(valid_615003, JString, required = false,
                                 default = nil)
  if valid_615003 != nil:
    section.add "X-Amz-Date", valid_615003
  var valid_615004 = header.getOrDefault("X-Amz-Credential")
  valid_615004 = validateParameter(valid_615004, JString, required = false,
                                 default = nil)
  if valid_615004 != nil:
    section.add "X-Amz-Credential", valid_615004
  var valid_615005 = header.getOrDefault("X-Amz-Security-Token")
  valid_615005 = validateParameter(valid_615005, JString, required = false,
                                 default = nil)
  if valid_615005 != nil:
    section.add "X-Amz-Security-Token", valid_615005
  var valid_615006 = header.getOrDefault("X-Amz-Algorithm")
  valid_615006 = validateParameter(valid_615006, JString, required = false,
                                 default = nil)
  if valid_615006 != nil:
    section.add "X-Amz-Algorithm", valid_615006
  var valid_615007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615007 = validateParameter(valid_615007, JString, required = false,
                                 default = nil)
  if valid_615007 != nil:
    section.add "X-Amz-SignedHeaders", valid_615007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615009: Call_StartNotebookInstance_614997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_615009.validator(path, query, header, formData, body)
  let scheme = call_615009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615009.url(scheme.get, call_615009.host, call_615009.base,
                         call_615009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615009, url, valid)

proc call*(call_615010: Call_StartNotebookInstance_614997; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_615011 = newJObject()
  if body != nil:
    body_615011 = body
  result = call_615010.call(nil, nil, nil, nil, body_615011)

var startNotebookInstance* = Call_StartNotebookInstance_614997(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_614998, base: "/",
    url: url_StartNotebookInstance_614999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_615012 = ref object of OpenApiRestCall_612658
proc url_StopAutoMLJob_615014(protocol: Scheme; host: string; base: string;
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

proc validate_StopAutoMLJob_615013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615015 = header.getOrDefault("X-Amz-Target")
  valid_615015 = validateParameter(valid_615015, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_615015 != nil:
    section.add "X-Amz-Target", valid_615015
  var valid_615016 = header.getOrDefault("X-Amz-Signature")
  valid_615016 = validateParameter(valid_615016, JString, required = false,
                                 default = nil)
  if valid_615016 != nil:
    section.add "X-Amz-Signature", valid_615016
  var valid_615017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615017 = validateParameter(valid_615017, JString, required = false,
                                 default = nil)
  if valid_615017 != nil:
    section.add "X-Amz-Content-Sha256", valid_615017
  var valid_615018 = header.getOrDefault("X-Amz-Date")
  valid_615018 = validateParameter(valid_615018, JString, required = false,
                                 default = nil)
  if valid_615018 != nil:
    section.add "X-Amz-Date", valid_615018
  var valid_615019 = header.getOrDefault("X-Amz-Credential")
  valid_615019 = validateParameter(valid_615019, JString, required = false,
                                 default = nil)
  if valid_615019 != nil:
    section.add "X-Amz-Credential", valid_615019
  var valid_615020 = header.getOrDefault("X-Amz-Security-Token")
  valid_615020 = validateParameter(valid_615020, JString, required = false,
                                 default = nil)
  if valid_615020 != nil:
    section.add "X-Amz-Security-Token", valid_615020
  var valid_615021 = header.getOrDefault("X-Amz-Algorithm")
  valid_615021 = validateParameter(valid_615021, JString, required = false,
                                 default = nil)
  if valid_615021 != nil:
    section.add "X-Amz-Algorithm", valid_615021
  var valid_615022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615022 = validateParameter(valid_615022, JString, required = false,
                                 default = nil)
  if valid_615022 != nil:
    section.add "X-Amz-SignedHeaders", valid_615022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615024: Call_StopAutoMLJob_615012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_615024.validator(path, query, header, formData, body)
  let scheme = call_615024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615024.url(scheme.get, call_615024.host, call_615024.base,
                         call_615024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615024, url, valid)

proc call*(call_615025: Call_StopAutoMLJob_615012; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_615026 = newJObject()
  if body != nil:
    body_615026 = body
  result = call_615025.call(nil, nil, nil, nil, body_615026)

var stopAutoMLJob* = Call_StopAutoMLJob_615012(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_615013, base: "/", url: url_StopAutoMLJob_615014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_615027 = ref object of OpenApiRestCall_612658
proc url_StopCompilationJob_615029(protocol: Scheme; host: string; base: string;
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

proc validate_StopCompilationJob_615028(path: JsonNode; query: JsonNode;
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
  var valid_615030 = header.getOrDefault("X-Amz-Target")
  valid_615030 = validateParameter(valid_615030, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_615030 != nil:
    section.add "X-Amz-Target", valid_615030
  var valid_615031 = header.getOrDefault("X-Amz-Signature")
  valid_615031 = validateParameter(valid_615031, JString, required = false,
                                 default = nil)
  if valid_615031 != nil:
    section.add "X-Amz-Signature", valid_615031
  var valid_615032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615032 = validateParameter(valid_615032, JString, required = false,
                                 default = nil)
  if valid_615032 != nil:
    section.add "X-Amz-Content-Sha256", valid_615032
  var valid_615033 = header.getOrDefault("X-Amz-Date")
  valid_615033 = validateParameter(valid_615033, JString, required = false,
                                 default = nil)
  if valid_615033 != nil:
    section.add "X-Amz-Date", valid_615033
  var valid_615034 = header.getOrDefault("X-Amz-Credential")
  valid_615034 = validateParameter(valid_615034, JString, required = false,
                                 default = nil)
  if valid_615034 != nil:
    section.add "X-Amz-Credential", valid_615034
  var valid_615035 = header.getOrDefault("X-Amz-Security-Token")
  valid_615035 = validateParameter(valid_615035, JString, required = false,
                                 default = nil)
  if valid_615035 != nil:
    section.add "X-Amz-Security-Token", valid_615035
  var valid_615036 = header.getOrDefault("X-Amz-Algorithm")
  valid_615036 = validateParameter(valid_615036, JString, required = false,
                                 default = nil)
  if valid_615036 != nil:
    section.add "X-Amz-Algorithm", valid_615036
  var valid_615037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615037 = validateParameter(valid_615037, JString, required = false,
                                 default = nil)
  if valid_615037 != nil:
    section.add "X-Amz-SignedHeaders", valid_615037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615039: Call_StopCompilationJob_615027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_615039.validator(path, query, header, formData, body)
  let scheme = call_615039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615039.url(scheme.get, call_615039.host, call_615039.base,
                         call_615039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615039, url, valid)

proc call*(call_615040: Call_StopCompilationJob_615027; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_615041 = newJObject()
  if body != nil:
    body_615041 = body
  result = call_615040.call(nil, nil, nil, nil, body_615041)

var stopCompilationJob* = Call_StopCompilationJob_615027(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_615028, base: "/",
    url: url_StopCompilationJob_615029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_615042 = ref object of OpenApiRestCall_612658
proc url_StopHyperParameterTuningJob_615044(protocol: Scheme; host: string;
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

proc validate_StopHyperParameterTuningJob_615043(path: JsonNode; query: JsonNode;
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
  var valid_615045 = header.getOrDefault("X-Amz-Target")
  valid_615045 = validateParameter(valid_615045, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_615045 != nil:
    section.add "X-Amz-Target", valid_615045
  var valid_615046 = header.getOrDefault("X-Amz-Signature")
  valid_615046 = validateParameter(valid_615046, JString, required = false,
                                 default = nil)
  if valid_615046 != nil:
    section.add "X-Amz-Signature", valid_615046
  var valid_615047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615047 = validateParameter(valid_615047, JString, required = false,
                                 default = nil)
  if valid_615047 != nil:
    section.add "X-Amz-Content-Sha256", valid_615047
  var valid_615048 = header.getOrDefault("X-Amz-Date")
  valid_615048 = validateParameter(valid_615048, JString, required = false,
                                 default = nil)
  if valid_615048 != nil:
    section.add "X-Amz-Date", valid_615048
  var valid_615049 = header.getOrDefault("X-Amz-Credential")
  valid_615049 = validateParameter(valid_615049, JString, required = false,
                                 default = nil)
  if valid_615049 != nil:
    section.add "X-Amz-Credential", valid_615049
  var valid_615050 = header.getOrDefault("X-Amz-Security-Token")
  valid_615050 = validateParameter(valid_615050, JString, required = false,
                                 default = nil)
  if valid_615050 != nil:
    section.add "X-Amz-Security-Token", valid_615050
  var valid_615051 = header.getOrDefault("X-Amz-Algorithm")
  valid_615051 = validateParameter(valid_615051, JString, required = false,
                                 default = nil)
  if valid_615051 != nil:
    section.add "X-Amz-Algorithm", valid_615051
  var valid_615052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615052 = validateParameter(valid_615052, JString, required = false,
                                 default = nil)
  if valid_615052 != nil:
    section.add "X-Amz-SignedHeaders", valid_615052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615054: Call_StopHyperParameterTuningJob_615042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_615054.validator(path, query, header, formData, body)
  let scheme = call_615054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615054.url(scheme.get, call_615054.host, call_615054.base,
                         call_615054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615054, url, valid)

proc call*(call_615055: Call_StopHyperParameterTuningJob_615042; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_615056 = newJObject()
  if body != nil:
    body_615056 = body
  result = call_615055.call(nil, nil, nil, nil, body_615056)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_615042(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_615043, base: "/",
    url: url_StopHyperParameterTuningJob_615044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_615057 = ref object of OpenApiRestCall_612658
proc url_StopLabelingJob_615059(protocol: Scheme; host: string; base: string;
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

proc validate_StopLabelingJob_615058(path: JsonNode; query: JsonNode;
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
  var valid_615060 = header.getOrDefault("X-Amz-Target")
  valid_615060 = validateParameter(valid_615060, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_615060 != nil:
    section.add "X-Amz-Target", valid_615060
  var valid_615061 = header.getOrDefault("X-Amz-Signature")
  valid_615061 = validateParameter(valid_615061, JString, required = false,
                                 default = nil)
  if valid_615061 != nil:
    section.add "X-Amz-Signature", valid_615061
  var valid_615062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615062 = validateParameter(valid_615062, JString, required = false,
                                 default = nil)
  if valid_615062 != nil:
    section.add "X-Amz-Content-Sha256", valid_615062
  var valid_615063 = header.getOrDefault("X-Amz-Date")
  valid_615063 = validateParameter(valid_615063, JString, required = false,
                                 default = nil)
  if valid_615063 != nil:
    section.add "X-Amz-Date", valid_615063
  var valid_615064 = header.getOrDefault("X-Amz-Credential")
  valid_615064 = validateParameter(valid_615064, JString, required = false,
                                 default = nil)
  if valid_615064 != nil:
    section.add "X-Amz-Credential", valid_615064
  var valid_615065 = header.getOrDefault("X-Amz-Security-Token")
  valid_615065 = validateParameter(valid_615065, JString, required = false,
                                 default = nil)
  if valid_615065 != nil:
    section.add "X-Amz-Security-Token", valid_615065
  var valid_615066 = header.getOrDefault("X-Amz-Algorithm")
  valid_615066 = validateParameter(valid_615066, JString, required = false,
                                 default = nil)
  if valid_615066 != nil:
    section.add "X-Amz-Algorithm", valid_615066
  var valid_615067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615067 = validateParameter(valid_615067, JString, required = false,
                                 default = nil)
  if valid_615067 != nil:
    section.add "X-Amz-SignedHeaders", valid_615067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615069: Call_StopLabelingJob_615057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_615069.validator(path, query, header, formData, body)
  let scheme = call_615069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615069.url(scheme.get, call_615069.host, call_615069.base,
                         call_615069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615069, url, valid)

proc call*(call_615070: Call_StopLabelingJob_615057; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_615071 = newJObject()
  if body != nil:
    body_615071 = body
  result = call_615070.call(nil, nil, nil, nil, body_615071)

var stopLabelingJob* = Call_StopLabelingJob_615057(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_615058, base: "/", url: url_StopLabelingJob_615059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_615072 = ref object of OpenApiRestCall_612658
proc url_StopMonitoringSchedule_615074(protocol: Scheme; host: string; base: string;
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

proc validate_StopMonitoringSchedule_615073(path: JsonNode; query: JsonNode;
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
  var valid_615075 = header.getOrDefault("X-Amz-Target")
  valid_615075 = validateParameter(valid_615075, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_615075 != nil:
    section.add "X-Amz-Target", valid_615075
  var valid_615076 = header.getOrDefault("X-Amz-Signature")
  valid_615076 = validateParameter(valid_615076, JString, required = false,
                                 default = nil)
  if valid_615076 != nil:
    section.add "X-Amz-Signature", valid_615076
  var valid_615077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615077 = validateParameter(valid_615077, JString, required = false,
                                 default = nil)
  if valid_615077 != nil:
    section.add "X-Amz-Content-Sha256", valid_615077
  var valid_615078 = header.getOrDefault("X-Amz-Date")
  valid_615078 = validateParameter(valid_615078, JString, required = false,
                                 default = nil)
  if valid_615078 != nil:
    section.add "X-Amz-Date", valid_615078
  var valid_615079 = header.getOrDefault("X-Amz-Credential")
  valid_615079 = validateParameter(valid_615079, JString, required = false,
                                 default = nil)
  if valid_615079 != nil:
    section.add "X-Amz-Credential", valid_615079
  var valid_615080 = header.getOrDefault("X-Amz-Security-Token")
  valid_615080 = validateParameter(valid_615080, JString, required = false,
                                 default = nil)
  if valid_615080 != nil:
    section.add "X-Amz-Security-Token", valid_615080
  var valid_615081 = header.getOrDefault("X-Amz-Algorithm")
  valid_615081 = validateParameter(valid_615081, JString, required = false,
                                 default = nil)
  if valid_615081 != nil:
    section.add "X-Amz-Algorithm", valid_615081
  var valid_615082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615082 = validateParameter(valid_615082, JString, required = false,
                                 default = nil)
  if valid_615082 != nil:
    section.add "X-Amz-SignedHeaders", valid_615082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615084: Call_StopMonitoringSchedule_615072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_615084.validator(path, query, header, formData, body)
  let scheme = call_615084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615084.url(scheme.get, call_615084.host, call_615084.base,
                         call_615084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615084, url, valid)

proc call*(call_615085: Call_StopMonitoringSchedule_615072; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_615086 = newJObject()
  if body != nil:
    body_615086 = body
  result = call_615085.call(nil, nil, nil, nil, body_615086)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_615072(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_615073, base: "/",
    url: url_StopMonitoringSchedule_615074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_615087 = ref object of OpenApiRestCall_612658
proc url_StopNotebookInstance_615089(protocol: Scheme; host: string; base: string;
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

proc validate_StopNotebookInstance_615088(path: JsonNode; query: JsonNode;
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
  var valid_615090 = header.getOrDefault("X-Amz-Target")
  valid_615090 = validateParameter(valid_615090, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_615090 != nil:
    section.add "X-Amz-Target", valid_615090
  var valid_615091 = header.getOrDefault("X-Amz-Signature")
  valid_615091 = validateParameter(valid_615091, JString, required = false,
                                 default = nil)
  if valid_615091 != nil:
    section.add "X-Amz-Signature", valid_615091
  var valid_615092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615092 = validateParameter(valid_615092, JString, required = false,
                                 default = nil)
  if valid_615092 != nil:
    section.add "X-Amz-Content-Sha256", valid_615092
  var valid_615093 = header.getOrDefault("X-Amz-Date")
  valid_615093 = validateParameter(valid_615093, JString, required = false,
                                 default = nil)
  if valid_615093 != nil:
    section.add "X-Amz-Date", valid_615093
  var valid_615094 = header.getOrDefault("X-Amz-Credential")
  valid_615094 = validateParameter(valid_615094, JString, required = false,
                                 default = nil)
  if valid_615094 != nil:
    section.add "X-Amz-Credential", valid_615094
  var valid_615095 = header.getOrDefault("X-Amz-Security-Token")
  valid_615095 = validateParameter(valid_615095, JString, required = false,
                                 default = nil)
  if valid_615095 != nil:
    section.add "X-Amz-Security-Token", valid_615095
  var valid_615096 = header.getOrDefault("X-Amz-Algorithm")
  valid_615096 = validateParameter(valid_615096, JString, required = false,
                                 default = nil)
  if valid_615096 != nil:
    section.add "X-Amz-Algorithm", valid_615096
  var valid_615097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615097 = validateParameter(valid_615097, JString, required = false,
                                 default = nil)
  if valid_615097 != nil:
    section.add "X-Amz-SignedHeaders", valid_615097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615099: Call_StopNotebookInstance_615087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_615099.validator(path, query, header, formData, body)
  let scheme = call_615099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615099.url(scheme.get, call_615099.host, call_615099.base,
                         call_615099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615099, url, valid)

proc call*(call_615100: Call_StopNotebookInstance_615087; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_615101 = newJObject()
  if body != nil:
    body_615101 = body
  result = call_615100.call(nil, nil, nil, nil, body_615101)

var stopNotebookInstance* = Call_StopNotebookInstance_615087(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_615088, base: "/",
    url: url_StopNotebookInstance_615089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_615102 = ref object of OpenApiRestCall_612658
proc url_StopProcessingJob_615104(protocol: Scheme; host: string; base: string;
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

proc validate_StopProcessingJob_615103(path: JsonNode; query: JsonNode;
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
  var valid_615105 = header.getOrDefault("X-Amz-Target")
  valid_615105 = validateParameter(valid_615105, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_615105 != nil:
    section.add "X-Amz-Target", valid_615105
  var valid_615106 = header.getOrDefault("X-Amz-Signature")
  valid_615106 = validateParameter(valid_615106, JString, required = false,
                                 default = nil)
  if valid_615106 != nil:
    section.add "X-Amz-Signature", valid_615106
  var valid_615107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615107 = validateParameter(valid_615107, JString, required = false,
                                 default = nil)
  if valid_615107 != nil:
    section.add "X-Amz-Content-Sha256", valid_615107
  var valid_615108 = header.getOrDefault("X-Amz-Date")
  valid_615108 = validateParameter(valid_615108, JString, required = false,
                                 default = nil)
  if valid_615108 != nil:
    section.add "X-Amz-Date", valid_615108
  var valid_615109 = header.getOrDefault("X-Amz-Credential")
  valid_615109 = validateParameter(valid_615109, JString, required = false,
                                 default = nil)
  if valid_615109 != nil:
    section.add "X-Amz-Credential", valid_615109
  var valid_615110 = header.getOrDefault("X-Amz-Security-Token")
  valid_615110 = validateParameter(valid_615110, JString, required = false,
                                 default = nil)
  if valid_615110 != nil:
    section.add "X-Amz-Security-Token", valid_615110
  var valid_615111 = header.getOrDefault("X-Amz-Algorithm")
  valid_615111 = validateParameter(valid_615111, JString, required = false,
                                 default = nil)
  if valid_615111 != nil:
    section.add "X-Amz-Algorithm", valid_615111
  var valid_615112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615112 = validateParameter(valid_615112, JString, required = false,
                                 default = nil)
  if valid_615112 != nil:
    section.add "X-Amz-SignedHeaders", valid_615112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615114: Call_StopProcessingJob_615102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_615114.validator(path, query, header, formData, body)
  let scheme = call_615114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615114.url(scheme.get, call_615114.host, call_615114.base,
                         call_615114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615114, url, valid)

proc call*(call_615115: Call_StopProcessingJob_615102; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_615116 = newJObject()
  if body != nil:
    body_615116 = body
  result = call_615115.call(nil, nil, nil, nil, body_615116)

var stopProcessingJob* = Call_StopProcessingJob_615102(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_615103, base: "/",
    url: url_StopProcessingJob_615104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_615117 = ref object of OpenApiRestCall_612658
proc url_StopTrainingJob_615119(protocol: Scheme; host: string; base: string;
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

proc validate_StopTrainingJob_615118(path: JsonNode; query: JsonNode;
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
  var valid_615120 = header.getOrDefault("X-Amz-Target")
  valid_615120 = validateParameter(valid_615120, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_615120 != nil:
    section.add "X-Amz-Target", valid_615120
  var valid_615121 = header.getOrDefault("X-Amz-Signature")
  valid_615121 = validateParameter(valid_615121, JString, required = false,
                                 default = nil)
  if valid_615121 != nil:
    section.add "X-Amz-Signature", valid_615121
  var valid_615122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615122 = validateParameter(valid_615122, JString, required = false,
                                 default = nil)
  if valid_615122 != nil:
    section.add "X-Amz-Content-Sha256", valid_615122
  var valid_615123 = header.getOrDefault("X-Amz-Date")
  valid_615123 = validateParameter(valid_615123, JString, required = false,
                                 default = nil)
  if valid_615123 != nil:
    section.add "X-Amz-Date", valid_615123
  var valid_615124 = header.getOrDefault("X-Amz-Credential")
  valid_615124 = validateParameter(valid_615124, JString, required = false,
                                 default = nil)
  if valid_615124 != nil:
    section.add "X-Amz-Credential", valid_615124
  var valid_615125 = header.getOrDefault("X-Amz-Security-Token")
  valid_615125 = validateParameter(valid_615125, JString, required = false,
                                 default = nil)
  if valid_615125 != nil:
    section.add "X-Amz-Security-Token", valid_615125
  var valid_615126 = header.getOrDefault("X-Amz-Algorithm")
  valid_615126 = validateParameter(valid_615126, JString, required = false,
                                 default = nil)
  if valid_615126 != nil:
    section.add "X-Amz-Algorithm", valid_615126
  var valid_615127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615127 = validateParameter(valid_615127, JString, required = false,
                                 default = nil)
  if valid_615127 != nil:
    section.add "X-Amz-SignedHeaders", valid_615127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615129: Call_StopTrainingJob_615117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_615129.validator(path, query, header, formData, body)
  let scheme = call_615129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615129.url(scheme.get, call_615129.host, call_615129.base,
                         call_615129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615129, url, valid)

proc call*(call_615130: Call_StopTrainingJob_615117; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_615131 = newJObject()
  if body != nil:
    body_615131 = body
  result = call_615130.call(nil, nil, nil, nil, body_615131)

var stopTrainingJob* = Call_StopTrainingJob_615117(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_615118, base: "/", url: url_StopTrainingJob_615119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_615132 = ref object of OpenApiRestCall_612658
proc url_StopTransformJob_615134(protocol: Scheme; host: string; base: string;
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

proc validate_StopTransformJob_615133(path: JsonNode; query: JsonNode;
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
  var valid_615135 = header.getOrDefault("X-Amz-Target")
  valid_615135 = validateParameter(valid_615135, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_615135 != nil:
    section.add "X-Amz-Target", valid_615135
  var valid_615136 = header.getOrDefault("X-Amz-Signature")
  valid_615136 = validateParameter(valid_615136, JString, required = false,
                                 default = nil)
  if valid_615136 != nil:
    section.add "X-Amz-Signature", valid_615136
  var valid_615137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615137 = validateParameter(valid_615137, JString, required = false,
                                 default = nil)
  if valid_615137 != nil:
    section.add "X-Amz-Content-Sha256", valid_615137
  var valid_615138 = header.getOrDefault("X-Amz-Date")
  valid_615138 = validateParameter(valid_615138, JString, required = false,
                                 default = nil)
  if valid_615138 != nil:
    section.add "X-Amz-Date", valid_615138
  var valid_615139 = header.getOrDefault("X-Amz-Credential")
  valid_615139 = validateParameter(valid_615139, JString, required = false,
                                 default = nil)
  if valid_615139 != nil:
    section.add "X-Amz-Credential", valid_615139
  var valid_615140 = header.getOrDefault("X-Amz-Security-Token")
  valid_615140 = validateParameter(valid_615140, JString, required = false,
                                 default = nil)
  if valid_615140 != nil:
    section.add "X-Amz-Security-Token", valid_615140
  var valid_615141 = header.getOrDefault("X-Amz-Algorithm")
  valid_615141 = validateParameter(valid_615141, JString, required = false,
                                 default = nil)
  if valid_615141 != nil:
    section.add "X-Amz-Algorithm", valid_615141
  var valid_615142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615142 = validateParameter(valid_615142, JString, required = false,
                                 default = nil)
  if valid_615142 != nil:
    section.add "X-Amz-SignedHeaders", valid_615142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615144: Call_StopTransformJob_615132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_615144.validator(path, query, header, formData, body)
  let scheme = call_615144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615144.url(scheme.get, call_615144.host, call_615144.base,
                         call_615144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615144, url, valid)

proc call*(call_615145: Call_StopTransformJob_615132; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_615146 = newJObject()
  if body != nil:
    body_615146 = body
  result = call_615145.call(nil, nil, nil, nil, body_615146)

var stopTransformJob* = Call_StopTransformJob_615132(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_615133, base: "/",
    url: url_StopTransformJob_615134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_615147 = ref object of OpenApiRestCall_612658
proc url_UpdateCodeRepository_615149(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCodeRepository_615148(path: JsonNode; query: JsonNode;
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
  var valid_615150 = header.getOrDefault("X-Amz-Target")
  valid_615150 = validateParameter(valid_615150, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_615150 != nil:
    section.add "X-Amz-Target", valid_615150
  var valid_615151 = header.getOrDefault("X-Amz-Signature")
  valid_615151 = validateParameter(valid_615151, JString, required = false,
                                 default = nil)
  if valid_615151 != nil:
    section.add "X-Amz-Signature", valid_615151
  var valid_615152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615152 = validateParameter(valid_615152, JString, required = false,
                                 default = nil)
  if valid_615152 != nil:
    section.add "X-Amz-Content-Sha256", valid_615152
  var valid_615153 = header.getOrDefault("X-Amz-Date")
  valid_615153 = validateParameter(valid_615153, JString, required = false,
                                 default = nil)
  if valid_615153 != nil:
    section.add "X-Amz-Date", valid_615153
  var valid_615154 = header.getOrDefault("X-Amz-Credential")
  valid_615154 = validateParameter(valid_615154, JString, required = false,
                                 default = nil)
  if valid_615154 != nil:
    section.add "X-Amz-Credential", valid_615154
  var valid_615155 = header.getOrDefault("X-Amz-Security-Token")
  valid_615155 = validateParameter(valid_615155, JString, required = false,
                                 default = nil)
  if valid_615155 != nil:
    section.add "X-Amz-Security-Token", valid_615155
  var valid_615156 = header.getOrDefault("X-Amz-Algorithm")
  valid_615156 = validateParameter(valid_615156, JString, required = false,
                                 default = nil)
  if valid_615156 != nil:
    section.add "X-Amz-Algorithm", valid_615156
  var valid_615157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615157 = validateParameter(valid_615157, JString, required = false,
                                 default = nil)
  if valid_615157 != nil:
    section.add "X-Amz-SignedHeaders", valid_615157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615159: Call_UpdateCodeRepository_615147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_615159.validator(path, query, header, formData, body)
  let scheme = call_615159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615159.url(scheme.get, call_615159.host, call_615159.base,
                         call_615159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615159, url, valid)

proc call*(call_615160: Call_UpdateCodeRepository_615147; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_615161 = newJObject()
  if body != nil:
    body_615161 = body
  result = call_615160.call(nil, nil, nil, nil, body_615161)

var updateCodeRepository* = Call_UpdateCodeRepository_615147(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_615148, base: "/",
    url: url_UpdateCodeRepository_615149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_615162 = ref object of OpenApiRestCall_612658
proc url_UpdateDomain_615164(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomain_615163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615165 = header.getOrDefault("X-Amz-Target")
  valid_615165 = validateParameter(valid_615165, JString, required = true,
                                 default = newJString("SageMaker.UpdateDomain"))
  if valid_615165 != nil:
    section.add "X-Amz-Target", valid_615165
  var valid_615166 = header.getOrDefault("X-Amz-Signature")
  valid_615166 = validateParameter(valid_615166, JString, required = false,
                                 default = nil)
  if valid_615166 != nil:
    section.add "X-Amz-Signature", valid_615166
  var valid_615167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615167 = validateParameter(valid_615167, JString, required = false,
                                 default = nil)
  if valid_615167 != nil:
    section.add "X-Amz-Content-Sha256", valid_615167
  var valid_615168 = header.getOrDefault("X-Amz-Date")
  valid_615168 = validateParameter(valid_615168, JString, required = false,
                                 default = nil)
  if valid_615168 != nil:
    section.add "X-Amz-Date", valid_615168
  var valid_615169 = header.getOrDefault("X-Amz-Credential")
  valid_615169 = validateParameter(valid_615169, JString, required = false,
                                 default = nil)
  if valid_615169 != nil:
    section.add "X-Amz-Credential", valid_615169
  var valid_615170 = header.getOrDefault("X-Amz-Security-Token")
  valid_615170 = validateParameter(valid_615170, JString, required = false,
                                 default = nil)
  if valid_615170 != nil:
    section.add "X-Amz-Security-Token", valid_615170
  var valid_615171 = header.getOrDefault("X-Amz-Algorithm")
  valid_615171 = validateParameter(valid_615171, JString, required = false,
                                 default = nil)
  if valid_615171 != nil:
    section.add "X-Amz-Algorithm", valid_615171
  var valid_615172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615172 = validateParameter(valid_615172, JString, required = false,
                                 default = nil)
  if valid_615172 != nil:
    section.add "X-Amz-SignedHeaders", valid_615172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615174: Call_UpdateDomain_615162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_615174.validator(path, query, header, formData, body)
  let scheme = call_615174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615174.url(scheme.get, call_615174.host, call_615174.base,
                         call_615174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615174, url, valid)

proc call*(call_615175: Call_UpdateDomain_615162; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_615176 = newJObject()
  if body != nil:
    body_615176 = body
  result = call_615175.call(nil, nil, nil, nil, body_615176)

var updateDomain* = Call_UpdateDomain_615162(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_615163, base: "/", url: url_UpdateDomain_615164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_615177 = ref object of OpenApiRestCall_612658
proc url_UpdateEndpoint_615179(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_615178(path: JsonNode; query: JsonNode;
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
  var valid_615180 = header.getOrDefault("X-Amz-Target")
  valid_615180 = validateParameter(valid_615180, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_615180 != nil:
    section.add "X-Amz-Target", valid_615180
  var valid_615181 = header.getOrDefault("X-Amz-Signature")
  valid_615181 = validateParameter(valid_615181, JString, required = false,
                                 default = nil)
  if valid_615181 != nil:
    section.add "X-Amz-Signature", valid_615181
  var valid_615182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615182 = validateParameter(valid_615182, JString, required = false,
                                 default = nil)
  if valid_615182 != nil:
    section.add "X-Amz-Content-Sha256", valid_615182
  var valid_615183 = header.getOrDefault("X-Amz-Date")
  valid_615183 = validateParameter(valid_615183, JString, required = false,
                                 default = nil)
  if valid_615183 != nil:
    section.add "X-Amz-Date", valid_615183
  var valid_615184 = header.getOrDefault("X-Amz-Credential")
  valid_615184 = validateParameter(valid_615184, JString, required = false,
                                 default = nil)
  if valid_615184 != nil:
    section.add "X-Amz-Credential", valid_615184
  var valid_615185 = header.getOrDefault("X-Amz-Security-Token")
  valid_615185 = validateParameter(valid_615185, JString, required = false,
                                 default = nil)
  if valid_615185 != nil:
    section.add "X-Amz-Security-Token", valid_615185
  var valid_615186 = header.getOrDefault("X-Amz-Algorithm")
  valid_615186 = validateParameter(valid_615186, JString, required = false,
                                 default = nil)
  if valid_615186 != nil:
    section.add "X-Amz-Algorithm", valid_615186
  var valid_615187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615187 = validateParameter(valid_615187, JString, required = false,
                                 default = nil)
  if valid_615187 != nil:
    section.add "X-Amz-SignedHeaders", valid_615187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615189: Call_UpdateEndpoint_615177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_615189.validator(path, query, header, formData, body)
  let scheme = call_615189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615189.url(scheme.get, call_615189.host, call_615189.base,
                         call_615189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615189, url, valid)

proc call*(call_615190: Call_UpdateEndpoint_615177; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_615191 = newJObject()
  if body != nil:
    body_615191 = body
  result = call_615190.call(nil, nil, nil, nil, body_615191)

var updateEndpoint* = Call_UpdateEndpoint_615177(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_615178, base: "/", url: url_UpdateEndpoint_615179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_615192 = ref object of OpenApiRestCall_612658
proc url_UpdateEndpointWeightsAndCapacities_615194(protocol: Scheme; host: string;
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

proc validate_UpdateEndpointWeightsAndCapacities_615193(path: JsonNode;
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
  var valid_615195 = header.getOrDefault("X-Amz-Target")
  valid_615195 = validateParameter(valid_615195, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_615195 != nil:
    section.add "X-Amz-Target", valid_615195
  var valid_615196 = header.getOrDefault("X-Amz-Signature")
  valid_615196 = validateParameter(valid_615196, JString, required = false,
                                 default = nil)
  if valid_615196 != nil:
    section.add "X-Amz-Signature", valid_615196
  var valid_615197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615197 = validateParameter(valid_615197, JString, required = false,
                                 default = nil)
  if valid_615197 != nil:
    section.add "X-Amz-Content-Sha256", valid_615197
  var valid_615198 = header.getOrDefault("X-Amz-Date")
  valid_615198 = validateParameter(valid_615198, JString, required = false,
                                 default = nil)
  if valid_615198 != nil:
    section.add "X-Amz-Date", valid_615198
  var valid_615199 = header.getOrDefault("X-Amz-Credential")
  valid_615199 = validateParameter(valid_615199, JString, required = false,
                                 default = nil)
  if valid_615199 != nil:
    section.add "X-Amz-Credential", valid_615199
  var valid_615200 = header.getOrDefault("X-Amz-Security-Token")
  valid_615200 = validateParameter(valid_615200, JString, required = false,
                                 default = nil)
  if valid_615200 != nil:
    section.add "X-Amz-Security-Token", valid_615200
  var valid_615201 = header.getOrDefault("X-Amz-Algorithm")
  valid_615201 = validateParameter(valid_615201, JString, required = false,
                                 default = nil)
  if valid_615201 != nil:
    section.add "X-Amz-Algorithm", valid_615201
  var valid_615202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615202 = validateParameter(valid_615202, JString, required = false,
                                 default = nil)
  if valid_615202 != nil:
    section.add "X-Amz-SignedHeaders", valid_615202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615204: Call_UpdateEndpointWeightsAndCapacities_615192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_615204.validator(path, query, header, formData, body)
  let scheme = call_615204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615204.url(scheme.get, call_615204.host, call_615204.base,
                         call_615204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615204, url, valid)

proc call*(call_615205: Call_UpdateEndpointWeightsAndCapacities_615192;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_615206 = newJObject()
  if body != nil:
    body_615206 = body
  result = call_615205.call(nil, nil, nil, nil, body_615206)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_615192(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_615193, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_615194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_615207 = ref object of OpenApiRestCall_612658
proc url_UpdateExperiment_615209(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateExperiment_615208(path: JsonNode; query: JsonNode;
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
  var valid_615210 = header.getOrDefault("X-Amz-Target")
  valid_615210 = validateParameter(valid_615210, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_615210 != nil:
    section.add "X-Amz-Target", valid_615210
  var valid_615211 = header.getOrDefault("X-Amz-Signature")
  valid_615211 = validateParameter(valid_615211, JString, required = false,
                                 default = nil)
  if valid_615211 != nil:
    section.add "X-Amz-Signature", valid_615211
  var valid_615212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615212 = validateParameter(valid_615212, JString, required = false,
                                 default = nil)
  if valid_615212 != nil:
    section.add "X-Amz-Content-Sha256", valid_615212
  var valid_615213 = header.getOrDefault("X-Amz-Date")
  valid_615213 = validateParameter(valid_615213, JString, required = false,
                                 default = nil)
  if valid_615213 != nil:
    section.add "X-Amz-Date", valid_615213
  var valid_615214 = header.getOrDefault("X-Amz-Credential")
  valid_615214 = validateParameter(valid_615214, JString, required = false,
                                 default = nil)
  if valid_615214 != nil:
    section.add "X-Amz-Credential", valid_615214
  var valid_615215 = header.getOrDefault("X-Amz-Security-Token")
  valid_615215 = validateParameter(valid_615215, JString, required = false,
                                 default = nil)
  if valid_615215 != nil:
    section.add "X-Amz-Security-Token", valid_615215
  var valid_615216 = header.getOrDefault("X-Amz-Algorithm")
  valid_615216 = validateParameter(valid_615216, JString, required = false,
                                 default = nil)
  if valid_615216 != nil:
    section.add "X-Amz-Algorithm", valid_615216
  var valid_615217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615217 = validateParameter(valid_615217, JString, required = false,
                                 default = nil)
  if valid_615217 != nil:
    section.add "X-Amz-SignedHeaders", valid_615217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615219: Call_UpdateExperiment_615207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_615219.validator(path, query, header, formData, body)
  let scheme = call_615219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615219.url(scheme.get, call_615219.host, call_615219.base,
                         call_615219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615219, url, valid)

proc call*(call_615220: Call_UpdateExperiment_615207; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_615221 = newJObject()
  if body != nil:
    body_615221 = body
  result = call_615220.call(nil, nil, nil, nil, body_615221)

var updateExperiment* = Call_UpdateExperiment_615207(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_615208, base: "/",
    url: url_UpdateExperiment_615209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_615222 = ref object of OpenApiRestCall_612658
proc url_UpdateMonitoringSchedule_615224(protocol: Scheme; host: string;
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

proc validate_UpdateMonitoringSchedule_615223(path: JsonNode; query: JsonNode;
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
  var valid_615225 = header.getOrDefault("X-Amz-Target")
  valid_615225 = validateParameter(valid_615225, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_615225 != nil:
    section.add "X-Amz-Target", valid_615225
  var valid_615226 = header.getOrDefault("X-Amz-Signature")
  valid_615226 = validateParameter(valid_615226, JString, required = false,
                                 default = nil)
  if valid_615226 != nil:
    section.add "X-Amz-Signature", valid_615226
  var valid_615227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615227 = validateParameter(valid_615227, JString, required = false,
                                 default = nil)
  if valid_615227 != nil:
    section.add "X-Amz-Content-Sha256", valid_615227
  var valid_615228 = header.getOrDefault("X-Amz-Date")
  valid_615228 = validateParameter(valid_615228, JString, required = false,
                                 default = nil)
  if valid_615228 != nil:
    section.add "X-Amz-Date", valid_615228
  var valid_615229 = header.getOrDefault("X-Amz-Credential")
  valid_615229 = validateParameter(valid_615229, JString, required = false,
                                 default = nil)
  if valid_615229 != nil:
    section.add "X-Amz-Credential", valid_615229
  var valid_615230 = header.getOrDefault("X-Amz-Security-Token")
  valid_615230 = validateParameter(valid_615230, JString, required = false,
                                 default = nil)
  if valid_615230 != nil:
    section.add "X-Amz-Security-Token", valid_615230
  var valid_615231 = header.getOrDefault("X-Amz-Algorithm")
  valid_615231 = validateParameter(valid_615231, JString, required = false,
                                 default = nil)
  if valid_615231 != nil:
    section.add "X-Amz-Algorithm", valid_615231
  var valid_615232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615232 = validateParameter(valid_615232, JString, required = false,
                                 default = nil)
  if valid_615232 != nil:
    section.add "X-Amz-SignedHeaders", valid_615232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615234: Call_UpdateMonitoringSchedule_615222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_615234.validator(path, query, header, formData, body)
  let scheme = call_615234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615234.url(scheme.get, call_615234.host, call_615234.base,
                         call_615234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615234, url, valid)

proc call*(call_615235: Call_UpdateMonitoringSchedule_615222; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_615236 = newJObject()
  if body != nil:
    body_615236 = body
  result = call_615235.call(nil, nil, nil, nil, body_615236)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_615222(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_615223, base: "/",
    url: url_UpdateMonitoringSchedule_615224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_615237 = ref object of OpenApiRestCall_612658
proc url_UpdateNotebookInstance_615239(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNotebookInstance_615238(path: JsonNode; query: JsonNode;
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
  var valid_615240 = header.getOrDefault("X-Amz-Target")
  valid_615240 = validateParameter(valid_615240, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_615240 != nil:
    section.add "X-Amz-Target", valid_615240
  var valid_615241 = header.getOrDefault("X-Amz-Signature")
  valid_615241 = validateParameter(valid_615241, JString, required = false,
                                 default = nil)
  if valid_615241 != nil:
    section.add "X-Amz-Signature", valid_615241
  var valid_615242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615242 = validateParameter(valid_615242, JString, required = false,
                                 default = nil)
  if valid_615242 != nil:
    section.add "X-Amz-Content-Sha256", valid_615242
  var valid_615243 = header.getOrDefault("X-Amz-Date")
  valid_615243 = validateParameter(valid_615243, JString, required = false,
                                 default = nil)
  if valid_615243 != nil:
    section.add "X-Amz-Date", valid_615243
  var valid_615244 = header.getOrDefault("X-Amz-Credential")
  valid_615244 = validateParameter(valid_615244, JString, required = false,
                                 default = nil)
  if valid_615244 != nil:
    section.add "X-Amz-Credential", valid_615244
  var valid_615245 = header.getOrDefault("X-Amz-Security-Token")
  valid_615245 = validateParameter(valid_615245, JString, required = false,
                                 default = nil)
  if valid_615245 != nil:
    section.add "X-Amz-Security-Token", valid_615245
  var valid_615246 = header.getOrDefault("X-Amz-Algorithm")
  valid_615246 = validateParameter(valid_615246, JString, required = false,
                                 default = nil)
  if valid_615246 != nil:
    section.add "X-Amz-Algorithm", valid_615246
  var valid_615247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615247 = validateParameter(valid_615247, JString, required = false,
                                 default = nil)
  if valid_615247 != nil:
    section.add "X-Amz-SignedHeaders", valid_615247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615249: Call_UpdateNotebookInstance_615237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_615249.validator(path, query, header, formData, body)
  let scheme = call_615249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615249.url(scheme.get, call_615249.host, call_615249.base,
                         call_615249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615249, url, valid)

proc call*(call_615250: Call_UpdateNotebookInstance_615237; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_615251 = newJObject()
  if body != nil:
    body_615251 = body
  result = call_615250.call(nil, nil, nil, nil, body_615251)

var updateNotebookInstance* = Call_UpdateNotebookInstance_615237(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_615238, base: "/",
    url: url_UpdateNotebookInstance_615239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_615252 = ref object of OpenApiRestCall_612658
proc url_UpdateNotebookInstanceLifecycleConfig_615254(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_615253(path: JsonNode;
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
  var valid_615255 = header.getOrDefault("X-Amz-Target")
  valid_615255 = validateParameter(valid_615255, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_615255 != nil:
    section.add "X-Amz-Target", valid_615255
  var valid_615256 = header.getOrDefault("X-Amz-Signature")
  valid_615256 = validateParameter(valid_615256, JString, required = false,
                                 default = nil)
  if valid_615256 != nil:
    section.add "X-Amz-Signature", valid_615256
  var valid_615257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615257 = validateParameter(valid_615257, JString, required = false,
                                 default = nil)
  if valid_615257 != nil:
    section.add "X-Amz-Content-Sha256", valid_615257
  var valid_615258 = header.getOrDefault("X-Amz-Date")
  valid_615258 = validateParameter(valid_615258, JString, required = false,
                                 default = nil)
  if valid_615258 != nil:
    section.add "X-Amz-Date", valid_615258
  var valid_615259 = header.getOrDefault("X-Amz-Credential")
  valid_615259 = validateParameter(valid_615259, JString, required = false,
                                 default = nil)
  if valid_615259 != nil:
    section.add "X-Amz-Credential", valid_615259
  var valid_615260 = header.getOrDefault("X-Amz-Security-Token")
  valid_615260 = validateParameter(valid_615260, JString, required = false,
                                 default = nil)
  if valid_615260 != nil:
    section.add "X-Amz-Security-Token", valid_615260
  var valid_615261 = header.getOrDefault("X-Amz-Algorithm")
  valid_615261 = validateParameter(valid_615261, JString, required = false,
                                 default = nil)
  if valid_615261 != nil:
    section.add "X-Amz-Algorithm", valid_615261
  var valid_615262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615262 = validateParameter(valid_615262, JString, required = false,
                                 default = nil)
  if valid_615262 != nil:
    section.add "X-Amz-SignedHeaders", valid_615262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615264: Call_UpdateNotebookInstanceLifecycleConfig_615252;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_615264.validator(path, query, header, formData, body)
  let scheme = call_615264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615264.url(scheme.get, call_615264.host, call_615264.base,
                         call_615264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615264, url, valid)

proc call*(call_615265: Call_UpdateNotebookInstanceLifecycleConfig_615252;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_615266 = newJObject()
  if body != nil:
    body_615266 = body
  result = call_615265.call(nil, nil, nil, nil, body_615266)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_615252(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_615253, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_615254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_615267 = ref object of OpenApiRestCall_612658
proc url_UpdateTrial_615269(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrial_615268(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_615270 = header.getOrDefault("X-Amz-Target")
  valid_615270 = validateParameter(valid_615270, JString, required = true,
                                 default = newJString("SageMaker.UpdateTrial"))
  if valid_615270 != nil:
    section.add "X-Amz-Target", valid_615270
  var valid_615271 = header.getOrDefault("X-Amz-Signature")
  valid_615271 = validateParameter(valid_615271, JString, required = false,
                                 default = nil)
  if valid_615271 != nil:
    section.add "X-Amz-Signature", valid_615271
  var valid_615272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615272 = validateParameter(valid_615272, JString, required = false,
                                 default = nil)
  if valid_615272 != nil:
    section.add "X-Amz-Content-Sha256", valid_615272
  var valid_615273 = header.getOrDefault("X-Amz-Date")
  valid_615273 = validateParameter(valid_615273, JString, required = false,
                                 default = nil)
  if valid_615273 != nil:
    section.add "X-Amz-Date", valid_615273
  var valid_615274 = header.getOrDefault("X-Amz-Credential")
  valid_615274 = validateParameter(valid_615274, JString, required = false,
                                 default = nil)
  if valid_615274 != nil:
    section.add "X-Amz-Credential", valid_615274
  var valid_615275 = header.getOrDefault("X-Amz-Security-Token")
  valid_615275 = validateParameter(valid_615275, JString, required = false,
                                 default = nil)
  if valid_615275 != nil:
    section.add "X-Amz-Security-Token", valid_615275
  var valid_615276 = header.getOrDefault("X-Amz-Algorithm")
  valid_615276 = validateParameter(valid_615276, JString, required = false,
                                 default = nil)
  if valid_615276 != nil:
    section.add "X-Amz-Algorithm", valid_615276
  var valid_615277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615277 = validateParameter(valid_615277, JString, required = false,
                                 default = nil)
  if valid_615277 != nil:
    section.add "X-Amz-SignedHeaders", valid_615277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615279: Call_UpdateTrial_615267; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_615279.validator(path, query, header, formData, body)
  let scheme = call_615279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615279.url(scheme.get, call_615279.host, call_615279.base,
                         call_615279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615279, url, valid)

proc call*(call_615280: Call_UpdateTrial_615267; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_615281 = newJObject()
  if body != nil:
    body_615281 = body
  result = call_615280.call(nil, nil, nil, nil, body_615281)

var updateTrial* = Call_UpdateTrial_615267(name: "updateTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.UpdateTrial",
                                        validator: validate_UpdateTrial_615268,
                                        base: "/", url: url_UpdateTrial_615269,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_615282 = ref object of OpenApiRestCall_612658
proc url_UpdateTrialComponent_615284(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrialComponent_615283(path: JsonNode; query: JsonNode;
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
  var valid_615285 = header.getOrDefault("X-Amz-Target")
  valid_615285 = validateParameter(valid_615285, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_615285 != nil:
    section.add "X-Amz-Target", valid_615285
  var valid_615286 = header.getOrDefault("X-Amz-Signature")
  valid_615286 = validateParameter(valid_615286, JString, required = false,
                                 default = nil)
  if valid_615286 != nil:
    section.add "X-Amz-Signature", valid_615286
  var valid_615287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615287 = validateParameter(valid_615287, JString, required = false,
                                 default = nil)
  if valid_615287 != nil:
    section.add "X-Amz-Content-Sha256", valid_615287
  var valid_615288 = header.getOrDefault("X-Amz-Date")
  valid_615288 = validateParameter(valid_615288, JString, required = false,
                                 default = nil)
  if valid_615288 != nil:
    section.add "X-Amz-Date", valid_615288
  var valid_615289 = header.getOrDefault("X-Amz-Credential")
  valid_615289 = validateParameter(valid_615289, JString, required = false,
                                 default = nil)
  if valid_615289 != nil:
    section.add "X-Amz-Credential", valid_615289
  var valid_615290 = header.getOrDefault("X-Amz-Security-Token")
  valid_615290 = validateParameter(valid_615290, JString, required = false,
                                 default = nil)
  if valid_615290 != nil:
    section.add "X-Amz-Security-Token", valid_615290
  var valid_615291 = header.getOrDefault("X-Amz-Algorithm")
  valid_615291 = validateParameter(valid_615291, JString, required = false,
                                 default = nil)
  if valid_615291 != nil:
    section.add "X-Amz-Algorithm", valid_615291
  var valid_615292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615292 = validateParameter(valid_615292, JString, required = false,
                                 default = nil)
  if valid_615292 != nil:
    section.add "X-Amz-SignedHeaders", valid_615292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615294: Call_UpdateTrialComponent_615282; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_615294.validator(path, query, header, formData, body)
  let scheme = call_615294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615294.url(scheme.get, call_615294.host, call_615294.base,
                         call_615294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615294, url, valid)

proc call*(call_615295: Call_UpdateTrialComponent_615282; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_615296 = newJObject()
  if body != nil:
    body_615296 = body
  result = call_615295.call(nil, nil, nil, nil, body_615296)

var updateTrialComponent* = Call_UpdateTrialComponent_615282(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_615283, base: "/",
    url: url_UpdateTrialComponent_615284, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_615297 = ref object of OpenApiRestCall_612658
proc url_UpdateUserProfile_615299(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserProfile_615298(path: JsonNode; query: JsonNode;
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
  var valid_615300 = header.getOrDefault("X-Amz-Target")
  valid_615300 = validateParameter(valid_615300, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_615300 != nil:
    section.add "X-Amz-Target", valid_615300
  var valid_615301 = header.getOrDefault("X-Amz-Signature")
  valid_615301 = validateParameter(valid_615301, JString, required = false,
                                 default = nil)
  if valid_615301 != nil:
    section.add "X-Amz-Signature", valid_615301
  var valid_615302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615302 = validateParameter(valid_615302, JString, required = false,
                                 default = nil)
  if valid_615302 != nil:
    section.add "X-Amz-Content-Sha256", valid_615302
  var valid_615303 = header.getOrDefault("X-Amz-Date")
  valid_615303 = validateParameter(valid_615303, JString, required = false,
                                 default = nil)
  if valid_615303 != nil:
    section.add "X-Amz-Date", valid_615303
  var valid_615304 = header.getOrDefault("X-Amz-Credential")
  valid_615304 = validateParameter(valid_615304, JString, required = false,
                                 default = nil)
  if valid_615304 != nil:
    section.add "X-Amz-Credential", valid_615304
  var valid_615305 = header.getOrDefault("X-Amz-Security-Token")
  valid_615305 = validateParameter(valid_615305, JString, required = false,
                                 default = nil)
  if valid_615305 != nil:
    section.add "X-Amz-Security-Token", valid_615305
  var valid_615306 = header.getOrDefault("X-Amz-Algorithm")
  valid_615306 = validateParameter(valid_615306, JString, required = false,
                                 default = nil)
  if valid_615306 != nil:
    section.add "X-Amz-Algorithm", valid_615306
  var valid_615307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615307 = validateParameter(valid_615307, JString, required = false,
                                 default = nil)
  if valid_615307 != nil:
    section.add "X-Amz-SignedHeaders", valid_615307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615309: Call_UpdateUserProfile_615297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_615309.validator(path, query, header, formData, body)
  let scheme = call_615309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615309.url(scheme.get, call_615309.host, call_615309.base,
                         call_615309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615309, url, valid)

proc call*(call_615310: Call_UpdateUserProfile_615297; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_615311 = newJObject()
  if body != nil:
    body_615311 = body
  result = call_615310.call(nil, nil, nil, nil, body_615311)

var updateUserProfile* = Call_UpdateUserProfile_615297(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_615298, base: "/",
    url: url_UpdateUserProfile_615299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkforce_615312 = ref object of OpenApiRestCall_612658
proc url_UpdateWorkforce_615314(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkforce_615313(path: JsonNode; query: JsonNode;
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
  var valid_615315 = header.getOrDefault("X-Amz-Target")
  valid_615315 = validateParameter(valid_615315, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkforce"))
  if valid_615315 != nil:
    section.add "X-Amz-Target", valid_615315
  var valid_615316 = header.getOrDefault("X-Amz-Signature")
  valid_615316 = validateParameter(valid_615316, JString, required = false,
                                 default = nil)
  if valid_615316 != nil:
    section.add "X-Amz-Signature", valid_615316
  var valid_615317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615317 = validateParameter(valid_615317, JString, required = false,
                                 default = nil)
  if valid_615317 != nil:
    section.add "X-Amz-Content-Sha256", valid_615317
  var valid_615318 = header.getOrDefault("X-Amz-Date")
  valid_615318 = validateParameter(valid_615318, JString, required = false,
                                 default = nil)
  if valid_615318 != nil:
    section.add "X-Amz-Date", valid_615318
  var valid_615319 = header.getOrDefault("X-Amz-Credential")
  valid_615319 = validateParameter(valid_615319, JString, required = false,
                                 default = nil)
  if valid_615319 != nil:
    section.add "X-Amz-Credential", valid_615319
  var valid_615320 = header.getOrDefault("X-Amz-Security-Token")
  valid_615320 = validateParameter(valid_615320, JString, required = false,
                                 default = nil)
  if valid_615320 != nil:
    section.add "X-Amz-Security-Token", valid_615320
  var valid_615321 = header.getOrDefault("X-Amz-Algorithm")
  valid_615321 = validateParameter(valid_615321, JString, required = false,
                                 default = nil)
  if valid_615321 != nil:
    section.add "X-Amz-Algorithm", valid_615321
  var valid_615322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615322 = validateParameter(valid_615322, JString, required = false,
                                 default = nil)
  if valid_615322 != nil:
    section.add "X-Amz-SignedHeaders", valid_615322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615324: Call_UpdateWorkforce_615312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_615324.validator(path, query, header, formData, body)
  let scheme = call_615324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615324.url(scheme.get, call_615324.host, call_615324.base,
                         call_615324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615324, url, valid)

proc call*(call_615325: Call_UpdateWorkforce_615312; body: JsonNode): Recallable =
  ## updateWorkforce
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_615326 = newJObject()
  if body != nil:
    body_615326 = body
  result = call_615325.call(nil, nil, nil, nil, body_615326)

var updateWorkforce* = Call_UpdateWorkforce_615312(name: "updateWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkforce",
    validator: validate_UpdateWorkforce_615313, base: "/", url: url_UpdateWorkforce_615314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_615327 = ref object of OpenApiRestCall_612658
proc url_UpdateWorkteam_615329(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkteam_615328(path: JsonNode; query: JsonNode;
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
  var valid_615330 = header.getOrDefault("X-Amz-Target")
  valid_615330 = validateParameter(valid_615330, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_615330 != nil:
    section.add "X-Amz-Target", valid_615330
  var valid_615331 = header.getOrDefault("X-Amz-Signature")
  valid_615331 = validateParameter(valid_615331, JString, required = false,
                                 default = nil)
  if valid_615331 != nil:
    section.add "X-Amz-Signature", valid_615331
  var valid_615332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_615332 = validateParameter(valid_615332, JString, required = false,
                                 default = nil)
  if valid_615332 != nil:
    section.add "X-Amz-Content-Sha256", valid_615332
  var valid_615333 = header.getOrDefault("X-Amz-Date")
  valid_615333 = validateParameter(valid_615333, JString, required = false,
                                 default = nil)
  if valid_615333 != nil:
    section.add "X-Amz-Date", valid_615333
  var valid_615334 = header.getOrDefault("X-Amz-Credential")
  valid_615334 = validateParameter(valid_615334, JString, required = false,
                                 default = nil)
  if valid_615334 != nil:
    section.add "X-Amz-Credential", valid_615334
  var valid_615335 = header.getOrDefault("X-Amz-Security-Token")
  valid_615335 = validateParameter(valid_615335, JString, required = false,
                                 default = nil)
  if valid_615335 != nil:
    section.add "X-Amz-Security-Token", valid_615335
  var valid_615336 = header.getOrDefault("X-Amz-Algorithm")
  valid_615336 = validateParameter(valid_615336, JString, required = false,
                                 default = nil)
  if valid_615336 != nil:
    section.add "X-Amz-Algorithm", valid_615336
  var valid_615337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_615337 = validateParameter(valid_615337, JString, required = false,
                                 default = nil)
  if valid_615337 != nil:
    section.add "X-Amz-SignedHeaders", valid_615337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_615339: Call_UpdateWorkteam_615327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_615339.validator(path, query, header, formData, body)
  let scheme = call_615339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_615339.url(scheme.get, call_615339.host, call_615339.base,
                         call_615339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_615339, url, valid)

proc call*(call_615340: Call_UpdateWorkteam_615327; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_615341 = newJObject()
  if body != nil:
    body_615341 = body
  result = call_615340.call(nil, nil, nil, nil, body_615341)

var updateWorkteam* = Call_UpdateWorkteam_615327(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_615328, base: "/", url: url_UpdateWorkteam_615329,
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
