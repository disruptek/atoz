
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "api.sagemaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.sagemaker.ap-southeast-1.amazonaws.com", "us-west-2": "api.sagemaker.us-west-2.amazonaws.com", "eu-west-2": "api.sagemaker.eu-west-2.amazonaws.com", "ap-northeast-3": "api.sagemaker.ap-northeast-3.amazonaws.com", "eu-central-1": "api.sagemaker.eu-central-1.amazonaws.com", "us-east-2": "api.sagemaker.us-east-2.amazonaws.com", "us-east-1": "api.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "api.sagemaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.sagemaker.ap-south-1.amazonaws.com", "eu-north-1": "api.sagemaker.eu-north-1.amazonaws.com", "ap-northeast-2": "api.sagemaker.ap-northeast-2.amazonaws.com", "us-west-1": "api.sagemaker.us-west-1.amazonaws.com", "us-gov-east-1": "api.sagemaker.us-gov-east-1.amazonaws.com", "eu-west-3": "api.sagemaker.eu-west-3.amazonaws.com", "cn-north-1": "api.sagemaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.sagemaker.sa-east-1.amazonaws.com", "eu-west-1": "api.sagemaker.eu-west-1.amazonaws.com", "us-gov-west-1": "api.sagemaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.sagemaker.ap-southeast-2.amazonaws.com", "ca-central-1": "api.sagemaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddTags_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddTags_402656296(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_402656295(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true,
                                      default = newJString("SageMaker.AddTags"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AddTags_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AddTags_402656294; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var addTags* = Call_AddTags_402656294(name: "addTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.AddTags",
                                      validator: validate_AddTags_402656295,
                                      base: "/", makeUrl: url_AddTags_402656296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_402656489 = ref object of OpenApiRestCall_402656044
proc url_AssociateTrialComponent_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTrialComponent_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_AssociateTrialComponent_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_AssociateTrialComponent_402656489;
           body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var associateTrialComponent* = Call_AssociateTrialComponent_402656489(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_402656490, base: "/",
    makeUrl: url_AssociateTrialComponent_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateAlgorithm_402656506(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlgorithm_402656505(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CreateAlgorithm_402656504; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateAlgorithm_402656504; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   
                                                                                                              ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createAlgorithm* = Call_CreateAlgorithm_402656504(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_402656505, base: "/",
    makeUrl: url_CreateAlgorithm_402656506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateApp_402656521(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_402656520(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "SageMaker.CreateApp"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_CreateApp_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateApp_402656519; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createApp* = Call_CreateApp_402656519(name: "createApp",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateApp", validator: validate_CreateApp_402656520,
    base: "/", makeUrl: url_CreateApp_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateAutoMLJob_402656536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAutoMLJob_402656535(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_CreateAutoMLJob_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an AutoPilot job.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateAutoMLJob_402656534; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createAutoMLJob* = Call_CreateAutoMLJob_402656534(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_402656535, base: "/",
    makeUrl: url_CreateAutoMLJob_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateCodeRepository_402656551(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCodeRepository_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_CreateCodeRepository_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateCodeRepository_402656549; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createCodeRepository* = Call_CreateCodeRepository_402656549(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_402656550, base: "/",
    makeUrl: url_CreateCodeRepository_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_402656564 = ref object of OpenApiRestCall_402656044
proc url_CreateCompilationJob_402656566(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCompilationJob_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_CreateCompilationJob_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CreateCompilationJob_402656564; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var createCompilationJob* = Call_CreateCompilationJob_402656564(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_402656565, base: "/",
    makeUrl: url_CreateCompilationJob_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_402656579 = ref object of OpenApiRestCall_402656044
proc url_CreateDomain_402656581(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_402656580(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "SageMaker.CreateDomain"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_CreateDomain_402656579; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateDomain_402656579; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createDomain* = Call_CreateDomain_402656579(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_402656580, base: "/",
    makeUrl: url_CreateDomain_402656581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_402656594 = ref object of OpenApiRestCall_402656044
proc url_CreateEndpoint_402656596(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_402656595(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using Amazon SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_CreateEndpoint_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using Amazon SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateEndpoint_402656594; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using Amazon SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createEndpoint* = Call_CreateEndpoint_402656594(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_402656595, base: "/",
    makeUrl: url_CreateEndpoint_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_402656609 = ref object of OpenApiRestCall_402656044
proc url_CreateEndpointConfig_402656611(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpointConfig_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_CreateEndpointConfig_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreateEndpointConfig_402656609; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var createEndpointConfig* = Call_CreateEndpointConfig_402656609(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_402656610, base: "/",
    makeUrl: url_CreateEndpointConfig_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_402656624 = ref object of OpenApiRestCall_402656044
proc url_CreateExperiment_402656626(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExperiment_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_CreateExperiment_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_CreateExperiment_402656624; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var createExperiment* = Call_CreateExperiment_402656624(
    name: "createExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_402656625, base: "/",
    makeUrl: url_CreateExperiment_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_402656639 = ref object of OpenApiRestCall_402656044
proc url_CreateFlowDefinition_402656641(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowDefinition_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_CreateFlowDefinition_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a flow definition.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_CreateFlowDefinition_402656639; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var createFlowDefinition* = Call_CreateFlowDefinition_402656639(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_402656640, base: "/",
    makeUrl: url_CreateFlowDefinition_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_402656654 = ref object of OpenApiRestCall_402656044
proc url_CreateHumanTaskUi_402656656(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHumanTaskUi_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_CreateHumanTaskUi_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_CreateHumanTaskUi_402656654; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   
                                                                                                                                                                                                ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var createHumanTaskUi* = Call_CreateHumanTaskUi_402656654(
    name: "createHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_402656655, base: "/",
    makeUrl: url_CreateHumanTaskUi_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_402656669 = ref object of OpenApiRestCall_402656044
proc url_CreateHyperParameterTuningJob_402656671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHyperParameterTuningJob_402656670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_CreateHyperParameterTuningJob_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_CreateHyperParameterTuningJob_402656669;
           body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_402656669(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_402656670, base: "/",
    makeUrl: url_CreateHyperParameterTuningJob_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_402656684 = ref object of OpenApiRestCall_402656044
proc url_CreateLabelingJob_402656686(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLabelingJob_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_CreateLabelingJob_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_CreateLabelingJob_402656684; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var createLabelingJob* = Call_CreateLabelingJob_402656684(
    name: "createLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_402656685, base: "/",
    makeUrl: url_CreateLabelingJob_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_402656699 = ref object of OpenApiRestCall_402656044
proc url_CreateModel_402656701(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModel_402656700(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "SageMaker.CreateModel"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_CreateModel_402656699; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_CreateModel_402656699; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var createModel* = Call_CreateModel_402656699(name: "createModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModel",
    validator: validate_CreateModel_402656700, base: "/",
    makeUrl: url_CreateModel_402656701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_402656714 = ref object of OpenApiRestCall_402656044
proc url_CreateModelPackage_402656716(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelPackage_402656715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_CreateModelPackage_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_CreateModelPackage_402656714; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var createModelPackage* = Call_CreateModelPackage_402656714(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_402656715, base: "/",
    makeUrl: url_CreateModelPackage_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_402656729 = ref object of OpenApiRestCall_402656044
proc url_CreateMonitoringSchedule_402656731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMonitoringSchedule_402656730(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_CreateMonitoringSchedule_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_CreateMonitoringSchedule_402656729;
           body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   
                                                                                                                                            ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_402656729(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_402656730, base: "/",
    makeUrl: url_CreateMonitoringSchedule_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_402656744 = ref object of OpenApiRestCall_402656044
proc url_CreateNotebookInstance_402656746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstance_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_CreateNotebookInstance_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_CreateNotebookInstance_402656744; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var createNotebookInstance* = Call_CreateNotebookInstance_402656744(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_402656745, base: "/",
    makeUrl: url_CreateNotebookInstance_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_402656759 = ref object of OpenApiRestCall_402656044
proc url_CreateNotebookInstanceLifecycleConfig_402656761(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_402656760(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_CreateNotebookInstanceLifecycleConfig_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_CreateNotebookInstanceLifecycleConfig_402656759;
           body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_402656759(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_402656760,
    base: "/", makeUrl: url_CreateNotebookInstanceLifecycleConfig_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_402656774 = ref object of OpenApiRestCall_402656044
proc url_CreatePresignedDomainUrl_402656776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedDomainUrl_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_CreatePresignedDomainUrl_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_CreatePresignedDomainUrl_402656774;
           body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   
                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_402656774(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_402656775, base: "/",
    makeUrl: url_CreatePresignedDomainUrl_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_402656789 = ref object of OpenApiRestCall_402656044
proc url_CreatePresignedNotebookInstanceUrl_402656791(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedNotebookInstanceUrl_402656790(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_CreatePresignedNotebookInstanceUrl_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_CreatePresignedNotebookInstanceUrl_402656789;
           body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_402656789(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_402656790, base: "/",
    makeUrl: url_CreatePresignedNotebookInstanceUrl_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_402656804 = ref object of OpenApiRestCall_402656044
proc url_CreateProcessingJob_402656806(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProcessingJob_402656805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656816: Call_CreateProcessingJob_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a processing job.
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_CreateProcessingJob_402656804; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var createProcessingJob* = Call_CreateProcessingJob_402656804(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_402656805, base: "/",
    makeUrl: url_CreateProcessingJob_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_402656819 = ref object of OpenApiRestCall_402656044
proc url_CreateTrainingJob_402656821(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrainingJob_402656820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656831: Call_CreateTrainingJob_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_CreateTrainingJob_402656819; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var createTrainingJob* = Call_CreateTrainingJob_402656819(
    name: "createTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_402656820, base: "/",
    makeUrl: url_CreateTrainingJob_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_402656834 = ref object of OpenApiRestCall_402656044
proc url_CreateTransformJob_402656836(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransformJob_402656835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Target")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_402656837 != nil:
    section.add "X-Amz-Target", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656846: Call_CreateTransformJob_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
                                                                                         ## 
  let valid = call_402656846.validator(path, query, header, formData, body, _)
  let scheme = call_402656846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656846.makeUrl(scheme.get, call_402656846.host, call_402656846.base,
                                   call_402656846.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656846, uri, valid, _)

proc call*(call_402656847: Call_CreateTransformJob_402656834; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656848 = newJObject()
  if body != nil:
    body_402656848 = body
  result = call_402656847.call(nil, nil, nil, nil, body_402656848)

var createTransformJob* = Call_CreateTransformJob_402656834(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_402656835, base: "/",
    makeUrl: url_CreateTransformJob_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_402656849 = ref object of OpenApiRestCall_402656044
proc url_CreateTrial_402656851(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrial_402656850(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Target")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true, default = newJString(
      "SageMaker.CreateTrial"))
  if valid_402656852 != nil:
    section.add "X-Amz-Target", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Security-Token", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Signature")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Signature", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Algorithm", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Date")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Date", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Credential")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Credential", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656861: Call_CreateTrial_402656849; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
                                                                                         ## 
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_CreateTrial_402656849; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656863 = newJObject()
  if body != nil:
    body_402656863 = body
  result = call_402656862.call(nil, nil, nil, nil, body_402656863)

var createTrial* = Call_CreateTrial_402656849(name: "createTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrial",
    validator: validate_CreateTrial_402656850, base: "/",
    makeUrl: url_CreateTrial_402656851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_402656864 = ref object of OpenApiRestCall_402656044
proc url_CreateTrialComponent_402656866(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrialComponent_402656865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656867 = header.getOrDefault("X-Amz-Target")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_402656867 != nil:
    section.add "X-Amz-Target", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Security-Token", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Signature")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Signature", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Algorithm", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Date")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Date", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Credential")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Credential", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656876: Call_CreateTrialComponent_402656864;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
                                                                                         ## 
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_CreateTrialComponent_402656864; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656878 = newJObject()
  if body != nil:
    body_402656878 = body
  result = call_402656877.call(nil, nil, nil, nil, body_402656878)

var createTrialComponent* = Call_CreateTrialComponent_402656864(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_402656865, base: "/",
    makeUrl: url_CreateTrialComponent_402656866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_402656879 = ref object of OpenApiRestCall_402656044
proc url_CreateUserProfile_402656881(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserProfile_402656880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656882 = header.getOrDefault("X-Amz-Target")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_402656882 != nil:
    section.add "X-Amz-Target", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Security-Token", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Signature")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Signature", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Algorithm", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Date")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Date", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Credential")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Credential", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656891: Call_CreateUserProfile_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_CreateUserProfile_402656879; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656893 = newJObject()
  if body != nil:
    body_402656893 = body
  result = call_402656892.call(nil, nil, nil, nil, body_402656893)

var createUserProfile* = Call_CreateUserProfile_402656879(
    name: "createUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_402656880, base: "/",
    makeUrl: url_CreateUserProfile_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_402656894 = ref object of OpenApiRestCall_402656044
proc url_CreateWorkteam_402656896(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkteam_402656895(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656897 = header.getOrDefault("X-Amz-Target")
  valid_402656897 = validateParameter(valid_402656897, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_402656897 != nil:
    section.add "X-Amz-Target", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Security-Token", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Signature")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Signature", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Algorithm", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Date")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Date", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Credential")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Credential", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656906: Call_CreateWorkteam_402656894; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
                                                                                         ## 
  let valid = call_402656906.validator(path, query, header, formData, body, _)
  let scheme = call_402656906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656906.makeUrl(scheme.get, call_402656906.host, call_402656906.base,
                                   call_402656906.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656906, uri, valid, _)

proc call*(call_402656907: Call_CreateWorkteam_402656894; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   
                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656908 = newJObject()
  if body != nil:
    body_402656908 = body
  result = call_402656907.call(nil, nil, nil, nil, body_402656908)

var createWorkteam* = Call_CreateWorkteam_402656894(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_402656895, base: "/",
    makeUrl: url_CreateWorkteam_402656896, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_402656909 = ref object of OpenApiRestCall_402656044
proc url_DeleteAlgorithm_402656911(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlgorithm_402656910(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656912 = header.getOrDefault("X-Amz-Target")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_402656912 != nil:
    section.add "X-Amz-Target", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Security-Token", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Signature")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Signature", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Algorithm", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Date")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Date", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Credential")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Credential", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656921: Call_DeleteAlgorithm_402656909; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified algorithm from your account.
                                                                                         ## 
  let valid = call_402656921.validator(path, query, header, formData, body, _)
  let scheme = call_402656921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656921.makeUrl(scheme.get, call_402656921.host, call_402656921.base,
                                   call_402656921.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656921, uri, valid, _)

proc call*(call_402656922: Call_DeleteAlgorithm_402656909; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  result = call_402656922.call(nil, nil, nil, nil, body_402656923)

var deleteAlgorithm* = Call_DeleteAlgorithm_402656909(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_402656910, base: "/",
    makeUrl: url_DeleteAlgorithm_402656911, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_402656924 = ref object of OpenApiRestCall_402656044
proc url_DeleteApp_402656926(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_402656925(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656927 = header.getOrDefault("X-Amz-Target")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true, default = newJString(
      "SageMaker.DeleteApp"))
  if valid_402656927 != nil:
    section.add "X-Amz-Target", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Security-Token", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Signature")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Signature", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Algorithm", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Date")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Date", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Credential")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Credential", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656936: Call_DeleteApp_402656924; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to stop and delete an app.
                                                                                         ## 
  let valid = call_402656936.validator(path, query, header, formData, body, _)
  let scheme = call_402656936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656936.makeUrl(scheme.get, call_402656936.host, call_402656936.base,
                                   call_402656936.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656936, uri, valid, _)

proc call*(call_402656937: Call_DeleteApp_402656924; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_402656938 = newJObject()
  if body != nil:
    body_402656938 = body
  result = call_402656937.call(nil, nil, nil, nil, body_402656938)

var deleteApp* = Call_DeleteApp_402656924(name: "deleteApp",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteApp", validator: validate_DeleteApp_402656925,
    base: "/", makeUrl: url_DeleteApp_402656926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_402656939 = ref object of OpenApiRestCall_402656044
proc url_DeleteCodeRepository_402656941(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCodeRepository_402656940(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656942 = header.getOrDefault("X-Amz-Target")
  valid_402656942 = validateParameter(valid_402656942, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_402656942 != nil:
    section.add "X-Amz-Target", valid_402656942
  var valid_402656943 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656943 = validateParameter(valid_402656943, JString,
                                      required = false, default = nil)
  if valid_402656943 != nil:
    section.add "X-Amz-Security-Token", valid_402656943
  var valid_402656944 = header.getOrDefault("X-Amz-Signature")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Signature", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Algorithm", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Date")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Date", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Credential")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Credential", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656951: Call_DeleteCodeRepository_402656939;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Git repository from your account.
                                                                                         ## 
  let valid = call_402656951.validator(path, query, header, formData, body, _)
  let scheme = call_402656951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656951.makeUrl(scheme.get, call_402656951.host, call_402656951.base,
                                   call_402656951.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656951, uri, valid, _)

proc call*(call_402656952: Call_DeleteCodeRepository_402656939; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_402656953 = newJObject()
  if body != nil:
    body_402656953 = body
  result = call_402656952.call(nil, nil, nil, nil, body_402656953)

var deleteCodeRepository* = Call_DeleteCodeRepository_402656939(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_402656940, base: "/",
    makeUrl: url_DeleteCodeRepository_402656941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_402656954 = ref object of OpenApiRestCall_402656044
proc url_DeleteDomain_402656956(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_402656955(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656957 = header.getOrDefault("X-Amz-Target")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true, default = newJString(
      "SageMaker.DeleteDomain"))
  if valid_402656957 != nil:
    section.add "X-Amz-Target", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Security-Token", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Signature")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Signature", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Algorithm", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Date")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Date", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Credential")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Credential", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656966: Call_DeleteDomain_402656954; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
                                                                                         ## 
  let valid = call_402656966.validator(path, query, header, formData, body, _)
  let scheme = call_402656966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656966.makeUrl(scheme.get, call_402656966.host, call_402656966.base,
                                   call_402656966.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656966, uri, valid, _)

proc call*(call_402656967: Call_DeleteDomain_402656954; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   
                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656968 = newJObject()
  if body != nil:
    body_402656968 = body
  result = call_402656967.call(nil, nil, nil, nil, body_402656968)

var deleteDomain* = Call_DeleteDomain_402656954(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_402656955, base: "/",
    makeUrl: url_DeleteDomain_402656956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_402656969 = ref object of OpenApiRestCall_402656044
proc url_DeleteEndpoint_402656971(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_402656970(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656972 = header.getOrDefault("X-Amz-Target")
  valid_402656972 = validateParameter(valid_402656972, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_402656972 != nil:
    section.add "X-Amz-Target", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656981: Call_DeleteEndpoint_402656969; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
                                                                                         ## 
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_DeleteEndpoint_402656969; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656983 = newJObject()
  if body != nil:
    body_402656983 = body
  result = call_402656982.call(nil, nil, nil, nil, body_402656983)

var deleteEndpoint* = Call_DeleteEndpoint_402656969(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_402656970, base: "/",
    makeUrl: url_DeleteEndpoint_402656971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_402656984 = ref object of OpenApiRestCall_402656044
proc url_DeleteEndpointConfig_402656986(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpointConfig_402656985(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656987 = header.getOrDefault("X-Amz-Target")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_402656987 != nil:
    section.add "X-Amz-Target", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656996: Call_DeleteEndpointConfig_402656984;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
                                                                                         ## 
  let valid = call_402656996.validator(path, query, header, formData, body, _)
  let scheme = call_402656996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656996.makeUrl(scheme.get, call_402656996.host, call_402656996.base,
                                   call_402656996.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656996, uri, valid, _)

proc call*(call_402656997: Call_DeleteEndpointConfig_402656984; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  var body_402656998 = newJObject()
  if body != nil:
    body_402656998 = body
  result = call_402656997.call(nil, nil, nil, nil, body_402656998)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_402656984(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_402656985, base: "/",
    makeUrl: url_DeleteEndpointConfig_402656986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_402656999 = ref object of OpenApiRestCall_402656044
proc url_DeleteExperiment_402657001(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteExperiment_402657000(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657002 = header.getOrDefault("X-Amz-Target")
  valid_402657002 = validateParameter(valid_402657002, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_402657002 != nil:
    section.add "X-Amz-Target", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Security-Token", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-Signature")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-Signature", valid_402657004
  var valid_402657005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657005 = validateParameter(valid_402657005, JString,
                                      required = false, default = nil)
  if valid_402657005 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Algorithm", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Date")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Date", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Credential")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Credential", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657011: Call_DeleteExperiment_402656999;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
                                                                                         ## 
  let valid = call_402657011.validator(path, query, header, formData, body, _)
  let scheme = call_402657011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657011.makeUrl(scheme.get, call_402657011.host, call_402657011.base,
                                   call_402657011.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657011, uri, valid, _)

proc call*(call_402657012: Call_DeleteExperiment_402656999; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   
                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657013 = newJObject()
  if body != nil:
    body_402657013 = body
  result = call_402657012.call(nil, nil, nil, nil, body_402657013)

var deleteExperiment* = Call_DeleteExperiment_402656999(
    name: "deleteExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_402657000, base: "/",
    makeUrl: url_DeleteExperiment_402657001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_402657014 = ref object of OpenApiRestCall_402656044
proc url_DeleteFlowDefinition_402657016(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowDefinition_402657015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657017 = header.getOrDefault("X-Amz-Target")
  valid_402657017 = validateParameter(valid_402657017, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_402657017 != nil:
    section.add "X-Amz-Target", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Security-Token", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Signature")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Signature", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-Algorithm", valid_402657021
  var valid_402657022 = header.getOrDefault("X-Amz-Date")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Date", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Credential")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Credential", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657026: Call_DeleteFlowDefinition_402657014;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified flow definition.
                                                                                         ## 
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_DeleteFlowDefinition_402657014; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_402657028 = newJObject()
  if body != nil:
    body_402657028 = body
  result = call_402657027.call(nil, nil, nil, nil, body_402657028)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_402657014(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_402657015, base: "/",
    makeUrl: url_DeleteFlowDefinition_402657016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_402657029 = ref object of OpenApiRestCall_402656044
proc url_DeleteModel_402657031(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModel_402657030(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657032 = header.getOrDefault("X-Amz-Target")
  valid_402657032 = validateParameter(valid_402657032, JString, required = true, default = newJString(
      "SageMaker.DeleteModel"))
  if valid_402657032 != nil:
    section.add "X-Amz-Target", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Security-Token", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Signature")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Signature", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657035
  var valid_402657036 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Algorithm", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Date")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Date", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Credential")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Credential", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657041: Call_DeleteModel_402657029; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
                                                                                         ## 
  let valid = call_402657041.validator(path, query, header, formData, body, _)
  let scheme = call_402657041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657041.makeUrl(scheme.get, call_402657041.host, call_402657041.base,
                                   call_402657041.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657041, uri, valid, _)

proc call*(call_402657042: Call_DeleteModel_402657029; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657043 = newJObject()
  if body != nil:
    body_402657043 = body
  result = call_402657042.call(nil, nil, nil, nil, body_402657043)

var deleteModel* = Call_DeleteModel_402657029(name: "deleteModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModel",
    validator: validate_DeleteModel_402657030, base: "/",
    makeUrl: url_DeleteModel_402657031, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_402657044 = ref object of OpenApiRestCall_402656044
proc url_DeleteModelPackage_402657046(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModelPackage_402657045(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657047 = header.getOrDefault("X-Amz-Target")
  valid_402657047 = validateParameter(valid_402657047, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_402657047 != nil:
    section.add "X-Amz-Target", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Security-Token", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Signature")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Signature", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657050
  var valid_402657051 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657051 = validateParameter(valid_402657051, JString,
                                      required = false, default = nil)
  if valid_402657051 != nil:
    section.add "X-Amz-Algorithm", valid_402657051
  var valid_402657052 = header.getOrDefault("X-Amz-Date")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Date", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Credential")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Credential", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657056: Call_DeleteModelPackage_402657044;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
                                                                                         ## 
  let valid = call_402657056.validator(path, query, header, formData, body, _)
  let scheme = call_402657056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657056.makeUrl(scheme.get, call_402657056.host, call_402657056.base,
                                   call_402657056.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657056, uri, valid, _)

proc call*(call_402657057: Call_DeleteModelPackage_402657044; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   
                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657058 = newJObject()
  if body != nil:
    body_402657058 = body
  result = call_402657057.call(nil, nil, nil, nil, body_402657058)

var deleteModelPackage* = Call_DeleteModelPackage_402657044(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_402657045, base: "/",
    makeUrl: url_DeleteModelPackage_402657046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_402657059 = ref object of OpenApiRestCall_402656044
proc url_DeleteMonitoringSchedule_402657061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMonitoringSchedule_402657060(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657062 = header.getOrDefault("X-Amz-Target")
  valid_402657062 = validateParameter(valid_402657062, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_402657062 != nil:
    section.add "X-Amz-Target", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Security-Token", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Signature")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Signature", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Algorithm", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-Date")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-Date", valid_402657067
  var valid_402657068 = header.getOrDefault("X-Amz-Credential")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Credential", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657071: Call_DeleteMonitoringSchedule_402657059;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
                                                                                         ## 
  let valid = call_402657071.validator(path, query, header, formData, body, _)
  let scheme = call_402657071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657071.makeUrl(scheme.get, call_402657071.host, call_402657071.base,
                                   call_402657071.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657071, uri, valid, _)

proc call*(call_402657072: Call_DeleteMonitoringSchedule_402657059;
           body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var body_402657073 = newJObject()
  if body != nil:
    body_402657073 = body
  result = call_402657072.call(nil, nil, nil, nil, body_402657073)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_402657059(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_402657060, base: "/",
    makeUrl: url_DeleteMonitoringSchedule_402657061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_402657074 = ref object of OpenApiRestCall_402656044
proc url_DeleteNotebookInstance_402657076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstance_402657075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657077 = header.getOrDefault("X-Amz-Target")
  valid_402657077 = validateParameter(valid_402657077, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_402657077 != nil:
    section.add "X-Amz-Target", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Security-Token", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Signature")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Signature", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Algorithm", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Date")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Date", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Credential")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Credential", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657086: Call_DeleteNotebookInstance_402657074;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
                                                                                         ## 
  let valid = call_402657086.validator(path, query, header, formData, body, _)
  let scheme = call_402657086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657086.makeUrl(scheme.get, call_402657086.host, call_402657086.base,
                                   call_402657086.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657086, uri, valid, _)

proc call*(call_402657087: Call_DeleteNotebookInstance_402657074; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657088 = newJObject()
  if body != nil:
    body_402657088 = body
  result = call_402657087.call(nil, nil, nil, nil, body_402657088)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_402657074(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_402657075, base: "/",
    makeUrl: url_DeleteNotebookInstance_402657076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_402657089 = ref object of OpenApiRestCall_402656044
proc url_DeleteNotebookInstanceLifecycleConfig_402657091(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_402657090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657092 = header.getOrDefault("X-Amz-Target")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_402657092 != nil:
    section.add "X-Amz-Target", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_DeleteNotebookInstanceLifecycleConfig_402657089;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
                                                                                         ## 
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_DeleteNotebookInstanceLifecycleConfig_402657089;
           body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_402657103 = newJObject()
  if body != nil:
    body_402657103 = body
  result = call_402657102.call(nil, nil, nil, nil, body_402657103)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_402657089(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_402657090,
    base: "/", makeUrl: url_DeleteNotebookInstanceLifecycleConfig_402657091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_402657104 = ref object of OpenApiRestCall_402656044
proc url_DeleteTags_402657106(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_402657105(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657107 = header.getOrDefault("X-Amz-Target")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true, default = newJString(
      "SageMaker.DeleteTags"))
  if valid_402657107 != nil:
    section.add "X-Amz-Target", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657116: Call_DeleteTags_402657104; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
                                                                                         ## 
  let valid = call_402657116.validator(path, query, header, formData, body, _)
  let scheme = call_402657116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657116.makeUrl(scheme.get, call_402657116.host, call_402657116.base,
                                   call_402657116.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657116, uri, valid, _)

proc call*(call_402657117: Call_DeleteTags_402657104; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402657118 = newJObject()
  if body != nil:
    body_402657118 = body
  result = call_402657117.call(nil, nil, nil, nil, body_402657118)

var deleteTags* = Call_DeleteTags_402657104(name: "deleteTags",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTags",
    validator: validate_DeleteTags_402657105, base: "/",
    makeUrl: url_DeleteTags_402657106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_402657119 = ref object of OpenApiRestCall_402656044
proc url_DeleteTrial_402657121(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrial_402657120(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657122 = header.getOrDefault("X-Amz-Target")
  valid_402657122 = validateParameter(valid_402657122, JString, required = true, default = newJString(
      "SageMaker.DeleteTrial"))
  if valid_402657122 != nil:
    section.add "X-Amz-Target", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Security-Token", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Signature")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Signature", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Algorithm", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Date")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Date", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Credential")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Credential", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657131: Call_DeleteTrial_402657119; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
                                                                                         ## 
  let valid = call_402657131.validator(path, query, header, formData, body, _)
  let scheme = call_402657131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657131.makeUrl(scheme.get, call_402657131.host, call_402657131.base,
                                   call_402657131.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657131, uri, valid, _)

proc call*(call_402657132: Call_DeleteTrial_402657119; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   
                                                                                                                                                                                   ## body: JObject (required)
  var body_402657133 = newJObject()
  if body != nil:
    body_402657133 = body
  result = call_402657132.call(nil, nil, nil, nil, body_402657133)

var deleteTrial* = Call_DeleteTrial_402657119(name: "deleteTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrial",
    validator: validate_DeleteTrial_402657120, base: "/",
    makeUrl: url_DeleteTrial_402657121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_402657134 = ref object of OpenApiRestCall_402656044
proc url_DeleteTrialComponent_402657136(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrialComponent_402657135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657137 = header.getOrDefault("X-Amz-Target")
  valid_402657137 = validateParameter(valid_402657137, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_402657137 != nil:
    section.add "X-Amz-Target", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Security-Token", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Signature")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Signature", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Algorithm", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Date")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Date", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Credential")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Credential", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657146: Call_DeleteTrialComponent_402657134;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
                                                                                         ## 
  let valid = call_402657146.validator(path, query, header, formData, body, _)
  let scheme = call_402657146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657146.makeUrl(scheme.get, call_402657146.host, call_402657146.base,
                                   call_402657146.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657146, uri, valid, _)

proc call*(call_402657147: Call_DeleteTrialComponent_402657134; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   
                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402657148 = newJObject()
  if body != nil:
    body_402657148 = body
  result = call_402657147.call(nil, nil, nil, nil, body_402657148)

var deleteTrialComponent* = Call_DeleteTrialComponent_402657134(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_402657135, base: "/",
    makeUrl: url_DeleteTrialComponent_402657136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_402657149 = ref object of OpenApiRestCall_402656044
proc url_DeleteUserProfile_402657151(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserProfile_402657150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657152 = header.getOrDefault("X-Amz-Target")
  valid_402657152 = validateParameter(valid_402657152, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_402657152 != nil:
    section.add "X-Amz-Target", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Security-Token", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Signature")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Signature", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Algorithm", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Date")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Date", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Credential")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Credential", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657161: Call_DeleteUserProfile_402657149;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a user profile.
                                                                                         ## 
  let valid = call_402657161.validator(path, query, header, formData, body, _)
  let scheme = call_402657161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657161.makeUrl(scheme.get, call_402657161.host, call_402657161.base,
                                   call_402657161.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657161, uri, valid, _)

proc call*(call_402657162: Call_DeleteUserProfile_402657149; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_402657163 = newJObject()
  if body != nil:
    body_402657163 = body
  result = call_402657162.call(nil, nil, nil, nil, body_402657163)

var deleteUserProfile* = Call_DeleteUserProfile_402657149(
    name: "deleteUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_402657150, base: "/",
    makeUrl: url_DeleteUserProfile_402657151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_402657164 = ref object of OpenApiRestCall_402656044
proc url_DeleteWorkteam_402657166(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkteam_402657165(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657167 = header.getOrDefault("X-Amz-Target")
  valid_402657167 = validateParameter(valid_402657167, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_402657167 != nil:
    section.add "X-Amz-Target", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Security-Token", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Signature")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Signature", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657170
  var valid_402657171 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657171 = validateParameter(valid_402657171, JString,
                                      required = false, default = nil)
  if valid_402657171 != nil:
    section.add "X-Amz-Algorithm", valid_402657171
  var valid_402657172 = header.getOrDefault("X-Amz-Date")
  valid_402657172 = validateParameter(valid_402657172, JString,
                                      required = false, default = nil)
  if valid_402657172 != nil:
    section.add "X-Amz-Date", valid_402657172
  var valid_402657173 = header.getOrDefault("X-Amz-Credential")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Credential", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657176: Call_DeleteWorkteam_402657164; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
                                                                                         ## 
  let valid = call_402657176.validator(path, query, header, formData, body, _)
  let scheme = call_402657176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657176.makeUrl(scheme.get, call_402657176.host, call_402657176.base,
                                   call_402657176.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657176, uri, valid, _)

proc call*(call_402657177: Call_DeleteWorkteam_402657164; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_402657178 = newJObject()
  if body != nil:
    body_402657178 = body
  result = call_402657177.call(nil, nil, nil, nil, body_402657178)

var deleteWorkteam* = Call_DeleteWorkteam_402657164(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_402657165, base: "/",
    makeUrl: url_DeleteWorkteam_402657166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_402657179 = ref object of OpenApiRestCall_402656044
proc url_DescribeAlgorithm_402657181(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAlgorithm_402657180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657182 = header.getOrDefault("X-Amz-Target")
  valid_402657182 = validateParameter(valid_402657182, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_402657182 != nil:
    section.add "X-Amz-Target", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Security-Token", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Signature")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Signature", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-Algorithm", valid_402657186
  var valid_402657187 = header.getOrDefault("X-Amz-Date")
  valid_402657187 = validateParameter(valid_402657187, JString,
                                      required = false, default = nil)
  if valid_402657187 != nil:
    section.add "X-Amz-Date", valid_402657187
  var valid_402657188 = header.getOrDefault("X-Amz-Credential")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Credential", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657191: Call_DescribeAlgorithm_402657179;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
                                                                                         ## 
  let valid = call_402657191.validator(path, query, header, formData, body, _)
  let scheme = call_402657191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657191.makeUrl(scheme.get, call_402657191.host, call_402657191.base,
                                   call_402657191.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657191, uri, valid, _)

proc call*(call_402657192: Call_DescribeAlgorithm_402657179; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   
                                                                              ## body: JObject (required)
  var body_402657193 = newJObject()
  if body != nil:
    body_402657193 = body
  result = call_402657192.call(nil, nil, nil, nil, body_402657193)

var describeAlgorithm* = Call_DescribeAlgorithm_402657179(
    name: "describeAlgorithm", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_402657180, base: "/",
    makeUrl: url_DescribeAlgorithm_402657181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_402657194 = ref object of OpenApiRestCall_402656044
proc url_DescribeApp_402657196(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApp_402657195(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657197 = header.getOrDefault("X-Amz-Target")
  valid_402657197 = validateParameter(valid_402657197, JString, required = true, default = newJString(
      "SageMaker.DescribeApp"))
  if valid_402657197 != nil:
    section.add "X-Amz-Target", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Security-Token", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Signature")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Signature", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-Algorithm", valid_402657201
  var valid_402657202 = header.getOrDefault("X-Amz-Date")
  valid_402657202 = validateParameter(valid_402657202, JString,
                                      required = false, default = nil)
  if valid_402657202 != nil:
    section.add "X-Amz-Date", valid_402657202
  var valid_402657203 = header.getOrDefault("X-Amz-Credential")
  valid_402657203 = validateParameter(valid_402657203, JString,
                                      required = false, default = nil)
  if valid_402657203 != nil:
    section.add "X-Amz-Credential", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657206: Call_DescribeApp_402657194; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the app.
                                                                                         ## 
  let valid = call_402657206.validator(path, query, header, formData, body, _)
  let scheme = call_402657206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657206.makeUrl(scheme.get, call_402657206.host, call_402657206.base,
                                   call_402657206.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657206, uri, valid, _)

proc call*(call_402657207: Call_DescribeApp_402657194; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_402657208 = newJObject()
  if body != nil:
    body_402657208 = body
  result = call_402657207.call(nil, nil, nil, nil, body_402657208)

var describeApp* = Call_DescribeApp_402657194(name: "describeApp",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeApp",
    validator: validate_DescribeApp_402657195, base: "/",
    makeUrl: url_DescribeApp_402657196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_402657209 = ref object of OpenApiRestCall_402656044
proc url_DescribeAutoMLJob_402657211(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutoMLJob_402657210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657212 = header.getOrDefault("X-Amz-Target")
  valid_402657212 = validateParameter(valid_402657212, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_402657212 != nil:
    section.add "X-Amz-Target", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Security-Token", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Signature")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Signature", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Algorithm", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Date")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Date", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Credential")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Credential", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657221: Call_DescribeAutoMLJob_402657209;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about an Amazon SageMaker job.
                                                                                         ## 
  let valid = call_402657221.validator(path, query, header, formData, body, _)
  let scheme = call_402657221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657221.makeUrl(scheme.get, call_402657221.host, call_402657221.base,
                                   call_402657221.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657221, uri, valid, _)

proc call*(call_402657222: Call_DescribeAutoMLJob_402657209; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_402657223 = newJObject()
  if body != nil:
    body_402657223 = body
  result = call_402657222.call(nil, nil, nil, nil, body_402657223)

var describeAutoMLJob* = Call_DescribeAutoMLJob_402657209(
    name: "describeAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_402657210, base: "/",
    makeUrl: url_DescribeAutoMLJob_402657211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_402657224 = ref object of OpenApiRestCall_402656044
proc url_DescribeCodeRepository_402657226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCodeRepository_402657225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657227 = header.getOrDefault("X-Amz-Target")
  valid_402657227 = validateParameter(valid_402657227, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_402657227 != nil:
    section.add "X-Amz-Target", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Security-Token", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Signature")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Signature", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Algorithm", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Date")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Date", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Credential")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Credential", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657236: Call_DescribeCodeRepository_402657224;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about the specified Git repository.
                                                                                         ## 
  let valid = call_402657236.validator(path, query, header, formData, body, _)
  let scheme = call_402657236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657236.makeUrl(scheme.get, call_402657236.host, call_402657236.base,
                                   call_402657236.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657236, uri, valid, _)

proc call*(call_402657237: Call_DescribeCodeRepository_402657224; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_402657238 = newJObject()
  if body != nil:
    body_402657238 = body
  result = call_402657237.call(nil, nil, nil, nil, body_402657238)

var describeCodeRepository* = Call_DescribeCodeRepository_402657224(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_402657225, base: "/",
    makeUrl: url_DescribeCodeRepository_402657226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_402657239 = ref object of OpenApiRestCall_402656044
proc url_DescribeCompilationJob_402657241(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompilationJob_402657240(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657242 = header.getOrDefault("X-Amz-Target")
  valid_402657242 = validateParameter(valid_402657242, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_402657242 != nil:
    section.add "X-Amz-Target", valid_402657242
  var valid_402657243 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Security-Token", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Signature")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Signature", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Algorithm", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Date")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Date", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Credential")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Credential", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657251: Call_DescribeCompilationJob_402657239;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
                                                                                         ## 
  let valid = call_402657251.validator(path, query, header, formData, body, _)
  let scheme = call_402657251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657251.makeUrl(scheme.get, call_402657251.host, call_402657251.base,
                                   call_402657251.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657251, uri, valid, _)

proc call*(call_402657252: Call_DescribeCompilationJob_402657239; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   
                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657253 = newJObject()
  if body != nil:
    body_402657253 = body
  result = call_402657252.call(nil, nil, nil, nil, body_402657253)

var describeCompilationJob* = Call_DescribeCompilationJob_402657239(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_402657240, base: "/",
    makeUrl: url_DescribeCompilationJob_402657241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_402657254 = ref object of OpenApiRestCall_402656044
proc url_DescribeDomain_402657256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_402657255(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657257 = header.getOrDefault("X-Amz-Target")
  valid_402657257 = validateParameter(valid_402657257, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_402657257 != nil:
    section.add "X-Amz-Target", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Security-Token", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Signature")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Signature", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Algorithm", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Date")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Date", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Credential")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Credential", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657266: Call_DescribeDomain_402657254; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The desciption of the domain.
                                                                                         ## 
  let valid = call_402657266.validator(path, query, header, formData, body, _)
  let scheme = call_402657266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657266.makeUrl(scheme.get, call_402657266.host, call_402657266.base,
                                   call_402657266.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657266, uri, valid, _)

proc call*(call_402657267: Call_DescribeDomain_402657254; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_402657268 = newJObject()
  if body != nil:
    body_402657268 = body
  result = call_402657267.call(nil, nil, nil, nil, body_402657268)

var describeDomain* = Call_DescribeDomain_402657254(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_402657255, base: "/",
    makeUrl: url_DescribeDomain_402657256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_402657269 = ref object of OpenApiRestCall_402656044
proc url_DescribeEndpoint_402657271(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_402657270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657272 = header.getOrDefault("X-Amz-Target")
  valid_402657272 = validateParameter(valid_402657272, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_402657272 != nil:
    section.add "X-Amz-Target", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-Security-Token", valid_402657273
  var valid_402657274 = header.getOrDefault("X-Amz-Signature")
  valid_402657274 = validateParameter(valid_402657274, JString,
                                      required = false, default = nil)
  if valid_402657274 != nil:
    section.add "X-Amz-Signature", valid_402657274
  var valid_402657275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657275
  var valid_402657276 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Algorithm", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Date")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Date", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-Credential")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Credential", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657281: Call_DescribeEndpoint_402657269;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the description of an endpoint.
                                                                                         ## 
  let valid = call_402657281.validator(path, query, header, formData, body, _)
  let scheme = call_402657281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657281.makeUrl(scheme.get, call_402657281.host, call_402657281.base,
                                   call_402657281.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657281, uri, valid, _)

proc call*(call_402657282: Call_DescribeEndpoint_402657269; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_402657283 = newJObject()
  if body != nil:
    body_402657283 = body
  result = call_402657282.call(nil, nil, nil, nil, body_402657283)

var describeEndpoint* = Call_DescribeEndpoint_402657269(
    name: "describeEndpoint", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_402657270, base: "/",
    makeUrl: url_DescribeEndpoint_402657271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_402657284 = ref object of OpenApiRestCall_402656044
proc url_DescribeEndpointConfig_402657286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointConfig_402657285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657287 = header.getOrDefault("X-Amz-Target")
  valid_402657287 = validateParameter(valid_402657287, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_402657287 != nil:
    section.add "X-Amz-Target", valid_402657287
  var valid_402657288 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "X-Amz-Security-Token", valid_402657288
  var valid_402657289 = header.getOrDefault("X-Amz-Signature")
  valid_402657289 = validateParameter(valid_402657289, JString,
                                      required = false, default = nil)
  if valid_402657289 != nil:
    section.add "X-Amz-Signature", valid_402657289
  var valid_402657290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657290 = validateParameter(valid_402657290, JString,
                                      required = false, default = nil)
  if valid_402657290 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657290
  var valid_402657291 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Algorithm", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Date")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Date", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Credential")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Credential", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657296: Call_DescribeEndpointConfig_402657284;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
                                                                                         ## 
  let valid = call_402657296.validator(path, query, header, formData, body, _)
  let scheme = call_402657296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657296.makeUrl(scheme.get, call_402657296.host, call_402657296.base,
                                   call_402657296.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657296, uri, valid, _)

proc call*(call_402657297: Call_DescribeEndpointConfig_402657284; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   
                                                                                                                  ## body: JObject (required)
  var body_402657298 = newJObject()
  if body != nil:
    body_402657298 = body
  result = call_402657297.call(nil, nil, nil, nil, body_402657298)

var describeEndpointConfig* = Call_DescribeEndpointConfig_402657284(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_402657285, base: "/",
    makeUrl: url_DescribeEndpointConfig_402657286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_402657299 = ref object of OpenApiRestCall_402656044
proc url_DescribeExperiment_402657301(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExperiment_402657300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657302 = header.getOrDefault("X-Amz-Target")
  valid_402657302 = validateParameter(valid_402657302, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_402657302 != nil:
    section.add "X-Amz-Target", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-Security-Token", valid_402657303
  var valid_402657304 = header.getOrDefault("X-Amz-Signature")
  valid_402657304 = validateParameter(valid_402657304, JString,
                                      required = false, default = nil)
  if valid_402657304 != nil:
    section.add "X-Amz-Signature", valid_402657304
  var valid_402657305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657305 = validateParameter(valid_402657305, JString,
                                      required = false, default = nil)
  if valid_402657305 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657305
  var valid_402657306 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657306 = validateParameter(valid_402657306, JString,
                                      required = false, default = nil)
  if valid_402657306 != nil:
    section.add "X-Amz-Algorithm", valid_402657306
  var valid_402657307 = header.getOrDefault("X-Amz-Date")
  valid_402657307 = validateParameter(valid_402657307, JString,
                                      required = false, default = nil)
  if valid_402657307 != nil:
    section.add "X-Amz-Date", valid_402657307
  var valid_402657308 = header.getOrDefault("X-Amz-Credential")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Credential", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657311: Call_DescribeExperiment_402657299;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of an experiment's properties.
                                                                                         ## 
  let valid = call_402657311.validator(path, query, header, formData, body, _)
  let scheme = call_402657311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657311.makeUrl(scheme.get, call_402657311.host, call_402657311.base,
                                   call_402657311.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657311, uri, valid, _)

proc call*(call_402657312: Call_DescribeExperiment_402657299; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_402657313 = newJObject()
  if body != nil:
    body_402657313 = body
  result = call_402657312.call(nil, nil, nil, nil, body_402657313)

var describeExperiment* = Call_DescribeExperiment_402657299(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_402657300, base: "/",
    makeUrl: url_DescribeExperiment_402657301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_402657314 = ref object of OpenApiRestCall_402656044
proc url_DescribeFlowDefinition_402657316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFlowDefinition_402657315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657317 = header.getOrDefault("X-Amz-Target")
  valid_402657317 = validateParameter(valid_402657317, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_402657317 != nil:
    section.add "X-Amz-Target", valid_402657317
  var valid_402657318 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-Security-Token", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-Signature")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Signature", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Algorithm", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Date")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Date", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Credential")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Credential", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657326: Call_DescribeFlowDefinition_402657314;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified flow definition.
                                                                                         ## 
  let valid = call_402657326.validator(path, query, header, formData, body, _)
  let scheme = call_402657326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657326.makeUrl(scheme.get, call_402657326.host, call_402657326.base,
                                   call_402657326.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657326, uri, valid, _)

proc call*(call_402657327: Call_DescribeFlowDefinition_402657314; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_402657328 = newJObject()
  if body != nil:
    body_402657328 = body
  result = call_402657327.call(nil, nil, nil, nil, body_402657328)

var describeFlowDefinition* = Call_DescribeFlowDefinition_402657314(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_402657315, base: "/",
    makeUrl: url_DescribeFlowDefinition_402657316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_402657329 = ref object of OpenApiRestCall_402656044
proc url_DescribeHumanTaskUi_402657331(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHumanTaskUi_402657330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657332 = header.getOrDefault("X-Amz-Target")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_402657332 != nil:
    section.add "X-Amz-Target", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Security-Token", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Signature")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Signature", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Algorithm", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Date")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Date", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Credential")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Credential", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657341: Call_DescribeHumanTaskUi_402657329;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the requested human task user interface.
                                                                                         ## 
  let valid = call_402657341.validator(path, query, header, formData, body, _)
  let scheme = call_402657341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657341.makeUrl(scheme.get, call_402657341.host, call_402657341.base,
                                   call_402657341.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657341, uri, valid, _)

proc call*(call_402657342: Call_DescribeHumanTaskUi_402657329; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject 
                                                                       ## (required)
  var body_402657343 = newJObject()
  if body != nil:
    body_402657343 = body
  result = call_402657342.call(nil, nil, nil, nil, body_402657343)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_402657329(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_402657330, base: "/",
    makeUrl: url_DescribeHumanTaskUi_402657331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_402657344 = ref object of OpenApiRestCall_402656044
proc url_DescribeHyperParameterTuningJob_402657346(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHyperParameterTuningJob_402657345(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657347 = header.getOrDefault("X-Amz-Target")
  valid_402657347 = validateParameter(valid_402657347, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_402657347 != nil:
    section.add "X-Amz-Target", valid_402657347
  var valid_402657348 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-Security-Token", valid_402657348
  var valid_402657349 = header.getOrDefault("X-Amz-Signature")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "X-Amz-Signature", valid_402657349
  var valid_402657350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657350 = validateParameter(valid_402657350, JString,
                                      required = false, default = nil)
  if valid_402657350 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Algorithm", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Date")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Date", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Credential")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Credential", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657356: Call_DescribeHyperParameterTuningJob_402657344;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a description of a hyperparameter tuning job.
                                                                                         ## 
  let valid = call_402657356.validator(path, query, header, formData, body, _)
  let scheme = call_402657356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657356.makeUrl(scheme.get, call_402657356.host, call_402657356.base,
                                   call_402657356.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657356, uri, valid, _)

proc call*(call_402657357: Call_DescribeHyperParameterTuningJob_402657344;
           body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_402657358 = newJObject()
  if body != nil:
    body_402657358 = body
  result = call_402657357.call(nil, nil, nil, nil, body_402657358)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_402657344(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_402657345, base: "/",
    makeUrl: url_DescribeHyperParameterTuningJob_402657346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_402657359 = ref object of OpenApiRestCall_402656044
proc url_DescribeLabelingJob_402657361(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLabelingJob_402657360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657362 = header.getOrDefault("X-Amz-Target")
  valid_402657362 = validateParameter(valid_402657362, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_402657362 != nil:
    section.add "X-Amz-Target", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Security-Token", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-Signature")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Signature", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-Algorithm", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Date")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Date", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-Credential")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-Credential", valid_402657368
  var valid_402657369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657369 = validateParameter(valid_402657369, JString,
                                      required = false, default = nil)
  if valid_402657369 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657371: Call_DescribeLabelingJob_402657359;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a labeling job.
                                                                                         ## 
  let valid = call_402657371.validator(path, query, header, formData, body, _)
  let scheme = call_402657371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657371.makeUrl(scheme.get, call_402657371.host, call_402657371.base,
                                   call_402657371.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657371, uri, valid, _)

proc call*(call_402657372: Call_DescribeLabelingJob_402657359; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_402657373 = newJObject()
  if body != nil:
    body_402657373 = body
  result = call_402657372.call(nil, nil, nil, nil, body_402657373)

var describeLabelingJob* = Call_DescribeLabelingJob_402657359(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_402657360, base: "/",
    makeUrl: url_DescribeLabelingJob_402657361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_402657374 = ref object of OpenApiRestCall_402656044
proc url_DescribeModel_402657376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModel_402657375(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657377 = header.getOrDefault("X-Amz-Target")
  valid_402657377 = validateParameter(valid_402657377, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_402657377 != nil:
    section.add "X-Amz-Target", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Security-Token", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-Signature")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Signature", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657380
  var valid_402657381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "X-Amz-Algorithm", valid_402657381
  var valid_402657382 = header.getOrDefault("X-Amz-Date")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "X-Amz-Date", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-Credential")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-Credential", valid_402657383
  var valid_402657384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657386: Call_DescribeModel_402657374; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
                                                                                         ## 
  let valid = call_402657386.validator(path, query, header, formData, body, _)
  let scheme = call_402657386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657386.makeUrl(scheme.get, call_402657386.host, call_402657386.base,
                                   call_402657386.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657386, uri, valid, _)

proc call*(call_402657387: Call_DescribeModel_402657374; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   
                                                                               ## body: JObject (required)
  var body_402657388 = newJObject()
  if body != nil:
    body_402657388 = body
  result = call_402657387.call(nil, nil, nil, nil, body_402657388)

var describeModel* = Call_DescribeModel_402657374(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_402657375, base: "/",
    makeUrl: url_DescribeModel_402657376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_402657389 = ref object of OpenApiRestCall_402656044
proc url_DescribeModelPackage_402657391(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelPackage_402657390(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657392 = header.getOrDefault("X-Amz-Target")
  valid_402657392 = validateParameter(valid_402657392, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_402657392 != nil:
    section.add "X-Amz-Target", valid_402657392
  var valid_402657393 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "X-Amz-Security-Token", valid_402657393
  var valid_402657394 = header.getOrDefault("X-Amz-Signature")
  valid_402657394 = validateParameter(valid_402657394, JString,
                                      required = false, default = nil)
  if valid_402657394 != nil:
    section.add "X-Amz-Signature", valid_402657394
  var valid_402657395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657395 = validateParameter(valid_402657395, JString,
                                      required = false, default = nil)
  if valid_402657395 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657395
  var valid_402657396 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "X-Amz-Algorithm", valid_402657396
  var valid_402657397 = header.getOrDefault("X-Amz-Date")
  valid_402657397 = validateParameter(valid_402657397, JString,
                                      required = false, default = nil)
  if valid_402657397 != nil:
    section.add "X-Amz-Date", valid_402657397
  var valid_402657398 = header.getOrDefault("X-Amz-Credential")
  valid_402657398 = validateParameter(valid_402657398, JString,
                                      required = false, default = nil)
  if valid_402657398 != nil:
    section.add "X-Amz-Credential", valid_402657398
  var valid_402657399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657401: Call_DescribeModelPackage_402657389;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
                                                                                         ## 
  let valid = call_402657401.validator(path, query, header, formData, body, _)
  let scheme = call_402657401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657401.makeUrl(scheme.get, call_402657401.host, call_402657401.base,
                                   call_402657401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657401, uri, valid, _)

proc call*(call_402657402: Call_DescribeModelPackage_402657389; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   
                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657403 = newJObject()
  if body != nil:
    body_402657403 = body
  result = call_402657402.call(nil, nil, nil, nil, body_402657403)

var describeModelPackage* = Call_DescribeModelPackage_402657389(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_402657390, base: "/",
    makeUrl: url_DescribeModelPackage_402657391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_402657404 = ref object of OpenApiRestCall_402656044
proc url_DescribeMonitoringSchedule_402657406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMonitoringSchedule_402657405(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657407 = header.getOrDefault("X-Amz-Target")
  valid_402657407 = validateParameter(valid_402657407, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_402657407 != nil:
    section.add "X-Amz-Target", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Security-Token", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-Signature")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Signature", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657410
  var valid_402657411 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657411 = validateParameter(valid_402657411, JString,
                                      required = false, default = nil)
  if valid_402657411 != nil:
    section.add "X-Amz-Algorithm", valid_402657411
  var valid_402657412 = header.getOrDefault("X-Amz-Date")
  valid_402657412 = validateParameter(valid_402657412, JString,
                                      required = false, default = nil)
  if valid_402657412 != nil:
    section.add "X-Amz-Date", valid_402657412
  var valid_402657413 = header.getOrDefault("X-Amz-Credential")
  valid_402657413 = validateParameter(valid_402657413, JString,
                                      required = false, default = nil)
  if valid_402657413 != nil:
    section.add "X-Amz-Credential", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657416: Call_DescribeMonitoringSchedule_402657404;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the schedule for a monitoring job.
                                                                                         ## 
  let valid = call_402657416.validator(path, query, header, formData, body, _)
  let scheme = call_402657416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657416.makeUrl(scheme.get, call_402657416.host, call_402657416.base,
                                   call_402657416.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657416, uri, valid, _)

proc call*(call_402657417: Call_DescribeMonitoringSchedule_402657404;
           body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_402657418 = newJObject()
  if body != nil:
    body_402657418 = body
  result = call_402657417.call(nil, nil, nil, nil, body_402657418)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_402657404(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_402657405, base: "/",
    makeUrl: url_DescribeMonitoringSchedule_402657406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_402657419 = ref object of OpenApiRestCall_402656044
proc url_DescribeNotebookInstance_402657421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstance_402657420(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657422 = header.getOrDefault("X-Amz-Target")
  valid_402657422 = validateParameter(valid_402657422, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_402657422 != nil:
    section.add "X-Amz-Target", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Security-Token", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-Signature")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Signature", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657425
  var valid_402657426 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "X-Amz-Algorithm", valid_402657426
  var valid_402657427 = header.getOrDefault("X-Amz-Date")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "X-Amz-Date", valid_402657427
  var valid_402657428 = header.getOrDefault("X-Amz-Credential")
  valid_402657428 = validateParameter(valid_402657428, JString,
                                      required = false, default = nil)
  if valid_402657428 != nil:
    section.add "X-Amz-Credential", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657431: Call_DescribeNotebookInstance_402657419;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a notebook instance.
                                                                                         ## 
  let valid = call_402657431.validator(path, query, header, formData, body, _)
  let scheme = call_402657431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657431.makeUrl(scheme.get, call_402657431.host, call_402657431.base,
                                   call_402657431.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657431, uri, valid, _)

proc call*(call_402657432: Call_DescribeNotebookInstance_402657419;
           body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_402657433 = newJObject()
  if body != nil:
    body_402657433 = body
  result = call_402657432.call(nil, nil, nil, nil, body_402657433)

var describeNotebookInstance* = Call_DescribeNotebookInstance_402657419(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_402657420, base: "/",
    makeUrl: url_DescribeNotebookInstance_402657421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_402657434 = ref object of OpenApiRestCall_402656044
proc url_DescribeNotebookInstanceLifecycleConfig_402657436(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_402657435(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657437 = header.getOrDefault("X-Amz-Target")
  valid_402657437 = validateParameter(valid_402657437, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_402657437 != nil:
    section.add "X-Amz-Target", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-Security-Token", valid_402657438
  var valid_402657439 = header.getOrDefault("X-Amz-Signature")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "X-Amz-Signature", valid_402657439
  var valid_402657440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657440
  var valid_402657441 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "X-Amz-Algorithm", valid_402657441
  var valid_402657442 = header.getOrDefault("X-Amz-Date")
  valid_402657442 = validateParameter(valid_402657442, JString,
                                      required = false, default = nil)
  if valid_402657442 != nil:
    section.add "X-Amz-Date", valid_402657442
  var valid_402657443 = header.getOrDefault("X-Amz-Credential")
  valid_402657443 = validateParameter(valid_402657443, JString,
                                      required = false, default = nil)
  if valid_402657443 != nil:
    section.add "X-Amz-Credential", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657446: Call_DescribeNotebookInstanceLifecycleConfig_402657434;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
                                                                                         ## 
  let valid = call_402657446.validator(path, query, header, formData, body, _)
  let scheme = call_402657446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657446.makeUrl(scheme.get, call_402657446.host, call_402657446.base,
                                   call_402657446.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657446, uri, valid, _)

proc call*(call_402657447: Call_DescribeNotebookInstanceLifecycleConfig_402657434;
           body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402657448 = newJObject()
  if body != nil:
    body_402657448 = body
  result = call_402657447.call(nil, nil, nil, nil, body_402657448)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_402657434(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_402657435,
    base: "/", makeUrl: url_DescribeNotebookInstanceLifecycleConfig_402657436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_402657449 = ref object of OpenApiRestCall_402656044
proc url_DescribeProcessingJob_402657451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProcessingJob_402657450(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657452 = header.getOrDefault("X-Amz-Target")
  valid_402657452 = validateParameter(valid_402657452, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_402657452 != nil:
    section.add "X-Amz-Target", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Security-Token", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-Signature")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-Signature", valid_402657454
  var valid_402657455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657455 = validateParameter(valid_402657455, JString,
                                      required = false, default = nil)
  if valid_402657455 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657455
  var valid_402657456 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657456 = validateParameter(valid_402657456, JString,
                                      required = false, default = nil)
  if valid_402657456 != nil:
    section.add "X-Amz-Algorithm", valid_402657456
  var valid_402657457 = header.getOrDefault("X-Amz-Date")
  valid_402657457 = validateParameter(valid_402657457, JString,
                                      required = false, default = nil)
  if valid_402657457 != nil:
    section.add "X-Amz-Date", valid_402657457
  var valid_402657458 = header.getOrDefault("X-Amz-Credential")
  valid_402657458 = validateParameter(valid_402657458, JString,
                                      required = false, default = nil)
  if valid_402657458 != nil:
    section.add "X-Amz-Credential", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657461: Call_DescribeProcessingJob_402657449;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of a processing job.
                                                                                         ## 
  let valid = call_402657461.validator(path, query, header, formData, body, _)
  let scheme = call_402657461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657461.makeUrl(scheme.get, call_402657461.host, call_402657461.base,
                                   call_402657461.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657461, uri, valid, _)

proc call*(call_402657462: Call_DescribeProcessingJob_402657449; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_402657463 = newJObject()
  if body != nil:
    body_402657463 = body
  result = call_402657462.call(nil, nil, nil, nil, body_402657463)

var describeProcessingJob* = Call_DescribeProcessingJob_402657449(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_402657450, base: "/",
    makeUrl: url_DescribeProcessingJob_402657451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_402657464 = ref object of OpenApiRestCall_402656044
proc url_DescribeSubscribedWorkteam_402657466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubscribedWorkteam_402657465(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657467 = header.getOrDefault("X-Amz-Target")
  valid_402657467 = validateParameter(valid_402657467, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_402657467 != nil:
    section.add "X-Amz-Target", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Security-Token", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-Signature")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-Signature", valid_402657469
  var valid_402657470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657470
  var valid_402657471 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "X-Amz-Algorithm", valid_402657471
  var valid_402657472 = header.getOrDefault("X-Amz-Date")
  valid_402657472 = validateParameter(valid_402657472, JString,
                                      required = false, default = nil)
  if valid_402657472 != nil:
    section.add "X-Amz-Date", valid_402657472
  var valid_402657473 = header.getOrDefault("X-Amz-Credential")
  valid_402657473 = validateParameter(valid_402657473, JString,
                                      required = false, default = nil)
  if valid_402657473 != nil:
    section.add "X-Amz-Credential", valid_402657473
  var valid_402657474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657476: Call_DescribeSubscribedWorkteam_402657464;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
                                                                                         ## 
  let valid = call_402657476.validator(path, query, header, formData, body, _)
  let scheme = call_402657476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657476.makeUrl(scheme.get, call_402657476.host, call_402657476.base,
                                   call_402657476.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657476, uri, valid, _)

proc call*(call_402657477: Call_DescribeSubscribedWorkteam_402657464;
           body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   
                                                                                                                                             ## body: JObject (required)
  var body_402657478 = newJObject()
  if body != nil:
    body_402657478 = body
  result = call_402657477.call(nil, nil, nil, nil, body_402657478)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_402657464(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_402657465, base: "/",
    makeUrl: url_DescribeSubscribedWorkteam_402657466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_402657479 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrainingJob_402657481(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrainingJob_402657480(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657482 = header.getOrDefault("X-Amz-Target")
  valid_402657482 = validateParameter(valid_402657482, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_402657482 != nil:
    section.add "X-Amz-Target", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Security-Token", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-Signature")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-Signature", valid_402657484
  var valid_402657485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657485
  var valid_402657486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Algorithm", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Date")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Date", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Credential")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Credential", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657491: Call_DescribeTrainingJob_402657479;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a training job.
                                                                                         ## 
  let valid = call_402657491.validator(path, query, header, formData, body, _)
  let scheme = call_402657491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657491.makeUrl(scheme.get, call_402657491.host, call_402657491.base,
                                   call_402657491.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657491, uri, valid, _)

proc call*(call_402657492: Call_DescribeTrainingJob_402657479; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_402657493 = newJObject()
  if body != nil:
    body_402657493 = body
  result = call_402657492.call(nil, nil, nil, nil, body_402657493)

var describeTrainingJob* = Call_DescribeTrainingJob_402657479(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_402657480, base: "/",
    makeUrl: url_DescribeTrainingJob_402657481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_402657494 = ref object of OpenApiRestCall_402656044
proc url_DescribeTransformJob_402657496(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTransformJob_402657495(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657497 = header.getOrDefault("X-Amz-Target")
  valid_402657497 = validateParameter(valid_402657497, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_402657497 != nil:
    section.add "X-Amz-Target", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Security-Token", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-Signature")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-Signature", valid_402657499
  var valid_402657500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657500 = validateParameter(valid_402657500, JString,
                                      required = false, default = nil)
  if valid_402657500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657500
  var valid_402657501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Algorithm", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-Date")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Date", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Credential")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Credential", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657506: Call_DescribeTransformJob_402657494;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a transform job.
                                                                                         ## 
  let valid = call_402657506.validator(path, query, header, formData, body, _)
  let scheme = call_402657506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657506.makeUrl(scheme.get, call_402657506.host, call_402657506.base,
                                   call_402657506.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657506, uri, valid, _)

proc call*(call_402657507: Call_DescribeTransformJob_402657494; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_402657508 = newJObject()
  if body != nil:
    body_402657508 = body
  result = call_402657507.call(nil, nil, nil, nil, body_402657508)

var describeTransformJob* = Call_DescribeTransformJob_402657494(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_402657495, base: "/",
    makeUrl: url_DescribeTransformJob_402657496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_402657509 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrial_402657511(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrial_402657510(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657512 = header.getOrDefault("X-Amz-Target")
  valid_402657512 = validateParameter(valid_402657512, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_402657512 != nil:
    section.add "X-Amz-Target", valid_402657512
  var valid_402657513 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657513 = validateParameter(valid_402657513, JString,
                                      required = false, default = nil)
  if valid_402657513 != nil:
    section.add "X-Amz-Security-Token", valid_402657513
  var valid_402657514 = header.getOrDefault("X-Amz-Signature")
  valid_402657514 = validateParameter(valid_402657514, JString,
                                      required = false, default = nil)
  if valid_402657514 != nil:
    section.add "X-Amz-Signature", valid_402657514
  var valid_402657515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657515 = validateParameter(valid_402657515, JString,
                                      required = false, default = nil)
  if valid_402657515 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657515
  var valid_402657516 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657516 = validateParameter(valid_402657516, JString,
                                      required = false, default = nil)
  if valid_402657516 != nil:
    section.add "X-Amz-Algorithm", valid_402657516
  var valid_402657517 = header.getOrDefault("X-Amz-Date")
  valid_402657517 = validateParameter(valid_402657517, JString,
                                      required = false, default = nil)
  if valid_402657517 != nil:
    section.add "X-Amz-Date", valid_402657517
  var valid_402657518 = header.getOrDefault("X-Amz-Credential")
  valid_402657518 = validateParameter(valid_402657518, JString,
                                      required = false, default = nil)
  if valid_402657518 != nil:
    section.add "X-Amz-Credential", valid_402657518
  var valid_402657519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657519 = validateParameter(valid_402657519, JString,
                                      required = false, default = nil)
  if valid_402657519 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657521: Call_DescribeTrial_402657509; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of a trial's properties.
                                                                                         ## 
  let valid = call_402657521.validator(path, query, header, formData, body, _)
  let scheme = call_402657521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657521.makeUrl(scheme.get, call_402657521.host, call_402657521.base,
                                   call_402657521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657521, uri, valid, _)

proc call*(call_402657522: Call_DescribeTrial_402657509; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_402657523 = newJObject()
  if body != nil:
    body_402657523 = body
  result = call_402657522.call(nil, nil, nil, nil, body_402657523)

var describeTrial* = Call_DescribeTrial_402657509(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_402657510, base: "/",
    makeUrl: url_DescribeTrial_402657511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_402657524 = ref object of OpenApiRestCall_402656044
proc url_DescribeTrialComponent_402657526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrialComponent_402657525(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657527 = header.getOrDefault("X-Amz-Target")
  valid_402657527 = validateParameter(valid_402657527, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_402657527 != nil:
    section.add "X-Amz-Target", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Security-Token", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-Signature")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-Signature", valid_402657529
  var valid_402657530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657530 = validateParameter(valid_402657530, JString,
                                      required = false, default = nil)
  if valid_402657530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657530
  var valid_402657531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657531 = validateParameter(valid_402657531, JString,
                                      required = false, default = nil)
  if valid_402657531 != nil:
    section.add "X-Amz-Algorithm", valid_402657531
  var valid_402657532 = header.getOrDefault("X-Amz-Date")
  valid_402657532 = validateParameter(valid_402657532, JString,
                                      required = false, default = nil)
  if valid_402657532 != nil:
    section.add "X-Amz-Date", valid_402657532
  var valid_402657533 = header.getOrDefault("X-Amz-Credential")
  valid_402657533 = validateParameter(valid_402657533, JString,
                                      required = false, default = nil)
  if valid_402657533 != nil:
    section.add "X-Amz-Credential", valid_402657533
  var valid_402657534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657534 = validateParameter(valid_402657534, JString,
                                      required = false, default = nil)
  if valid_402657534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657536: Call_DescribeTrialComponent_402657524;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of a trials component's properties.
                                                                                         ## 
  let valid = call_402657536.validator(path, query, header, formData, body, _)
  let scheme = call_402657536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657536.makeUrl(scheme.get, call_402657536.host, call_402657536.base,
                                   call_402657536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657536, uri, valid, _)

proc call*(call_402657537: Call_DescribeTrialComponent_402657524; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_402657538 = newJObject()
  if body != nil:
    body_402657538 = body
  result = call_402657537.call(nil, nil, nil, nil, body_402657538)

var describeTrialComponent* = Call_DescribeTrialComponent_402657524(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_402657525, base: "/",
    makeUrl: url_DescribeTrialComponent_402657526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_402657539 = ref object of OpenApiRestCall_402656044
proc url_DescribeUserProfile_402657541(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserProfile_402657540(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657542 = header.getOrDefault("X-Amz-Target")
  valid_402657542 = validateParameter(valid_402657542, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_402657542 != nil:
    section.add "X-Amz-Target", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Security-Token", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-Signature")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-Signature", valid_402657544
  var valid_402657545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657545
  var valid_402657546 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "X-Amz-Algorithm", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-Date")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-Date", valid_402657547
  var valid_402657548 = header.getOrDefault("X-Amz-Credential")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "X-Amz-Credential", valid_402657548
  var valid_402657549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657549 = validateParameter(valid_402657549, JString,
                                      required = false, default = nil)
  if valid_402657549 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657551: Call_DescribeUserProfile_402657539;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user profile.
                                                                                         ## 
  let valid = call_402657551.validator(path, query, header, formData, body, _)
  let scheme = call_402657551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657551.makeUrl(scheme.get, call_402657551.host, call_402657551.base,
                                   call_402657551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657551, uri, valid, _)

proc call*(call_402657552: Call_DescribeUserProfile_402657539; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_402657553 = newJObject()
  if body != nil:
    body_402657553 = body
  result = call_402657552.call(nil, nil, nil, nil, body_402657553)

var describeUserProfile* = Call_DescribeUserProfile_402657539(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_402657540, base: "/",
    makeUrl: url_DescribeUserProfile_402657541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkforce_402657554 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkforce_402657556(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkforce_402657555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657557 = header.getOrDefault("X-Amz-Target")
  valid_402657557 = validateParameter(valid_402657557, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkforce"))
  if valid_402657557 != nil:
    section.add "X-Amz-Target", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-Security-Token", valid_402657558
  var valid_402657559 = header.getOrDefault("X-Amz-Signature")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-Signature", valid_402657559
  var valid_402657560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657560
  var valid_402657561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Algorithm", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Date")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Date", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Credential")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Credential", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657566: Call_DescribeWorkforce_402657554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
                                                                                         ## 
  let valid = call_402657566.validator(path, query, header, formData, body, _)
  let scheme = call_402657566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657566.makeUrl(scheme.get, call_402657566.host, call_402657566.base,
                                   call_402657566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657566, uri, valid, _)

proc call*(call_402657567: Call_DescribeWorkforce_402657554; body: JsonNode): Recallable =
  ## describeWorkforce
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657568 = newJObject()
  if body != nil:
    body_402657568 = body
  result = call_402657567.call(nil, nil, nil, nil, body_402657568)

var describeWorkforce* = Call_DescribeWorkforce_402657554(
    name: "describeWorkforce", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkforce",
    validator: validate_DescribeWorkforce_402657555, base: "/",
    makeUrl: url_DescribeWorkforce_402657556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_402657569 = ref object of OpenApiRestCall_402656044
proc url_DescribeWorkteam_402657571(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkteam_402657570(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657572 = header.getOrDefault("X-Amz-Target")
  valid_402657572 = validateParameter(valid_402657572, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_402657572 != nil:
    section.add "X-Amz-Target", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-Security-Token", valid_402657573
  var valid_402657574 = header.getOrDefault("X-Amz-Signature")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-Signature", valid_402657574
  var valid_402657575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657575
  var valid_402657576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "X-Amz-Algorithm", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Date")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Date", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Credential")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Credential", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657581: Call_DescribeWorkteam_402657569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
                                                                                         ## 
  let valid = call_402657581.validator(path, query, header, formData, body, _)
  let scheme = call_402657581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657581.makeUrl(scheme.get, call_402657581.host, call_402657581.base,
                                   call_402657581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657581, uri, valid, _)

proc call*(call_402657582: Call_DescribeWorkteam_402657569; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   
                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657583 = newJObject()
  if body != nil:
    body_402657583 = body
  result = call_402657582.call(nil, nil, nil, nil, body_402657583)

var describeWorkteam* = Call_DescribeWorkteam_402657569(
    name: "describeWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_402657570, base: "/",
    makeUrl: url_DescribeWorkteam_402657571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_402657584 = ref object of OpenApiRestCall_402656044
proc url_DisassociateTrialComponent_402657586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTrialComponent_402657585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657587 = header.getOrDefault("X-Amz-Target")
  valid_402657587 = validateParameter(valid_402657587, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_402657587 != nil:
    section.add "X-Amz-Target", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-Security-Token", valid_402657588
  var valid_402657589 = header.getOrDefault("X-Amz-Signature")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "X-Amz-Signature", valid_402657589
  var valid_402657590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657590
  var valid_402657591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657591 = validateParameter(valid_402657591, JString,
                                      required = false, default = nil)
  if valid_402657591 != nil:
    section.add "X-Amz-Algorithm", valid_402657591
  var valid_402657592 = header.getOrDefault("X-Amz-Date")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "X-Amz-Date", valid_402657592
  var valid_402657593 = header.getOrDefault("X-Amz-Credential")
  valid_402657593 = validateParameter(valid_402657593, JString,
                                      required = false, default = nil)
  if valid_402657593 != nil:
    section.add "X-Amz-Credential", valid_402657593
  var valid_402657594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657596: Call_DisassociateTrialComponent_402657584;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
                                                                                         ## 
  let valid = call_402657596.validator(path, query, header, formData, body, _)
  let scheme = call_402657596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657596.makeUrl(scheme.get, call_402657596.host, call_402657596.base,
                                   call_402657596.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657596, uri, valid, _)

proc call*(call_402657597: Call_DisassociateTrialComponent_402657584;
           body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402657598 = newJObject()
  if body != nil:
    body_402657598 = body
  result = call_402657597.call(nil, nil, nil, nil, body_402657598)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_402657584(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_402657585, base: "/",
    makeUrl: url_DisassociateTrialComponent_402657586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_402657599 = ref object of OpenApiRestCall_402656044
proc url_GetSearchSuggestions_402657601(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSearchSuggestions_402657600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657602 = header.getOrDefault("X-Amz-Target")
  valid_402657602 = validateParameter(valid_402657602, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_402657602 != nil:
    section.add "X-Amz-Target", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Security-Token", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-Signature")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-Signature", valid_402657604
  var valid_402657605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657605
  var valid_402657606 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657606 = validateParameter(valid_402657606, JString,
                                      required = false, default = nil)
  if valid_402657606 != nil:
    section.add "X-Amz-Algorithm", valid_402657606
  var valid_402657607 = header.getOrDefault("X-Amz-Date")
  valid_402657607 = validateParameter(valid_402657607, JString,
                                      required = false, default = nil)
  if valid_402657607 != nil:
    section.add "X-Amz-Date", valid_402657607
  var valid_402657608 = header.getOrDefault("X-Amz-Credential")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-Credential", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657611: Call_GetSearchSuggestions_402657599;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
                                                                                         ## 
  let valid = call_402657611.validator(path, query, header, formData, body, _)
  let scheme = call_402657611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657611.makeUrl(scheme.get, call_402657611.host, call_402657611.base,
                                   call_402657611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657611, uri, valid, _)

proc call*(call_402657612: Call_GetSearchSuggestions_402657599; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   
                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657613 = newJObject()
  if body != nil:
    body_402657613 = body
  result = call_402657612.call(nil, nil, nil, nil, body_402657613)

var getSearchSuggestions* = Call_GetSearchSuggestions_402657599(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_402657600, base: "/",
    makeUrl: url_GetSearchSuggestions_402657601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_402657614 = ref object of OpenApiRestCall_402656044
proc url_ListAlgorithms_402657616(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAlgorithms_402657615(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657617 = query.getOrDefault("MaxResults")
  valid_402657617 = validateParameter(valid_402657617, JString,
                                      required = false, default = nil)
  if valid_402657617 != nil:
    section.add "MaxResults", valid_402657617
  var valid_402657618 = query.getOrDefault("NextToken")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "NextToken", valid_402657618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657619 = header.getOrDefault("X-Amz-Target")
  valid_402657619 = validateParameter(valid_402657619, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_402657619 != nil:
    section.add "X-Amz-Target", valid_402657619
  var valid_402657620 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657620 = validateParameter(valid_402657620, JString,
                                      required = false, default = nil)
  if valid_402657620 != nil:
    section.add "X-Amz-Security-Token", valid_402657620
  var valid_402657621 = header.getOrDefault("X-Amz-Signature")
  valid_402657621 = validateParameter(valid_402657621, JString,
                                      required = false, default = nil)
  if valid_402657621 != nil:
    section.add "X-Amz-Signature", valid_402657621
  var valid_402657622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657622 = validateParameter(valid_402657622, JString,
                                      required = false, default = nil)
  if valid_402657622 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657622
  var valid_402657623 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-Algorithm", valid_402657623
  var valid_402657624 = header.getOrDefault("X-Amz-Date")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "X-Amz-Date", valid_402657624
  var valid_402657625 = header.getOrDefault("X-Amz-Credential")
  valid_402657625 = validateParameter(valid_402657625, JString,
                                      required = false, default = nil)
  if valid_402657625 != nil:
    section.add "X-Amz-Credential", valid_402657625
  var valid_402657626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657628: Call_ListAlgorithms_402657614; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the machine learning algorithms that have been created.
                                                                                         ## 
  let valid = call_402657628.validator(path, query, header, formData, body, _)
  let scheme = call_402657628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657628.makeUrl(scheme.get, call_402657628.host, call_402657628.base,
                                   call_402657628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657628, uri, valid, _)

proc call*(call_402657629: Call_ListAlgorithms_402657614; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
                                                                  ##             : Pagination limit
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  var query_402657630 = newJObject()
  var body_402657631 = newJObject()
  add(query_402657630, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657631 = body
  add(query_402657630, "NextToken", newJString(NextToken))
  result = call_402657629.call(nil, query_402657630, nil, nil, body_402657631)

var listAlgorithms* = Call_ListAlgorithms_402657614(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_402657615, base: "/",
    makeUrl: url_ListAlgorithms_402657616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_402657632 = ref object of OpenApiRestCall_402656044
proc url_ListApps_402657634(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_402657633(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657635 = query.getOrDefault("MaxResults")
  valid_402657635 = validateParameter(valid_402657635, JString,
                                      required = false, default = nil)
  if valid_402657635 != nil:
    section.add "MaxResults", valid_402657635
  var valid_402657636 = query.getOrDefault("NextToken")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "NextToken", valid_402657636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657637 = header.getOrDefault("X-Amz-Target")
  valid_402657637 = validateParameter(valid_402657637, JString, required = true, default = newJString(
      "SageMaker.ListApps"))
  if valid_402657637 != nil:
    section.add "X-Amz-Target", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-Security-Token", valid_402657638
  var valid_402657639 = header.getOrDefault("X-Amz-Signature")
  valid_402657639 = validateParameter(valid_402657639, JString,
                                      required = false, default = nil)
  if valid_402657639 != nil:
    section.add "X-Amz-Signature", valid_402657639
  var valid_402657640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657640 = validateParameter(valid_402657640, JString,
                                      required = false, default = nil)
  if valid_402657640 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657640
  var valid_402657641 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657641 = validateParameter(valid_402657641, JString,
                                      required = false, default = nil)
  if valid_402657641 != nil:
    section.add "X-Amz-Algorithm", valid_402657641
  var valid_402657642 = header.getOrDefault("X-Amz-Date")
  valid_402657642 = validateParameter(valid_402657642, JString,
                                      required = false, default = nil)
  if valid_402657642 != nil:
    section.add "X-Amz-Date", valid_402657642
  var valid_402657643 = header.getOrDefault("X-Amz-Credential")
  valid_402657643 = validateParameter(valid_402657643, JString,
                                      required = false, default = nil)
  if valid_402657643 != nil:
    section.add "X-Amz-Credential", valid_402657643
  var valid_402657644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657644 = validateParameter(valid_402657644, JString,
                                      required = false, default = nil)
  if valid_402657644 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657646: Call_ListApps_402657632; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists apps.
                                                                                         ## 
  let valid = call_402657646.validator(path, query, header, formData, body, _)
  let scheme = call_402657646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657646.makeUrl(scheme.get, call_402657646.host, call_402657646.base,
                                   call_402657646.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657646, uri, valid, _)

proc call*(call_402657647: Call_ListApps_402657632; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
                ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657648 = newJObject()
  var body_402657649 = newJObject()
  add(query_402657648, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657649 = body
  add(query_402657648, "NextToken", newJString(NextToken))
  result = call_402657647.call(nil, query_402657648, nil, nil, body_402657649)

var listApps* = Call_ListApps_402657632(name: "listApps",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListApps",
                                        validator: validate_ListApps_402657633,
                                        base: "/", makeUrl: url_ListApps_402657634,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_402657650 = ref object of OpenApiRestCall_402656044
proc url_ListAutoMLJobs_402657652(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAutoMLJobs_402657651(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657653 = query.getOrDefault("MaxResults")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "MaxResults", valid_402657653
  var valid_402657654 = query.getOrDefault("NextToken")
  valid_402657654 = validateParameter(valid_402657654, JString,
                                      required = false, default = nil)
  if valid_402657654 != nil:
    section.add "NextToken", valid_402657654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657655 = header.getOrDefault("X-Amz-Target")
  valid_402657655 = validateParameter(valid_402657655, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_402657655 != nil:
    section.add "X-Amz-Target", valid_402657655
  var valid_402657656 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657656 = validateParameter(valid_402657656, JString,
                                      required = false, default = nil)
  if valid_402657656 != nil:
    section.add "X-Amz-Security-Token", valid_402657656
  var valid_402657657 = header.getOrDefault("X-Amz-Signature")
  valid_402657657 = validateParameter(valid_402657657, JString,
                                      required = false, default = nil)
  if valid_402657657 != nil:
    section.add "X-Amz-Signature", valid_402657657
  var valid_402657658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657658 = validateParameter(valid_402657658, JString,
                                      required = false, default = nil)
  if valid_402657658 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657658
  var valid_402657659 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657659 = validateParameter(valid_402657659, JString,
                                      required = false, default = nil)
  if valid_402657659 != nil:
    section.add "X-Amz-Algorithm", valid_402657659
  var valid_402657660 = header.getOrDefault("X-Amz-Date")
  valid_402657660 = validateParameter(valid_402657660, JString,
                                      required = false, default = nil)
  if valid_402657660 != nil:
    section.add "X-Amz-Date", valid_402657660
  var valid_402657661 = header.getOrDefault("X-Amz-Credential")
  valid_402657661 = validateParameter(valid_402657661, JString,
                                      required = false, default = nil)
  if valid_402657661 != nil:
    section.add "X-Amz-Credential", valid_402657661
  var valid_402657662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657664: Call_ListAutoMLJobs_402657650; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Request a list of jobs.
                                                                                         ## 
  let valid = call_402657664.validator(path, query, header, formData, body, _)
  let scheme = call_402657664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657664.makeUrl(scheme.get, call_402657664.host, call_402657664.base,
                                   call_402657664.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657664, uri, valid, _)

proc call*(call_402657665: Call_ListAutoMLJobs_402657650; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
                            ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657666 = newJObject()
  var body_402657667 = newJObject()
  add(query_402657666, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657667 = body
  add(query_402657666, "NextToken", newJString(NextToken))
  result = call_402657665.call(nil, query_402657666, nil, nil, body_402657667)

var listAutoMLJobs* = Call_ListAutoMLJobs_402657650(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_402657651, base: "/",
    makeUrl: url_ListAutoMLJobs_402657652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_402657668 = ref object of OpenApiRestCall_402656044
proc url_ListCandidatesForAutoMLJob_402657670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCandidatesForAutoMLJob_402657669(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657671 = query.getOrDefault("MaxResults")
  valid_402657671 = validateParameter(valid_402657671, JString,
                                      required = false, default = nil)
  if valid_402657671 != nil:
    section.add "MaxResults", valid_402657671
  var valid_402657672 = query.getOrDefault("NextToken")
  valid_402657672 = validateParameter(valid_402657672, JString,
                                      required = false, default = nil)
  if valid_402657672 != nil:
    section.add "NextToken", valid_402657672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657673 = header.getOrDefault("X-Amz-Target")
  valid_402657673 = validateParameter(valid_402657673, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_402657673 != nil:
    section.add "X-Amz-Target", valid_402657673
  var valid_402657674 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657674 = validateParameter(valid_402657674, JString,
                                      required = false, default = nil)
  if valid_402657674 != nil:
    section.add "X-Amz-Security-Token", valid_402657674
  var valid_402657675 = header.getOrDefault("X-Amz-Signature")
  valid_402657675 = validateParameter(valid_402657675, JString,
                                      required = false, default = nil)
  if valid_402657675 != nil:
    section.add "X-Amz-Signature", valid_402657675
  var valid_402657676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657676 = validateParameter(valid_402657676, JString,
                                      required = false, default = nil)
  if valid_402657676 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657676
  var valid_402657677 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657677 = validateParameter(valid_402657677, JString,
                                      required = false, default = nil)
  if valid_402657677 != nil:
    section.add "X-Amz-Algorithm", valid_402657677
  var valid_402657678 = header.getOrDefault("X-Amz-Date")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "X-Amz-Date", valid_402657678
  var valid_402657679 = header.getOrDefault("X-Amz-Credential")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Credential", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657682: Call_ListCandidatesForAutoMLJob_402657668;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the Candidates created for the job.
                                                                                         ## 
  let valid = call_402657682.validator(path, query, header, formData, body, _)
  let scheme = call_402657682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657682.makeUrl(scheme.get, call_402657682.host, call_402657682.base,
                                   call_402657682.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657682, uri, valid, _)

proc call*(call_402657683: Call_ListCandidatesForAutoMLJob_402657668;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
                                             ##             : Pagination limit
  ##   
                                                                              ## body: JObject (required)
  ##   
                                                                                                         ## NextToken: string
                                                                                                         ##            
                                                                                                         ## : 
                                                                                                         ## Pagination 
                                                                                                         ## token
  var query_402657684 = newJObject()
  var body_402657685 = newJObject()
  add(query_402657684, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657685 = body
  add(query_402657684, "NextToken", newJString(NextToken))
  result = call_402657683.call(nil, query_402657684, nil, nil, body_402657685)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_402657668(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_402657669, base: "/",
    makeUrl: url_ListCandidatesForAutoMLJob_402657670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_402657686 = ref object of OpenApiRestCall_402656044
proc url_ListCodeRepositories_402657688(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCodeRepositories_402657687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657689 = query.getOrDefault("MaxResults")
  valid_402657689 = validateParameter(valid_402657689, JString,
                                      required = false, default = nil)
  if valid_402657689 != nil:
    section.add "MaxResults", valid_402657689
  var valid_402657690 = query.getOrDefault("NextToken")
  valid_402657690 = validateParameter(valid_402657690, JString,
                                      required = false, default = nil)
  if valid_402657690 != nil:
    section.add "NextToken", valid_402657690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657691 = header.getOrDefault("X-Amz-Target")
  valid_402657691 = validateParameter(valid_402657691, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_402657691 != nil:
    section.add "X-Amz-Target", valid_402657691
  var valid_402657692 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657692 = validateParameter(valid_402657692, JString,
                                      required = false, default = nil)
  if valid_402657692 != nil:
    section.add "X-Amz-Security-Token", valid_402657692
  var valid_402657693 = header.getOrDefault("X-Amz-Signature")
  valid_402657693 = validateParameter(valid_402657693, JString,
                                      required = false, default = nil)
  if valid_402657693 != nil:
    section.add "X-Amz-Signature", valid_402657693
  var valid_402657694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Algorithm", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Date")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Date", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Credential")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Credential", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657700: Call_ListCodeRepositories_402657686;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the Git repositories in your account.
                                                                                         ## 
  let valid = call_402657700.validator(path, query, header, formData, body, _)
  let scheme = call_402657700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657700.makeUrl(scheme.get, call_402657700.host, call_402657700.base,
                                   call_402657700.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657700, uri, valid, _)

proc call*(call_402657701: Call_ListCodeRepositories_402657686; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
                                                         ##             : Pagination limit
  ##   
                                                                                          ## body: JObject (required)
  ##   
                                                                                                                     ## NextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  var query_402657702 = newJObject()
  var body_402657703 = newJObject()
  add(query_402657702, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657703 = body
  add(query_402657702, "NextToken", newJString(NextToken))
  result = call_402657701.call(nil, query_402657702, nil, nil, body_402657703)

var listCodeRepositories* = Call_ListCodeRepositories_402657686(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_402657687, base: "/",
    makeUrl: url_ListCodeRepositories_402657688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_402657704 = ref object of OpenApiRestCall_402656044
proc url_ListCompilationJobs_402657706(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompilationJobs_402657705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657707 = query.getOrDefault("MaxResults")
  valid_402657707 = validateParameter(valid_402657707, JString,
                                      required = false, default = nil)
  if valid_402657707 != nil:
    section.add "MaxResults", valid_402657707
  var valid_402657708 = query.getOrDefault("NextToken")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "NextToken", valid_402657708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657709 = header.getOrDefault("X-Amz-Target")
  valid_402657709 = validateParameter(valid_402657709, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_402657709 != nil:
    section.add "X-Amz-Target", valid_402657709
  var valid_402657710 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "X-Amz-Security-Token", valid_402657710
  var valid_402657711 = header.getOrDefault("X-Amz-Signature")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-Signature", valid_402657711
  var valid_402657712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657712
  var valid_402657713 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657713 = validateParameter(valid_402657713, JString,
                                      required = false, default = nil)
  if valid_402657713 != nil:
    section.add "X-Amz-Algorithm", valid_402657713
  var valid_402657714 = header.getOrDefault("X-Amz-Date")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "X-Amz-Date", valid_402657714
  var valid_402657715 = header.getOrDefault("X-Amz-Credential")
  valid_402657715 = validateParameter(valid_402657715, JString,
                                      required = false, default = nil)
  if valid_402657715 != nil:
    section.add "X-Amz-Credential", valid_402657715
  var valid_402657716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657716 = validateParameter(valid_402657716, JString,
                                      required = false, default = nil)
  if valid_402657716 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657718: Call_ListCompilationJobs_402657704;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
                                                                                         ## 
  let valid = call_402657718.validator(path, query, header, formData, body, _)
  let scheme = call_402657718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657718.makeUrl(scheme.get, call_402657718.host, call_402657718.base,
                                   call_402657718.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657718, uri, valid, _)

proc call*(call_402657719: Call_ListCompilationJobs_402657704; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   
                                                                                                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                     ## token
  var query_402657720 = newJObject()
  var body_402657721 = newJObject()
  add(query_402657720, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657721 = body
  add(query_402657720, "NextToken", newJString(NextToken))
  result = call_402657719.call(nil, query_402657720, nil, nil, body_402657721)

var listCompilationJobs* = Call_ListCompilationJobs_402657704(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_402657705, base: "/",
    makeUrl: url_ListCompilationJobs_402657706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_402657722 = ref object of OpenApiRestCall_402656044
proc url_ListDomains_402657724(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_402657723(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657725 = query.getOrDefault("MaxResults")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "MaxResults", valid_402657725
  var valid_402657726 = query.getOrDefault("NextToken")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "NextToken", valid_402657726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657727 = header.getOrDefault("X-Amz-Target")
  valid_402657727 = validateParameter(valid_402657727, JString, required = true, default = newJString(
      "SageMaker.ListDomains"))
  if valid_402657727 != nil:
    section.add "X-Amz-Target", valid_402657727
  var valid_402657728 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Security-Token", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-Signature")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-Signature", valid_402657729
  var valid_402657730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657730 = validateParameter(valid_402657730, JString,
                                      required = false, default = nil)
  if valid_402657730 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657730
  var valid_402657731 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657731 = validateParameter(valid_402657731, JString,
                                      required = false, default = nil)
  if valid_402657731 != nil:
    section.add "X-Amz-Algorithm", valid_402657731
  var valid_402657732 = header.getOrDefault("X-Amz-Date")
  valid_402657732 = validateParameter(valid_402657732, JString,
                                      required = false, default = nil)
  if valid_402657732 != nil:
    section.add "X-Amz-Date", valid_402657732
  var valid_402657733 = header.getOrDefault("X-Amz-Credential")
  valid_402657733 = validateParameter(valid_402657733, JString,
                                      required = false, default = nil)
  if valid_402657733 != nil:
    section.add "X-Amz-Credential", valid_402657733
  var valid_402657734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657734 = validateParameter(valid_402657734, JString,
                                      required = false, default = nil)
  if valid_402657734 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657736: Call_ListDomains_402657722; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the domains.
                                                                                         ## 
  let valid = call_402657736.validator(path, query, header, formData, body, _)
  let scheme = call_402657736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657736.makeUrl(scheme.get, call_402657736.host, call_402657736.base,
                                   call_402657736.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657736, uri, valid, _)

proc call*(call_402657737: Call_ListDomains_402657722; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
                       ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657738 = newJObject()
  var body_402657739 = newJObject()
  add(query_402657738, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657739 = body
  add(query_402657738, "NextToken", newJString(NextToken))
  result = call_402657737.call(nil, query_402657738, nil, nil, body_402657739)

var listDomains* = Call_ListDomains_402657722(name: "listDomains",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListDomains",
    validator: validate_ListDomains_402657723, base: "/",
    makeUrl: url_ListDomains_402657724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_402657740 = ref object of OpenApiRestCall_402656044
proc url_ListEndpointConfigs_402657742(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpointConfigs_402657741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657743 = query.getOrDefault("MaxResults")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "MaxResults", valid_402657743
  var valid_402657744 = query.getOrDefault("NextToken")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "NextToken", valid_402657744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657745 = header.getOrDefault("X-Amz-Target")
  valid_402657745 = validateParameter(valid_402657745, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_402657745 != nil:
    section.add "X-Amz-Target", valid_402657745
  var valid_402657746 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "X-Amz-Security-Token", valid_402657746
  var valid_402657747 = header.getOrDefault("X-Amz-Signature")
  valid_402657747 = validateParameter(valid_402657747, JString,
                                      required = false, default = nil)
  if valid_402657747 != nil:
    section.add "X-Amz-Signature", valid_402657747
  var valid_402657748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657748 = validateParameter(valid_402657748, JString,
                                      required = false, default = nil)
  if valid_402657748 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657748
  var valid_402657749 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657749 = validateParameter(valid_402657749, JString,
                                      required = false, default = nil)
  if valid_402657749 != nil:
    section.add "X-Amz-Algorithm", valid_402657749
  var valid_402657750 = header.getOrDefault("X-Amz-Date")
  valid_402657750 = validateParameter(valid_402657750, JString,
                                      required = false, default = nil)
  if valid_402657750 != nil:
    section.add "X-Amz-Date", valid_402657750
  var valid_402657751 = header.getOrDefault("X-Amz-Credential")
  valid_402657751 = validateParameter(valid_402657751, JString,
                                      required = false, default = nil)
  if valid_402657751 != nil:
    section.add "X-Amz-Credential", valid_402657751
  var valid_402657752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657752 = validateParameter(valid_402657752, JString,
                                      required = false, default = nil)
  if valid_402657752 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657754: Call_ListEndpointConfigs_402657740;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists endpoint configurations.
                                                                                         ## 
  let valid = call_402657754.validator(path, query, header, formData, body, _)
  let scheme = call_402657754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657754.makeUrl(scheme.get, call_402657754.host, call_402657754.base,
                                   call_402657754.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657754, uri, valid, _)

proc call*(call_402657755: Call_ListEndpointConfigs_402657740; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
                                   ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657756 = newJObject()
  var body_402657757 = newJObject()
  add(query_402657756, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657757 = body
  add(query_402657756, "NextToken", newJString(NextToken))
  result = call_402657755.call(nil, query_402657756, nil, nil, body_402657757)

var listEndpointConfigs* = Call_ListEndpointConfigs_402657740(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_402657741, base: "/",
    makeUrl: url_ListEndpointConfigs_402657742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_402657758 = ref object of OpenApiRestCall_402656044
proc url_ListEndpoints_402657760(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_402657759(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657761 = query.getOrDefault("MaxResults")
  valid_402657761 = validateParameter(valid_402657761, JString,
                                      required = false, default = nil)
  if valid_402657761 != nil:
    section.add "MaxResults", valid_402657761
  var valid_402657762 = query.getOrDefault("NextToken")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "NextToken", valid_402657762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657763 = header.getOrDefault("X-Amz-Target")
  valid_402657763 = validateParameter(valid_402657763, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_402657763 != nil:
    section.add "X-Amz-Target", valid_402657763
  var valid_402657764 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657764 = validateParameter(valid_402657764, JString,
                                      required = false, default = nil)
  if valid_402657764 != nil:
    section.add "X-Amz-Security-Token", valid_402657764
  var valid_402657765 = header.getOrDefault("X-Amz-Signature")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "X-Amz-Signature", valid_402657765
  var valid_402657766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Algorithm", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-Date")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-Date", valid_402657768
  var valid_402657769 = header.getOrDefault("X-Amz-Credential")
  valid_402657769 = validateParameter(valid_402657769, JString,
                                      required = false, default = nil)
  if valid_402657769 != nil:
    section.add "X-Amz-Credential", valid_402657769
  var valid_402657770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657770 = validateParameter(valid_402657770, JString,
                                      required = false, default = nil)
  if valid_402657770 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657772: Call_ListEndpoints_402657758; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists endpoints.
                                                                                         ## 
  let valid = call_402657772.validator(path, query, header, formData, body, _)
  let scheme = call_402657772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657772.makeUrl(scheme.get, call_402657772.host, call_402657772.base,
                                   call_402657772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657772, uri, valid, _)

proc call*(call_402657773: Call_ListEndpoints_402657758; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
                     ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657774 = newJObject()
  var body_402657775 = newJObject()
  add(query_402657774, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657775 = body
  add(query_402657774, "NextToken", newJString(NextToken))
  result = call_402657773.call(nil, query_402657774, nil, nil, body_402657775)

var listEndpoints* = Call_ListEndpoints_402657758(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_402657759, base: "/",
    makeUrl: url_ListEndpoints_402657760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_402657776 = ref object of OpenApiRestCall_402656044
proc url_ListExperiments_402657778(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExperiments_402657777(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657779 = query.getOrDefault("MaxResults")
  valid_402657779 = validateParameter(valid_402657779, JString,
                                      required = false, default = nil)
  if valid_402657779 != nil:
    section.add "MaxResults", valid_402657779
  var valid_402657780 = query.getOrDefault("NextToken")
  valid_402657780 = validateParameter(valid_402657780, JString,
                                      required = false, default = nil)
  if valid_402657780 != nil:
    section.add "NextToken", valid_402657780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657781 = header.getOrDefault("X-Amz-Target")
  valid_402657781 = validateParameter(valid_402657781, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_402657781 != nil:
    section.add "X-Amz-Target", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Security-Token", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-Signature")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-Signature", valid_402657783
  var valid_402657784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657784
  var valid_402657785 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "X-Amz-Algorithm", valid_402657785
  var valid_402657786 = header.getOrDefault("X-Amz-Date")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "X-Amz-Date", valid_402657786
  var valid_402657787 = header.getOrDefault("X-Amz-Credential")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "X-Amz-Credential", valid_402657787
  var valid_402657788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657790: Call_ListExperiments_402657776; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
                                                                                         ## 
  let valid = call_402657790.validator(path, query, header, formData, body, _)
  let scheme = call_402657790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657790.makeUrl(scheme.get, call_402657790.host, call_402657790.base,
                                   call_402657790.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657790, uri, valid, _)

proc call*(call_402657791: Call_ListExperiments_402657776; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   
                                                                                                                                                                                                         ## MaxResults: string
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                            ## token
  var query_402657792 = newJObject()
  var body_402657793 = newJObject()
  add(query_402657792, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657793 = body
  add(query_402657792, "NextToken", newJString(NextToken))
  result = call_402657791.call(nil, query_402657792, nil, nil, body_402657793)

var listExperiments* = Call_ListExperiments_402657776(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_402657777, base: "/",
    makeUrl: url_ListExperiments_402657778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_402657794 = ref object of OpenApiRestCall_402656044
proc url_ListFlowDefinitions_402657796(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowDefinitions_402657795(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657797 = query.getOrDefault("MaxResults")
  valid_402657797 = validateParameter(valid_402657797, JString,
                                      required = false, default = nil)
  if valid_402657797 != nil:
    section.add "MaxResults", valid_402657797
  var valid_402657798 = query.getOrDefault("NextToken")
  valid_402657798 = validateParameter(valid_402657798, JString,
                                      required = false, default = nil)
  if valid_402657798 != nil:
    section.add "NextToken", valid_402657798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657799 = header.getOrDefault("X-Amz-Target")
  valid_402657799 = validateParameter(valid_402657799, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_402657799 != nil:
    section.add "X-Amz-Target", valid_402657799
  var valid_402657800 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657800 = validateParameter(valid_402657800, JString,
                                      required = false, default = nil)
  if valid_402657800 != nil:
    section.add "X-Amz-Security-Token", valid_402657800
  var valid_402657801 = header.getOrDefault("X-Amz-Signature")
  valid_402657801 = validateParameter(valid_402657801, JString,
                                      required = false, default = nil)
  if valid_402657801 != nil:
    section.add "X-Amz-Signature", valid_402657801
  var valid_402657802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657802 = validateParameter(valid_402657802, JString,
                                      required = false, default = nil)
  if valid_402657802 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657802
  var valid_402657803 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657803 = validateParameter(valid_402657803, JString,
                                      required = false, default = nil)
  if valid_402657803 != nil:
    section.add "X-Amz-Algorithm", valid_402657803
  var valid_402657804 = header.getOrDefault("X-Amz-Date")
  valid_402657804 = validateParameter(valid_402657804, JString,
                                      required = false, default = nil)
  if valid_402657804 != nil:
    section.add "X-Amz-Date", valid_402657804
  var valid_402657805 = header.getOrDefault("X-Amz-Credential")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "X-Amz-Credential", valid_402657805
  var valid_402657806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657806 = validateParameter(valid_402657806, JString,
                                      required = false, default = nil)
  if valid_402657806 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657808: Call_ListFlowDefinitions_402657794;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the flow definitions in your account.
                                                                                         ## 
  let valid = call_402657808.validator(path, query, header, formData, body, _)
  let scheme = call_402657808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657808.makeUrl(scheme.get, call_402657808.host, call_402657808.base,
                                   call_402657808.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657808, uri, valid, _)

proc call*(call_402657809: Call_ListFlowDefinitions_402657794; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
                                                                    ##             : Pagination limit
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  var query_402657810 = newJObject()
  var body_402657811 = newJObject()
  add(query_402657810, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657811 = body
  add(query_402657810, "NextToken", newJString(NextToken))
  result = call_402657809.call(nil, query_402657810, nil, nil, body_402657811)

var listFlowDefinitions* = Call_ListFlowDefinitions_402657794(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_402657795, base: "/",
    makeUrl: url_ListFlowDefinitions_402657796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_402657812 = ref object of OpenApiRestCall_402656044
proc url_ListHumanTaskUis_402657814(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanTaskUis_402657813(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657815 = query.getOrDefault("MaxResults")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "MaxResults", valid_402657815
  var valid_402657816 = query.getOrDefault("NextToken")
  valid_402657816 = validateParameter(valid_402657816, JString,
                                      required = false, default = nil)
  if valid_402657816 != nil:
    section.add "NextToken", valid_402657816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657817 = header.getOrDefault("X-Amz-Target")
  valid_402657817 = validateParameter(valid_402657817, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_402657817 != nil:
    section.add "X-Amz-Target", valid_402657817
  var valid_402657818 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657818 = validateParameter(valid_402657818, JString,
                                      required = false, default = nil)
  if valid_402657818 != nil:
    section.add "X-Amz-Security-Token", valid_402657818
  var valid_402657819 = header.getOrDefault("X-Amz-Signature")
  valid_402657819 = validateParameter(valid_402657819, JString,
                                      required = false, default = nil)
  if valid_402657819 != nil:
    section.add "X-Amz-Signature", valid_402657819
  var valid_402657820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657820 = validateParameter(valid_402657820, JString,
                                      required = false, default = nil)
  if valid_402657820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657820
  var valid_402657821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657821 = validateParameter(valid_402657821, JString,
                                      required = false, default = nil)
  if valid_402657821 != nil:
    section.add "X-Amz-Algorithm", valid_402657821
  var valid_402657822 = header.getOrDefault("X-Amz-Date")
  valid_402657822 = validateParameter(valid_402657822, JString,
                                      required = false, default = nil)
  if valid_402657822 != nil:
    section.add "X-Amz-Date", valid_402657822
  var valid_402657823 = header.getOrDefault("X-Amz-Credential")
  valid_402657823 = validateParameter(valid_402657823, JString,
                                      required = false, default = nil)
  if valid_402657823 != nil:
    section.add "X-Amz-Credential", valid_402657823
  var valid_402657824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657824 = validateParameter(valid_402657824, JString,
                                      required = false, default = nil)
  if valid_402657824 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657826: Call_ListHumanTaskUis_402657812;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the human task user interfaces in your account.
                                                                                         ## 
  let valid = call_402657826.validator(path, query, header, formData, body, _)
  let scheme = call_402657826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657826.makeUrl(scheme.get, call_402657826.host, call_402657826.base,
                                   call_402657826.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657826, uri, valid, _)

proc call*(call_402657827: Call_ListHumanTaskUis_402657812; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   
                                                                              ## MaxResults: string
                                                                              ##             
                                                                              ## : 
                                                                              ## Pagination 
                                                                              ## limit
  ##   
                                                                                      ## body: JObject (required)
  ##   
                                                                                                                 ## NextToken: string
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## token
  var query_402657828 = newJObject()
  var body_402657829 = newJObject()
  add(query_402657828, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657829 = body
  add(query_402657828, "NextToken", newJString(NextToken))
  result = call_402657827.call(nil, query_402657828, nil, nil, body_402657829)

var listHumanTaskUis* = Call_ListHumanTaskUis_402657812(
    name: "listHumanTaskUis", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_402657813, base: "/",
    makeUrl: url_ListHumanTaskUis_402657814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_402657830 = ref object of OpenApiRestCall_402656044
proc url_ListHyperParameterTuningJobs_402657832(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHyperParameterTuningJobs_402657831(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657833 = query.getOrDefault("MaxResults")
  valid_402657833 = validateParameter(valid_402657833, JString,
                                      required = false, default = nil)
  if valid_402657833 != nil:
    section.add "MaxResults", valid_402657833
  var valid_402657834 = query.getOrDefault("NextToken")
  valid_402657834 = validateParameter(valid_402657834, JString,
                                      required = false, default = nil)
  if valid_402657834 != nil:
    section.add "NextToken", valid_402657834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657835 = header.getOrDefault("X-Amz-Target")
  valid_402657835 = validateParameter(valid_402657835, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_402657835 != nil:
    section.add "X-Amz-Target", valid_402657835
  var valid_402657836 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657836 = validateParameter(valid_402657836, JString,
                                      required = false, default = nil)
  if valid_402657836 != nil:
    section.add "X-Amz-Security-Token", valid_402657836
  var valid_402657837 = header.getOrDefault("X-Amz-Signature")
  valid_402657837 = validateParameter(valid_402657837, JString,
                                      required = false, default = nil)
  if valid_402657837 != nil:
    section.add "X-Amz-Signature", valid_402657837
  var valid_402657838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657838 = validateParameter(valid_402657838, JString,
                                      required = false, default = nil)
  if valid_402657838 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657838
  var valid_402657839 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657839 = validateParameter(valid_402657839, JString,
                                      required = false, default = nil)
  if valid_402657839 != nil:
    section.add "X-Amz-Algorithm", valid_402657839
  var valid_402657840 = header.getOrDefault("X-Amz-Date")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "X-Amz-Date", valid_402657840
  var valid_402657841 = header.getOrDefault("X-Amz-Credential")
  valid_402657841 = validateParameter(valid_402657841, JString,
                                      required = false, default = nil)
  if valid_402657841 != nil:
    section.add "X-Amz-Credential", valid_402657841
  var valid_402657842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657842 = validateParameter(valid_402657842, JString,
                                      required = false, default = nil)
  if valid_402657842 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657844: Call_ListHyperParameterTuningJobs_402657830;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
                                                                                         ## 
  let valid = call_402657844.validator(path, query, header, formData, body, _)
  let scheme = call_402657844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657844.makeUrl(scheme.get, call_402657844.host, call_402657844.base,
                                   call_402657844.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657844, uri, valid, _)

proc call*(call_402657845: Call_ListHyperParameterTuningJobs_402657830;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   
                                                                                                                                        ## MaxResults: string
                                                                                                                                        ##             
                                                                                                                                        ## : 
                                                                                                                                        ## Pagination 
                                                                                                                                        ## limit
  ##   
                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                           ##            
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## Pagination 
                                                                                                                                                                           ## token
  var query_402657846 = newJObject()
  var body_402657847 = newJObject()
  add(query_402657846, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657847 = body
  add(query_402657846, "NextToken", newJString(NextToken))
  result = call_402657845.call(nil, query_402657846, nil, nil, body_402657847)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_402657830(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_402657831, base: "/",
    makeUrl: url_ListHyperParameterTuningJobs_402657832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_402657848 = ref object of OpenApiRestCall_402656044
proc url_ListLabelingJobs_402657850(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobs_402657849(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657851 = query.getOrDefault("MaxResults")
  valid_402657851 = validateParameter(valid_402657851, JString,
                                      required = false, default = nil)
  if valid_402657851 != nil:
    section.add "MaxResults", valid_402657851
  var valid_402657852 = query.getOrDefault("NextToken")
  valid_402657852 = validateParameter(valid_402657852, JString,
                                      required = false, default = nil)
  if valid_402657852 != nil:
    section.add "NextToken", valid_402657852
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657853 = header.getOrDefault("X-Amz-Target")
  valid_402657853 = validateParameter(valid_402657853, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_402657853 != nil:
    section.add "X-Amz-Target", valid_402657853
  var valid_402657854 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657854 = validateParameter(valid_402657854, JString,
                                      required = false, default = nil)
  if valid_402657854 != nil:
    section.add "X-Amz-Security-Token", valid_402657854
  var valid_402657855 = header.getOrDefault("X-Amz-Signature")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "X-Amz-Signature", valid_402657855
  var valid_402657856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657856
  var valid_402657857 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Algorithm", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Date")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Date", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Credential")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Credential", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657862: Call_ListLabelingJobs_402657848;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of labeling jobs.
                                                                                         ## 
  let valid = call_402657862.validator(path, query, header, formData, body, _)
  let scheme = call_402657862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657862.makeUrl(scheme.get, call_402657862.host, call_402657862.base,
                                   call_402657862.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657862, uri, valid, _)

proc call*(call_402657863: Call_ListLabelingJobs_402657848; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
                                  ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402657864 = newJObject()
  var body_402657865 = newJObject()
  add(query_402657864, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657865 = body
  add(query_402657864, "NextToken", newJString(NextToken))
  result = call_402657863.call(nil, query_402657864, nil, nil, body_402657865)

var listLabelingJobs* = Call_ListLabelingJobs_402657848(
    name: "listLabelingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_402657849, base: "/",
    makeUrl: url_ListLabelingJobs_402657850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_402657866 = ref object of OpenApiRestCall_402656044
proc url_ListLabelingJobsForWorkteam_402657868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobsForWorkteam_402657867(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657869 = query.getOrDefault("MaxResults")
  valid_402657869 = validateParameter(valid_402657869, JString,
                                      required = false, default = nil)
  if valid_402657869 != nil:
    section.add "MaxResults", valid_402657869
  var valid_402657870 = query.getOrDefault("NextToken")
  valid_402657870 = validateParameter(valid_402657870, JString,
                                      required = false, default = nil)
  if valid_402657870 != nil:
    section.add "NextToken", valid_402657870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657871 = header.getOrDefault("X-Amz-Target")
  valid_402657871 = validateParameter(valid_402657871, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_402657871 != nil:
    section.add "X-Amz-Target", valid_402657871
  var valid_402657872 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "X-Amz-Security-Token", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-Signature")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-Signature", valid_402657873
  var valid_402657874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Algorithm", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-Date")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-Date", valid_402657876
  var valid_402657877 = header.getOrDefault("X-Amz-Credential")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "X-Amz-Credential", valid_402657877
  var valid_402657878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657878 = validateParameter(valid_402657878, JString,
                                      required = false, default = nil)
  if valid_402657878 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657880: Call_ListLabelingJobsForWorkteam_402657866;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
                                                                                         ## 
  let valid = call_402657880.validator(path, query, header, formData, body, _)
  let scheme = call_402657880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657880.makeUrl(scheme.get, call_402657880.host, call_402657880.base,
                                   call_402657880.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657880, uri, valid, _)

proc call*(call_402657881: Call_ListLabelingJobsForWorkteam_402657866;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
                                                                    ##             : Pagination limit
  ##   
                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                ## NextToken: string
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  var query_402657882 = newJObject()
  var body_402657883 = newJObject()
  add(query_402657882, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657883 = body
  add(query_402657882, "NextToken", newJString(NextToken))
  result = call_402657881.call(nil, query_402657882, nil, nil, body_402657883)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_402657866(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_402657867, base: "/",
    makeUrl: url_ListLabelingJobsForWorkteam_402657868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_402657884 = ref object of OpenApiRestCall_402656044
proc url_ListModelPackages_402657886(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModelPackages_402657885(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657887 = query.getOrDefault("MaxResults")
  valid_402657887 = validateParameter(valid_402657887, JString,
                                      required = false, default = nil)
  if valid_402657887 != nil:
    section.add "MaxResults", valid_402657887
  var valid_402657888 = query.getOrDefault("NextToken")
  valid_402657888 = validateParameter(valid_402657888, JString,
                                      required = false, default = nil)
  if valid_402657888 != nil:
    section.add "NextToken", valid_402657888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657889 = header.getOrDefault("X-Amz-Target")
  valid_402657889 = validateParameter(valid_402657889, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_402657889 != nil:
    section.add "X-Amz-Target", valid_402657889
  var valid_402657890 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657890 = validateParameter(valid_402657890, JString,
                                      required = false, default = nil)
  if valid_402657890 != nil:
    section.add "X-Amz-Security-Token", valid_402657890
  var valid_402657891 = header.getOrDefault("X-Amz-Signature")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "X-Amz-Signature", valid_402657891
  var valid_402657892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657892 = validateParameter(valid_402657892, JString,
                                      required = false, default = nil)
  if valid_402657892 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657892
  var valid_402657893 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657893 = validateParameter(valid_402657893, JString,
                                      required = false, default = nil)
  if valid_402657893 != nil:
    section.add "X-Amz-Algorithm", valid_402657893
  var valid_402657894 = header.getOrDefault("X-Amz-Date")
  valid_402657894 = validateParameter(valid_402657894, JString,
                                      required = false, default = nil)
  if valid_402657894 != nil:
    section.add "X-Amz-Date", valid_402657894
  var valid_402657895 = header.getOrDefault("X-Amz-Credential")
  valid_402657895 = validateParameter(valid_402657895, JString,
                                      required = false, default = nil)
  if valid_402657895 != nil:
    section.add "X-Amz-Credential", valid_402657895
  var valid_402657896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657896 = validateParameter(valid_402657896, JString,
                                      required = false, default = nil)
  if valid_402657896 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657898: Call_ListModelPackages_402657884;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the model packages that have been created.
                                                                                         ## 
  let valid = call_402657898.validator(path, query, header, formData, body, _)
  let scheme = call_402657898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657898.makeUrl(scheme.get, call_402657898.host, call_402657898.base,
                                   call_402657898.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657898, uri, valid, _)

proc call*(call_402657899: Call_ListModelPackages_402657884; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
                                                     ##             : Pagination limit
  ##   
                                                                                      ## body: JObject (required)
  ##   
                                                                                                                 ## NextToken: string
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Pagination 
                                                                                                                 ## token
  var query_402657900 = newJObject()
  var body_402657901 = newJObject()
  add(query_402657900, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657901 = body
  add(query_402657900, "NextToken", newJString(NextToken))
  result = call_402657899.call(nil, query_402657900, nil, nil, body_402657901)

var listModelPackages* = Call_ListModelPackages_402657884(
    name: "listModelPackages", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_402657885, base: "/",
    makeUrl: url_ListModelPackages_402657886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_402657902 = ref object of OpenApiRestCall_402656044
proc url_ListModels_402657904(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModels_402657903(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657905 = query.getOrDefault("MaxResults")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "MaxResults", valid_402657905
  var valid_402657906 = query.getOrDefault("NextToken")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "NextToken", valid_402657906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657907 = header.getOrDefault("X-Amz-Target")
  valid_402657907 = validateParameter(valid_402657907, JString, required = true, default = newJString(
      "SageMaker.ListModels"))
  if valid_402657907 != nil:
    section.add "X-Amz-Target", valid_402657907
  var valid_402657908 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657908 = validateParameter(valid_402657908, JString,
                                      required = false, default = nil)
  if valid_402657908 != nil:
    section.add "X-Amz-Security-Token", valid_402657908
  var valid_402657909 = header.getOrDefault("X-Amz-Signature")
  valid_402657909 = validateParameter(valid_402657909, JString,
                                      required = false, default = nil)
  if valid_402657909 != nil:
    section.add "X-Amz-Signature", valid_402657909
  var valid_402657910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657910 = validateParameter(valid_402657910, JString,
                                      required = false, default = nil)
  if valid_402657910 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657910
  var valid_402657911 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657911 = validateParameter(valid_402657911, JString,
                                      required = false, default = nil)
  if valid_402657911 != nil:
    section.add "X-Amz-Algorithm", valid_402657911
  var valid_402657912 = header.getOrDefault("X-Amz-Date")
  valid_402657912 = validateParameter(valid_402657912, JString,
                                      required = false, default = nil)
  if valid_402657912 != nil:
    section.add "X-Amz-Date", valid_402657912
  var valid_402657913 = header.getOrDefault("X-Amz-Credential")
  valid_402657913 = validateParameter(valid_402657913, JString,
                                      required = false, default = nil)
  if valid_402657913 != nil:
    section.add "X-Amz-Credential", valid_402657913
  var valid_402657914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657914 = validateParameter(valid_402657914, JString,
                                      required = false, default = nil)
  if valid_402657914 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657916: Call_ListModels_402657902; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
                                                                                         ## 
  let valid = call_402657916.validator(path, query, header, formData, body, _)
  let scheme = call_402657916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657916.makeUrl(scheme.get, call_402657916.host, call_402657916.base,
                                   call_402657916.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657916, uri, valid, _)

proc call*(call_402657917: Call_ListModels_402657902; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   
                                                                                                                                      ## MaxResults: string
                                                                                                                                      ##             
                                                                                                                                      ## : 
                                                                                                                                      ## Pagination 
                                                                                                                                      ## limit
  ##   
                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                         ##            
                                                                                                                                                                         ## : 
                                                                                                                                                                         ## Pagination 
                                                                                                                                                                         ## token
  var query_402657918 = newJObject()
  var body_402657919 = newJObject()
  add(query_402657918, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657919 = body
  add(query_402657918, "NextToken", newJString(NextToken))
  result = call_402657917.call(nil, query_402657918, nil, nil, body_402657919)

var listModels* = Call_ListModels_402657902(name: "listModels",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModels",
    validator: validate_ListModels_402657903, base: "/",
    makeUrl: url_ListModels_402657904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_402657920 = ref object of OpenApiRestCall_402656044
proc url_ListMonitoringExecutions_402657922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringExecutions_402657921(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657923 = query.getOrDefault("MaxResults")
  valid_402657923 = validateParameter(valid_402657923, JString,
                                      required = false, default = nil)
  if valid_402657923 != nil:
    section.add "MaxResults", valid_402657923
  var valid_402657924 = query.getOrDefault("NextToken")
  valid_402657924 = validateParameter(valid_402657924, JString,
                                      required = false, default = nil)
  if valid_402657924 != nil:
    section.add "NextToken", valid_402657924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657925 = header.getOrDefault("X-Amz-Target")
  valid_402657925 = validateParameter(valid_402657925, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_402657925 != nil:
    section.add "X-Amz-Target", valid_402657925
  var valid_402657926 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657926 = validateParameter(valid_402657926, JString,
                                      required = false, default = nil)
  if valid_402657926 != nil:
    section.add "X-Amz-Security-Token", valid_402657926
  var valid_402657927 = header.getOrDefault("X-Amz-Signature")
  valid_402657927 = validateParameter(valid_402657927, JString,
                                      required = false, default = nil)
  if valid_402657927 != nil:
    section.add "X-Amz-Signature", valid_402657927
  var valid_402657928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657928 = validateParameter(valid_402657928, JString,
                                      required = false, default = nil)
  if valid_402657928 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657928
  var valid_402657929 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657929 = validateParameter(valid_402657929, JString,
                                      required = false, default = nil)
  if valid_402657929 != nil:
    section.add "X-Amz-Algorithm", valid_402657929
  var valid_402657930 = header.getOrDefault("X-Amz-Date")
  valid_402657930 = validateParameter(valid_402657930, JString,
                                      required = false, default = nil)
  if valid_402657930 != nil:
    section.add "X-Amz-Date", valid_402657930
  var valid_402657931 = header.getOrDefault("X-Amz-Credential")
  valid_402657931 = validateParameter(valid_402657931, JString,
                                      required = false, default = nil)
  if valid_402657931 != nil:
    section.add "X-Amz-Credential", valid_402657931
  var valid_402657932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657932 = validateParameter(valid_402657932, JString,
                                      required = false, default = nil)
  if valid_402657932 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657934: Call_ListMonitoringExecutions_402657920;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns list of all monitoring job executions.
                                                                                         ## 
  let valid = call_402657934.validator(path, query, header, formData, body, _)
  let scheme = call_402657934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657934.makeUrl(scheme.get, call_402657934.host, call_402657934.base,
                                   call_402657934.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657934, uri, valid, _)

proc call*(call_402657935: Call_ListMonitoringExecutions_402657920;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
                                                   ##             : Pagination limit
  ##   
                                                                                    ## body: JObject (required)
  ##   
                                                                                                               ## NextToken: string
                                                                                                               ##            
                                                                                                               ## : 
                                                                                                               ## Pagination 
                                                                                                               ## token
  var query_402657936 = newJObject()
  var body_402657937 = newJObject()
  add(query_402657936, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657937 = body
  add(query_402657936, "NextToken", newJString(NextToken))
  result = call_402657935.call(nil, query_402657936, nil, nil, body_402657937)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_402657920(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_402657921, base: "/",
    makeUrl: url_ListMonitoringExecutions_402657922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_402657938 = ref object of OpenApiRestCall_402656044
proc url_ListMonitoringSchedules_402657940(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringSchedules_402657939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657941 = query.getOrDefault("MaxResults")
  valid_402657941 = validateParameter(valid_402657941, JString,
                                      required = false, default = nil)
  if valid_402657941 != nil:
    section.add "MaxResults", valid_402657941
  var valid_402657942 = query.getOrDefault("NextToken")
  valid_402657942 = validateParameter(valid_402657942, JString,
                                      required = false, default = nil)
  if valid_402657942 != nil:
    section.add "NextToken", valid_402657942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657943 = header.getOrDefault("X-Amz-Target")
  valid_402657943 = validateParameter(valid_402657943, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_402657943 != nil:
    section.add "X-Amz-Target", valid_402657943
  var valid_402657944 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657944 = validateParameter(valid_402657944, JString,
                                      required = false, default = nil)
  if valid_402657944 != nil:
    section.add "X-Amz-Security-Token", valid_402657944
  var valid_402657945 = header.getOrDefault("X-Amz-Signature")
  valid_402657945 = validateParameter(valid_402657945, JString,
                                      required = false, default = nil)
  if valid_402657945 != nil:
    section.add "X-Amz-Signature", valid_402657945
  var valid_402657946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657946 = validateParameter(valid_402657946, JString,
                                      required = false, default = nil)
  if valid_402657946 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657946
  var valid_402657947 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657947 = validateParameter(valid_402657947, JString,
                                      required = false, default = nil)
  if valid_402657947 != nil:
    section.add "X-Amz-Algorithm", valid_402657947
  var valid_402657948 = header.getOrDefault("X-Amz-Date")
  valid_402657948 = validateParameter(valid_402657948, JString,
                                      required = false, default = nil)
  if valid_402657948 != nil:
    section.add "X-Amz-Date", valid_402657948
  var valid_402657949 = header.getOrDefault("X-Amz-Credential")
  valid_402657949 = validateParameter(valid_402657949, JString,
                                      required = false, default = nil)
  if valid_402657949 != nil:
    section.add "X-Amz-Credential", valid_402657949
  var valid_402657950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657952: Call_ListMonitoringSchedules_402657938;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns list of all monitoring schedules.
                                                                                         ## 
  let valid = call_402657952.validator(path, query, header, formData, body, _)
  let scheme = call_402657952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657952.makeUrl(scheme.get, call_402657952.host, call_402657952.base,
                                   call_402657952.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657952, uri, valid, _)

proc call*(call_402657953: Call_ListMonitoringSchedules_402657938;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
                                              ##             : Pagination limit
  ##   
                                                                               ## body: JObject (required)
  ##   
                                                                                                          ## NextToken: string
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## Pagination 
                                                                                                          ## token
  var query_402657954 = newJObject()
  var body_402657955 = newJObject()
  add(query_402657954, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657955 = body
  add(query_402657954, "NextToken", newJString(NextToken))
  result = call_402657953.call(nil, query_402657954, nil, nil, body_402657955)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_402657938(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_402657939, base: "/",
    makeUrl: url_ListMonitoringSchedules_402657940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_402657956 = ref object of OpenApiRestCall_402656044
proc url_ListNotebookInstanceLifecycleConfigs_402657958(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_402657957(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402657959 = query.getOrDefault("MaxResults")
  valid_402657959 = validateParameter(valid_402657959, JString,
                                      required = false, default = nil)
  if valid_402657959 != nil:
    section.add "MaxResults", valid_402657959
  var valid_402657960 = query.getOrDefault("NextToken")
  valid_402657960 = validateParameter(valid_402657960, JString,
                                      required = false, default = nil)
  if valid_402657960 != nil:
    section.add "NextToken", valid_402657960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657961 = header.getOrDefault("X-Amz-Target")
  valid_402657961 = validateParameter(valid_402657961, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_402657961 != nil:
    section.add "X-Amz-Target", valid_402657961
  var valid_402657962 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657962 = validateParameter(valid_402657962, JString,
                                      required = false, default = nil)
  if valid_402657962 != nil:
    section.add "X-Amz-Security-Token", valid_402657962
  var valid_402657963 = header.getOrDefault("X-Amz-Signature")
  valid_402657963 = validateParameter(valid_402657963, JString,
                                      required = false, default = nil)
  if valid_402657963 != nil:
    section.add "X-Amz-Signature", valid_402657963
  var valid_402657964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657964 = validateParameter(valid_402657964, JString,
                                      required = false, default = nil)
  if valid_402657964 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657964
  var valid_402657965 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657965 = validateParameter(valid_402657965, JString,
                                      required = false, default = nil)
  if valid_402657965 != nil:
    section.add "X-Amz-Algorithm", valid_402657965
  var valid_402657966 = header.getOrDefault("X-Amz-Date")
  valid_402657966 = validateParameter(valid_402657966, JString,
                                      required = false, default = nil)
  if valid_402657966 != nil:
    section.add "X-Amz-Date", valid_402657966
  var valid_402657967 = header.getOrDefault("X-Amz-Credential")
  valid_402657967 = validateParameter(valid_402657967, JString,
                                      required = false, default = nil)
  if valid_402657967 != nil:
    section.add "X-Amz-Credential", valid_402657967
  var valid_402657968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657968 = validateParameter(valid_402657968, JString,
                                      required = false, default = nil)
  if valid_402657968 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657970: Call_ListNotebookInstanceLifecycleConfigs_402657956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
                                                                                         ## 
  let valid = call_402657970.validator(path, query, header, formData, body, _)
  let scheme = call_402657970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657970.makeUrl(scheme.get, call_402657970.host, call_402657970.base,
                                   call_402657970.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657970, uri, valid, _)

proc call*(call_402657971: Call_ListNotebookInstanceLifecycleConfigs_402657956;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   
                                                                                                                        ## MaxResults: string
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  ##   
                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                           ## NextToken: string
                                                                                                                                                           ##            
                                                                                                                                                           ## : 
                                                                                                                                                           ## Pagination 
                                                                                                                                                           ## token
  var query_402657972 = newJObject()
  var body_402657973 = newJObject()
  add(query_402657972, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657973 = body
  add(query_402657972, "NextToken", newJString(NextToken))
  result = call_402657971.call(nil, query_402657972, nil, nil, body_402657973)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_402657956(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_402657957,
    base: "/", makeUrl: url_ListNotebookInstanceLifecycleConfigs_402657958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_402657974 = ref object of OpenApiRestCall_402656044
proc url_ListNotebookInstances_402657976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstances_402657975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657977 = query.getOrDefault("MaxResults")
  valid_402657977 = validateParameter(valid_402657977, JString,
                                      required = false, default = nil)
  if valid_402657977 != nil:
    section.add "MaxResults", valid_402657977
  var valid_402657978 = query.getOrDefault("NextToken")
  valid_402657978 = validateParameter(valid_402657978, JString,
                                      required = false, default = nil)
  if valid_402657978 != nil:
    section.add "NextToken", valid_402657978
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657979 = header.getOrDefault("X-Amz-Target")
  valid_402657979 = validateParameter(valid_402657979, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_402657979 != nil:
    section.add "X-Amz-Target", valid_402657979
  var valid_402657980 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657980 = validateParameter(valid_402657980, JString,
                                      required = false, default = nil)
  if valid_402657980 != nil:
    section.add "X-Amz-Security-Token", valid_402657980
  var valid_402657981 = header.getOrDefault("X-Amz-Signature")
  valid_402657981 = validateParameter(valid_402657981, JString,
                                      required = false, default = nil)
  if valid_402657981 != nil:
    section.add "X-Amz-Signature", valid_402657981
  var valid_402657982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657982 = validateParameter(valid_402657982, JString,
                                      required = false, default = nil)
  if valid_402657982 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657982
  var valid_402657983 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657983 = validateParameter(valid_402657983, JString,
                                      required = false, default = nil)
  if valid_402657983 != nil:
    section.add "X-Amz-Algorithm", valid_402657983
  var valid_402657984 = header.getOrDefault("X-Amz-Date")
  valid_402657984 = validateParameter(valid_402657984, JString,
                                      required = false, default = nil)
  if valid_402657984 != nil:
    section.add "X-Amz-Date", valid_402657984
  var valid_402657985 = header.getOrDefault("X-Amz-Credential")
  valid_402657985 = validateParameter(valid_402657985, JString,
                                      required = false, default = nil)
  if valid_402657985 != nil:
    section.add "X-Amz-Credential", valid_402657985
  var valid_402657986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657986 = validateParameter(valid_402657986, JString,
                                      required = false, default = nil)
  if valid_402657986 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657988: Call_ListNotebookInstances_402657974;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
                                                                                         ## 
  let valid = call_402657988.validator(path, query, header, formData, body, _)
  let scheme = call_402657988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657988.makeUrl(scheme.get, call_402657988.host, call_402657988.base,
                                   call_402657988.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657988, uri, valid, _)

proc call*(call_402657989: Call_ListNotebookInstances_402657974; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   
                                                                                                            ## MaxResults: string
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## Pagination 
                                                                                                            ## limit
  ##   
                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                               ## NextToken: string
                                                                                                                                               ##            
                                                                                                                                               ## : 
                                                                                                                                               ## Pagination 
                                                                                                                                               ## token
  var query_402657990 = newJObject()
  var body_402657991 = newJObject()
  add(query_402657990, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657991 = body
  add(query_402657990, "NextToken", newJString(NextToken))
  result = call_402657989.call(nil, query_402657990, nil, nil, body_402657991)

var listNotebookInstances* = Call_ListNotebookInstances_402657974(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_402657975, base: "/",
    makeUrl: url_ListNotebookInstances_402657976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_402657992 = ref object of OpenApiRestCall_402656044
proc url_ListProcessingJobs_402657994(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProcessingJobs_402657993(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402657995 = query.getOrDefault("MaxResults")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "MaxResults", valid_402657995
  var valid_402657996 = query.getOrDefault("NextToken")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "NextToken", valid_402657996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657997 = header.getOrDefault("X-Amz-Target")
  valid_402657997 = validateParameter(valid_402657997, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_402657997 != nil:
    section.add "X-Amz-Target", valid_402657997
  var valid_402657998 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657998 = validateParameter(valid_402657998, JString,
                                      required = false, default = nil)
  if valid_402657998 != nil:
    section.add "X-Amz-Security-Token", valid_402657998
  var valid_402657999 = header.getOrDefault("X-Amz-Signature")
  valid_402657999 = validateParameter(valid_402657999, JString,
                                      required = false, default = nil)
  if valid_402657999 != nil:
    section.add "X-Amz-Signature", valid_402657999
  var valid_402658000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658000 = validateParameter(valid_402658000, JString,
                                      required = false, default = nil)
  if valid_402658000 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658000
  var valid_402658001 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658001 = validateParameter(valid_402658001, JString,
                                      required = false, default = nil)
  if valid_402658001 != nil:
    section.add "X-Amz-Algorithm", valid_402658001
  var valid_402658002 = header.getOrDefault("X-Amz-Date")
  valid_402658002 = validateParameter(valid_402658002, JString,
                                      required = false, default = nil)
  if valid_402658002 != nil:
    section.add "X-Amz-Date", valid_402658002
  var valid_402658003 = header.getOrDefault("X-Amz-Credential")
  valid_402658003 = validateParameter(valid_402658003, JString,
                                      required = false, default = nil)
  if valid_402658003 != nil:
    section.add "X-Amz-Credential", valid_402658003
  var valid_402658004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658004 = validateParameter(valid_402658004, JString,
                                      required = false, default = nil)
  if valid_402658004 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658006: Call_ListProcessingJobs_402657992;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists processing jobs that satisfy various filters.
                                                                                         ## 
  let valid = call_402658006.validator(path, query, header, formData, body, _)
  let scheme = call_402658006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658006.makeUrl(scheme.get, call_402658006.host, call_402658006.base,
                                   call_402658006.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658006, uri, valid, _)

proc call*(call_402658007: Call_ListProcessingJobs_402657992; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
                                                        ##             : Pagination limit
  ##   
                                                                                         ## body: JObject (required)
  ##   
                                                                                                                    ## NextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  var query_402658008 = newJObject()
  var body_402658009 = newJObject()
  add(query_402658008, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658009 = body
  add(query_402658008, "NextToken", newJString(NextToken))
  result = call_402658007.call(nil, query_402658008, nil, nil, body_402658009)

var listProcessingJobs* = Call_ListProcessingJobs_402657992(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_402657993, base: "/",
    makeUrl: url_ListProcessingJobs_402657994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_402658010 = ref object of OpenApiRestCall_402656044
proc url_ListSubscribedWorkteams_402658012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscribedWorkteams_402658011(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658013 = query.getOrDefault("MaxResults")
  valid_402658013 = validateParameter(valid_402658013, JString,
                                      required = false, default = nil)
  if valid_402658013 != nil:
    section.add "MaxResults", valid_402658013
  var valid_402658014 = query.getOrDefault("NextToken")
  valid_402658014 = validateParameter(valid_402658014, JString,
                                      required = false, default = nil)
  if valid_402658014 != nil:
    section.add "NextToken", valid_402658014
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658015 = header.getOrDefault("X-Amz-Target")
  valid_402658015 = validateParameter(valid_402658015, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_402658015 != nil:
    section.add "X-Amz-Target", valid_402658015
  var valid_402658016 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658016 = validateParameter(valid_402658016, JString,
                                      required = false, default = nil)
  if valid_402658016 != nil:
    section.add "X-Amz-Security-Token", valid_402658016
  var valid_402658017 = header.getOrDefault("X-Amz-Signature")
  valid_402658017 = validateParameter(valid_402658017, JString,
                                      required = false, default = nil)
  if valid_402658017 != nil:
    section.add "X-Amz-Signature", valid_402658017
  var valid_402658018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658018 = validateParameter(valid_402658018, JString,
                                      required = false, default = nil)
  if valid_402658018 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658018
  var valid_402658019 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658019 = validateParameter(valid_402658019, JString,
                                      required = false, default = nil)
  if valid_402658019 != nil:
    section.add "X-Amz-Algorithm", valid_402658019
  var valid_402658020 = header.getOrDefault("X-Amz-Date")
  valid_402658020 = validateParameter(valid_402658020, JString,
                                      required = false, default = nil)
  if valid_402658020 != nil:
    section.add "X-Amz-Date", valid_402658020
  var valid_402658021 = header.getOrDefault("X-Amz-Credential")
  valid_402658021 = validateParameter(valid_402658021, JString,
                                      required = false, default = nil)
  if valid_402658021 != nil:
    section.add "X-Amz-Credential", valid_402658021
  var valid_402658022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658022 = validateParameter(valid_402658022, JString,
                                      required = false, default = nil)
  if valid_402658022 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658024: Call_ListSubscribedWorkteams_402658010;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
                                                                                         ## 
  let valid = call_402658024.validator(path, query, header, formData, body, _)
  let scheme = call_402658024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658024.makeUrl(scheme.get, call_402658024.host, call_402658024.base,
                                   call_402658024.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658024, uri, valid, _)

proc call*(call_402658025: Call_ListSubscribedWorkteams_402658010;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   
                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                      ##             
                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                         ## token
  var query_402658026 = newJObject()
  var body_402658027 = newJObject()
  add(query_402658026, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658027 = body
  add(query_402658026, "NextToken", newJString(NextToken))
  result = call_402658025.call(nil, query_402658026, nil, nil, body_402658027)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_402658010(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_402658011, base: "/",
    makeUrl: url_ListSubscribedWorkteams_402658012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_402658028 = ref object of OpenApiRestCall_402656044
proc url_ListTags_402658030(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_402658029(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658031 = query.getOrDefault("MaxResults")
  valid_402658031 = validateParameter(valid_402658031, JString,
                                      required = false, default = nil)
  if valid_402658031 != nil:
    section.add "MaxResults", valid_402658031
  var valid_402658032 = query.getOrDefault("NextToken")
  valid_402658032 = validateParameter(valid_402658032, JString,
                                      required = false, default = nil)
  if valid_402658032 != nil:
    section.add "NextToken", valid_402658032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658033 = header.getOrDefault("X-Amz-Target")
  valid_402658033 = validateParameter(valid_402658033, JString, required = true, default = newJString(
      "SageMaker.ListTags"))
  if valid_402658033 != nil:
    section.add "X-Amz-Target", valid_402658033
  var valid_402658034 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658034 = validateParameter(valid_402658034, JString,
                                      required = false, default = nil)
  if valid_402658034 != nil:
    section.add "X-Amz-Security-Token", valid_402658034
  var valid_402658035 = header.getOrDefault("X-Amz-Signature")
  valid_402658035 = validateParameter(valid_402658035, JString,
                                      required = false, default = nil)
  if valid_402658035 != nil:
    section.add "X-Amz-Signature", valid_402658035
  var valid_402658036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658036 = validateParameter(valid_402658036, JString,
                                      required = false, default = nil)
  if valid_402658036 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658036
  var valid_402658037 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658037 = validateParameter(valid_402658037, JString,
                                      required = false, default = nil)
  if valid_402658037 != nil:
    section.add "X-Amz-Algorithm", valid_402658037
  var valid_402658038 = header.getOrDefault("X-Amz-Date")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "X-Amz-Date", valid_402658038
  var valid_402658039 = header.getOrDefault("X-Amz-Credential")
  valid_402658039 = validateParameter(valid_402658039, JString,
                                      required = false, default = nil)
  if valid_402658039 != nil:
    section.add "X-Amz-Credential", valid_402658039
  var valid_402658040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658040 = validateParameter(valid_402658040, JString,
                                      required = false, default = nil)
  if valid_402658040 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658042: Call_ListTags_402658028; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
                                                                                         ## 
  let valid = call_402658042.validator(path, query, header, formData, body, _)
  let scheme = call_402658042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658042.makeUrl(scheme.get, call_402658042.host, call_402658042.base,
                                   call_402658042.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658042, uri, valid, _)

proc call*(call_402658043: Call_ListTags_402658028; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
                                                                  ##             : Pagination limit
  ##   
                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                              ## NextToken: string
                                                                                                                              ##            
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## token
  var query_402658044 = newJObject()
  var body_402658045 = newJObject()
  add(query_402658044, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658045 = body
  add(query_402658044, "NextToken", newJString(NextToken))
  result = call_402658043.call(nil, query_402658044, nil, nil, body_402658045)

var listTags* = Call_ListTags_402658028(name: "listTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTags",
                                        validator: validate_ListTags_402658029,
                                        base: "/", makeUrl: url_ListTags_402658030,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_402658046 = ref object of OpenApiRestCall_402656044
proc url_ListTrainingJobs_402658048(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobs_402658047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658049 = query.getOrDefault("MaxResults")
  valid_402658049 = validateParameter(valid_402658049, JString,
                                      required = false, default = nil)
  if valid_402658049 != nil:
    section.add "MaxResults", valid_402658049
  var valid_402658050 = query.getOrDefault("NextToken")
  valid_402658050 = validateParameter(valid_402658050, JString,
                                      required = false, default = nil)
  if valid_402658050 != nil:
    section.add "NextToken", valid_402658050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658051 = header.getOrDefault("X-Amz-Target")
  valid_402658051 = validateParameter(valid_402658051, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_402658051 != nil:
    section.add "X-Amz-Target", valid_402658051
  var valid_402658052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658052 = validateParameter(valid_402658052, JString,
                                      required = false, default = nil)
  if valid_402658052 != nil:
    section.add "X-Amz-Security-Token", valid_402658052
  var valid_402658053 = header.getOrDefault("X-Amz-Signature")
  valid_402658053 = validateParameter(valid_402658053, JString,
                                      required = false, default = nil)
  if valid_402658053 != nil:
    section.add "X-Amz-Signature", valid_402658053
  var valid_402658054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658054 = validateParameter(valid_402658054, JString,
                                      required = false, default = nil)
  if valid_402658054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658054
  var valid_402658055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658055 = validateParameter(valid_402658055, JString,
                                      required = false, default = nil)
  if valid_402658055 != nil:
    section.add "X-Amz-Algorithm", valid_402658055
  var valid_402658056 = header.getOrDefault("X-Amz-Date")
  valid_402658056 = validateParameter(valid_402658056, JString,
                                      required = false, default = nil)
  if valid_402658056 != nil:
    section.add "X-Amz-Date", valid_402658056
  var valid_402658057 = header.getOrDefault("X-Amz-Credential")
  valid_402658057 = validateParameter(valid_402658057, JString,
                                      required = false, default = nil)
  if valid_402658057 != nil:
    section.add "X-Amz-Credential", valid_402658057
  var valid_402658058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658058 = validateParameter(valid_402658058, JString,
                                      required = false, default = nil)
  if valid_402658058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658060: Call_ListTrainingJobs_402658046;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists training jobs.
                                                                                         ## 
  let valid = call_402658060.validator(path, query, header, formData, body, _)
  let scheme = call_402658060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658060.makeUrl(scheme.get, call_402658060.host, call_402658060.base,
                                   call_402658060.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658060, uri, valid, _)

proc call*(call_402658061: Call_ListTrainingJobs_402658046; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
                         ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402658062 = newJObject()
  var body_402658063 = newJObject()
  add(query_402658062, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658063 = body
  add(query_402658062, "NextToken", newJString(NextToken))
  result = call_402658061.call(nil, query_402658062, nil, nil, body_402658063)

var listTrainingJobs* = Call_ListTrainingJobs_402658046(
    name: "listTrainingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_402658047, base: "/",
    makeUrl: url_ListTrainingJobs_402658048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_402658064 = ref object of OpenApiRestCall_402656044
proc url_ListTrainingJobsForHyperParameterTuningJob_402658066(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_402658065(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402658067 = query.getOrDefault("MaxResults")
  valid_402658067 = validateParameter(valid_402658067, JString,
                                      required = false, default = nil)
  if valid_402658067 != nil:
    section.add "MaxResults", valid_402658067
  var valid_402658068 = query.getOrDefault("NextToken")
  valid_402658068 = validateParameter(valid_402658068, JString,
                                      required = false, default = nil)
  if valid_402658068 != nil:
    section.add "NextToken", valid_402658068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658069 = header.getOrDefault("X-Amz-Target")
  valid_402658069 = validateParameter(valid_402658069, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_402658069 != nil:
    section.add "X-Amz-Target", valid_402658069
  var valid_402658070 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658070 = validateParameter(valid_402658070, JString,
                                      required = false, default = nil)
  if valid_402658070 != nil:
    section.add "X-Amz-Security-Token", valid_402658070
  var valid_402658071 = header.getOrDefault("X-Amz-Signature")
  valid_402658071 = validateParameter(valid_402658071, JString,
                                      required = false, default = nil)
  if valid_402658071 != nil:
    section.add "X-Amz-Signature", valid_402658071
  var valid_402658072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658072 = validateParameter(valid_402658072, JString,
                                      required = false, default = nil)
  if valid_402658072 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658072
  var valid_402658073 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658073 = validateParameter(valid_402658073, JString,
                                      required = false, default = nil)
  if valid_402658073 != nil:
    section.add "X-Amz-Algorithm", valid_402658073
  var valid_402658074 = header.getOrDefault("X-Amz-Date")
  valid_402658074 = validateParameter(valid_402658074, JString,
                                      required = false, default = nil)
  if valid_402658074 != nil:
    section.add "X-Amz-Date", valid_402658074
  var valid_402658075 = header.getOrDefault("X-Amz-Credential")
  valid_402658075 = validateParameter(valid_402658075, JString,
                                      required = false, default = nil)
  if valid_402658075 != nil:
    section.add "X-Amz-Credential", valid_402658075
  var valid_402658076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658076 = validateParameter(valid_402658076, JString,
                                      required = false, default = nil)
  if valid_402658076 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658078: Call_ListTrainingJobsForHyperParameterTuningJob_402658064;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
                                                                                         ## 
  let valid = call_402658078.validator(path, query, header, formData, body, _)
  let scheme = call_402658078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658078.makeUrl(scheme.get, call_402658078.host, call_402658078.base,
                                   call_402658078.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658078, uri, valid, _)

proc call*(call_402658079: Call_ListTrainingJobsForHyperParameterTuningJob_402658064;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   
                                                                                                                                ## MaxResults: string
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## limit
  ##   
                                                                                                                                        ## body: JObject (required)
  ##   
                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                   ##            
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## Pagination 
                                                                                                                                                                   ## token
  var query_402658080 = newJObject()
  var body_402658081 = newJObject()
  add(query_402658080, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658081 = body
  add(query_402658080, "NextToken", newJString(NextToken))
  result = call_402658079.call(nil, query_402658080, nil, nil, body_402658081)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_402658064(
    name: "listTrainingJobsForHyperParameterTuningJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_402658065,
    base: "/", makeUrl: url_ListTrainingJobsForHyperParameterTuningJob_402658066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_402658082 = ref object of OpenApiRestCall_402656044
proc url_ListTransformJobs_402658084(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTransformJobs_402658083(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658085 = query.getOrDefault("MaxResults")
  valid_402658085 = validateParameter(valid_402658085, JString,
                                      required = false, default = nil)
  if valid_402658085 != nil:
    section.add "MaxResults", valid_402658085
  var valid_402658086 = query.getOrDefault("NextToken")
  valid_402658086 = validateParameter(valid_402658086, JString,
                                      required = false, default = nil)
  if valid_402658086 != nil:
    section.add "NextToken", valid_402658086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658087 = header.getOrDefault("X-Amz-Target")
  valid_402658087 = validateParameter(valid_402658087, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_402658087 != nil:
    section.add "X-Amz-Target", valid_402658087
  var valid_402658088 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658088 = validateParameter(valid_402658088, JString,
                                      required = false, default = nil)
  if valid_402658088 != nil:
    section.add "X-Amz-Security-Token", valid_402658088
  var valid_402658089 = header.getOrDefault("X-Amz-Signature")
  valid_402658089 = validateParameter(valid_402658089, JString,
                                      required = false, default = nil)
  if valid_402658089 != nil:
    section.add "X-Amz-Signature", valid_402658089
  var valid_402658090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658090 = validateParameter(valid_402658090, JString,
                                      required = false, default = nil)
  if valid_402658090 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658090
  var valid_402658091 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658091 = validateParameter(valid_402658091, JString,
                                      required = false, default = nil)
  if valid_402658091 != nil:
    section.add "X-Amz-Algorithm", valid_402658091
  var valid_402658092 = header.getOrDefault("X-Amz-Date")
  valid_402658092 = validateParameter(valid_402658092, JString,
                                      required = false, default = nil)
  if valid_402658092 != nil:
    section.add "X-Amz-Date", valid_402658092
  var valid_402658093 = header.getOrDefault("X-Amz-Credential")
  valid_402658093 = validateParameter(valid_402658093, JString,
                                      required = false, default = nil)
  if valid_402658093 != nil:
    section.add "X-Amz-Credential", valid_402658093
  var valid_402658094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658094 = validateParameter(valid_402658094, JString,
                                      required = false, default = nil)
  if valid_402658094 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658096: Call_ListTransformJobs_402658082;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists transform jobs.
                                                                                         ## 
  let valid = call_402658096.validator(path, query, header, formData, body, _)
  let scheme = call_402658096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658096.makeUrl(scheme.get, call_402658096.host, call_402658096.base,
                                   call_402658096.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658096, uri, valid, _)

proc call*(call_402658097: Call_ListTransformJobs_402658082; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
                          ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402658098 = newJObject()
  var body_402658099 = newJObject()
  add(query_402658098, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658099 = body
  add(query_402658098, "NextToken", newJString(NextToken))
  result = call_402658097.call(nil, query_402658098, nil, nil, body_402658099)

var listTransformJobs* = Call_ListTransformJobs_402658082(
    name: "listTransformJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_402658083, base: "/",
    makeUrl: url_ListTransformJobs_402658084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_402658100 = ref object of OpenApiRestCall_402656044
proc url_ListTrialComponents_402658102(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrialComponents_402658101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658103 = query.getOrDefault("MaxResults")
  valid_402658103 = validateParameter(valid_402658103, JString,
                                      required = false, default = nil)
  if valid_402658103 != nil:
    section.add "MaxResults", valid_402658103
  var valid_402658104 = query.getOrDefault("NextToken")
  valid_402658104 = validateParameter(valid_402658104, JString,
                                      required = false, default = nil)
  if valid_402658104 != nil:
    section.add "NextToken", valid_402658104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658105 = header.getOrDefault("X-Amz-Target")
  valid_402658105 = validateParameter(valid_402658105, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_402658105 != nil:
    section.add "X-Amz-Target", valid_402658105
  var valid_402658106 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658106 = validateParameter(valid_402658106, JString,
                                      required = false, default = nil)
  if valid_402658106 != nil:
    section.add "X-Amz-Security-Token", valid_402658106
  var valid_402658107 = header.getOrDefault("X-Amz-Signature")
  valid_402658107 = validateParameter(valid_402658107, JString,
                                      required = false, default = nil)
  if valid_402658107 != nil:
    section.add "X-Amz-Signature", valid_402658107
  var valid_402658108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658108 = validateParameter(valid_402658108, JString,
                                      required = false, default = nil)
  if valid_402658108 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658108
  var valid_402658109 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658109 = validateParameter(valid_402658109, JString,
                                      required = false, default = nil)
  if valid_402658109 != nil:
    section.add "X-Amz-Algorithm", valid_402658109
  var valid_402658110 = header.getOrDefault("X-Amz-Date")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "X-Amz-Date", valid_402658110
  var valid_402658111 = header.getOrDefault("X-Amz-Credential")
  valid_402658111 = validateParameter(valid_402658111, JString,
                                      required = false, default = nil)
  if valid_402658111 != nil:
    section.add "X-Amz-Credential", valid_402658111
  var valid_402658112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658112 = validateParameter(valid_402658112, JString,
                                      required = false, default = nil)
  if valid_402658112 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658114: Call_ListTrialComponents_402658100;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
                                                                                         ## 
  let valid = call_402658114.validator(path, query, header, formData, body, _)
  let scheme = call_402658114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658114.makeUrl(scheme.get, call_402658114.host, call_402658114.base,
                                   call_402658114.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658114, uri, valid, _)

proc call*(call_402658115: Call_ListTrialComponents_402658100; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## token
  var query_402658116 = newJObject()
  var body_402658117 = newJObject()
  add(query_402658116, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658117 = body
  add(query_402658116, "NextToken", newJString(NextToken))
  result = call_402658115.call(nil, query_402658116, nil, nil, body_402658117)

var listTrialComponents* = Call_ListTrialComponents_402658100(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_402658101, base: "/",
    makeUrl: url_ListTrialComponents_402658102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_402658118 = ref object of OpenApiRestCall_402656044
proc url_ListTrials_402658120(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrials_402658119(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
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
  var valid_402658121 = query.getOrDefault("MaxResults")
  valid_402658121 = validateParameter(valid_402658121, JString,
                                      required = false, default = nil)
  if valid_402658121 != nil:
    section.add "MaxResults", valid_402658121
  var valid_402658122 = query.getOrDefault("NextToken")
  valid_402658122 = validateParameter(valid_402658122, JString,
                                      required = false, default = nil)
  if valid_402658122 != nil:
    section.add "NextToken", valid_402658122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658123 = header.getOrDefault("X-Amz-Target")
  valid_402658123 = validateParameter(valid_402658123, JString, required = true, default = newJString(
      "SageMaker.ListTrials"))
  if valid_402658123 != nil:
    section.add "X-Amz-Target", valid_402658123
  var valid_402658124 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658124 = validateParameter(valid_402658124, JString,
                                      required = false, default = nil)
  if valid_402658124 != nil:
    section.add "X-Amz-Security-Token", valid_402658124
  var valid_402658125 = header.getOrDefault("X-Amz-Signature")
  valid_402658125 = validateParameter(valid_402658125, JString,
                                      required = false, default = nil)
  if valid_402658125 != nil:
    section.add "X-Amz-Signature", valid_402658125
  var valid_402658126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658126 = validateParameter(valid_402658126, JString,
                                      required = false, default = nil)
  if valid_402658126 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658126
  var valid_402658127 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658127 = validateParameter(valid_402658127, JString,
                                      required = false, default = nil)
  if valid_402658127 != nil:
    section.add "X-Amz-Algorithm", valid_402658127
  var valid_402658128 = header.getOrDefault("X-Amz-Date")
  valid_402658128 = validateParameter(valid_402658128, JString,
                                      required = false, default = nil)
  if valid_402658128 != nil:
    section.add "X-Amz-Date", valid_402658128
  var valid_402658129 = header.getOrDefault("X-Amz-Credential")
  valid_402658129 = validateParameter(valid_402658129, JString,
                                      required = false, default = nil)
  if valid_402658129 != nil:
    section.add "X-Amz-Credential", valid_402658129
  var valid_402658130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658130 = validateParameter(valid_402658130, JString,
                                      required = false, default = nil)
  if valid_402658130 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658132: Call_ListTrials_402658118; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
                                                                                         ## 
  let valid = call_402658132.validator(path, query, header, formData, body, _)
  let scheme = call_402658132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658132.makeUrl(scheme.get, call_402658132.host, call_402658132.base,
                                   call_402658132.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658132, uri, valid, _)

proc call*(call_402658133: Call_ListTrials_402658118; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402658134 = newJObject()
  var body_402658135 = newJObject()
  add(query_402658134, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658135 = body
  add(query_402658134, "NextToken", newJString(NextToken))
  result = call_402658133.call(nil, query_402658134, nil, nil, body_402658135)

var listTrials* = Call_ListTrials_402658118(name: "listTrials",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrials",
    validator: validate_ListTrials_402658119, base: "/",
    makeUrl: url_ListTrials_402658120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_402658136 = ref object of OpenApiRestCall_402656044
proc url_ListUserProfiles_402658138(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserProfiles_402658137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658139 = query.getOrDefault("MaxResults")
  valid_402658139 = validateParameter(valid_402658139, JString,
                                      required = false, default = nil)
  if valid_402658139 != nil:
    section.add "MaxResults", valid_402658139
  var valid_402658140 = query.getOrDefault("NextToken")
  valid_402658140 = validateParameter(valid_402658140, JString,
                                      required = false, default = nil)
  if valid_402658140 != nil:
    section.add "NextToken", valid_402658140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658141 = header.getOrDefault("X-Amz-Target")
  valid_402658141 = validateParameter(valid_402658141, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_402658141 != nil:
    section.add "X-Amz-Target", valid_402658141
  var valid_402658142 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658142 = validateParameter(valid_402658142, JString,
                                      required = false, default = nil)
  if valid_402658142 != nil:
    section.add "X-Amz-Security-Token", valid_402658142
  var valid_402658143 = header.getOrDefault("X-Amz-Signature")
  valid_402658143 = validateParameter(valid_402658143, JString,
                                      required = false, default = nil)
  if valid_402658143 != nil:
    section.add "X-Amz-Signature", valid_402658143
  var valid_402658144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658144 = validateParameter(valid_402658144, JString,
                                      required = false, default = nil)
  if valid_402658144 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658144
  var valid_402658145 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658145 = validateParameter(valid_402658145, JString,
                                      required = false, default = nil)
  if valid_402658145 != nil:
    section.add "X-Amz-Algorithm", valid_402658145
  var valid_402658146 = header.getOrDefault("X-Amz-Date")
  valid_402658146 = validateParameter(valid_402658146, JString,
                                      required = false, default = nil)
  if valid_402658146 != nil:
    section.add "X-Amz-Date", valid_402658146
  var valid_402658147 = header.getOrDefault("X-Amz-Credential")
  valid_402658147 = validateParameter(valid_402658147, JString,
                                      required = false, default = nil)
  if valid_402658147 != nil:
    section.add "X-Amz-Credential", valid_402658147
  var valid_402658148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658148 = validateParameter(valid_402658148, JString,
                                      required = false, default = nil)
  if valid_402658148 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658150: Call_ListUserProfiles_402658136;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists user profiles.
                                                                                         ## 
  let valid = call_402658150.validator(path, query, header, formData, body, _)
  let scheme = call_402658150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658150.makeUrl(scheme.get, call_402658150.host, call_402658150.base,
                                   call_402658150.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658150, uri, valid, _)

proc call*(call_402658151: Call_ListUserProfiles_402658136; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
                         ##             : Pagination limit
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402658152 = newJObject()
  var body_402658153 = newJObject()
  add(query_402658152, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658153 = body
  add(query_402658152, "NextToken", newJString(NextToken))
  result = call_402658151.call(nil, query_402658152, nil, nil, body_402658153)

var listUserProfiles* = Call_ListUserProfiles_402658136(
    name: "listUserProfiles", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_402658137, base: "/",
    makeUrl: url_ListUserProfiles_402658138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_402658154 = ref object of OpenApiRestCall_402656044
proc url_ListWorkteams_402658156(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkteams_402658155(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658157 = query.getOrDefault("MaxResults")
  valid_402658157 = validateParameter(valid_402658157, JString,
                                      required = false, default = nil)
  if valid_402658157 != nil:
    section.add "MaxResults", valid_402658157
  var valid_402658158 = query.getOrDefault("NextToken")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "NextToken", valid_402658158
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658159 = header.getOrDefault("X-Amz-Target")
  valid_402658159 = validateParameter(valid_402658159, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_402658159 != nil:
    section.add "X-Amz-Target", valid_402658159
  var valid_402658160 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658160 = validateParameter(valid_402658160, JString,
                                      required = false, default = nil)
  if valid_402658160 != nil:
    section.add "X-Amz-Security-Token", valid_402658160
  var valid_402658161 = header.getOrDefault("X-Amz-Signature")
  valid_402658161 = validateParameter(valid_402658161, JString,
                                      required = false, default = nil)
  if valid_402658161 != nil:
    section.add "X-Amz-Signature", valid_402658161
  var valid_402658162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658162 = validateParameter(valid_402658162, JString,
                                      required = false, default = nil)
  if valid_402658162 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658162
  var valid_402658163 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658163 = validateParameter(valid_402658163, JString,
                                      required = false, default = nil)
  if valid_402658163 != nil:
    section.add "X-Amz-Algorithm", valid_402658163
  var valid_402658164 = header.getOrDefault("X-Amz-Date")
  valid_402658164 = validateParameter(valid_402658164, JString,
                                      required = false, default = nil)
  if valid_402658164 != nil:
    section.add "X-Amz-Date", valid_402658164
  var valid_402658165 = header.getOrDefault("X-Amz-Credential")
  valid_402658165 = validateParameter(valid_402658165, JString,
                                      required = false, default = nil)
  if valid_402658165 != nil:
    section.add "X-Amz-Credential", valid_402658165
  var valid_402658166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658166 = validateParameter(valid_402658166, JString,
                                      required = false, default = nil)
  if valid_402658166 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658168: Call_ListWorkteams_402658154; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
                                                                                         ## 
  let valid = call_402658168.validator(path, query, header, formData, body, _)
  let scheme = call_402658168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658168.makeUrl(scheme.get, call_402658168.host, call_402658168.base,
                                   call_402658168.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658168, uri, valid, _)

proc call*(call_402658169: Call_ListWorkteams_402658154; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   
                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                  ##             
                                                                                                                                                                                  ## : 
                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                     ## token
  var query_402658170 = newJObject()
  var body_402658171 = newJObject()
  add(query_402658170, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658171 = body
  add(query_402658170, "NextToken", newJString(NextToken))
  result = call_402658169.call(nil, query_402658170, nil, nil, body_402658171)

var listWorkteams* = Call_ListWorkteams_402658154(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_402658155, base: "/",
    makeUrl: url_ListWorkteams_402658156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_402658172 = ref object of OpenApiRestCall_402656044
proc url_RenderUiTemplate_402658174(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenderUiTemplate_402658173(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658175 = header.getOrDefault("X-Amz-Target")
  valid_402658175 = validateParameter(valid_402658175, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_402658175 != nil:
    section.add "X-Amz-Target", valid_402658175
  var valid_402658176 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658176 = validateParameter(valid_402658176, JString,
                                      required = false, default = nil)
  if valid_402658176 != nil:
    section.add "X-Amz-Security-Token", valid_402658176
  var valid_402658177 = header.getOrDefault("X-Amz-Signature")
  valid_402658177 = validateParameter(valid_402658177, JString,
                                      required = false, default = nil)
  if valid_402658177 != nil:
    section.add "X-Amz-Signature", valid_402658177
  var valid_402658178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658178 = validateParameter(valid_402658178, JString,
                                      required = false, default = nil)
  if valid_402658178 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658178
  var valid_402658179 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658179 = validateParameter(valid_402658179, JString,
                                      required = false, default = nil)
  if valid_402658179 != nil:
    section.add "X-Amz-Algorithm", valid_402658179
  var valid_402658180 = header.getOrDefault("X-Amz-Date")
  valid_402658180 = validateParameter(valid_402658180, JString,
                                      required = false, default = nil)
  if valid_402658180 != nil:
    section.add "X-Amz-Date", valid_402658180
  var valid_402658181 = header.getOrDefault("X-Amz-Credential")
  valid_402658181 = validateParameter(valid_402658181, JString,
                                      required = false, default = nil)
  if valid_402658181 != nil:
    section.add "X-Amz-Credential", valid_402658181
  var valid_402658182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658182 = validateParameter(valid_402658182, JString,
                                      required = false, default = nil)
  if valid_402658182 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658184: Call_RenderUiTemplate_402658172;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
                                                                                         ## 
  let valid = call_402658184.validator(path, query, header, formData, body, _)
  let scheme = call_402658184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658184.makeUrl(scheme.get, call_402658184.host, call_402658184.base,
                                   call_402658184.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658184, uri, valid, _)

proc call*(call_402658185: Call_RenderUiTemplate_402658172; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   
                                                                              ## body: JObject (required)
  var body_402658186 = newJObject()
  if body != nil:
    body_402658186 = body
  result = call_402658185.call(nil, nil, nil, nil, body_402658186)

var renderUiTemplate* = Call_RenderUiTemplate_402658172(
    name: "renderUiTemplate", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_402658173, base: "/",
    makeUrl: url_RenderUiTemplate_402658174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_402658187 = ref object of OpenApiRestCall_402656044
proc url_Search_402658189(protocol: Scheme; host: string; base: string;
                          route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Search_402658188(path: JsonNode; query: JsonNode;
                               header: JsonNode; formData: JsonNode;
                               body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402658190 = query.getOrDefault("MaxResults")
  valid_402658190 = validateParameter(valid_402658190, JString,
                                      required = false, default = nil)
  if valid_402658190 != nil:
    section.add "MaxResults", valid_402658190
  var valid_402658191 = query.getOrDefault("NextToken")
  valid_402658191 = validateParameter(valid_402658191, JString,
                                      required = false, default = nil)
  if valid_402658191 != nil:
    section.add "NextToken", valid_402658191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658192 = header.getOrDefault("X-Amz-Target")
  valid_402658192 = validateParameter(valid_402658192, JString, required = true,
                                      default = newJString("SageMaker.Search"))
  if valid_402658192 != nil:
    section.add "X-Amz-Target", valid_402658192
  var valid_402658193 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658193 = validateParameter(valid_402658193, JString,
                                      required = false, default = nil)
  if valid_402658193 != nil:
    section.add "X-Amz-Security-Token", valid_402658193
  var valid_402658194 = header.getOrDefault("X-Amz-Signature")
  valid_402658194 = validateParameter(valid_402658194, JString,
                                      required = false, default = nil)
  if valid_402658194 != nil:
    section.add "X-Amz-Signature", valid_402658194
  var valid_402658195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658195 = validateParameter(valid_402658195, JString,
                                      required = false, default = nil)
  if valid_402658195 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658195
  var valid_402658196 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658196 = validateParameter(valid_402658196, JString,
                                      required = false, default = nil)
  if valid_402658196 != nil:
    section.add "X-Amz-Algorithm", valid_402658196
  var valid_402658197 = header.getOrDefault("X-Amz-Date")
  valid_402658197 = validateParameter(valid_402658197, JString,
                                      required = false, default = nil)
  if valid_402658197 != nil:
    section.add "X-Amz-Date", valid_402658197
  var valid_402658198 = header.getOrDefault("X-Amz-Credential")
  valid_402658198 = validateParameter(valid_402658198, JString,
                                      required = false, default = nil)
  if valid_402658198 != nil:
    section.add "X-Amz-Credential", valid_402658198
  var valid_402658199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658199 = validateParameter(valid_402658199, JString,
                                      required = false, default = nil)
  if valid_402658199 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658201: Call_Search_402658187; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
                                                                                         ## 
  let valid = call_402658201.validator(path, query, header, formData, body, _)
  let scheme = call_402658201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658201.makeUrl(scheme.get, call_402658201.host, call_402658201.base,
                                   call_402658201.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658201, uri, valid, _)

proc call*(call_402658202: Call_Search_402658187; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                          ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                             ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                             ## token
  var query_402658203 = newJObject()
  var body_402658204 = newJObject()
  add(query_402658203, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402658204 = body
  add(query_402658203, "NextToken", newJString(NextToken))
  result = call_402658202.call(nil, query_402658203, nil, nil, body_402658204)

var search* = Call_Search_402658187(name: "search", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com",
                                    route: "/#X-Amz-Target=SageMaker.Search",
                                    validator: validate_Search_402658188,
                                    base: "/", makeUrl: url_Search_402658189,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_402658205 = ref object of OpenApiRestCall_402656044
proc url_StartMonitoringSchedule_402658207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMonitoringSchedule_402658206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658208 = header.getOrDefault("X-Amz-Target")
  valid_402658208 = validateParameter(valid_402658208, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_402658208 != nil:
    section.add "X-Amz-Target", valid_402658208
  var valid_402658209 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658209 = validateParameter(valid_402658209, JString,
                                      required = false, default = nil)
  if valid_402658209 != nil:
    section.add "X-Amz-Security-Token", valid_402658209
  var valid_402658210 = header.getOrDefault("X-Amz-Signature")
  valid_402658210 = validateParameter(valid_402658210, JString,
                                      required = false, default = nil)
  if valid_402658210 != nil:
    section.add "X-Amz-Signature", valid_402658210
  var valid_402658211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658211 = validateParameter(valid_402658211, JString,
                                      required = false, default = nil)
  if valid_402658211 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658211
  var valid_402658212 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658212 = validateParameter(valid_402658212, JString,
                                      required = false, default = nil)
  if valid_402658212 != nil:
    section.add "X-Amz-Algorithm", valid_402658212
  var valid_402658213 = header.getOrDefault("X-Amz-Date")
  valid_402658213 = validateParameter(valid_402658213, JString,
                                      required = false, default = nil)
  if valid_402658213 != nil:
    section.add "X-Amz-Date", valid_402658213
  var valid_402658214 = header.getOrDefault("X-Amz-Credential")
  valid_402658214 = validateParameter(valid_402658214, JString,
                                      required = false, default = nil)
  if valid_402658214 != nil:
    section.add "X-Amz-Credential", valid_402658214
  var valid_402658215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658215 = validateParameter(valid_402658215, JString,
                                      required = false, default = nil)
  if valid_402658215 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658217: Call_StartMonitoringSchedule_402658205;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
                                                                                         ## 
  let valid = call_402658217.validator(path, query, header, formData, body, _)
  let scheme = call_402658217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658217.makeUrl(scheme.get, call_402658217.host, call_402658217.base,
                                   call_402658217.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658217, uri, valid, _)

proc call*(call_402658218: Call_StartMonitoringSchedule_402658205;
           body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   
                                                                                                                                                   ## body: JObject (required)
  var body_402658219 = newJObject()
  if body != nil:
    body_402658219 = body
  result = call_402658218.call(nil, nil, nil, nil, body_402658219)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_402658205(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_402658206, base: "/",
    makeUrl: url_StartMonitoringSchedule_402658207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_402658220 = ref object of OpenApiRestCall_402656044
proc url_StartNotebookInstance_402658222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartNotebookInstance_402658221(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658223 = header.getOrDefault("X-Amz-Target")
  valid_402658223 = validateParameter(valid_402658223, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_402658223 != nil:
    section.add "X-Amz-Target", valid_402658223
  var valid_402658224 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658224 = validateParameter(valid_402658224, JString,
                                      required = false, default = nil)
  if valid_402658224 != nil:
    section.add "X-Amz-Security-Token", valid_402658224
  var valid_402658225 = header.getOrDefault("X-Amz-Signature")
  valid_402658225 = validateParameter(valid_402658225, JString,
                                      required = false, default = nil)
  if valid_402658225 != nil:
    section.add "X-Amz-Signature", valid_402658225
  var valid_402658226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658226 = validateParameter(valid_402658226, JString,
                                      required = false, default = nil)
  if valid_402658226 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658226
  var valid_402658227 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658227 = validateParameter(valid_402658227, JString,
                                      required = false, default = nil)
  if valid_402658227 != nil:
    section.add "X-Amz-Algorithm", valid_402658227
  var valid_402658228 = header.getOrDefault("X-Amz-Date")
  valid_402658228 = validateParameter(valid_402658228, JString,
                                      required = false, default = nil)
  if valid_402658228 != nil:
    section.add "X-Amz-Date", valid_402658228
  var valid_402658229 = header.getOrDefault("X-Amz-Credential")
  valid_402658229 = validateParameter(valid_402658229, JString,
                                      required = false, default = nil)
  if valid_402658229 != nil:
    section.add "X-Amz-Credential", valid_402658229
  var valid_402658230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658230 = validateParameter(valid_402658230, JString,
                                      required = false, default = nil)
  if valid_402658230 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658232: Call_StartNotebookInstance_402658220;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
                                                                                         ## 
  let valid = call_402658232.validator(path, query, header, formData, body, _)
  let scheme = call_402658232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658232.makeUrl(scheme.get, call_402658232.host, call_402658232.base,
                                   call_402658232.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658232, uri, valid, _)

proc call*(call_402658233: Call_StartNotebookInstance_402658220; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   
                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402658234 = newJObject()
  if body != nil:
    body_402658234 = body
  result = call_402658233.call(nil, nil, nil, nil, body_402658234)

var startNotebookInstance* = Call_StartNotebookInstance_402658220(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_402658221, base: "/",
    makeUrl: url_StartNotebookInstance_402658222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_402658235 = ref object of OpenApiRestCall_402656044
proc url_StopAutoMLJob_402658237(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutoMLJob_402658236(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658238 = header.getOrDefault("X-Amz-Target")
  valid_402658238 = validateParameter(valid_402658238, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_402658238 != nil:
    section.add "X-Amz-Target", valid_402658238
  var valid_402658239 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658239 = validateParameter(valid_402658239, JString,
                                      required = false, default = nil)
  if valid_402658239 != nil:
    section.add "X-Amz-Security-Token", valid_402658239
  var valid_402658240 = header.getOrDefault("X-Amz-Signature")
  valid_402658240 = validateParameter(valid_402658240, JString,
                                      required = false, default = nil)
  if valid_402658240 != nil:
    section.add "X-Amz-Signature", valid_402658240
  var valid_402658241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658241 = validateParameter(valid_402658241, JString,
                                      required = false, default = nil)
  if valid_402658241 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658241
  var valid_402658242 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658242 = validateParameter(valid_402658242, JString,
                                      required = false, default = nil)
  if valid_402658242 != nil:
    section.add "X-Amz-Algorithm", valid_402658242
  var valid_402658243 = header.getOrDefault("X-Amz-Date")
  valid_402658243 = validateParameter(valid_402658243, JString,
                                      required = false, default = nil)
  if valid_402658243 != nil:
    section.add "X-Amz-Date", valid_402658243
  var valid_402658244 = header.getOrDefault("X-Amz-Credential")
  valid_402658244 = validateParameter(valid_402658244, JString,
                                      required = false, default = nil)
  if valid_402658244 != nil:
    section.add "X-Amz-Credential", valid_402658244
  var valid_402658245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658245 = validateParameter(valid_402658245, JString,
                                      required = false, default = nil)
  if valid_402658245 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658247: Call_StopAutoMLJob_402658235; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ## A method for forcing the termination of a running job.
                                                                                         ## 
  let valid = call_402658247.validator(path, query, header, formData, body, _)
  let scheme = call_402658247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658247.makeUrl(scheme.get, call_402658247.host, call_402658247.base,
                                   call_402658247.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658247, uri, valid, _)

proc call*(call_402658248: Call_StopAutoMLJob_402658235; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_402658249 = newJObject()
  if body != nil:
    body_402658249 = body
  result = call_402658248.call(nil, nil, nil, nil, body_402658249)

var stopAutoMLJob* = Call_StopAutoMLJob_402658235(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_402658236, base: "/",
    makeUrl: url_StopAutoMLJob_402658237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_402658250 = ref object of OpenApiRestCall_402656044
proc url_StopCompilationJob_402658252(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCompilationJob_402658251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658253 = header.getOrDefault("X-Amz-Target")
  valid_402658253 = validateParameter(valid_402658253, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_402658253 != nil:
    section.add "X-Amz-Target", valid_402658253
  var valid_402658254 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658254 = validateParameter(valid_402658254, JString,
                                      required = false, default = nil)
  if valid_402658254 != nil:
    section.add "X-Amz-Security-Token", valid_402658254
  var valid_402658255 = header.getOrDefault("X-Amz-Signature")
  valid_402658255 = validateParameter(valid_402658255, JString,
                                      required = false, default = nil)
  if valid_402658255 != nil:
    section.add "X-Amz-Signature", valid_402658255
  var valid_402658256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658256 = validateParameter(valid_402658256, JString,
                                      required = false, default = nil)
  if valid_402658256 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658256
  var valid_402658257 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658257 = validateParameter(valid_402658257, JString,
                                      required = false, default = nil)
  if valid_402658257 != nil:
    section.add "X-Amz-Algorithm", valid_402658257
  var valid_402658258 = header.getOrDefault("X-Amz-Date")
  valid_402658258 = validateParameter(valid_402658258, JString,
                                      required = false, default = nil)
  if valid_402658258 != nil:
    section.add "X-Amz-Date", valid_402658258
  var valid_402658259 = header.getOrDefault("X-Amz-Credential")
  valid_402658259 = validateParameter(valid_402658259, JString,
                                      required = false, default = nil)
  if valid_402658259 != nil:
    section.add "X-Amz-Credential", valid_402658259
  var valid_402658260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658260 = validateParameter(valid_402658260, JString,
                                      required = false, default = nil)
  if valid_402658260 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658262: Call_StopCompilationJob_402658250;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
                                                                                         ## 
  let valid = call_402658262.validator(path, query, header, formData, body, _)
  let scheme = call_402658262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658262.makeUrl(scheme.get, call_402658262.host, call_402658262.base,
                                   call_402658262.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658262, uri, valid, _)

proc call*(call_402658263: Call_StopCompilationJob_402658250; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402658264 = newJObject()
  if body != nil:
    body_402658264 = body
  result = call_402658263.call(nil, nil, nil, nil, body_402658264)

var stopCompilationJob* = Call_StopCompilationJob_402658250(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_402658251, base: "/",
    makeUrl: url_StopCompilationJob_402658252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_402658265 = ref object of OpenApiRestCall_402656044
proc url_StopHyperParameterTuningJob_402658267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopHyperParameterTuningJob_402658266(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658268 = header.getOrDefault("X-Amz-Target")
  valid_402658268 = validateParameter(valid_402658268, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_402658268 != nil:
    section.add "X-Amz-Target", valid_402658268
  var valid_402658269 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658269 = validateParameter(valid_402658269, JString,
                                      required = false, default = nil)
  if valid_402658269 != nil:
    section.add "X-Amz-Security-Token", valid_402658269
  var valid_402658270 = header.getOrDefault("X-Amz-Signature")
  valid_402658270 = validateParameter(valid_402658270, JString,
                                      required = false, default = nil)
  if valid_402658270 != nil:
    section.add "X-Amz-Signature", valid_402658270
  var valid_402658271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658271 = validateParameter(valid_402658271, JString,
                                      required = false, default = nil)
  if valid_402658271 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658271
  var valid_402658272 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658272 = validateParameter(valid_402658272, JString,
                                      required = false, default = nil)
  if valid_402658272 != nil:
    section.add "X-Amz-Algorithm", valid_402658272
  var valid_402658273 = header.getOrDefault("X-Amz-Date")
  valid_402658273 = validateParameter(valid_402658273, JString,
                                      required = false, default = nil)
  if valid_402658273 != nil:
    section.add "X-Amz-Date", valid_402658273
  var valid_402658274 = header.getOrDefault("X-Amz-Credential")
  valid_402658274 = validateParameter(valid_402658274, JString,
                                      required = false, default = nil)
  if valid_402658274 != nil:
    section.add "X-Amz-Credential", valid_402658274
  var valid_402658275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658275 = validateParameter(valid_402658275, JString,
                                      required = false, default = nil)
  if valid_402658275 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658277: Call_StopHyperParameterTuningJob_402658265;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
                                                                                         ## 
  let valid = call_402658277.validator(path, query, header, formData, body, _)
  let scheme = call_402658277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658277.makeUrl(scheme.get, call_402658277.host, call_402658277.base,
                                   call_402658277.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658277, uri, valid, _)

proc call*(call_402658278: Call_StopHyperParameterTuningJob_402658265;
           body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402658279 = newJObject()
  if body != nil:
    body_402658279 = body
  result = call_402658278.call(nil, nil, nil, nil, body_402658279)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_402658265(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_402658266, base: "/",
    makeUrl: url_StopHyperParameterTuningJob_402658267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_402658280 = ref object of OpenApiRestCall_402656044
proc url_StopLabelingJob_402658282(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLabelingJob_402658281(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658283 = header.getOrDefault("X-Amz-Target")
  valid_402658283 = validateParameter(valid_402658283, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_402658283 != nil:
    section.add "X-Amz-Target", valid_402658283
  var valid_402658284 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658284 = validateParameter(valid_402658284, JString,
                                      required = false, default = nil)
  if valid_402658284 != nil:
    section.add "X-Amz-Security-Token", valid_402658284
  var valid_402658285 = header.getOrDefault("X-Amz-Signature")
  valid_402658285 = validateParameter(valid_402658285, JString,
                                      required = false, default = nil)
  if valid_402658285 != nil:
    section.add "X-Amz-Signature", valid_402658285
  var valid_402658286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658286 = validateParameter(valid_402658286, JString,
                                      required = false, default = nil)
  if valid_402658286 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658286
  var valid_402658287 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658287 = validateParameter(valid_402658287, JString,
                                      required = false, default = nil)
  if valid_402658287 != nil:
    section.add "X-Amz-Algorithm", valid_402658287
  var valid_402658288 = header.getOrDefault("X-Amz-Date")
  valid_402658288 = validateParameter(valid_402658288, JString,
                                      required = false, default = nil)
  if valid_402658288 != nil:
    section.add "X-Amz-Date", valid_402658288
  var valid_402658289 = header.getOrDefault("X-Amz-Credential")
  valid_402658289 = validateParameter(valid_402658289, JString,
                                      required = false, default = nil)
  if valid_402658289 != nil:
    section.add "X-Amz-Credential", valid_402658289
  var valid_402658290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658290 = validateParameter(valid_402658290, JString,
                                      required = false, default = nil)
  if valid_402658290 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658292: Call_StopLabelingJob_402658280; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
                                                                                         ## 
  let valid = call_402658292.validator(path, query, header, formData, body, _)
  let scheme = call_402658292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658292.makeUrl(scheme.get, call_402658292.host, call_402658292.base,
                                   call_402658292.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658292, uri, valid, _)

proc call*(call_402658293: Call_StopLabelingJob_402658280; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   
                                                                                                                                                                       ## body: JObject (required)
  var body_402658294 = newJObject()
  if body != nil:
    body_402658294 = body
  result = call_402658293.call(nil, nil, nil, nil, body_402658294)

var stopLabelingJob* = Call_StopLabelingJob_402658280(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_402658281, base: "/",
    makeUrl: url_StopLabelingJob_402658282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_402658295 = ref object of OpenApiRestCall_402656044
proc url_StopMonitoringSchedule_402658297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopMonitoringSchedule_402658296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658298 = header.getOrDefault("X-Amz-Target")
  valid_402658298 = validateParameter(valid_402658298, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_402658298 != nil:
    section.add "X-Amz-Target", valid_402658298
  var valid_402658299 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658299 = validateParameter(valid_402658299, JString,
                                      required = false, default = nil)
  if valid_402658299 != nil:
    section.add "X-Amz-Security-Token", valid_402658299
  var valid_402658300 = header.getOrDefault("X-Amz-Signature")
  valid_402658300 = validateParameter(valid_402658300, JString,
                                      required = false, default = nil)
  if valid_402658300 != nil:
    section.add "X-Amz-Signature", valid_402658300
  var valid_402658301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658301 = validateParameter(valid_402658301, JString,
                                      required = false, default = nil)
  if valid_402658301 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658301
  var valid_402658302 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658302 = validateParameter(valid_402658302, JString,
                                      required = false, default = nil)
  if valid_402658302 != nil:
    section.add "X-Amz-Algorithm", valid_402658302
  var valid_402658303 = header.getOrDefault("X-Amz-Date")
  valid_402658303 = validateParameter(valid_402658303, JString,
                                      required = false, default = nil)
  if valid_402658303 != nil:
    section.add "X-Amz-Date", valid_402658303
  var valid_402658304 = header.getOrDefault("X-Amz-Credential")
  valid_402658304 = validateParameter(valid_402658304, JString,
                                      required = false, default = nil)
  if valid_402658304 != nil:
    section.add "X-Amz-Credential", valid_402658304
  var valid_402658305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658305 = validateParameter(valid_402658305, JString,
                                      required = false, default = nil)
  if valid_402658305 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658307: Call_StopMonitoringSchedule_402658295;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a previously started monitoring schedule.
                                                                                         ## 
  let valid = call_402658307.validator(path, query, header, formData, body, _)
  let scheme = call_402658307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658307.makeUrl(scheme.get, call_402658307.host, call_402658307.base,
                                   call_402658307.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658307, uri, valid, _)

proc call*(call_402658308: Call_StopMonitoringSchedule_402658295; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_402658309 = newJObject()
  if body != nil:
    body_402658309 = body
  result = call_402658308.call(nil, nil, nil, nil, body_402658309)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_402658295(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_402658296, base: "/",
    makeUrl: url_StopMonitoringSchedule_402658297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_402658310 = ref object of OpenApiRestCall_402656044
proc url_StopNotebookInstance_402658312(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopNotebookInstance_402658311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658313 = header.getOrDefault("X-Amz-Target")
  valid_402658313 = validateParameter(valid_402658313, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_402658313 != nil:
    section.add "X-Amz-Target", valid_402658313
  var valid_402658314 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658314 = validateParameter(valid_402658314, JString,
                                      required = false, default = nil)
  if valid_402658314 != nil:
    section.add "X-Amz-Security-Token", valid_402658314
  var valid_402658315 = header.getOrDefault("X-Amz-Signature")
  valid_402658315 = validateParameter(valid_402658315, JString,
                                      required = false, default = nil)
  if valid_402658315 != nil:
    section.add "X-Amz-Signature", valid_402658315
  var valid_402658316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658316 = validateParameter(valid_402658316, JString,
                                      required = false, default = nil)
  if valid_402658316 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658316
  var valid_402658317 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658317 = validateParameter(valid_402658317, JString,
                                      required = false, default = nil)
  if valid_402658317 != nil:
    section.add "X-Amz-Algorithm", valid_402658317
  var valid_402658318 = header.getOrDefault("X-Amz-Date")
  valid_402658318 = validateParameter(valid_402658318, JString,
                                      required = false, default = nil)
  if valid_402658318 != nil:
    section.add "X-Amz-Date", valid_402658318
  var valid_402658319 = header.getOrDefault("X-Amz-Credential")
  valid_402658319 = validateParameter(valid_402658319, JString,
                                      required = false, default = nil)
  if valid_402658319 != nil:
    section.add "X-Amz-Credential", valid_402658319
  var valid_402658320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658320 = validateParameter(valid_402658320, JString,
                                      required = false, default = nil)
  if valid_402658320 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658322: Call_StopNotebookInstance_402658310;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
                                                                                         ## 
  let valid = call_402658322.validator(path, query, header, formData, body, _)
  let scheme = call_402658322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658322.makeUrl(scheme.get, call_402658322.host, call_402658322.base,
                                   call_402658322.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658322, uri, valid, _)

proc call*(call_402658323: Call_StopNotebookInstance_402658310; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402658324 = newJObject()
  if body != nil:
    body_402658324 = body
  result = call_402658323.call(nil, nil, nil, nil, body_402658324)

var stopNotebookInstance* = Call_StopNotebookInstance_402658310(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_402658311, base: "/",
    makeUrl: url_StopNotebookInstance_402658312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_402658325 = ref object of OpenApiRestCall_402656044
proc url_StopProcessingJob_402658327(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopProcessingJob_402658326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658328 = header.getOrDefault("X-Amz-Target")
  valid_402658328 = validateParameter(valid_402658328, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_402658328 != nil:
    section.add "X-Amz-Target", valid_402658328
  var valid_402658329 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658329 = validateParameter(valid_402658329, JString,
                                      required = false, default = nil)
  if valid_402658329 != nil:
    section.add "X-Amz-Security-Token", valid_402658329
  var valid_402658330 = header.getOrDefault("X-Amz-Signature")
  valid_402658330 = validateParameter(valid_402658330, JString,
                                      required = false, default = nil)
  if valid_402658330 != nil:
    section.add "X-Amz-Signature", valid_402658330
  var valid_402658331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658331 = validateParameter(valid_402658331, JString,
                                      required = false, default = nil)
  if valid_402658331 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658331
  var valid_402658332 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658332 = validateParameter(valid_402658332, JString,
                                      required = false, default = nil)
  if valid_402658332 != nil:
    section.add "X-Amz-Algorithm", valid_402658332
  var valid_402658333 = header.getOrDefault("X-Amz-Date")
  valid_402658333 = validateParameter(valid_402658333, JString,
                                      required = false, default = nil)
  if valid_402658333 != nil:
    section.add "X-Amz-Date", valid_402658333
  var valid_402658334 = header.getOrDefault("X-Amz-Credential")
  valid_402658334 = validateParameter(valid_402658334, JString,
                                      required = false, default = nil)
  if valid_402658334 != nil:
    section.add "X-Amz-Credential", valid_402658334
  var valid_402658335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658335 = validateParameter(valid_402658335, JString,
                                      required = false, default = nil)
  if valid_402658335 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658337: Call_StopProcessingJob_402658325;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a processing job.
                                                                                         ## 
  let valid = call_402658337.validator(path, query, header, formData, body, _)
  let scheme = call_402658337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658337.makeUrl(scheme.get, call_402658337.host, call_402658337.base,
                                   call_402658337.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658337, uri, valid, _)

proc call*(call_402658338: Call_StopProcessingJob_402658325; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_402658339 = newJObject()
  if body != nil:
    body_402658339 = body
  result = call_402658338.call(nil, nil, nil, nil, body_402658339)

var stopProcessingJob* = Call_StopProcessingJob_402658325(
    name: "stopProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_402658326, base: "/",
    makeUrl: url_StopProcessingJob_402658327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_402658340 = ref object of OpenApiRestCall_402656044
proc url_StopTrainingJob_402658342(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingJob_402658341(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658343 = header.getOrDefault("X-Amz-Target")
  valid_402658343 = validateParameter(valid_402658343, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_402658343 != nil:
    section.add "X-Amz-Target", valid_402658343
  var valid_402658344 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658344 = validateParameter(valid_402658344, JString,
                                      required = false, default = nil)
  if valid_402658344 != nil:
    section.add "X-Amz-Security-Token", valid_402658344
  var valid_402658345 = header.getOrDefault("X-Amz-Signature")
  valid_402658345 = validateParameter(valid_402658345, JString,
                                      required = false, default = nil)
  if valid_402658345 != nil:
    section.add "X-Amz-Signature", valid_402658345
  var valid_402658346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658346 = validateParameter(valid_402658346, JString,
                                      required = false, default = nil)
  if valid_402658346 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658346
  var valid_402658347 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658347 = validateParameter(valid_402658347, JString,
                                      required = false, default = nil)
  if valid_402658347 != nil:
    section.add "X-Amz-Algorithm", valid_402658347
  var valid_402658348 = header.getOrDefault("X-Amz-Date")
  valid_402658348 = validateParameter(valid_402658348, JString,
                                      required = false, default = nil)
  if valid_402658348 != nil:
    section.add "X-Amz-Date", valid_402658348
  var valid_402658349 = header.getOrDefault("X-Amz-Credential")
  valid_402658349 = validateParameter(valid_402658349, JString,
                                      required = false, default = nil)
  if valid_402658349 != nil:
    section.add "X-Amz-Credential", valid_402658349
  var valid_402658350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658350 = validateParameter(valid_402658350, JString,
                                      required = false, default = nil)
  if valid_402658350 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658352: Call_StopTrainingJob_402658340; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
                                                                                         ## 
  let valid = call_402658352.validator(path, query, header, formData, body, _)
  let scheme = call_402658352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658352.makeUrl(scheme.get, call_402658352.host, call_402658352.base,
                                   call_402658352.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658352, uri, valid, _)

proc call*(call_402658353: Call_StopTrainingJob_402658340; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402658354 = newJObject()
  if body != nil:
    body_402658354 = body
  result = call_402658353.call(nil, nil, nil, nil, body_402658354)

var stopTrainingJob* = Call_StopTrainingJob_402658340(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_402658341, base: "/",
    makeUrl: url_StopTrainingJob_402658342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_402658355 = ref object of OpenApiRestCall_402656044
proc url_StopTransformJob_402658357(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTransformJob_402658356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658358 = header.getOrDefault("X-Amz-Target")
  valid_402658358 = validateParameter(valid_402658358, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_402658358 != nil:
    section.add "X-Amz-Target", valid_402658358
  var valid_402658359 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658359 = validateParameter(valid_402658359, JString,
                                      required = false, default = nil)
  if valid_402658359 != nil:
    section.add "X-Amz-Security-Token", valid_402658359
  var valid_402658360 = header.getOrDefault("X-Amz-Signature")
  valid_402658360 = validateParameter(valid_402658360, JString,
                                      required = false, default = nil)
  if valid_402658360 != nil:
    section.add "X-Amz-Signature", valid_402658360
  var valid_402658361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658361 = validateParameter(valid_402658361, JString,
                                      required = false, default = nil)
  if valid_402658361 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658361
  var valid_402658362 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658362 = validateParameter(valid_402658362, JString,
                                      required = false, default = nil)
  if valid_402658362 != nil:
    section.add "X-Amz-Algorithm", valid_402658362
  var valid_402658363 = header.getOrDefault("X-Amz-Date")
  valid_402658363 = validateParameter(valid_402658363, JString,
                                      required = false, default = nil)
  if valid_402658363 != nil:
    section.add "X-Amz-Date", valid_402658363
  var valid_402658364 = header.getOrDefault("X-Amz-Credential")
  valid_402658364 = validateParameter(valid_402658364, JString,
                                      required = false, default = nil)
  if valid_402658364 != nil:
    section.add "X-Amz-Credential", valid_402658364
  var valid_402658365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658365 = validateParameter(valid_402658365, JString,
                                      required = false, default = nil)
  if valid_402658365 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658367: Call_StopTransformJob_402658355;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
                                                                                         ## 
  let valid = call_402658367.validator(path, query, header, formData, body, _)
  let scheme = call_402658367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658367.makeUrl(scheme.get, call_402658367.host, call_402658367.base,
                                   call_402658367.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658367, uri, valid, _)

proc call*(call_402658368: Call_StopTransformJob_402658355; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402658369 = newJObject()
  if body != nil:
    body_402658369 = body
  result = call_402658368.call(nil, nil, nil, nil, body_402658369)

var stopTransformJob* = Call_StopTransformJob_402658355(
    name: "stopTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_402658356, base: "/",
    makeUrl: url_StopTransformJob_402658357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_402658370 = ref object of OpenApiRestCall_402656044
proc url_UpdateCodeRepository_402658372(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCodeRepository_402658371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658373 = header.getOrDefault("X-Amz-Target")
  valid_402658373 = validateParameter(valid_402658373, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_402658373 != nil:
    section.add "X-Amz-Target", valid_402658373
  var valid_402658374 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658374 = validateParameter(valid_402658374, JString,
                                      required = false, default = nil)
  if valid_402658374 != nil:
    section.add "X-Amz-Security-Token", valid_402658374
  var valid_402658375 = header.getOrDefault("X-Amz-Signature")
  valid_402658375 = validateParameter(valid_402658375, JString,
                                      required = false, default = nil)
  if valid_402658375 != nil:
    section.add "X-Amz-Signature", valid_402658375
  var valid_402658376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658376 = validateParameter(valid_402658376, JString,
                                      required = false, default = nil)
  if valid_402658376 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658376
  var valid_402658377 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658377 = validateParameter(valid_402658377, JString,
                                      required = false, default = nil)
  if valid_402658377 != nil:
    section.add "X-Amz-Algorithm", valid_402658377
  var valid_402658378 = header.getOrDefault("X-Amz-Date")
  valid_402658378 = validateParameter(valid_402658378, JString,
                                      required = false, default = nil)
  if valid_402658378 != nil:
    section.add "X-Amz-Date", valid_402658378
  var valid_402658379 = header.getOrDefault("X-Amz-Credential")
  valid_402658379 = validateParameter(valid_402658379, JString,
                                      required = false, default = nil)
  if valid_402658379 != nil:
    section.add "X-Amz-Credential", valid_402658379
  var valid_402658380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658380 = validateParameter(valid_402658380, JString,
                                      required = false, default = nil)
  if valid_402658380 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658382: Call_UpdateCodeRepository_402658370;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified Git repository with the specified values.
                                                                                         ## 
  let valid = call_402658382.validator(path, query, header, formData, body, _)
  let scheme = call_402658382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658382.makeUrl(scheme.get, call_402658382.host, call_402658382.base,
                                   call_402658382.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658382, uri, valid, _)

proc call*(call_402658383: Call_UpdateCodeRepository_402658370; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_402658384 = newJObject()
  if body != nil:
    body_402658384 = body
  result = call_402658383.call(nil, nil, nil, nil, body_402658384)

var updateCodeRepository* = Call_UpdateCodeRepository_402658370(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_402658371, base: "/",
    makeUrl: url_UpdateCodeRepository_402658372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_402658385 = ref object of OpenApiRestCall_402656044
proc url_UpdateDomain_402658387(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomain_402658386(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658388 = header.getOrDefault("X-Amz-Target")
  valid_402658388 = validateParameter(valid_402658388, JString, required = true, default = newJString(
      "SageMaker.UpdateDomain"))
  if valid_402658388 != nil:
    section.add "X-Amz-Target", valid_402658388
  var valid_402658389 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658389 = validateParameter(valid_402658389, JString,
                                      required = false, default = nil)
  if valid_402658389 != nil:
    section.add "X-Amz-Security-Token", valid_402658389
  var valid_402658390 = header.getOrDefault("X-Amz-Signature")
  valid_402658390 = validateParameter(valid_402658390, JString,
                                      required = false, default = nil)
  if valid_402658390 != nil:
    section.add "X-Amz-Signature", valid_402658390
  var valid_402658391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658391 = validateParameter(valid_402658391, JString,
                                      required = false, default = nil)
  if valid_402658391 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658391
  var valid_402658392 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658392 = validateParameter(valid_402658392, JString,
                                      required = false, default = nil)
  if valid_402658392 != nil:
    section.add "X-Amz-Algorithm", valid_402658392
  var valid_402658393 = header.getOrDefault("X-Amz-Date")
  valid_402658393 = validateParameter(valid_402658393, JString,
                                      required = false, default = nil)
  if valid_402658393 != nil:
    section.add "X-Amz-Date", valid_402658393
  var valid_402658394 = header.getOrDefault("X-Amz-Credential")
  valid_402658394 = validateParameter(valid_402658394, JString,
                                      required = false, default = nil)
  if valid_402658394 != nil:
    section.add "X-Amz-Credential", valid_402658394
  var valid_402658395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658395 = validateParameter(valid_402658395, JString,
                                      required = false, default = nil)
  if valid_402658395 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658397: Call_UpdateDomain_402658385; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
                                                                                         ## 
  let valid = call_402658397.validator(path, query, header, formData, body, _)
  let scheme = call_402658397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658397.makeUrl(scheme.get, call_402658397.host, call_402658397.base,
                                   call_402658397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658397, uri, valid, _)

proc call*(call_402658398: Call_UpdateDomain_402658385; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: 
                                                                           ## JObject (required)
  var body_402658399 = newJObject()
  if body != nil:
    body_402658399 = body
  result = call_402658398.call(nil, nil, nil, nil, body_402658399)

var updateDomain* = Call_UpdateDomain_402658385(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_402658386, base: "/",
    makeUrl: url_UpdateDomain_402658387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_402658400 = ref object of OpenApiRestCall_402656044
proc url_UpdateEndpoint_402658402(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_402658401(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658403 = header.getOrDefault("X-Amz-Target")
  valid_402658403 = validateParameter(valid_402658403, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_402658403 != nil:
    section.add "X-Amz-Target", valid_402658403
  var valid_402658404 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658404 = validateParameter(valid_402658404, JString,
                                      required = false, default = nil)
  if valid_402658404 != nil:
    section.add "X-Amz-Security-Token", valid_402658404
  var valid_402658405 = header.getOrDefault("X-Amz-Signature")
  valid_402658405 = validateParameter(valid_402658405, JString,
                                      required = false, default = nil)
  if valid_402658405 != nil:
    section.add "X-Amz-Signature", valid_402658405
  var valid_402658406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658406 = validateParameter(valid_402658406, JString,
                                      required = false, default = nil)
  if valid_402658406 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658406
  var valid_402658407 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658407 = validateParameter(valid_402658407, JString,
                                      required = false, default = nil)
  if valid_402658407 != nil:
    section.add "X-Amz-Algorithm", valid_402658407
  var valid_402658408 = header.getOrDefault("X-Amz-Date")
  valid_402658408 = validateParameter(valid_402658408, JString,
                                      required = false, default = nil)
  if valid_402658408 != nil:
    section.add "X-Amz-Date", valid_402658408
  var valid_402658409 = header.getOrDefault("X-Amz-Credential")
  valid_402658409 = validateParameter(valid_402658409, JString,
                                      required = false, default = nil)
  if valid_402658409 != nil:
    section.add "X-Amz-Credential", valid_402658409
  var valid_402658410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658410 = validateParameter(valid_402658410, JString,
                                      required = false, default = nil)
  if valid_402658410 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658412: Call_UpdateEndpoint_402658400; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
                                                                                         ## 
  let valid = call_402658412.validator(path, query, header, formData, body, _)
  let scheme = call_402658412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658412.makeUrl(scheme.get, call_402658412.host, call_402658412.base,
                                   call_402658412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658412, uri, valid, _)

proc call*(call_402658413: Call_UpdateEndpoint_402658400; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402658414 = newJObject()
  if body != nil:
    body_402658414 = body
  result = call_402658413.call(nil, nil, nil, nil, body_402658414)

var updateEndpoint* = Call_UpdateEndpoint_402658400(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_402658401, base: "/",
    makeUrl: url_UpdateEndpoint_402658402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_402658415 = ref object of OpenApiRestCall_402656044
proc url_UpdateEndpointWeightsAndCapacities_402658417(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpointWeightsAndCapacities_402658416(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658418 = header.getOrDefault("X-Amz-Target")
  valid_402658418 = validateParameter(valid_402658418, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_402658418 != nil:
    section.add "X-Amz-Target", valid_402658418
  var valid_402658419 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658419 = validateParameter(valid_402658419, JString,
                                      required = false, default = nil)
  if valid_402658419 != nil:
    section.add "X-Amz-Security-Token", valid_402658419
  var valid_402658420 = header.getOrDefault("X-Amz-Signature")
  valid_402658420 = validateParameter(valid_402658420, JString,
                                      required = false, default = nil)
  if valid_402658420 != nil:
    section.add "X-Amz-Signature", valid_402658420
  var valid_402658421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658421 = validateParameter(valid_402658421, JString,
                                      required = false, default = nil)
  if valid_402658421 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658421
  var valid_402658422 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658422 = validateParameter(valid_402658422, JString,
                                      required = false, default = nil)
  if valid_402658422 != nil:
    section.add "X-Amz-Algorithm", valid_402658422
  var valid_402658423 = header.getOrDefault("X-Amz-Date")
  valid_402658423 = validateParameter(valid_402658423, JString,
                                      required = false, default = nil)
  if valid_402658423 != nil:
    section.add "X-Amz-Date", valid_402658423
  var valid_402658424 = header.getOrDefault("X-Amz-Credential")
  valid_402658424 = validateParameter(valid_402658424, JString,
                                      required = false, default = nil)
  if valid_402658424 != nil:
    section.add "X-Amz-Credential", valid_402658424
  var valid_402658425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658425 = validateParameter(valid_402658425, JString,
                                      required = false, default = nil)
  if valid_402658425 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658427: Call_UpdateEndpointWeightsAndCapacities_402658415;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
                                                                                         ## 
  let valid = call_402658427.validator(path, query, header, formData, body, _)
  let scheme = call_402658427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658427.makeUrl(scheme.get, call_402658427.host, call_402658427.base,
                                   call_402658427.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658427, uri, valid, _)

proc call*(call_402658428: Call_UpdateEndpointWeightsAndCapacities_402658415;
           body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402658429 = newJObject()
  if body != nil:
    body_402658429 = body
  result = call_402658428.call(nil, nil, nil, nil, body_402658429)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_402658415(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_402658416, base: "/",
    makeUrl: url_UpdateEndpointWeightsAndCapacities_402658417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_402658430 = ref object of OpenApiRestCall_402656044
proc url_UpdateExperiment_402658432(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateExperiment_402658431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658433 = header.getOrDefault("X-Amz-Target")
  valid_402658433 = validateParameter(valid_402658433, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_402658433 != nil:
    section.add "X-Amz-Target", valid_402658433
  var valid_402658434 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658434 = validateParameter(valid_402658434, JString,
                                      required = false, default = nil)
  if valid_402658434 != nil:
    section.add "X-Amz-Security-Token", valid_402658434
  var valid_402658435 = header.getOrDefault("X-Amz-Signature")
  valid_402658435 = validateParameter(valid_402658435, JString,
                                      required = false, default = nil)
  if valid_402658435 != nil:
    section.add "X-Amz-Signature", valid_402658435
  var valid_402658436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658436 = validateParameter(valid_402658436, JString,
                                      required = false, default = nil)
  if valid_402658436 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658436
  var valid_402658437 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658437 = validateParameter(valid_402658437, JString,
                                      required = false, default = nil)
  if valid_402658437 != nil:
    section.add "X-Amz-Algorithm", valid_402658437
  var valid_402658438 = header.getOrDefault("X-Amz-Date")
  valid_402658438 = validateParameter(valid_402658438, JString,
                                      required = false, default = nil)
  if valid_402658438 != nil:
    section.add "X-Amz-Date", valid_402658438
  var valid_402658439 = header.getOrDefault("X-Amz-Credential")
  valid_402658439 = validateParameter(valid_402658439, JString,
                                      required = false, default = nil)
  if valid_402658439 != nil:
    section.add "X-Amz-Credential", valid_402658439
  var valid_402658440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658440 = validateParameter(valid_402658440, JString,
                                      required = false, default = nil)
  if valid_402658440 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658442: Call_UpdateExperiment_402658430;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
                                                                                         ## 
  let valid = call_402658442.validator(path, query, header, formData, body, _)
  let scheme = call_402658442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658442.makeUrl(scheme.get, call_402658442.host, call_402658442.base,
                                   call_402658442.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658442, uri, valid, _)

proc call*(call_402658443: Call_UpdateExperiment_402658430; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   
                                                                                                           ## body: JObject (required)
  var body_402658444 = newJObject()
  if body != nil:
    body_402658444 = body
  result = call_402658443.call(nil, nil, nil, nil, body_402658444)

var updateExperiment* = Call_UpdateExperiment_402658430(
    name: "updateExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_402658431, base: "/",
    makeUrl: url_UpdateExperiment_402658432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_402658445 = ref object of OpenApiRestCall_402656044
proc url_UpdateMonitoringSchedule_402658447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMonitoringSchedule_402658446(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658448 = header.getOrDefault("X-Amz-Target")
  valid_402658448 = validateParameter(valid_402658448, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_402658448 != nil:
    section.add "X-Amz-Target", valid_402658448
  var valid_402658449 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658449 = validateParameter(valid_402658449, JString,
                                      required = false, default = nil)
  if valid_402658449 != nil:
    section.add "X-Amz-Security-Token", valid_402658449
  var valid_402658450 = header.getOrDefault("X-Amz-Signature")
  valid_402658450 = validateParameter(valid_402658450, JString,
                                      required = false, default = nil)
  if valid_402658450 != nil:
    section.add "X-Amz-Signature", valid_402658450
  var valid_402658451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658451 = validateParameter(valid_402658451, JString,
                                      required = false, default = nil)
  if valid_402658451 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658451
  var valid_402658452 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658452 = validateParameter(valid_402658452, JString,
                                      required = false, default = nil)
  if valid_402658452 != nil:
    section.add "X-Amz-Algorithm", valid_402658452
  var valid_402658453 = header.getOrDefault("X-Amz-Date")
  valid_402658453 = validateParameter(valid_402658453, JString,
                                      required = false, default = nil)
  if valid_402658453 != nil:
    section.add "X-Amz-Date", valid_402658453
  var valid_402658454 = header.getOrDefault("X-Amz-Credential")
  valid_402658454 = validateParameter(valid_402658454, JString,
                                      required = false, default = nil)
  if valid_402658454 != nil:
    section.add "X-Amz-Credential", valid_402658454
  var valid_402658455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658455 = validateParameter(valid_402658455, JString,
                                      required = false, default = nil)
  if valid_402658455 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658457: Call_UpdateMonitoringSchedule_402658445;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a previously created schedule.
                                                                                         ## 
  let valid = call_402658457.validator(path, query, header, formData, body, _)
  let scheme = call_402658457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658457.makeUrl(scheme.get, call_402658457.host, call_402658457.base,
                                   call_402658457.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658457, uri, valid, _)

proc call*(call_402658458: Call_UpdateMonitoringSchedule_402658445;
           body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_402658459 = newJObject()
  if body != nil:
    body_402658459 = body
  result = call_402658458.call(nil, nil, nil, nil, body_402658459)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_402658445(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_402658446, base: "/",
    makeUrl: url_UpdateMonitoringSchedule_402658447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_402658460 = ref object of OpenApiRestCall_402656044
proc url_UpdateNotebookInstance_402658462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstance_402658461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658463 = header.getOrDefault("X-Amz-Target")
  valid_402658463 = validateParameter(valid_402658463, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_402658463 != nil:
    section.add "X-Amz-Target", valid_402658463
  var valid_402658464 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658464 = validateParameter(valid_402658464, JString,
                                      required = false, default = nil)
  if valid_402658464 != nil:
    section.add "X-Amz-Security-Token", valid_402658464
  var valid_402658465 = header.getOrDefault("X-Amz-Signature")
  valid_402658465 = validateParameter(valid_402658465, JString,
                                      required = false, default = nil)
  if valid_402658465 != nil:
    section.add "X-Amz-Signature", valid_402658465
  var valid_402658466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658466 = validateParameter(valid_402658466, JString,
                                      required = false, default = nil)
  if valid_402658466 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658466
  var valid_402658467 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658467 = validateParameter(valid_402658467, JString,
                                      required = false, default = nil)
  if valid_402658467 != nil:
    section.add "X-Amz-Algorithm", valid_402658467
  var valid_402658468 = header.getOrDefault("X-Amz-Date")
  valid_402658468 = validateParameter(valid_402658468, JString,
                                      required = false, default = nil)
  if valid_402658468 != nil:
    section.add "X-Amz-Date", valid_402658468
  var valid_402658469 = header.getOrDefault("X-Amz-Credential")
  valid_402658469 = validateParameter(valid_402658469, JString,
                                      required = false, default = nil)
  if valid_402658469 != nil:
    section.add "X-Amz-Credential", valid_402658469
  var valid_402658470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658470 = validateParameter(valid_402658470, JString,
                                      required = false, default = nil)
  if valid_402658470 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658472: Call_UpdateNotebookInstance_402658460;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
                                                                                         ## 
  let valid = call_402658472.validator(path, query, header, formData, body, _)
  let scheme = call_402658472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658472.makeUrl(scheme.get, call_402658472.host, call_402658472.base,
                                   call_402658472.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658472, uri, valid, _)

proc call*(call_402658473: Call_UpdateNotebookInstance_402658460; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  var body_402658474 = newJObject()
  if body != nil:
    body_402658474 = body
  result = call_402658473.call(nil, nil, nil, nil, body_402658474)

var updateNotebookInstance* = Call_UpdateNotebookInstance_402658460(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_402658461, base: "/",
    makeUrl: url_UpdateNotebookInstance_402658462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_402658475 = ref object of OpenApiRestCall_402656044
proc url_UpdateNotebookInstanceLifecycleConfig_402658477(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_402658476(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658478 = header.getOrDefault("X-Amz-Target")
  valid_402658478 = validateParameter(valid_402658478, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_402658478 != nil:
    section.add "X-Amz-Target", valid_402658478
  var valid_402658479 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658479 = validateParameter(valid_402658479, JString,
                                      required = false, default = nil)
  if valid_402658479 != nil:
    section.add "X-Amz-Security-Token", valid_402658479
  var valid_402658480 = header.getOrDefault("X-Amz-Signature")
  valid_402658480 = validateParameter(valid_402658480, JString,
                                      required = false, default = nil)
  if valid_402658480 != nil:
    section.add "X-Amz-Signature", valid_402658480
  var valid_402658481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658481 = validateParameter(valid_402658481, JString,
                                      required = false, default = nil)
  if valid_402658481 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658481
  var valid_402658482 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658482 = validateParameter(valid_402658482, JString,
                                      required = false, default = nil)
  if valid_402658482 != nil:
    section.add "X-Amz-Algorithm", valid_402658482
  var valid_402658483 = header.getOrDefault("X-Amz-Date")
  valid_402658483 = validateParameter(valid_402658483, JString,
                                      required = false, default = nil)
  if valid_402658483 != nil:
    section.add "X-Amz-Date", valid_402658483
  var valid_402658484 = header.getOrDefault("X-Amz-Credential")
  valid_402658484 = validateParameter(valid_402658484, JString,
                                      required = false, default = nil)
  if valid_402658484 != nil:
    section.add "X-Amz-Credential", valid_402658484
  var valid_402658485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658485 = validateParameter(valid_402658485, JString,
                                      required = false, default = nil)
  if valid_402658485 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658487: Call_UpdateNotebookInstanceLifecycleConfig_402658475;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
                                                                                         ## 
  let valid = call_402658487.validator(path, query, header, formData, body, _)
  let scheme = call_402658487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658487.makeUrl(scheme.get, call_402658487.host, call_402658487.base,
                                   call_402658487.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658487, uri, valid, _)

proc call*(call_402658488: Call_UpdateNotebookInstanceLifecycleConfig_402658475;
           body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   
                                                                                                                           ## body: JObject (required)
  var body_402658489 = newJObject()
  if body != nil:
    body_402658489 = body
  result = call_402658488.call(nil, nil, nil, nil, body_402658489)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_402658475(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_402658476,
    base: "/", makeUrl: url_UpdateNotebookInstanceLifecycleConfig_402658477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_402658490 = ref object of OpenApiRestCall_402656044
proc url_UpdateTrial_402658492(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrial_402658491(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658493 = header.getOrDefault("X-Amz-Target")
  valid_402658493 = validateParameter(valid_402658493, JString, required = true, default = newJString(
      "SageMaker.UpdateTrial"))
  if valid_402658493 != nil:
    section.add "X-Amz-Target", valid_402658493
  var valid_402658494 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658494 = validateParameter(valid_402658494, JString,
                                      required = false, default = nil)
  if valid_402658494 != nil:
    section.add "X-Amz-Security-Token", valid_402658494
  var valid_402658495 = header.getOrDefault("X-Amz-Signature")
  valid_402658495 = validateParameter(valid_402658495, JString,
                                      required = false, default = nil)
  if valid_402658495 != nil:
    section.add "X-Amz-Signature", valid_402658495
  var valid_402658496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658496 = validateParameter(valid_402658496, JString,
                                      required = false, default = nil)
  if valid_402658496 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658496
  var valid_402658497 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658497 = validateParameter(valid_402658497, JString,
                                      required = false, default = nil)
  if valid_402658497 != nil:
    section.add "X-Amz-Algorithm", valid_402658497
  var valid_402658498 = header.getOrDefault("X-Amz-Date")
  valid_402658498 = validateParameter(valid_402658498, JString,
                                      required = false, default = nil)
  if valid_402658498 != nil:
    section.add "X-Amz-Date", valid_402658498
  var valid_402658499 = header.getOrDefault("X-Amz-Credential")
  valid_402658499 = validateParameter(valid_402658499, JString,
                                      required = false, default = nil)
  if valid_402658499 != nil:
    section.add "X-Amz-Credential", valid_402658499
  var valid_402658500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658500 = validateParameter(valid_402658500, JString,
                                      required = false, default = nil)
  if valid_402658500 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658502: Call_UpdateTrial_402658490; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the display name of a trial.
                                                                                         ## 
  let valid = call_402658502.validator(path, query, header, formData, body, _)
  let scheme = call_402658502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658502.makeUrl(scheme.get, call_402658502.host, call_402658502.base,
                                   call_402658502.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658502, uri, valid, _)

proc call*(call_402658503: Call_UpdateTrial_402658490; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_402658504 = newJObject()
  if body != nil:
    body_402658504 = body
  result = call_402658503.call(nil, nil, nil, nil, body_402658504)

var updateTrial* = Call_UpdateTrial_402658490(name: "updateTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrial",
    validator: validate_UpdateTrial_402658491, base: "/",
    makeUrl: url_UpdateTrial_402658492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_402658505 = ref object of OpenApiRestCall_402656044
proc url_UpdateTrialComponent_402658507(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrialComponent_402658506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658508 = header.getOrDefault("X-Amz-Target")
  valid_402658508 = validateParameter(valid_402658508, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_402658508 != nil:
    section.add "X-Amz-Target", valid_402658508
  var valid_402658509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658509 = validateParameter(valid_402658509, JString,
                                      required = false, default = nil)
  if valid_402658509 != nil:
    section.add "X-Amz-Security-Token", valid_402658509
  var valid_402658510 = header.getOrDefault("X-Amz-Signature")
  valid_402658510 = validateParameter(valid_402658510, JString,
                                      required = false, default = nil)
  if valid_402658510 != nil:
    section.add "X-Amz-Signature", valid_402658510
  var valid_402658511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658511 = validateParameter(valid_402658511, JString,
                                      required = false, default = nil)
  if valid_402658511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658511
  var valid_402658512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658512 = validateParameter(valid_402658512, JString,
                                      required = false, default = nil)
  if valid_402658512 != nil:
    section.add "X-Amz-Algorithm", valid_402658512
  var valid_402658513 = header.getOrDefault("X-Amz-Date")
  valid_402658513 = validateParameter(valid_402658513, JString,
                                      required = false, default = nil)
  if valid_402658513 != nil:
    section.add "X-Amz-Date", valid_402658513
  var valid_402658514 = header.getOrDefault("X-Amz-Credential")
  valid_402658514 = validateParameter(valid_402658514, JString,
                                      required = false, default = nil)
  if valid_402658514 != nil:
    section.add "X-Amz-Credential", valid_402658514
  var valid_402658515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658515 = validateParameter(valid_402658515, JString,
                                      required = false, default = nil)
  if valid_402658515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658517: Call_UpdateTrialComponent_402658505;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates one or more properties of a trial component.
                                                                                         ## 
  let valid = call_402658517.validator(path, query, header, formData, body, _)
  let scheme = call_402658517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658517.makeUrl(scheme.get, call_402658517.host, call_402658517.base,
                                   call_402658517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658517, uri, valid, _)

proc call*(call_402658518: Call_UpdateTrialComponent_402658505; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_402658519 = newJObject()
  if body != nil:
    body_402658519 = body
  result = call_402658518.call(nil, nil, nil, nil, body_402658519)

var updateTrialComponent* = Call_UpdateTrialComponent_402658505(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_402658506, base: "/",
    makeUrl: url_UpdateTrialComponent_402658507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_402658520 = ref object of OpenApiRestCall_402656044
proc url_UpdateUserProfile_402658522(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserProfile_402658521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658523 = header.getOrDefault("X-Amz-Target")
  valid_402658523 = validateParameter(valid_402658523, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_402658523 != nil:
    section.add "X-Amz-Target", valid_402658523
  var valid_402658524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658524 = validateParameter(valid_402658524, JString,
                                      required = false, default = nil)
  if valid_402658524 != nil:
    section.add "X-Amz-Security-Token", valid_402658524
  var valid_402658525 = header.getOrDefault("X-Amz-Signature")
  valid_402658525 = validateParameter(valid_402658525, JString,
                                      required = false, default = nil)
  if valid_402658525 != nil:
    section.add "X-Amz-Signature", valid_402658525
  var valid_402658526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658526 = validateParameter(valid_402658526, JString,
                                      required = false, default = nil)
  if valid_402658526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658526
  var valid_402658527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658527 = validateParameter(valid_402658527, JString,
                                      required = false, default = nil)
  if valid_402658527 != nil:
    section.add "X-Amz-Algorithm", valid_402658527
  var valid_402658528 = header.getOrDefault("X-Amz-Date")
  valid_402658528 = validateParameter(valid_402658528, JString,
                                      required = false, default = nil)
  if valid_402658528 != nil:
    section.add "X-Amz-Date", valid_402658528
  var valid_402658529 = header.getOrDefault("X-Amz-Credential")
  valid_402658529 = validateParameter(valid_402658529, JString,
                                      required = false, default = nil)
  if valid_402658529 != nil:
    section.add "X-Amz-Credential", valid_402658529
  var valid_402658530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658530 = validateParameter(valid_402658530, JString,
                                      required = false, default = nil)
  if valid_402658530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658532: Call_UpdateUserProfile_402658520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a user profile.
                                                                                         ## 
  let valid = call_402658532.validator(path, query, header, formData, body, _)
  let scheme = call_402658532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658532.makeUrl(scheme.get, call_402658532.host, call_402658532.base,
                                   call_402658532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658532, uri, valid, _)

proc call*(call_402658533: Call_UpdateUserProfile_402658520; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_402658534 = newJObject()
  if body != nil:
    body_402658534 = body
  result = call_402658533.call(nil, nil, nil, nil, body_402658534)

var updateUserProfile* = Call_UpdateUserProfile_402658520(
    name: "updateUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_402658521, base: "/",
    makeUrl: url_UpdateUserProfile_402658522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkforce_402658535 = ref object of OpenApiRestCall_402656044
proc url_UpdateWorkforce_402658537(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkforce_402658536(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658538 = header.getOrDefault("X-Amz-Target")
  valid_402658538 = validateParameter(valid_402658538, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkforce"))
  if valid_402658538 != nil:
    section.add "X-Amz-Target", valid_402658538
  var valid_402658539 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658539 = validateParameter(valid_402658539, JString,
                                      required = false, default = nil)
  if valid_402658539 != nil:
    section.add "X-Amz-Security-Token", valid_402658539
  var valid_402658540 = header.getOrDefault("X-Amz-Signature")
  valid_402658540 = validateParameter(valid_402658540, JString,
                                      required = false, default = nil)
  if valid_402658540 != nil:
    section.add "X-Amz-Signature", valid_402658540
  var valid_402658541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658541 = validateParameter(valid_402658541, JString,
                                      required = false, default = nil)
  if valid_402658541 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658541
  var valid_402658542 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658542 = validateParameter(valid_402658542, JString,
                                      required = false, default = nil)
  if valid_402658542 != nil:
    section.add "X-Amz-Algorithm", valid_402658542
  var valid_402658543 = header.getOrDefault("X-Amz-Date")
  valid_402658543 = validateParameter(valid_402658543, JString,
                                      required = false, default = nil)
  if valid_402658543 != nil:
    section.add "X-Amz-Date", valid_402658543
  var valid_402658544 = header.getOrDefault("X-Amz-Credential")
  valid_402658544 = validateParameter(valid_402658544, JString,
                                      required = false, default = nil)
  if valid_402658544 != nil:
    section.add "X-Amz-Credential", valid_402658544
  var valid_402658545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658545 = validateParameter(valid_402658545, JString,
                                      required = false, default = nil)
  if valid_402658545 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658547: Call_UpdateWorkforce_402658535; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
                                                                                         ## 
  let valid = call_402658547.validator(path, query, header, formData, body, _)
  let scheme = call_402658547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658547.makeUrl(scheme.get, call_402658547.host, call_402658547.base,
                                   call_402658547.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658547, uri, valid, _)

proc call*(call_402658548: Call_UpdateWorkforce_402658535; body: JsonNode): Recallable =
  ## updateWorkforce
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402658549 = newJObject()
  if body != nil:
    body_402658549 = body
  result = call_402658548.call(nil, nil, nil, nil, body_402658549)

var updateWorkforce* = Call_UpdateWorkforce_402658535(name: "updateWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkforce",
    validator: validate_UpdateWorkforce_402658536, base: "/",
    makeUrl: url_UpdateWorkforce_402658537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_402658550 = ref object of OpenApiRestCall_402656044
proc url_UpdateWorkteam_402658552(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkteam_402658551(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658553 = header.getOrDefault("X-Amz-Target")
  valid_402658553 = validateParameter(valid_402658553, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_402658553 != nil:
    section.add "X-Amz-Target", valid_402658553
  var valid_402658554 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658554 = validateParameter(valid_402658554, JString,
                                      required = false, default = nil)
  if valid_402658554 != nil:
    section.add "X-Amz-Security-Token", valid_402658554
  var valid_402658555 = header.getOrDefault("X-Amz-Signature")
  valid_402658555 = validateParameter(valid_402658555, JString,
                                      required = false, default = nil)
  if valid_402658555 != nil:
    section.add "X-Amz-Signature", valid_402658555
  var valid_402658556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658556 = validateParameter(valid_402658556, JString,
                                      required = false, default = nil)
  if valid_402658556 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658556
  var valid_402658557 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658557 = validateParameter(valid_402658557, JString,
                                      required = false, default = nil)
  if valid_402658557 != nil:
    section.add "X-Amz-Algorithm", valid_402658557
  var valid_402658558 = header.getOrDefault("X-Amz-Date")
  valid_402658558 = validateParameter(valid_402658558, JString,
                                      required = false, default = nil)
  if valid_402658558 != nil:
    section.add "X-Amz-Date", valid_402658558
  var valid_402658559 = header.getOrDefault("X-Amz-Credential")
  valid_402658559 = validateParameter(valid_402658559, JString,
                                      required = false, default = nil)
  if valid_402658559 != nil:
    section.add "X-Amz-Credential", valid_402658559
  var valid_402658560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658560 = validateParameter(valid_402658560, JString,
                                      required = false, default = nil)
  if valid_402658560 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658562: Call_UpdateWorkteam_402658550; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing work team with new member definitions or description.
                                                                                         ## 
  let valid = call_402658562.validator(path, query, header, formData, body, _)
  let scheme = call_402658562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658562.makeUrl(scheme.get, call_402658562.host, call_402658562.base,
                                   call_402658562.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658562, uri, valid, _)

proc call*(call_402658563: Call_UpdateWorkteam_402658550; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   
                                                                              ## body: JObject (required)
  var body_402658564 = newJObject()
  if body != nil:
    body_402658564 = body
  result = call_402658563.call(nil, nil, nil, nil, body_402658564)

var updateWorkteam* = Call_UpdateWorkteam_402658550(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_402658551, base: "/",
    makeUrl: url_UpdateWorkteam_402658552, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}