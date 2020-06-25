
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddTags_21625779 = ref object of OpenApiRestCall_21625435
proc url_AddTags_21625781(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_21625780(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = newJString("SageMaker.AddTags"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
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

proc call*(call_21625929: Call_AddTags_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AddTags_21625779; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var addTags* = Call_AddTags_21625779(name: "addTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.AddTags",
                                  validator: validate_AddTags_21625780, base: "/",
                                  makeUrl: url_AddTags_21625781,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_21626029 = ref object of OpenApiRestCall_21625435
proc url_AssociateTrialComponent_21626031(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateTrialComponent_21626030(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
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

proc call*(call_21626041: Call_AssociateTrialComponent_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_AssociateTrialComponent_21626029; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var associateTrialComponent* = Call_AssociateTrialComponent_21626029(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_21626030, base: "/",
    makeUrl: url_AssociateTrialComponent_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_21626044 = ref object of OpenApiRestCall_21625435
proc url_CreateAlgorithm_21626046(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlgorithm_21626045(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
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

proc call*(call_21626056: Call_CreateAlgorithm_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_CreateAlgorithm_21626044; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var createAlgorithm* = Call_CreateAlgorithm_21626044(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_21626045, base: "/",
    makeUrl: url_CreateAlgorithm_21626046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_21626059 = ref object of OpenApiRestCall_21625435
proc url_CreateApp_21626061(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApp_21626060(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true,
                                   default = newJString("SageMaker.CreateApp"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
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

proc call*(call_21626071: Call_CreateApp_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CreateApp_21626059; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var createApp* = Call_CreateApp_21626059(name: "createApp",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                      validator: validate_CreateApp_21626060,
                                      base: "/", makeUrl: url_CreateApp_21626061,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_21626074 = ref object of OpenApiRestCall_21625435
proc url_CreateAutoMLJob_21626076(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAutoMLJob_21626075(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
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

proc call*(call_21626086: Call_CreateAutoMLJob_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_CreateAutoMLJob_21626074; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var createAutoMLJob* = Call_CreateAutoMLJob_21626074(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_21626075, base: "/",
    makeUrl: url_CreateAutoMLJob_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_21626089 = ref object of OpenApiRestCall_21625435
proc url_CreateCodeRepository_21626091(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCodeRepository_21626090(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
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

proc call*(call_21626101: Call_CreateCodeRepository_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_CreateCodeRepository_21626089; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var createCodeRepository* = Call_CreateCodeRepository_21626089(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_21626090, base: "/",
    makeUrl: url_CreateCodeRepository_21626091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_21626104 = ref object of OpenApiRestCall_21625435
proc url_CreateCompilationJob_21626106(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCompilationJob_21626105(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_CreateCompilationJob_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CreateCompilationJob_21626104; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var createCompilationJob* = Call_CreateCompilationJob_21626104(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_21626105, base: "/",
    makeUrl: url_CreateCompilationJob_21626106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_21626119 = ref object of OpenApiRestCall_21625435
proc url_CreateDomain_21626121(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_21626120(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "SageMaker.CreateDomain"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
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

proc call*(call_21626131: Call_CreateDomain_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_CreateDomain_21626119; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var createDomain* = Call_CreateDomain_21626119(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_21626120, base: "/", makeUrl: url_CreateDomain_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateEndpoint_21626136(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_21626135(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Target")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_21626139 != nil:
    section.add "X-Amz-Target", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Algorithm", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Signature")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Signature", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Credential")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Credential", valid_21626144
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

proc call*(call_21626146: Call_CreateEndpoint_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using Amazon SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_CreateEndpoint_21626134; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using Amazon SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626148 = newJObject()
  if body != nil:
    body_21626148 = body
  result = call_21626147.call(nil, nil, nil, nil, body_21626148)

var createEndpoint* = Call_CreateEndpoint_21626134(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_21626135, base: "/",
    makeUrl: url_CreateEndpoint_21626136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_21626149 = ref object of OpenApiRestCall_21625435
proc url_CreateEndpointConfig_21626151(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpointConfig_21626150(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Target")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_21626154 != nil:
    section.add "X-Amz-Target", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_CreateEndpointConfig_21626149; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreateEndpointConfig_21626149; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createEndpointConfig* = Call_CreateEndpointConfig_21626149(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_21626150, base: "/",
    makeUrl: url_CreateEndpointConfig_21626151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_21626164 = ref object of OpenApiRestCall_21625435
proc url_CreateExperiment_21626166(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExperiment_21626165(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626167 = header.getOrDefault("X-Amz-Date")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Date", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Security-Token", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Target")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
  if valid_21626169 != nil:
    section.add "X-Amz-Target", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Algorithm", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Signature")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Signature", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Credential")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Credential", valid_21626174
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

proc call*(call_21626176: Call_CreateExperiment_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_CreateExperiment_21626164; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_21626178 = newJObject()
  if body != nil:
    body_21626178 = body
  result = call_21626177.call(nil, nil, nil, nil, body_21626178)

var createExperiment* = Call_CreateExperiment_21626164(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_21626165, base: "/",
    makeUrl: url_CreateExperiment_21626166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_21626179 = ref object of OpenApiRestCall_21625435
proc url_CreateFlowDefinition_21626181(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowDefinition_21626180(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626182 = header.getOrDefault("X-Amz-Date")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Date", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Security-Token", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Target")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
  if valid_21626184 != nil:
    section.add "X-Amz-Target", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Algorithm", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Signature")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Signature", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Credential")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Credential", valid_21626189
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

proc call*(call_21626191: Call_CreateFlowDefinition_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_CreateFlowDefinition_21626179; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_21626193 = newJObject()
  if body != nil:
    body_21626193 = body
  result = call_21626192.call(nil, nil, nil, nil, body_21626193)

var createFlowDefinition* = Call_CreateFlowDefinition_21626179(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_21626180, base: "/",
    makeUrl: url_CreateFlowDefinition_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_21626194 = ref object of OpenApiRestCall_21625435
proc url_CreateHumanTaskUi_21626196(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHumanTaskUi_21626195(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626197 = header.getOrDefault("X-Amz-Date")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Date", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Security-Token", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Target")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_21626199 != nil:
    section.add "X-Amz-Target", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
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

proc call*(call_21626206: Call_CreateHumanTaskUi_21626194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_21626206.validator(path, query, header, formData, body, _)
  let scheme = call_21626206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626206.makeUrl(scheme.get, call_21626206.host, call_21626206.base,
                               call_21626206.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626206, uri, valid, _)

proc call*(call_21626207: Call_CreateHumanTaskUi_21626194; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_21626208 = newJObject()
  if body != nil:
    body_21626208 = body
  result = call_21626207.call(nil, nil, nil, nil, body_21626208)

var createHumanTaskUi* = Call_CreateHumanTaskUi_21626194(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_21626195, base: "/",
    makeUrl: url_CreateHumanTaskUi_21626196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateHyperParameterTuningJob_21626211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHyperParameterTuningJob_21626210(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Target")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_21626214 != nil:
    section.add "X-Amz-Target", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_CreateHyperParameterTuningJob_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateHyperParameterTuningJob_21626209;
          body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_21626223 = newJObject()
  if body != nil:
    body_21626223 = body
  result = call_21626222.call(nil, nil, nil, nil, body_21626223)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_21626209(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_21626210, base: "/",
    makeUrl: url_CreateHyperParameterTuningJob_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_21626224 = ref object of OpenApiRestCall_21625435
proc url_CreateLabelingJob_21626226(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLabelingJob_21626225(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626227 = header.getOrDefault("X-Amz-Date")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Date", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Security-Token", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Target")
  valid_21626229 = validateParameter(valid_21626229, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_21626229 != nil:
    section.add "X-Amz-Target", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Algorithm", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Signature")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Signature", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Credential")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Credential", valid_21626234
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

proc call*(call_21626236: Call_CreateLabelingJob_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_CreateLabelingJob_21626224; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_21626238 = newJObject()
  if body != nil:
    body_21626238 = body
  result = call_21626237.call(nil, nil, nil, nil, body_21626238)

var createLabelingJob* = Call_CreateLabelingJob_21626224(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_21626225, base: "/",
    makeUrl: url_CreateLabelingJob_21626226, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateModel_21626241(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModel_21626240(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626242 = header.getOrDefault("X-Amz-Date")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Date", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Security-Token", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Target")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true, default = newJString(
      "SageMaker.CreateModel"))
  if valid_21626244 != nil:
    section.add "X-Amz-Target", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
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

proc call*(call_21626251: Call_CreateModel_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateModel_21626239; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to Amazon SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1-deploy-model.html#ex1-deploy-model-boto">Deploy the Model to Amazon SageMaker Hosting Services (AWS SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_21626253 = newJObject()
  if body != nil:
    body_21626253 = body
  result = call_21626252.call(nil, nil, nil, nil, body_21626253)

var createModel* = Call_CreateModel_21626239(name: "createModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModel",
    validator: validate_CreateModel_21626240, base: "/", makeUrl: url_CreateModel_21626241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_21626254 = ref object of OpenApiRestCall_21625435
proc url_CreateModelPackage_21626256(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelPackage_21626255(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626257 = header.getOrDefault("X-Amz-Date")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Date", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Security-Token", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Target")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_21626259 != nil:
    section.add "X-Amz-Target", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
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

proc call*(call_21626266: Call_CreateModelPackage_21626254; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_CreateModelPackage_21626254; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_21626268 = newJObject()
  if body != nil:
    body_21626268 = body
  result = call_21626267.call(nil, nil, nil, nil, body_21626268)

var createModelPackage* = Call_CreateModelPackage_21626254(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_21626255, base: "/",
    makeUrl: url_CreateModelPackage_21626256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_21626269 = ref object of OpenApiRestCall_21625435
proc url_CreateMonitoringSchedule_21626271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMonitoringSchedule_21626270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
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
  var valid_21626272 = header.getOrDefault("X-Amz-Date")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Date", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Security-Token", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Target")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
  if valid_21626274 != nil:
    section.add "X-Amz-Target", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
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

proc call*(call_21626281: Call_CreateMonitoringSchedule_21626269;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_CreateMonitoringSchedule_21626269; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_21626283 = newJObject()
  if body != nil:
    body_21626283 = body
  result = call_21626282.call(nil, nil, nil, nil, body_21626283)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_21626269(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_21626270, base: "/",
    makeUrl: url_CreateMonitoringSchedule_21626271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_21626284 = ref object of OpenApiRestCall_21625435
proc url_CreateNotebookInstance_21626286(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstance_21626285(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626287 = header.getOrDefault("X-Amz-Date")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Date", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Security-Token", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Target")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_21626289 != nil:
    section.add "X-Amz-Target", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
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

proc call*(call_21626296: Call_CreateNotebookInstance_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_CreateNotebookInstance_21626284; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_21626298 = newJObject()
  if body != nil:
    body_21626298 = body
  result = call_21626297.call(nil, nil, nil, nil, body_21626298)

var createNotebookInstance* = Call_CreateNotebookInstance_21626284(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_21626285, base: "/",
    makeUrl: url_CreateNotebookInstance_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_21626299 = ref object of OpenApiRestCall_21625435
proc url_CreateNotebookInstanceLifecycleConfig_21626301(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_21626300(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626302 = header.getOrDefault("X-Amz-Date")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Date", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Security-Token", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Target")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_21626304 != nil:
    section.add "X-Amz-Target", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
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

proc call*(call_21626311: Call_CreateNotebookInstanceLifecycleConfig_21626299;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_CreateNotebookInstanceLifecycleConfig_21626299;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_21626313 = newJObject()
  if body != nil:
    body_21626313 = body
  result = call_21626312.call(nil, nil, nil, nil, body_21626313)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_21626299(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_21626300, base: "/",
    makeUrl: url_CreateNotebookInstanceLifecycleConfig_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_21626314 = ref object of OpenApiRestCall_21625435
proc url_CreatePresignedDomainUrl_21626316(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedDomainUrl_21626315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Target")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_21626319 != nil:
    section.add "X-Amz-Target", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Algorithm", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Signature")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Signature", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Credential")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Credential", valid_21626324
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

proc call*(call_21626326: Call_CreatePresignedDomainUrl_21626314;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_21626326.validator(path, query, header, formData, body, _)
  let scheme = call_21626326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626326.makeUrl(scheme.get, call_21626326.host, call_21626326.base,
                               call_21626326.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626326, uri, valid, _)

proc call*(call_21626327: Call_CreatePresignedDomainUrl_21626314; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_21626328 = newJObject()
  if body != nil:
    body_21626328 = body
  result = call_21626327.call(nil, nil, nil, nil, body_21626328)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_21626314(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_21626315, base: "/",
    makeUrl: url_CreatePresignedDomainUrl_21626316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_21626329 = ref object of OpenApiRestCall_21625435
proc url_CreatePresignedNotebookInstanceUrl_21626331(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePresignedNotebookInstanceUrl_21626330(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Target")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_21626334 != nil:
    section.add "X-Amz-Target", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
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

proc call*(call_21626341: Call_CreatePresignedNotebookInstanceUrl_21626329;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_21626341.validator(path, query, header, formData, body, _)
  let scheme = call_21626341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626341.makeUrl(scheme.get, call_21626341.host, call_21626341.base,
                               call_21626341.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626341, uri, valid, _)

proc call*(call_21626342: Call_CreatePresignedNotebookInstanceUrl_21626329;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_21626343 = newJObject()
  if body != nil:
    body_21626343 = body
  result = call_21626342.call(nil, nil, nil, nil, body_21626343)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_21626329(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_21626330, base: "/",
    makeUrl: url_CreatePresignedNotebookInstanceUrl_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_21626344 = ref object of OpenApiRestCall_21625435
proc url_CreateProcessingJob_21626346(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProcessingJob_21626345(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Target")
  valid_21626349 = validateParameter(valid_21626349, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_21626349 != nil:
    section.add "X-Amz-Target", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Algorithm", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Signature")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Signature", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Credential")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Credential", valid_21626354
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

proc call*(call_21626356: Call_CreateProcessingJob_21626344; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_CreateProcessingJob_21626344; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_21626358 = newJObject()
  if body != nil:
    body_21626358 = body
  result = call_21626357.call(nil, nil, nil, nil, body_21626358)

var createProcessingJob* = Call_CreateProcessingJob_21626344(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_21626345, base: "/",
    makeUrl: url_CreateProcessingJob_21626346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_21626359 = ref object of OpenApiRestCall_21625435
proc url_CreateTrainingJob_21626361(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrainingJob_21626360(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626362 = header.getOrDefault("X-Amz-Date")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Date", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Security-Token", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Target")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_21626364 != nil:
    section.add "X-Amz-Target", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Algorithm", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Signature")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Signature", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Credential")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Credential", valid_21626369
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

proc call*(call_21626371: Call_CreateTrainingJob_21626359; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_CreateTrainingJob_21626359; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_21626373 = newJObject()
  if body != nil:
    body_21626373 = body
  result = call_21626372.call(nil, nil, nil, nil, body_21626373)

var createTrainingJob* = Call_CreateTrainingJob_21626359(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_21626360, base: "/",
    makeUrl: url_CreateTrainingJob_21626361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_21626374 = ref object of OpenApiRestCall_21625435
proc url_CreateTransformJob_21626376(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransformJob_21626375(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Target")
  valid_21626379 = validateParameter(valid_21626379, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_21626379 != nil:
    section.add "X-Amz-Target", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
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

proc call*(call_21626386: Call_CreateTransformJob_21626374; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_CreateTransformJob_21626374; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_21626388 = newJObject()
  if body != nil:
    body_21626388 = body
  result = call_21626387.call(nil, nil, nil, nil, body_21626388)

var createTransformJob* = Call_CreateTransformJob_21626374(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_21626375, base: "/",
    makeUrl: url_CreateTransformJob_21626376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_21626389 = ref object of OpenApiRestCall_21625435
proc url_CreateTrial_21626391(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrial_21626390(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626392 = header.getOrDefault("X-Amz-Date")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Date", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Security-Token", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Target")
  valid_21626394 = validateParameter(valid_21626394, JString, required = true, default = newJString(
      "SageMaker.CreateTrial"))
  if valid_21626394 != nil:
    section.add "X-Amz-Target", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
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

proc call*(call_21626401: Call_CreateTrial_21626389; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_CreateTrial_21626389; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_21626403 = newJObject()
  if body != nil:
    body_21626403 = body
  result = call_21626402.call(nil, nil, nil, nil, body_21626403)

var createTrial* = Call_CreateTrial_21626389(name: "createTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrial",
    validator: validate_CreateTrial_21626390, base: "/", makeUrl: url_CreateTrial_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_21626404 = ref object of OpenApiRestCall_21625435
proc url_CreateTrialComponent_21626406(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrialComponent_21626405(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626407 = header.getOrDefault("X-Amz-Date")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Date", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Security-Token", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Target")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_21626409 != nil:
    section.add "X-Amz-Target", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Algorithm", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Signature")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Signature", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Credential")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Credential", valid_21626414
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

proc call*(call_21626416: Call_CreateTrialComponent_21626404; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_CreateTrialComponent_21626404; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   body: JObject (required)
  var body_21626418 = newJObject()
  if body != nil:
    body_21626418 = body
  result = call_21626417.call(nil, nil, nil, nil, body_21626418)

var createTrialComponent* = Call_CreateTrialComponent_21626404(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_21626405, base: "/",
    makeUrl: url_CreateTrialComponent_21626406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_21626419 = ref object of OpenApiRestCall_21625435
proc url_CreateUserProfile_21626421(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserProfile_21626420(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626422 = header.getOrDefault("X-Amz-Date")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Date", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Security-Token", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Target")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_21626424 != nil:
    section.add "X-Amz-Target", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Algorithm", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Signature")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Signature", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Credential")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Credential", valid_21626429
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

proc call*(call_21626431: Call_CreateUserProfile_21626419; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_21626431.validator(path, query, header, formData, body, _)
  let scheme = call_21626431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626431.makeUrl(scheme.get, call_21626431.host, call_21626431.base,
                               call_21626431.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626431, uri, valid, _)

proc call*(call_21626432: Call_CreateUserProfile_21626419; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_21626433 = newJObject()
  if body != nil:
    body_21626433 = body
  result = call_21626432.call(nil, nil, nil, nil, body_21626433)

var createUserProfile* = Call_CreateUserProfile_21626419(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_21626420, base: "/",
    makeUrl: url_CreateUserProfile_21626421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_21626434 = ref object of OpenApiRestCall_21625435
proc url_CreateWorkteam_21626436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkteam_21626435(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626437 = header.getOrDefault("X-Amz-Date")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Date", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Security-Token", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Target")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_21626439 != nil:
    section.add "X-Amz-Target", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-Algorithm", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Signature")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Signature", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Credential")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Credential", valid_21626444
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

proc call*(call_21626446: Call_CreateWorkteam_21626434; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_21626446.validator(path, query, header, formData, body, _)
  let scheme = call_21626446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626446.makeUrl(scheme.get, call_21626446.host, call_21626446.base,
                               call_21626446.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626446, uri, valid, _)

proc call*(call_21626447: Call_CreateWorkteam_21626434; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_21626448 = newJObject()
  if body != nil:
    body_21626448 = body
  result = call_21626447.call(nil, nil, nil, nil, body_21626448)

var createWorkteam* = Call_CreateWorkteam_21626434(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_21626435, base: "/",
    makeUrl: url_CreateWorkteam_21626436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_21626449 = ref object of OpenApiRestCall_21625435
proc url_DeleteAlgorithm_21626451(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlgorithm_21626450(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626452 = header.getOrDefault("X-Amz-Date")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Date", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Security-Token", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Target")
  valid_21626454 = validateParameter(valid_21626454, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_21626454 != nil:
    section.add "X-Amz-Target", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Algorithm", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Signature")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Signature", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-Credential")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-Credential", valid_21626459
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

proc call*(call_21626461: Call_DeleteAlgorithm_21626449; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DeleteAlgorithm_21626449; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_21626463 = newJObject()
  if body != nil:
    body_21626463 = body
  result = call_21626462.call(nil, nil, nil, nil, body_21626463)

var deleteAlgorithm* = Call_DeleteAlgorithm_21626449(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_21626450, base: "/",
    makeUrl: url_DeleteAlgorithm_21626451, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_21626464 = ref object of OpenApiRestCall_21625435
proc url_DeleteApp_21626466(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApp_21626465(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626467 = header.getOrDefault("X-Amz-Date")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Date", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Security-Token", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Target")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true,
                                   default = newJString("SageMaker.DeleteApp"))
  if valid_21626469 != nil:
    section.add "X-Amz-Target", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
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

proc call*(call_21626476: Call_DeleteApp_21626464; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_21626476.validator(path, query, header, formData, body, _)
  let scheme = call_21626476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626476.makeUrl(scheme.get, call_21626476.host, call_21626476.base,
                               call_21626476.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626476, uri, valid, _)

proc call*(call_21626477: Call_DeleteApp_21626464; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_21626478 = newJObject()
  if body != nil:
    body_21626478 = body
  result = call_21626477.call(nil, nil, nil, nil, body_21626478)

var deleteApp* = Call_DeleteApp_21626464(name: "deleteApp",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                      validator: validate_DeleteApp_21626465,
                                      base: "/", makeUrl: url_DeleteApp_21626466,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_21626479 = ref object of OpenApiRestCall_21625435
proc url_DeleteCodeRepository_21626481(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCodeRepository_21626480(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Target")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_21626484 != nil:
    section.add "X-Amz-Target", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Algorithm", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Signature")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Signature", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Credential")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Credential", valid_21626489
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

proc call*(call_21626491: Call_DeleteCodeRepository_21626479; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_21626491.validator(path, query, header, formData, body, _)
  let scheme = call_21626491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626491.makeUrl(scheme.get, call_21626491.host, call_21626491.base,
                               call_21626491.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626491, uri, valid, _)

proc call*(call_21626492: Call_DeleteCodeRepository_21626479; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_21626493 = newJObject()
  if body != nil:
    body_21626493 = body
  result = call_21626492.call(nil, nil, nil, nil, body_21626493)

var deleteCodeRepository* = Call_DeleteCodeRepository_21626479(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_21626480, base: "/",
    makeUrl: url_DeleteCodeRepository_21626481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_21626494 = ref object of OpenApiRestCall_21625435
proc url_DeleteDomain_21626496(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_21626495(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
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
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Target")
  valid_21626499 = validateParameter(valid_21626499, JString, required = true, default = newJString(
      "SageMaker.DeleteDomain"))
  if valid_21626499 != nil:
    section.add "X-Amz-Target", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Algorithm", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Signature")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Signature", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Credential")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Credential", valid_21626504
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

proc call*(call_21626506: Call_DeleteDomain_21626494; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_21626506.validator(path, query, header, formData, body, _)
  let scheme = call_21626506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626506.makeUrl(scheme.get, call_21626506.host, call_21626506.base,
                               call_21626506.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626506, uri, valid, _)

proc call*(call_21626507: Call_DeleteDomain_21626494; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_21626508 = newJObject()
  if body != nil:
    body_21626508 = body
  result = call_21626507.call(nil, nil, nil, nil, body_21626508)

var deleteDomain* = Call_DeleteDomain_21626494(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_21626495, base: "/", makeUrl: url_DeleteDomain_21626496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_21626509 = ref object of OpenApiRestCall_21625435
proc url_DeleteEndpoint_21626511(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_21626510(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Target")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_21626514 != nil:
    section.add "X-Amz-Target", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
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

proc call*(call_21626521: Call_DeleteEndpoint_21626509; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_21626521.validator(path, query, header, formData, body, _)
  let scheme = call_21626521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626521.makeUrl(scheme.get, call_21626521.host, call_21626521.base,
                               call_21626521.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626521, uri, valid, _)

proc call*(call_21626522: Call_DeleteEndpoint_21626509; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_21626523 = newJObject()
  if body != nil:
    body_21626523 = body
  result = call_21626522.call(nil, nil, nil, nil, body_21626523)

var deleteEndpoint* = Call_DeleteEndpoint_21626509(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_21626510, base: "/",
    makeUrl: url_DeleteEndpoint_21626511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_21626524 = ref object of OpenApiRestCall_21625435
proc url_DeleteEndpointConfig_21626526(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpointConfig_21626525(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Target")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_21626529 != nil:
    section.add "X-Amz-Target", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Algorithm", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Signature")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Signature", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Credential")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Credential", valid_21626534
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

proc call*(call_21626536: Call_DeleteEndpointConfig_21626524; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_21626536.validator(path, query, header, formData, body, _)
  let scheme = call_21626536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626536.makeUrl(scheme.get, call_21626536.host, call_21626536.base,
                               call_21626536.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626536, uri, valid, _)

proc call*(call_21626537: Call_DeleteEndpointConfig_21626524; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_21626538 = newJObject()
  if body != nil:
    body_21626538 = body
  result = call_21626537.call(nil, nil, nil, nil, body_21626538)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_21626524(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_21626525, base: "/",
    makeUrl: url_DeleteEndpointConfig_21626526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_21626539 = ref object of OpenApiRestCall_21625435
proc url_DeleteExperiment_21626541(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteExperiment_21626540(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Target")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_21626544 != nil:
    section.add "X-Amz-Target", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Algorithm", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Signature")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Signature", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Credential")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Credential", valid_21626549
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

proc call*(call_21626551: Call_DeleteExperiment_21626539; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_DeleteExperiment_21626539; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_21626553 = newJObject()
  if body != nil:
    body_21626553 = body
  result = call_21626552.call(nil, nil, nil, nil, body_21626553)

var deleteExperiment* = Call_DeleteExperiment_21626539(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_21626540, base: "/",
    makeUrl: url_DeleteExperiment_21626541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_21626554 = ref object of OpenApiRestCall_21625435
proc url_DeleteFlowDefinition_21626556(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowDefinition_21626555(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Target")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_21626559 != nil:
    section.add "X-Amz-Target", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Algorithm", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Signature")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Signature", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Credential")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Credential", valid_21626564
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

proc call*(call_21626566: Call_DeleteFlowDefinition_21626554; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_DeleteFlowDefinition_21626554; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_21626568 = newJObject()
  if body != nil:
    body_21626568 = body
  result = call_21626567.call(nil, nil, nil, nil, body_21626568)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_21626554(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_21626555, base: "/",
    makeUrl: url_DeleteFlowDefinition_21626556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_21626569 = ref object of OpenApiRestCall_21625435
proc url_DeleteModel_21626571(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModel_21626570(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626572 = header.getOrDefault("X-Amz-Date")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Date", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Security-Token", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Target")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "SageMaker.DeleteModel"))
  if valid_21626574 != nil:
    section.add "X-Amz-Target", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626575
  var valid_21626576 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Algorithm", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Signature")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Signature", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Credential")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Credential", valid_21626579
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

proc call*(call_21626581: Call_DeleteModel_21626569; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_21626581.validator(path, query, header, formData, body, _)
  let scheme = call_21626581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626581.makeUrl(scheme.get, call_21626581.host, call_21626581.base,
                               call_21626581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626581, uri, valid, _)

proc call*(call_21626582: Call_DeleteModel_21626569; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_21626583 = newJObject()
  if body != nil:
    body_21626583 = body
  result = call_21626582.call(nil, nil, nil, nil, body_21626583)

var deleteModel* = Call_DeleteModel_21626569(name: "deleteModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModel",
    validator: validate_DeleteModel_21626570, base: "/", makeUrl: url_DeleteModel_21626571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_21626584 = ref object of OpenApiRestCall_21625435
proc url_DeleteModelPackage_21626586(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModelPackage_21626585(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626587 = header.getOrDefault("X-Amz-Date")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Date", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-Security-Token", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Target")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_21626589 != nil:
    section.add "X-Amz-Target", valid_21626589
  var valid_21626590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626590
  var valid_21626591 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Algorithm", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Signature")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Signature", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Credential")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Credential", valid_21626594
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

proc call*(call_21626596: Call_DeleteModelPackage_21626584; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_21626596.validator(path, query, header, formData, body, _)
  let scheme = call_21626596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626596.makeUrl(scheme.get, call_21626596.host, call_21626596.base,
                               call_21626596.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626596, uri, valid, _)

proc call*(call_21626597: Call_DeleteModelPackage_21626584; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_21626598 = newJObject()
  if body != nil:
    body_21626598 = body
  result = call_21626597.call(nil, nil, nil, nil, body_21626598)

var deleteModelPackage* = Call_DeleteModelPackage_21626584(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_21626585, base: "/",
    makeUrl: url_DeleteModelPackage_21626586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_21626599 = ref object of OpenApiRestCall_21625435
proc url_DeleteMonitoringSchedule_21626601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMonitoringSchedule_21626600(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
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
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Target")
  valid_21626604 = validateParameter(valid_21626604, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_21626604 != nil:
    section.add "X-Amz-Target", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Algorithm", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-Signature")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-Signature", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Credential")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Credential", valid_21626609
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

proc call*(call_21626611: Call_DeleteMonitoringSchedule_21626599;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_21626611.validator(path, query, header, formData, body, _)
  let scheme = call_21626611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626611.makeUrl(scheme.get, call_21626611.host, call_21626611.base,
                               call_21626611.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626611, uri, valid, _)

proc call*(call_21626612: Call_DeleteMonitoringSchedule_21626599; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_21626613 = newJObject()
  if body != nil:
    body_21626613 = body
  result = call_21626612.call(nil, nil, nil, nil, body_21626613)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_21626599(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_21626600, base: "/",
    makeUrl: url_DeleteMonitoringSchedule_21626601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_21626614 = ref object of OpenApiRestCall_21625435
proc url_DeleteNotebookInstance_21626616(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstance_21626615(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Target")
  valid_21626619 = validateParameter(valid_21626619, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_21626619 != nil:
    section.add "X-Amz-Target", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Algorithm", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Signature")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Signature", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626623
  var valid_21626624 = header.getOrDefault("X-Amz-Credential")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Credential", valid_21626624
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

proc call*(call_21626626: Call_DeleteNotebookInstance_21626614;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_21626626.validator(path, query, header, formData, body, _)
  let scheme = call_21626626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626626.makeUrl(scheme.get, call_21626626.host, call_21626626.base,
                               call_21626626.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626626, uri, valid, _)

proc call*(call_21626627: Call_DeleteNotebookInstance_21626614; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_21626628 = newJObject()
  if body != nil:
    body_21626628 = body
  result = call_21626627.call(nil, nil, nil, nil, body_21626628)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_21626614(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_21626615, base: "/",
    makeUrl: url_DeleteNotebookInstance_21626616,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_21626629 = ref object of OpenApiRestCall_21625435
proc url_DeleteNotebookInstanceLifecycleConfig_21626631(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_21626630(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626632 = header.getOrDefault("X-Amz-Date")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Date", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Security-Token", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Target")
  valid_21626634 = validateParameter(valid_21626634, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_21626634 != nil:
    section.add "X-Amz-Target", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Algorithm", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Signature")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Signature", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Credential")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Credential", valid_21626639
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

proc call*(call_21626641: Call_DeleteNotebookInstanceLifecycleConfig_21626629;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_DeleteNotebookInstanceLifecycleConfig_21626629;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_21626643 = newJObject()
  if body != nil:
    body_21626643 = body
  result = call_21626642.call(nil, nil, nil, nil, body_21626643)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_21626629(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_21626630, base: "/",
    makeUrl: url_DeleteNotebookInstanceLifecycleConfig_21626631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_21626644 = ref object of OpenApiRestCall_21625435
proc url_DeleteTags_21626646(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_21626645(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626647 = header.getOrDefault("X-Amz-Date")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Date", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Security-Token", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Target")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true,
                                   default = newJString("SageMaker.DeleteTags"))
  if valid_21626649 != nil:
    section.add "X-Amz-Target", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
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

proc call*(call_21626656: Call_DeleteTags_21626644; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_DeleteTags_21626644; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_21626658 = newJObject()
  if body != nil:
    body_21626658 = body
  result = call_21626657.call(nil, nil, nil, nil, body_21626658)

var deleteTags* = Call_DeleteTags_21626644(name: "deleteTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                        validator: validate_DeleteTags_21626645,
                                        base: "/", makeUrl: url_DeleteTags_21626646,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_21626659 = ref object of OpenApiRestCall_21625435
proc url_DeleteTrial_21626661(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrial_21626660(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626662 = header.getOrDefault("X-Amz-Date")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Date", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Security-Token", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Target")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "SageMaker.DeleteTrial"))
  if valid_21626664 != nil:
    section.add "X-Amz-Target", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
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

proc call*(call_21626671: Call_DeleteTrial_21626659; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_DeleteTrial_21626659; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_21626673 = newJObject()
  if body != nil:
    body_21626673 = body
  result = call_21626672.call(nil, nil, nil, nil, body_21626673)

var deleteTrial* = Call_DeleteTrial_21626659(name: "deleteTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrial",
    validator: validate_DeleteTrial_21626660, base: "/", makeUrl: url_DeleteTrial_21626661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_21626674 = ref object of OpenApiRestCall_21625435
proc url_DeleteTrialComponent_21626676(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrialComponent_21626675(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Target")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_21626679 != nil:
    section.add "X-Amz-Target", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Algorithm", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Signature")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Signature", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Credential")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Credential", valid_21626684
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

proc call*(call_21626686: Call_DeleteTrialComponent_21626674; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_21626686.validator(path, query, header, formData, body, _)
  let scheme = call_21626686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626686.makeUrl(scheme.get, call_21626686.host, call_21626686.base,
                               call_21626686.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626686, uri, valid, _)

proc call*(call_21626687: Call_DeleteTrialComponent_21626674; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_21626688 = newJObject()
  if body != nil:
    body_21626688 = body
  result = call_21626687.call(nil, nil, nil, nil, body_21626688)

var deleteTrialComponent* = Call_DeleteTrialComponent_21626674(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_21626675, base: "/",
    makeUrl: url_DeleteTrialComponent_21626676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_21626689 = ref object of OpenApiRestCall_21625435
proc url_DeleteUserProfile_21626691(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserProfile_21626690(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Target")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_21626694 != nil:
    section.add "X-Amz-Target", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Algorithm", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Signature")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Signature", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Credential")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Credential", valid_21626699
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

proc call*(call_21626701: Call_DeleteUserProfile_21626689; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_21626701.validator(path, query, header, formData, body, _)
  let scheme = call_21626701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626701.makeUrl(scheme.get, call_21626701.host, call_21626701.base,
                               call_21626701.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626701, uri, valid, _)

proc call*(call_21626702: Call_DeleteUserProfile_21626689; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_21626703 = newJObject()
  if body != nil:
    body_21626703 = body
  result = call_21626702.call(nil, nil, nil, nil, body_21626703)

var deleteUserProfile* = Call_DeleteUserProfile_21626689(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_21626690, base: "/",
    makeUrl: url_DeleteUserProfile_21626691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_21626704 = ref object of OpenApiRestCall_21625435
proc url_DeleteWorkteam_21626706(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkteam_21626705(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626707 = header.getOrDefault("X-Amz-Date")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Date", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Security-Token", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Target")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_21626709 != nil:
    section.add "X-Amz-Target", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Algorithm", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Signature")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Signature", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Credential")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Credential", valid_21626714
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

proc call*(call_21626716: Call_DeleteWorkteam_21626704; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_21626716.validator(path, query, header, formData, body, _)
  let scheme = call_21626716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626716.makeUrl(scheme.get, call_21626716.host, call_21626716.base,
                               call_21626716.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626716, uri, valid, _)

proc call*(call_21626717: Call_DeleteWorkteam_21626704; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_21626718 = newJObject()
  if body != nil:
    body_21626718 = body
  result = call_21626717.call(nil, nil, nil, nil, body_21626718)

var deleteWorkteam* = Call_DeleteWorkteam_21626704(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_21626705, base: "/",
    makeUrl: url_DeleteWorkteam_21626706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_21626719 = ref object of OpenApiRestCall_21625435
proc url_DescribeAlgorithm_21626721(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAlgorithm_21626720(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626722 = header.getOrDefault("X-Amz-Date")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Date", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Security-Token", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Target")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_21626724 != nil:
    section.add "X-Amz-Target", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Algorithm", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Signature")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Signature", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Credential")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Credential", valid_21626729
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

proc call*(call_21626731: Call_DescribeAlgorithm_21626719; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_21626731.validator(path, query, header, formData, body, _)
  let scheme = call_21626731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626731.makeUrl(scheme.get, call_21626731.host, call_21626731.base,
                               call_21626731.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626731, uri, valid, _)

proc call*(call_21626732: Call_DescribeAlgorithm_21626719; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_21626733 = newJObject()
  if body != nil:
    body_21626733 = body
  result = call_21626732.call(nil, nil, nil, nil, body_21626733)

var describeAlgorithm* = Call_DescribeAlgorithm_21626719(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_21626720, base: "/",
    makeUrl: url_DescribeAlgorithm_21626721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_21626734 = ref object of OpenApiRestCall_21625435
proc url_DescribeApp_21626736(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApp_21626735(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626737 = header.getOrDefault("X-Amz-Date")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Date", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Security-Token", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Target")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true, default = newJString(
      "SageMaker.DescribeApp"))
  if valid_21626739 != nil:
    section.add "X-Amz-Target", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-Algorithm", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Signature")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Signature", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Credential")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Credential", valid_21626744
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

proc call*(call_21626746: Call_DescribeApp_21626734; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the app.
  ## 
  let valid = call_21626746.validator(path, query, header, formData, body, _)
  let scheme = call_21626746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626746.makeUrl(scheme.get, call_21626746.host, call_21626746.base,
                               call_21626746.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626746, uri, valid, _)

proc call*(call_21626747: Call_DescribeApp_21626734; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_21626748 = newJObject()
  if body != nil:
    body_21626748 = body
  result = call_21626747.call(nil, nil, nil, nil, body_21626748)

var describeApp* = Call_DescribeApp_21626734(name: "describeApp",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeApp",
    validator: validate_DescribeApp_21626735, base: "/", makeUrl: url_DescribeApp_21626736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_21626749 = ref object of OpenApiRestCall_21625435
proc url_DescribeAutoMLJob_21626751(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutoMLJob_21626750(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626752 = header.getOrDefault("X-Amz-Date")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Date", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Security-Token", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Target")
  valid_21626754 = validateParameter(valid_21626754, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_21626754 != nil:
    section.add "X-Amz-Target", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Algorithm", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Signature")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Signature", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Credential")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Credential", valid_21626759
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

proc call*(call_21626761: Call_DescribeAutoMLJob_21626749; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_21626761.validator(path, query, header, formData, body, _)
  let scheme = call_21626761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626761.makeUrl(scheme.get, call_21626761.host, call_21626761.base,
                               call_21626761.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626761, uri, valid, _)

proc call*(call_21626762: Call_DescribeAutoMLJob_21626749; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_21626763 = newJObject()
  if body != nil:
    body_21626763 = body
  result = call_21626762.call(nil, nil, nil, nil, body_21626763)

var describeAutoMLJob* = Call_DescribeAutoMLJob_21626749(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_21626750, base: "/",
    makeUrl: url_DescribeAutoMLJob_21626751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_21626764 = ref object of OpenApiRestCall_21625435
proc url_DescribeCodeRepository_21626766(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCodeRepository_21626765(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626767 = header.getOrDefault("X-Amz-Date")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Date", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Security-Token", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Target")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_21626769 != nil:
    section.add "X-Amz-Target", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Algorithm", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Signature")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Signature", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Credential")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Credential", valid_21626774
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

proc call*(call_21626776: Call_DescribeCodeRepository_21626764;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_21626776.validator(path, query, header, formData, body, _)
  let scheme = call_21626776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626776.makeUrl(scheme.get, call_21626776.host, call_21626776.base,
                               call_21626776.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626776, uri, valid, _)

proc call*(call_21626777: Call_DescribeCodeRepository_21626764; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_21626778 = newJObject()
  if body != nil:
    body_21626778 = body
  result = call_21626777.call(nil, nil, nil, nil, body_21626778)

var describeCodeRepository* = Call_DescribeCodeRepository_21626764(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_21626765, base: "/",
    makeUrl: url_DescribeCodeRepository_21626766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_21626779 = ref object of OpenApiRestCall_21625435
proc url_DescribeCompilationJob_21626781(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompilationJob_21626780(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626782 = header.getOrDefault("X-Amz-Date")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Date", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Security-Token", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Target")
  valid_21626784 = validateParameter(valid_21626784, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_21626784 != nil:
    section.add "X-Amz-Target", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Algorithm", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Signature")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Signature", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Credential")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Credential", valid_21626789
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

proc call*(call_21626791: Call_DescribeCompilationJob_21626779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_21626791.validator(path, query, header, formData, body, _)
  let scheme = call_21626791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626791.makeUrl(scheme.get, call_21626791.host, call_21626791.base,
                               call_21626791.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626791, uri, valid, _)

proc call*(call_21626792: Call_DescribeCompilationJob_21626779; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_21626793 = newJObject()
  if body != nil:
    body_21626793 = body
  result = call_21626792.call(nil, nil, nil, nil, body_21626793)

var describeCompilationJob* = Call_DescribeCompilationJob_21626779(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_21626780, base: "/",
    makeUrl: url_DescribeCompilationJob_21626781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_21626794 = ref object of OpenApiRestCall_21625435
proc url_DescribeDomain_21626796(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_21626795(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626797 = header.getOrDefault("X-Amz-Date")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Date", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Security-Token", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Target")
  valid_21626799 = validateParameter(valid_21626799, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_21626799 != nil:
    section.add "X-Amz-Target", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Algorithm", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Signature")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Signature", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Credential")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Credential", valid_21626804
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

proc call*(call_21626806: Call_DescribeDomain_21626794; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_21626806.validator(path, query, header, formData, body, _)
  let scheme = call_21626806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626806.makeUrl(scheme.get, call_21626806.host, call_21626806.base,
                               call_21626806.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626806, uri, valid, _)

proc call*(call_21626807: Call_DescribeDomain_21626794; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_21626808 = newJObject()
  if body != nil:
    body_21626808 = body
  result = call_21626807.call(nil, nil, nil, nil, body_21626808)

var describeDomain* = Call_DescribeDomain_21626794(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_21626795, base: "/",
    makeUrl: url_DescribeDomain_21626796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_21626809 = ref object of OpenApiRestCall_21625435
proc url_DescribeEndpoint_21626811(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_21626810(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626812 = header.getOrDefault("X-Amz-Date")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Date", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Security-Token", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Target")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_21626814 != nil:
    section.add "X-Amz-Target", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Algorithm", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Signature")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Signature", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Credential")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Credential", valid_21626819
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

proc call*(call_21626821: Call_DescribeEndpoint_21626809; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_21626821.validator(path, query, header, formData, body, _)
  let scheme = call_21626821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626821.makeUrl(scheme.get, call_21626821.host, call_21626821.base,
                               call_21626821.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626821, uri, valid, _)

proc call*(call_21626822: Call_DescribeEndpoint_21626809; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_21626823 = newJObject()
  if body != nil:
    body_21626823 = body
  result = call_21626822.call(nil, nil, nil, nil, body_21626823)

var describeEndpoint* = Call_DescribeEndpoint_21626809(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_21626810, base: "/",
    makeUrl: url_DescribeEndpoint_21626811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_21626824 = ref object of OpenApiRestCall_21625435
proc url_DescribeEndpointConfig_21626826(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointConfig_21626825(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Target")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_21626829 != nil:
    section.add "X-Amz-Target", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
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

proc call*(call_21626836: Call_DescribeEndpointConfig_21626824;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_21626836.validator(path, query, header, formData, body, _)
  let scheme = call_21626836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626836.makeUrl(scheme.get, call_21626836.host, call_21626836.base,
                               call_21626836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626836, uri, valid, _)

proc call*(call_21626837: Call_DescribeEndpointConfig_21626824; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_21626838 = newJObject()
  if body != nil:
    body_21626838 = body
  result = call_21626837.call(nil, nil, nil, nil, body_21626838)

var describeEndpointConfig* = Call_DescribeEndpointConfig_21626824(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_21626825, base: "/",
    makeUrl: url_DescribeEndpointConfig_21626826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_21626839 = ref object of OpenApiRestCall_21625435
proc url_DescribeExperiment_21626841(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExperiment_21626840(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626842 = header.getOrDefault("X-Amz-Date")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Date", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Security-Token", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Target")
  valid_21626844 = validateParameter(valid_21626844, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_21626844 != nil:
    section.add "X-Amz-Target", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Algorithm", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-Signature")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-Signature", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626848
  var valid_21626849 = header.getOrDefault("X-Amz-Credential")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "X-Amz-Credential", valid_21626849
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

proc call*(call_21626851: Call_DescribeExperiment_21626839; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_21626851.validator(path, query, header, formData, body, _)
  let scheme = call_21626851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626851.makeUrl(scheme.get, call_21626851.host, call_21626851.base,
                               call_21626851.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626851, uri, valid, _)

proc call*(call_21626852: Call_DescribeExperiment_21626839; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_21626853 = newJObject()
  if body != nil:
    body_21626853 = body
  result = call_21626852.call(nil, nil, nil, nil, body_21626853)

var describeExperiment* = Call_DescribeExperiment_21626839(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_21626840, base: "/",
    makeUrl: url_DescribeExperiment_21626841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_21626854 = ref object of OpenApiRestCall_21625435
proc url_DescribeFlowDefinition_21626856(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFlowDefinition_21626855(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626857 = header.getOrDefault("X-Amz-Date")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Date", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Security-Token", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Target")
  valid_21626859 = validateParameter(valid_21626859, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_21626859 != nil:
    section.add "X-Amz-Target", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Algorithm", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Signature")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Signature", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626863
  var valid_21626864 = header.getOrDefault("X-Amz-Credential")
  valid_21626864 = validateParameter(valid_21626864, JString, required = false,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "X-Amz-Credential", valid_21626864
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

proc call*(call_21626866: Call_DescribeFlowDefinition_21626854;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_21626866.validator(path, query, header, formData, body, _)
  let scheme = call_21626866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626866.makeUrl(scheme.get, call_21626866.host, call_21626866.base,
                               call_21626866.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626866, uri, valid, _)

proc call*(call_21626867: Call_DescribeFlowDefinition_21626854; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_21626868 = newJObject()
  if body != nil:
    body_21626868 = body
  result = call_21626867.call(nil, nil, nil, nil, body_21626868)

var describeFlowDefinition* = Call_DescribeFlowDefinition_21626854(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_21626855, base: "/",
    makeUrl: url_DescribeFlowDefinition_21626856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_21626869 = ref object of OpenApiRestCall_21625435
proc url_DescribeHumanTaskUi_21626871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHumanTaskUi_21626870(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626872 = header.getOrDefault("X-Amz-Date")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Date", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Security-Token", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Target")
  valid_21626874 = validateParameter(valid_21626874, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_21626874 != nil:
    section.add "X-Amz-Target", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Algorithm", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Signature")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Signature", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626878
  var valid_21626879 = header.getOrDefault("X-Amz-Credential")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "X-Amz-Credential", valid_21626879
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

proc call*(call_21626881: Call_DescribeHumanTaskUi_21626869; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_21626881.validator(path, query, header, formData, body, _)
  let scheme = call_21626881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626881.makeUrl(scheme.get, call_21626881.host, call_21626881.base,
                               call_21626881.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626881, uri, valid, _)

proc call*(call_21626882: Call_DescribeHumanTaskUi_21626869; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_21626883 = newJObject()
  if body != nil:
    body_21626883 = body
  result = call_21626882.call(nil, nil, nil, nil, body_21626883)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_21626869(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_21626870, base: "/",
    makeUrl: url_DescribeHumanTaskUi_21626871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_21626884 = ref object of OpenApiRestCall_21625435
proc url_DescribeHyperParameterTuningJob_21626886(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHyperParameterTuningJob_21626885(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626887 = header.getOrDefault("X-Amz-Date")
  valid_21626887 = validateParameter(valid_21626887, JString, required = false,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "X-Amz-Date", valid_21626887
  var valid_21626888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "X-Amz-Security-Token", valid_21626888
  var valid_21626889 = header.getOrDefault("X-Amz-Target")
  valid_21626889 = validateParameter(valid_21626889, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_21626889 != nil:
    section.add "X-Amz-Target", valid_21626889
  var valid_21626890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626890
  var valid_21626891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "X-Amz-Algorithm", valid_21626891
  var valid_21626892 = header.getOrDefault("X-Amz-Signature")
  valid_21626892 = validateParameter(valid_21626892, JString, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "X-Amz-Signature", valid_21626892
  var valid_21626893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626893
  var valid_21626894 = header.getOrDefault("X-Amz-Credential")
  valid_21626894 = validateParameter(valid_21626894, JString, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "X-Amz-Credential", valid_21626894
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

proc call*(call_21626896: Call_DescribeHyperParameterTuningJob_21626884;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_21626896.validator(path, query, header, formData, body, _)
  let scheme = call_21626896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626896.makeUrl(scheme.get, call_21626896.host, call_21626896.base,
                               call_21626896.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626896, uri, valid, _)

proc call*(call_21626897: Call_DescribeHyperParameterTuningJob_21626884;
          body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_21626898 = newJObject()
  if body != nil:
    body_21626898 = body
  result = call_21626897.call(nil, nil, nil, nil, body_21626898)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_21626884(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_21626885, base: "/",
    makeUrl: url_DescribeHyperParameterTuningJob_21626886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_21626899 = ref object of OpenApiRestCall_21625435
proc url_DescribeLabelingJob_21626901(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLabelingJob_21626900(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626902 = header.getOrDefault("X-Amz-Date")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Date", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Security-Token", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Target")
  valid_21626904 = validateParameter(valid_21626904, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_21626904 != nil:
    section.add "X-Amz-Target", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Algorithm", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Signature")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Signature", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Credential")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Credential", valid_21626909
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

proc call*(call_21626911: Call_DescribeLabelingJob_21626899; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_21626911.validator(path, query, header, formData, body, _)
  let scheme = call_21626911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626911.makeUrl(scheme.get, call_21626911.host, call_21626911.base,
                               call_21626911.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626911, uri, valid, _)

proc call*(call_21626912: Call_DescribeLabelingJob_21626899; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_21626913 = newJObject()
  if body != nil:
    body_21626913 = body
  result = call_21626912.call(nil, nil, nil, nil, body_21626913)

var describeLabelingJob* = Call_DescribeLabelingJob_21626899(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_21626900, base: "/",
    makeUrl: url_DescribeLabelingJob_21626901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_21626914 = ref object of OpenApiRestCall_21625435
proc url_DescribeModel_21626916(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModel_21626915(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Describes a model that you created using the <code>CreateModel</code> API.
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
  var valid_21626917 = header.getOrDefault("X-Amz-Date")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Date", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Security-Token", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Target")
  valid_21626919 = validateParameter(valid_21626919, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_21626919 != nil:
    section.add "X-Amz-Target", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Algorithm", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Signature")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Signature", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Credential")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Credential", valid_21626924
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

proc call*(call_21626926: Call_DescribeModel_21626914; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_21626926.validator(path, query, header, formData, body, _)
  let scheme = call_21626926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626926.makeUrl(scheme.get, call_21626926.host, call_21626926.base,
                               call_21626926.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626926, uri, valid, _)

proc call*(call_21626927: Call_DescribeModel_21626914; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_21626928 = newJObject()
  if body != nil:
    body_21626928 = body
  result = call_21626927.call(nil, nil, nil, nil, body_21626928)

var describeModel* = Call_DescribeModel_21626914(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_21626915, base: "/",
    makeUrl: url_DescribeModel_21626916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_21626929 = ref object of OpenApiRestCall_21625435
proc url_DescribeModelPackage_21626931(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelPackage_21626930(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626932 = header.getOrDefault("X-Amz-Date")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Date", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Security-Token", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Target")
  valid_21626934 = validateParameter(valid_21626934, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_21626934 != nil:
    section.add "X-Amz-Target", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-Algorithm", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Signature")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Signature", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Credential")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Credential", valid_21626939
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

proc call*(call_21626941: Call_DescribeModelPackage_21626929; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_21626941.validator(path, query, header, formData, body, _)
  let scheme = call_21626941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626941.makeUrl(scheme.get, call_21626941.host, call_21626941.base,
                               call_21626941.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626941, uri, valid, _)

proc call*(call_21626942: Call_DescribeModelPackage_21626929; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_21626943 = newJObject()
  if body != nil:
    body_21626943 = body
  result = call_21626942.call(nil, nil, nil, nil, body_21626943)

var describeModelPackage* = Call_DescribeModelPackage_21626929(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_21626930, base: "/",
    makeUrl: url_DescribeModelPackage_21626931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_21626944 = ref object of OpenApiRestCall_21625435
proc url_DescribeMonitoringSchedule_21626946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMonitoringSchedule_21626945(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the schedule for a monitoring job.
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
  var valid_21626947 = header.getOrDefault("X-Amz-Date")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Date", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Security-Token", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Target")
  valid_21626949 = validateParameter(valid_21626949, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_21626949 != nil:
    section.add "X-Amz-Target", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Algorithm", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Signature")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Signature", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Credential")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Credential", valid_21626954
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

proc call*(call_21626956: Call_DescribeMonitoringSchedule_21626944;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_21626956.validator(path, query, header, formData, body, _)
  let scheme = call_21626956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626956.makeUrl(scheme.get, call_21626956.host, call_21626956.base,
                               call_21626956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626956, uri, valid, _)

proc call*(call_21626957: Call_DescribeMonitoringSchedule_21626944; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_21626958 = newJObject()
  if body != nil:
    body_21626958 = body
  result = call_21626957.call(nil, nil, nil, nil, body_21626958)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_21626944(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_21626945, base: "/",
    makeUrl: url_DescribeMonitoringSchedule_21626946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_21626959 = ref object of OpenApiRestCall_21625435
proc url_DescribeNotebookInstance_21626961(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstance_21626960(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a notebook instance.
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
  var valid_21626962 = header.getOrDefault("X-Amz-Date")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Date", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Security-Token", valid_21626963
  var valid_21626964 = header.getOrDefault("X-Amz-Target")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_21626964 != nil:
    section.add "X-Amz-Target", valid_21626964
  var valid_21626965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Algorithm", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Signature")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Signature", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Credential")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Credential", valid_21626969
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

proc call*(call_21626971: Call_DescribeNotebookInstance_21626959;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_21626971.validator(path, query, header, formData, body, _)
  let scheme = call_21626971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626971.makeUrl(scheme.get, call_21626971.host, call_21626971.base,
                               call_21626971.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626971, uri, valid, _)

proc call*(call_21626972: Call_DescribeNotebookInstance_21626959; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_21626973 = newJObject()
  if body != nil:
    body_21626973 = body
  result = call_21626972.call(nil, nil, nil, nil, body_21626973)

var describeNotebookInstance* = Call_DescribeNotebookInstance_21626959(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_21626960, base: "/",
    makeUrl: url_DescribeNotebookInstance_21626961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_21626974 = ref object of OpenApiRestCall_21625435
proc url_DescribeNotebookInstanceLifecycleConfig_21626976(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_21626975(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626977 = header.getOrDefault("X-Amz-Date")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Date", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Security-Token", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Target")
  valid_21626979 = validateParameter(valid_21626979, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_21626979 != nil:
    section.add "X-Amz-Target", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Algorithm", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Signature")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Signature", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Credential")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Credential", valid_21626984
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

proc call*(call_21626986: Call_DescribeNotebookInstanceLifecycleConfig_21626974;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_21626986.validator(path, query, header, formData, body, _)
  let scheme = call_21626986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626986.makeUrl(scheme.get, call_21626986.host, call_21626986.base,
                               call_21626986.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626986, uri, valid, _)

proc call*(call_21626987: Call_DescribeNotebookInstanceLifecycleConfig_21626974;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_21626988 = newJObject()
  if body != nil:
    body_21626988 = body
  result = call_21626987.call(nil, nil, nil, nil, body_21626988)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_21626974(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_21626975,
    base: "/", makeUrl: url_DescribeNotebookInstanceLifecycleConfig_21626976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_21626989 = ref object of OpenApiRestCall_21625435
proc url_DescribeProcessingJob_21626991(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProcessingJob_21626990(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626992 = header.getOrDefault("X-Amz-Date")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Date", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Security-Token", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Target")
  valid_21626994 = validateParameter(valid_21626994, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_21626994 != nil:
    section.add "X-Amz-Target", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Algorithm", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Signature")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Signature", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Credential")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Credential", valid_21626999
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

proc call*(call_21627001: Call_DescribeProcessingJob_21626989;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_21627001.validator(path, query, header, formData, body, _)
  let scheme = call_21627001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627001.makeUrl(scheme.get, call_21627001.host, call_21627001.base,
                               call_21627001.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627001, uri, valid, _)

proc call*(call_21627002: Call_DescribeProcessingJob_21626989; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_21627003 = newJObject()
  if body != nil:
    body_21627003 = body
  result = call_21627002.call(nil, nil, nil, nil, body_21627003)

var describeProcessingJob* = Call_DescribeProcessingJob_21626989(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_21626990, base: "/",
    makeUrl: url_DescribeProcessingJob_21626991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_21627004 = ref object of OpenApiRestCall_21625435
proc url_DescribeSubscribedWorkteam_21627006(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSubscribedWorkteam_21627005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
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
  var valid_21627007 = header.getOrDefault("X-Amz-Date")
  valid_21627007 = validateParameter(valid_21627007, JString, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "X-Amz-Date", valid_21627007
  var valid_21627008 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627008 = validateParameter(valid_21627008, JString, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "X-Amz-Security-Token", valid_21627008
  var valid_21627009 = header.getOrDefault("X-Amz-Target")
  valid_21627009 = validateParameter(valid_21627009, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_21627009 != nil:
    section.add "X-Amz-Target", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Algorithm", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Signature")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Signature", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-Credential")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-Credential", valid_21627014
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

proc call*(call_21627016: Call_DescribeSubscribedWorkteam_21627004;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_21627016.validator(path, query, header, formData, body, _)
  let scheme = call_21627016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627016.makeUrl(scheme.get, call_21627016.host, call_21627016.base,
                               call_21627016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627016, uri, valid, _)

proc call*(call_21627017: Call_DescribeSubscribedWorkteam_21627004; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_21627018 = newJObject()
  if body != nil:
    body_21627018 = body
  result = call_21627017.call(nil, nil, nil, nil, body_21627018)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_21627004(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_21627005, base: "/",
    makeUrl: url_DescribeSubscribedWorkteam_21627006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_21627019 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrainingJob_21627021(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrainingJob_21627020(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627022 = header.getOrDefault("X-Amz-Date")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Date", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Security-Token", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Target")
  valid_21627024 = validateParameter(valid_21627024, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_21627024 != nil:
    section.add "X-Amz-Target", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Algorithm", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Signature")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Signature", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Credential")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Credential", valid_21627029
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

proc call*(call_21627031: Call_DescribeTrainingJob_21627019; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_21627031.validator(path, query, header, formData, body, _)
  let scheme = call_21627031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627031.makeUrl(scheme.get, call_21627031.host, call_21627031.base,
                               call_21627031.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627031, uri, valid, _)

proc call*(call_21627032: Call_DescribeTrainingJob_21627019; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_21627033 = newJObject()
  if body != nil:
    body_21627033 = body
  result = call_21627032.call(nil, nil, nil, nil, body_21627033)

var describeTrainingJob* = Call_DescribeTrainingJob_21627019(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_21627020, base: "/",
    makeUrl: url_DescribeTrainingJob_21627021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_21627034 = ref object of OpenApiRestCall_21625435
proc url_DescribeTransformJob_21627036(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTransformJob_21627035(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627037 = header.getOrDefault("X-Amz-Date")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Date", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Security-Token", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Target")
  valid_21627039 = validateParameter(valid_21627039, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_21627039 != nil:
    section.add "X-Amz-Target", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Algorithm", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Signature")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Signature", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Credential")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Credential", valid_21627044
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

proc call*(call_21627046: Call_DescribeTransformJob_21627034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_21627046.validator(path, query, header, formData, body, _)
  let scheme = call_21627046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627046.makeUrl(scheme.get, call_21627046.host, call_21627046.base,
                               call_21627046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627046, uri, valid, _)

proc call*(call_21627047: Call_DescribeTransformJob_21627034; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_21627048 = newJObject()
  if body != nil:
    body_21627048 = body
  result = call_21627047.call(nil, nil, nil, nil, body_21627048)

var describeTransformJob* = Call_DescribeTransformJob_21627034(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_21627035, base: "/",
    makeUrl: url_DescribeTransformJob_21627036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_21627049 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrial_21627051(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrial_21627050(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Provides a list of a trial's properties.
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
  var valid_21627052 = header.getOrDefault("X-Amz-Date")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "X-Amz-Date", valid_21627052
  var valid_21627053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Security-Token", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Target")
  valid_21627054 = validateParameter(valid_21627054, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_21627054 != nil:
    section.add "X-Amz-Target", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Algorithm", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Signature")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Signature", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Credential")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Credential", valid_21627059
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

proc call*(call_21627061: Call_DescribeTrial_21627049; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_21627061.validator(path, query, header, formData, body, _)
  let scheme = call_21627061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627061.makeUrl(scheme.get, call_21627061.host, call_21627061.base,
                               call_21627061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627061, uri, valid, _)

proc call*(call_21627062: Call_DescribeTrial_21627049; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_21627063 = newJObject()
  if body != nil:
    body_21627063 = body
  result = call_21627062.call(nil, nil, nil, nil, body_21627063)

var describeTrial* = Call_DescribeTrial_21627049(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_21627050, base: "/",
    makeUrl: url_DescribeTrial_21627051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_21627064 = ref object of OpenApiRestCall_21625435
proc url_DescribeTrialComponent_21627066(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrialComponent_21627065(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627067 = header.getOrDefault("X-Amz-Date")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Date", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Security-Token", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Target")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_21627069 != nil:
    section.add "X-Amz-Target", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
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

proc call*(call_21627076: Call_DescribeTrialComponent_21627064;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_21627076.validator(path, query, header, formData, body, _)
  let scheme = call_21627076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627076.makeUrl(scheme.get, call_21627076.host, call_21627076.base,
                               call_21627076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627076, uri, valid, _)

proc call*(call_21627077: Call_DescribeTrialComponent_21627064; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_21627078 = newJObject()
  if body != nil:
    body_21627078 = body
  result = call_21627077.call(nil, nil, nil, nil, body_21627078)

var describeTrialComponent* = Call_DescribeTrialComponent_21627064(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_21627065, base: "/",
    makeUrl: url_DescribeTrialComponent_21627066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_21627079 = ref object of OpenApiRestCall_21625435
proc url_DescribeUserProfile_21627081(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserProfile_21627080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627082 = header.getOrDefault("X-Amz-Date")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Date", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-Security-Token", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Target")
  valid_21627084 = validateParameter(valid_21627084, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_21627084 != nil:
    section.add "X-Amz-Target", valid_21627084
  var valid_21627085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Algorithm", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Signature")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Signature", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Credential")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Credential", valid_21627089
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

proc call*(call_21627091: Call_DescribeUserProfile_21627079; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_21627091.validator(path, query, header, formData, body, _)
  let scheme = call_21627091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627091.makeUrl(scheme.get, call_21627091.host, call_21627091.base,
                               call_21627091.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627091, uri, valid, _)

proc call*(call_21627092: Call_DescribeUserProfile_21627079; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_21627093 = newJObject()
  if body != nil:
    body_21627093 = body
  result = call_21627092.call(nil, nil, nil, nil, body_21627093)

var describeUserProfile* = Call_DescribeUserProfile_21627079(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_21627080, base: "/",
    makeUrl: url_DescribeUserProfile_21627081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkforce_21627094 = ref object of OpenApiRestCall_21625435
proc url_DescribeWorkforce_21627096(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkforce_21627095(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627097 = header.getOrDefault("X-Amz-Date")
  valid_21627097 = validateParameter(valid_21627097, JString, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "X-Amz-Date", valid_21627097
  var valid_21627098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Security-Token", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Target")
  valid_21627099 = validateParameter(valid_21627099, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkforce"))
  if valid_21627099 != nil:
    section.add "X-Amz-Target", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Algorithm", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Signature")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Signature", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Credential")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Credential", valid_21627104
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

proc call*(call_21627106: Call_DescribeWorkforce_21627094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_21627106.validator(path, query, header, formData, body, _)
  let scheme = call_21627106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627106.makeUrl(scheme.get, call_21627106.host, call_21627106.base,
                               call_21627106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627106, uri, valid, _)

proc call*(call_21627107: Call_DescribeWorkforce_21627094; body: JsonNode): Recallable =
  ## describeWorkforce
  ## <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_21627108 = newJObject()
  if body != nil:
    body_21627108 = body
  result = call_21627107.call(nil, nil, nil, nil, body_21627108)

var describeWorkforce* = Call_DescribeWorkforce_21627094(name: "describeWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkforce",
    validator: validate_DescribeWorkforce_21627095, base: "/",
    makeUrl: url_DescribeWorkforce_21627096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_21627109 = ref object of OpenApiRestCall_21625435
proc url_DescribeWorkteam_21627111(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkteam_21627110(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627112 = header.getOrDefault("X-Amz-Date")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Date", valid_21627112
  var valid_21627113 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Security-Token", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Target")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_21627114 != nil:
    section.add "X-Amz-Target", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Algorithm", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Signature")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Signature", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Credential")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Credential", valid_21627119
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

proc call*(call_21627121: Call_DescribeWorkteam_21627109; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_21627121.validator(path, query, header, formData, body, _)
  let scheme = call_21627121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627121.makeUrl(scheme.get, call_21627121.host, call_21627121.base,
                               call_21627121.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627121, uri, valid, _)

proc call*(call_21627122: Call_DescribeWorkteam_21627109; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_21627123 = newJObject()
  if body != nil:
    body_21627123 = body
  result = call_21627122.call(nil, nil, nil, nil, body_21627123)

var describeWorkteam* = Call_DescribeWorkteam_21627109(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_21627110, base: "/",
    makeUrl: url_DescribeWorkteam_21627111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_21627124 = ref object of OpenApiRestCall_21625435
proc url_DisassociateTrialComponent_21627126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateTrialComponent_21627125(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
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
  var valid_21627127 = header.getOrDefault("X-Amz-Date")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Date", valid_21627127
  var valid_21627128 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "X-Amz-Security-Token", valid_21627128
  var valid_21627129 = header.getOrDefault("X-Amz-Target")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_21627129 != nil:
    section.add "X-Amz-Target", valid_21627129
  var valid_21627130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Algorithm", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Signature")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Signature", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Credential")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Credential", valid_21627134
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

proc call*(call_21627136: Call_DisassociateTrialComponent_21627124;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
  ## 
  let valid = call_21627136.validator(path, query, header, formData, body, _)
  let scheme = call_21627136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627136.makeUrl(scheme.get, call_21627136.host, call_21627136.base,
                               call_21627136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627136, uri, valid, _)

proc call*(call_21627137: Call_DisassociateTrialComponent_21627124; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a>Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
  ##   body: JObject (required)
  var body_21627138 = newJObject()
  if body != nil:
    body_21627138 = body
  result = call_21627137.call(nil, nil, nil, nil, body_21627138)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_21627124(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_21627125, base: "/",
    makeUrl: url_DisassociateTrialComponent_21627126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_21627139 = ref object of OpenApiRestCall_21625435
proc url_GetSearchSuggestions_21627141(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSearchSuggestions_21627140(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627142 = header.getOrDefault("X-Amz-Date")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Date", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-Security-Token", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Target")
  valid_21627144 = validateParameter(valid_21627144, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_21627144 != nil:
    section.add "X-Amz-Target", valid_21627144
  var valid_21627145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Algorithm", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Signature")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "X-Amz-Signature", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Credential")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Credential", valid_21627149
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

proc call*(call_21627151: Call_GetSearchSuggestions_21627139; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_21627151.validator(path, query, header, formData, body, _)
  let scheme = call_21627151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627151.makeUrl(scheme.get, call_21627151.host, call_21627151.base,
                               call_21627151.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627151, uri, valid, _)

proc call*(call_21627152: Call_GetSearchSuggestions_21627139; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_21627153 = newJObject()
  if body != nil:
    body_21627153 = body
  result = call_21627152.call(nil, nil, nil, nil, body_21627153)

var getSearchSuggestions* = Call_GetSearchSuggestions_21627139(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_21627140, base: "/",
    makeUrl: url_GetSearchSuggestions_21627141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_21627154 = ref object of OpenApiRestCall_21625435
proc url_ListAlgorithms_21627156(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAlgorithms_21627155(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627157 = query.getOrDefault("NextToken")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "NextToken", valid_21627157
  var valid_21627158 = query.getOrDefault("MaxResults")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "MaxResults", valid_21627158
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
  var valid_21627159 = header.getOrDefault("X-Amz-Date")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Date", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Security-Token", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Target")
  valid_21627161 = validateParameter(valid_21627161, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_21627161 != nil:
    section.add "X-Amz-Target", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Algorithm", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Signature")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Signature", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-Credential")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Credential", valid_21627166
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

proc call*(call_21627168: Call_ListAlgorithms_21627154; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_21627168.validator(path, query, header, formData, body, _)
  let scheme = call_21627168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627168.makeUrl(scheme.get, call_21627168.host, call_21627168.base,
                               call_21627168.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627168, uri, valid, _)

proc call*(call_21627169: Call_ListAlgorithms_21627154; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627171 = newJObject()
  var body_21627172 = newJObject()
  add(query_21627171, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627172 = body
  add(query_21627171, "MaxResults", newJString(MaxResults))
  result = call_21627169.call(nil, query_21627171, nil, nil, body_21627172)

var listAlgorithms* = Call_ListAlgorithms_21627154(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_21627155, base: "/",
    makeUrl: url_ListAlgorithms_21627156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_21627176 = ref object of OpenApiRestCall_21625435
proc url_ListApps_21627178(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApps_21627177(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists apps.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627179 = query.getOrDefault("NextToken")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "NextToken", valid_21627179
  var valid_21627180 = query.getOrDefault("MaxResults")
  valid_21627180 = validateParameter(valid_21627180, JString, required = false,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "MaxResults", valid_21627180
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
  var valid_21627181 = header.getOrDefault("X-Amz-Date")
  valid_21627181 = validateParameter(valid_21627181, JString, required = false,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "X-Amz-Date", valid_21627181
  var valid_21627182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "X-Amz-Security-Token", valid_21627182
  var valid_21627183 = header.getOrDefault("X-Amz-Target")
  valid_21627183 = validateParameter(valid_21627183, JString, required = true,
                                   default = newJString("SageMaker.ListApps"))
  if valid_21627183 != nil:
    section.add "X-Amz-Target", valid_21627183
  var valid_21627184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Algorithm", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Signature")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Signature", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Credential")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Credential", valid_21627188
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

proc call*(call_21627190: Call_ListApps_21627176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists apps.
  ## 
  let valid = call_21627190.validator(path, query, header, formData, body, _)
  let scheme = call_21627190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627190.makeUrl(scheme.get, call_21627190.host, call_21627190.base,
                               call_21627190.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627190, uri, valid, _)

proc call*(call_21627191: Call_ListApps_21627176; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627192 = newJObject()
  var body_21627193 = newJObject()
  add(query_21627192, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627193 = body
  add(query_21627192, "MaxResults", newJString(MaxResults))
  result = call_21627191.call(nil, query_21627192, nil, nil, body_21627193)

var listApps* = Call_ListApps_21627176(name: "listApps", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com",
                                    route: "/#X-Amz-Target=SageMaker.ListApps",
                                    validator: validate_ListApps_21627177,
                                    base: "/", makeUrl: url_ListApps_21627178,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_21627194 = ref object of OpenApiRestCall_21625435
proc url_ListAutoMLJobs_21627196(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAutoMLJobs_21627195(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627197 = query.getOrDefault("NextToken")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "NextToken", valid_21627197
  var valid_21627198 = query.getOrDefault("MaxResults")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "MaxResults", valid_21627198
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
  var valid_21627199 = header.getOrDefault("X-Amz-Date")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "X-Amz-Date", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Security-Token", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Target")
  valid_21627201 = validateParameter(valid_21627201, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_21627201 != nil:
    section.add "X-Amz-Target", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Algorithm", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-Signature")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-Signature", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627205
  var valid_21627206 = header.getOrDefault("X-Amz-Credential")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Credential", valid_21627206
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

proc call*(call_21627208: Call_ListAutoMLJobs_21627194; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_21627208.validator(path, query, header, formData, body, _)
  let scheme = call_21627208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627208.makeUrl(scheme.get, call_21627208.host, call_21627208.base,
                               call_21627208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627208, uri, valid, _)

proc call*(call_21627209: Call_ListAutoMLJobs_21627194; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627210 = newJObject()
  var body_21627211 = newJObject()
  add(query_21627210, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627211 = body
  add(query_21627210, "MaxResults", newJString(MaxResults))
  result = call_21627209.call(nil, query_21627210, nil, nil, body_21627211)

var listAutoMLJobs* = Call_ListAutoMLJobs_21627194(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_21627195, base: "/",
    makeUrl: url_ListAutoMLJobs_21627196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_21627212 = ref object of OpenApiRestCall_21625435
proc url_ListCandidatesForAutoMLJob_21627214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCandidatesForAutoMLJob_21627213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the Candidates created for the job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627215 = query.getOrDefault("NextToken")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "NextToken", valid_21627215
  var valid_21627216 = query.getOrDefault("MaxResults")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "MaxResults", valid_21627216
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
  var valid_21627217 = header.getOrDefault("X-Amz-Date")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Date", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Security-Token", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Target")
  valid_21627219 = validateParameter(valid_21627219, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_21627219 != nil:
    section.add "X-Amz-Target", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Algorithm", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Signature")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Signature", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Credential")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Credential", valid_21627224
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

proc call*(call_21627226: Call_ListCandidatesForAutoMLJob_21627212;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_21627226.validator(path, query, header, formData, body, _)
  let scheme = call_21627226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627226.makeUrl(scheme.get, call_21627226.host, call_21627226.base,
                               call_21627226.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627226, uri, valid, _)

proc call*(call_21627227: Call_ListCandidatesForAutoMLJob_21627212; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627228 = newJObject()
  var body_21627229 = newJObject()
  add(query_21627228, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627229 = body
  add(query_21627228, "MaxResults", newJString(MaxResults))
  result = call_21627227.call(nil, query_21627228, nil, nil, body_21627229)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_21627212(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_21627213, base: "/",
    makeUrl: url_ListCandidatesForAutoMLJob_21627214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_21627230 = ref object of OpenApiRestCall_21625435
proc url_ListCodeRepositories_21627232(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCodeRepositories_21627231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of the Git repositories in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627233 = query.getOrDefault("NextToken")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "NextToken", valid_21627233
  var valid_21627234 = query.getOrDefault("MaxResults")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "MaxResults", valid_21627234
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
  var valid_21627235 = header.getOrDefault("X-Amz-Date")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Date", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Security-Token", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Target")
  valid_21627237 = validateParameter(valid_21627237, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_21627237 != nil:
    section.add "X-Amz-Target", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Algorithm", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Signature")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Signature", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Credential")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Credential", valid_21627242
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

proc call*(call_21627244: Call_ListCodeRepositories_21627230; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_21627244.validator(path, query, header, formData, body, _)
  let scheme = call_21627244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627244.makeUrl(scheme.get, call_21627244.host, call_21627244.base,
                               call_21627244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627244, uri, valid, _)

proc call*(call_21627245: Call_ListCodeRepositories_21627230; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627246 = newJObject()
  var body_21627247 = newJObject()
  add(query_21627246, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627247 = body
  add(query_21627246, "MaxResults", newJString(MaxResults))
  result = call_21627245.call(nil, query_21627246, nil, nil, body_21627247)

var listCodeRepositories* = Call_ListCodeRepositories_21627230(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_21627231, base: "/",
    makeUrl: url_ListCodeRepositories_21627232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_21627248 = ref object of OpenApiRestCall_21625435
proc url_ListCompilationJobs_21627250(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompilationJobs_21627249(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627251 = query.getOrDefault("NextToken")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "NextToken", valid_21627251
  var valid_21627252 = query.getOrDefault("MaxResults")
  valid_21627252 = validateParameter(valid_21627252, JString, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "MaxResults", valid_21627252
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
  var valid_21627253 = header.getOrDefault("X-Amz-Date")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "X-Amz-Date", valid_21627253
  var valid_21627254 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "X-Amz-Security-Token", valid_21627254
  var valid_21627255 = header.getOrDefault("X-Amz-Target")
  valid_21627255 = validateParameter(valid_21627255, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_21627255 != nil:
    section.add "X-Amz-Target", valid_21627255
  var valid_21627256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Algorithm", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Signature")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Signature", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Credential")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Credential", valid_21627260
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

proc call*(call_21627262: Call_ListCompilationJobs_21627248; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_21627262.validator(path, query, header, formData, body, _)
  let scheme = call_21627262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627262.makeUrl(scheme.get, call_21627262.host, call_21627262.base,
                               call_21627262.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627262, uri, valid, _)

proc call*(call_21627263: Call_ListCompilationJobs_21627248; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627264 = newJObject()
  var body_21627265 = newJObject()
  add(query_21627264, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627265 = body
  add(query_21627264, "MaxResults", newJString(MaxResults))
  result = call_21627263.call(nil, query_21627264, nil, nil, body_21627265)

var listCompilationJobs* = Call_ListCompilationJobs_21627248(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_21627249, base: "/",
    makeUrl: url_ListCompilationJobs_21627250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_21627266 = ref object of OpenApiRestCall_21625435
proc url_ListDomains_21627268(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_21627267(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the domains.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627269 = query.getOrDefault("NextToken")
  valid_21627269 = validateParameter(valid_21627269, JString, required = false,
                                   default = nil)
  if valid_21627269 != nil:
    section.add "NextToken", valid_21627269
  var valid_21627270 = query.getOrDefault("MaxResults")
  valid_21627270 = validateParameter(valid_21627270, JString, required = false,
                                   default = nil)
  if valid_21627270 != nil:
    section.add "MaxResults", valid_21627270
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
  var valid_21627271 = header.getOrDefault("X-Amz-Date")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Date", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Security-Token", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Target")
  valid_21627273 = validateParameter(valid_21627273, JString, required = true, default = newJString(
      "SageMaker.ListDomains"))
  if valid_21627273 != nil:
    section.add "X-Amz-Target", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Algorithm", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Signature")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Signature", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Credential")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Credential", valid_21627278
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

proc call*(call_21627280: Call_ListDomains_21627266; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_21627280.validator(path, query, header, formData, body, _)
  let scheme = call_21627280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627280.makeUrl(scheme.get, call_21627280.host, call_21627280.base,
                               call_21627280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627280, uri, valid, _)

proc call*(call_21627281: Call_ListDomains_21627266; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627282 = newJObject()
  var body_21627283 = newJObject()
  add(query_21627282, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627283 = body
  add(query_21627282, "MaxResults", newJString(MaxResults))
  result = call_21627281.call(nil, query_21627282, nil, nil, body_21627283)

var listDomains* = Call_ListDomains_21627266(name: "listDomains",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListDomains",
    validator: validate_ListDomains_21627267, base: "/", makeUrl: url_ListDomains_21627268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_21627284 = ref object of OpenApiRestCall_21625435
proc url_ListEndpointConfigs_21627286(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpointConfigs_21627285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists endpoint configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627287 = query.getOrDefault("NextToken")
  valid_21627287 = validateParameter(valid_21627287, JString, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "NextToken", valid_21627287
  var valid_21627288 = query.getOrDefault("MaxResults")
  valid_21627288 = validateParameter(valid_21627288, JString, required = false,
                                   default = nil)
  if valid_21627288 != nil:
    section.add "MaxResults", valid_21627288
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
  var valid_21627289 = header.getOrDefault("X-Amz-Date")
  valid_21627289 = validateParameter(valid_21627289, JString, required = false,
                                   default = nil)
  if valid_21627289 != nil:
    section.add "X-Amz-Date", valid_21627289
  var valid_21627290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627290 = validateParameter(valid_21627290, JString, required = false,
                                   default = nil)
  if valid_21627290 != nil:
    section.add "X-Amz-Security-Token", valid_21627290
  var valid_21627291 = header.getOrDefault("X-Amz-Target")
  valid_21627291 = validateParameter(valid_21627291, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_21627291 != nil:
    section.add "X-Amz-Target", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Algorithm", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Signature")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Signature", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-Credential")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-Credential", valid_21627296
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

proc call*(call_21627298: Call_ListEndpointConfigs_21627284; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_21627298.validator(path, query, header, formData, body, _)
  let scheme = call_21627298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627298.makeUrl(scheme.get, call_21627298.host, call_21627298.base,
                               call_21627298.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627298, uri, valid, _)

proc call*(call_21627299: Call_ListEndpointConfigs_21627284; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627300 = newJObject()
  var body_21627301 = newJObject()
  add(query_21627300, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627301 = body
  add(query_21627300, "MaxResults", newJString(MaxResults))
  result = call_21627299.call(nil, query_21627300, nil, nil, body_21627301)

var listEndpointConfigs* = Call_ListEndpointConfigs_21627284(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_21627285, base: "/",
    makeUrl: url_ListEndpointConfigs_21627286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_21627302 = ref object of OpenApiRestCall_21625435
proc url_ListEndpoints_21627304(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_21627303(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists endpoints.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627305 = query.getOrDefault("NextToken")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "NextToken", valid_21627305
  var valid_21627306 = query.getOrDefault("MaxResults")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "MaxResults", valid_21627306
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
  var valid_21627307 = header.getOrDefault("X-Amz-Date")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Date", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Security-Token", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Target")
  valid_21627309 = validateParameter(valid_21627309, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_21627309 != nil:
    section.add "X-Amz-Target", valid_21627309
  var valid_21627310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627310
  var valid_21627311 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627311 = validateParameter(valid_21627311, JString, required = false,
                                   default = nil)
  if valid_21627311 != nil:
    section.add "X-Amz-Algorithm", valid_21627311
  var valid_21627312 = header.getOrDefault("X-Amz-Signature")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Signature", valid_21627312
  var valid_21627313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-Credential")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-Credential", valid_21627314
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

proc call*(call_21627316: Call_ListEndpoints_21627302; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_21627316.validator(path, query, header, formData, body, _)
  let scheme = call_21627316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627316.makeUrl(scheme.get, call_21627316.host, call_21627316.base,
                               call_21627316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627316, uri, valid, _)

proc call*(call_21627317: Call_ListEndpoints_21627302; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627318 = newJObject()
  var body_21627319 = newJObject()
  add(query_21627318, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627319 = body
  add(query_21627318, "MaxResults", newJString(MaxResults))
  result = call_21627317.call(nil, query_21627318, nil, nil, body_21627319)

var listEndpoints* = Call_ListEndpoints_21627302(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_21627303, base: "/",
    makeUrl: url_ListEndpoints_21627304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_21627320 = ref object of OpenApiRestCall_21625435
proc url_ListExperiments_21627322(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExperiments_21627321(path: JsonNode; query: JsonNode;
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
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627323 = query.getOrDefault("NextToken")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "NextToken", valid_21627323
  var valid_21627324 = query.getOrDefault("MaxResults")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "MaxResults", valid_21627324
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
  var valid_21627325 = header.getOrDefault("X-Amz-Date")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "X-Amz-Date", valid_21627325
  var valid_21627326 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "X-Amz-Security-Token", valid_21627326
  var valid_21627327 = header.getOrDefault("X-Amz-Target")
  valid_21627327 = validateParameter(valid_21627327, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_21627327 != nil:
    section.add "X-Amz-Target", valid_21627327
  var valid_21627328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-Algorithm", valid_21627329
  var valid_21627330 = header.getOrDefault("X-Amz-Signature")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "X-Amz-Signature", valid_21627330
  var valid_21627331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627331 = validateParameter(valid_21627331, JString, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627331
  var valid_21627332 = header.getOrDefault("X-Amz-Credential")
  valid_21627332 = validateParameter(valid_21627332, JString, required = false,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "X-Amz-Credential", valid_21627332
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

proc call*(call_21627334: Call_ListExperiments_21627320; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_21627334.validator(path, query, header, formData, body, _)
  let scheme = call_21627334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627334.makeUrl(scheme.get, call_21627334.host, call_21627334.base,
                               call_21627334.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627334, uri, valid, _)

proc call*(call_21627335: Call_ListExperiments_21627320; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627336 = newJObject()
  var body_21627337 = newJObject()
  add(query_21627336, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627337 = body
  add(query_21627336, "MaxResults", newJString(MaxResults))
  result = call_21627335.call(nil, query_21627336, nil, nil, body_21627337)

var listExperiments* = Call_ListExperiments_21627320(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_21627321, base: "/",
    makeUrl: url_ListExperiments_21627322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_21627338 = ref object of OpenApiRestCall_21625435
proc url_ListFlowDefinitions_21627340(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowDefinitions_21627339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the flow definitions in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627341 = query.getOrDefault("NextToken")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "NextToken", valid_21627341
  var valid_21627342 = query.getOrDefault("MaxResults")
  valid_21627342 = validateParameter(valid_21627342, JString, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "MaxResults", valid_21627342
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
  var valid_21627343 = header.getOrDefault("X-Amz-Date")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "X-Amz-Date", valid_21627343
  var valid_21627344 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "X-Amz-Security-Token", valid_21627344
  var valid_21627345 = header.getOrDefault("X-Amz-Target")
  valid_21627345 = validateParameter(valid_21627345, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_21627345 != nil:
    section.add "X-Amz-Target", valid_21627345
  var valid_21627346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627346
  var valid_21627347 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627347 = validateParameter(valid_21627347, JString, required = false,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "X-Amz-Algorithm", valid_21627347
  var valid_21627348 = header.getOrDefault("X-Amz-Signature")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Signature", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Credential")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Credential", valid_21627350
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

proc call*(call_21627352: Call_ListFlowDefinitions_21627338; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_21627352.validator(path, query, header, formData, body, _)
  let scheme = call_21627352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627352.makeUrl(scheme.get, call_21627352.host, call_21627352.base,
                               call_21627352.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627352, uri, valid, _)

proc call*(call_21627353: Call_ListFlowDefinitions_21627338; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627354 = newJObject()
  var body_21627355 = newJObject()
  add(query_21627354, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627355 = body
  add(query_21627354, "MaxResults", newJString(MaxResults))
  result = call_21627353.call(nil, query_21627354, nil, nil, body_21627355)

var listFlowDefinitions* = Call_ListFlowDefinitions_21627338(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_21627339, base: "/",
    makeUrl: url_ListFlowDefinitions_21627340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_21627356 = ref object of OpenApiRestCall_21625435
proc url_ListHumanTaskUis_21627358(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanTaskUis_21627357(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the human task user interfaces in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627359 = query.getOrDefault("NextToken")
  valid_21627359 = validateParameter(valid_21627359, JString, required = false,
                                   default = nil)
  if valid_21627359 != nil:
    section.add "NextToken", valid_21627359
  var valid_21627360 = query.getOrDefault("MaxResults")
  valid_21627360 = validateParameter(valid_21627360, JString, required = false,
                                   default = nil)
  if valid_21627360 != nil:
    section.add "MaxResults", valid_21627360
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
  var valid_21627361 = header.getOrDefault("X-Amz-Date")
  valid_21627361 = validateParameter(valid_21627361, JString, required = false,
                                   default = nil)
  if valid_21627361 != nil:
    section.add "X-Amz-Date", valid_21627361
  var valid_21627362 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "X-Amz-Security-Token", valid_21627362
  var valid_21627363 = header.getOrDefault("X-Amz-Target")
  valid_21627363 = validateParameter(valid_21627363, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_21627363 != nil:
    section.add "X-Amz-Target", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Algorithm", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Signature")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Signature", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Credential")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Credential", valid_21627368
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

proc call*(call_21627370: Call_ListHumanTaskUis_21627356; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_21627370.validator(path, query, header, formData, body, _)
  let scheme = call_21627370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627370.makeUrl(scheme.get, call_21627370.host, call_21627370.base,
                               call_21627370.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627370, uri, valid, _)

proc call*(call_21627371: Call_ListHumanTaskUis_21627356; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627372 = newJObject()
  var body_21627373 = newJObject()
  add(query_21627372, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627373 = body
  add(query_21627372, "MaxResults", newJString(MaxResults))
  result = call_21627371.call(nil, query_21627372, nil, nil, body_21627373)

var listHumanTaskUis* = Call_ListHumanTaskUis_21627356(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_21627357, base: "/",
    makeUrl: url_ListHumanTaskUis_21627358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_21627374 = ref object of OpenApiRestCall_21625435
proc url_ListHyperParameterTuningJobs_21627376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHyperParameterTuningJobs_21627375(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627377 = query.getOrDefault("NextToken")
  valid_21627377 = validateParameter(valid_21627377, JString, required = false,
                                   default = nil)
  if valid_21627377 != nil:
    section.add "NextToken", valid_21627377
  var valid_21627378 = query.getOrDefault("MaxResults")
  valid_21627378 = validateParameter(valid_21627378, JString, required = false,
                                   default = nil)
  if valid_21627378 != nil:
    section.add "MaxResults", valid_21627378
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
  var valid_21627379 = header.getOrDefault("X-Amz-Date")
  valid_21627379 = validateParameter(valid_21627379, JString, required = false,
                                   default = nil)
  if valid_21627379 != nil:
    section.add "X-Amz-Date", valid_21627379
  var valid_21627380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "X-Amz-Security-Token", valid_21627380
  var valid_21627381 = header.getOrDefault("X-Amz-Target")
  valid_21627381 = validateParameter(valid_21627381, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_21627381 != nil:
    section.add "X-Amz-Target", valid_21627381
  var valid_21627382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627382 = validateParameter(valid_21627382, JString, required = false,
                                   default = nil)
  if valid_21627382 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627382
  var valid_21627383 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "X-Amz-Algorithm", valid_21627383
  var valid_21627384 = header.getOrDefault("X-Amz-Signature")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "X-Amz-Signature", valid_21627384
  var valid_21627385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627385
  var valid_21627386 = header.getOrDefault("X-Amz-Credential")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Credential", valid_21627386
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

proc call*(call_21627388: Call_ListHyperParameterTuningJobs_21627374;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_21627388.validator(path, query, header, formData, body, _)
  let scheme = call_21627388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627388.makeUrl(scheme.get, call_21627388.host, call_21627388.base,
                               call_21627388.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627388, uri, valid, _)

proc call*(call_21627389: Call_ListHyperParameterTuningJobs_21627374;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627390 = newJObject()
  var body_21627391 = newJObject()
  add(query_21627390, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627391 = body
  add(query_21627390, "MaxResults", newJString(MaxResults))
  result = call_21627389.call(nil, query_21627390, nil, nil, body_21627391)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_21627374(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_21627375, base: "/",
    makeUrl: url_ListHyperParameterTuningJobs_21627376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_21627392 = ref object of OpenApiRestCall_21625435
proc url_ListLabelingJobs_21627394(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobs_21627393(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of labeling jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627395 = query.getOrDefault("NextToken")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "NextToken", valid_21627395
  var valid_21627396 = query.getOrDefault("MaxResults")
  valid_21627396 = validateParameter(valid_21627396, JString, required = false,
                                   default = nil)
  if valid_21627396 != nil:
    section.add "MaxResults", valid_21627396
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
  var valid_21627397 = header.getOrDefault("X-Amz-Date")
  valid_21627397 = validateParameter(valid_21627397, JString, required = false,
                                   default = nil)
  if valid_21627397 != nil:
    section.add "X-Amz-Date", valid_21627397
  var valid_21627398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Security-Token", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Target")
  valid_21627399 = validateParameter(valid_21627399, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_21627399 != nil:
    section.add "X-Amz-Target", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Algorithm", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Signature")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Signature", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Credential")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Credential", valid_21627404
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

proc call*(call_21627406: Call_ListLabelingJobs_21627392; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_21627406.validator(path, query, header, formData, body, _)
  let scheme = call_21627406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627406.makeUrl(scheme.get, call_21627406.host, call_21627406.base,
                               call_21627406.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627406, uri, valid, _)

proc call*(call_21627407: Call_ListLabelingJobs_21627392; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627408 = newJObject()
  var body_21627409 = newJObject()
  add(query_21627408, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627409 = body
  add(query_21627408, "MaxResults", newJString(MaxResults))
  result = call_21627407.call(nil, query_21627408, nil, nil, body_21627409)

var listLabelingJobs* = Call_ListLabelingJobs_21627392(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_21627393, base: "/",
    makeUrl: url_ListLabelingJobs_21627394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_21627410 = ref object of OpenApiRestCall_21625435
proc url_ListLabelingJobsForWorkteam_21627412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobsForWorkteam_21627411(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627413 = query.getOrDefault("NextToken")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "NextToken", valid_21627413
  var valid_21627414 = query.getOrDefault("MaxResults")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "MaxResults", valid_21627414
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
  var valid_21627415 = header.getOrDefault("X-Amz-Date")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "X-Amz-Date", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Security-Token", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-Target")
  valid_21627417 = validateParameter(valid_21627417, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_21627417 != nil:
    section.add "X-Amz-Target", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627418
  var valid_21627419 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "X-Amz-Algorithm", valid_21627419
  var valid_21627420 = header.getOrDefault("X-Amz-Signature")
  valid_21627420 = validateParameter(valid_21627420, JString, required = false,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "X-Amz-Signature", valid_21627420
  var valid_21627421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627421
  var valid_21627422 = header.getOrDefault("X-Amz-Credential")
  valid_21627422 = validateParameter(valid_21627422, JString, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "X-Amz-Credential", valid_21627422
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

proc call*(call_21627424: Call_ListLabelingJobsForWorkteam_21627410;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_21627424.validator(path, query, header, formData, body, _)
  let scheme = call_21627424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627424.makeUrl(scheme.get, call_21627424.host, call_21627424.base,
                               call_21627424.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627424, uri, valid, _)

proc call*(call_21627425: Call_ListLabelingJobsForWorkteam_21627410;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627426 = newJObject()
  var body_21627427 = newJObject()
  add(query_21627426, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627427 = body
  add(query_21627426, "MaxResults", newJString(MaxResults))
  result = call_21627425.call(nil, query_21627426, nil, nil, body_21627427)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_21627410(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_21627411, base: "/",
    makeUrl: url_ListLabelingJobsForWorkteam_21627412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_21627428 = ref object of OpenApiRestCall_21625435
proc url_ListModelPackages_21627430(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModelPackages_21627429(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the model packages that have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627431 = query.getOrDefault("NextToken")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "NextToken", valid_21627431
  var valid_21627432 = query.getOrDefault("MaxResults")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "MaxResults", valid_21627432
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
  var valid_21627433 = header.getOrDefault("X-Amz-Date")
  valid_21627433 = validateParameter(valid_21627433, JString, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "X-Amz-Date", valid_21627433
  var valid_21627434 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "X-Amz-Security-Token", valid_21627434
  var valid_21627435 = header.getOrDefault("X-Amz-Target")
  valid_21627435 = validateParameter(valid_21627435, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_21627435 != nil:
    section.add "X-Amz-Target", valid_21627435
  var valid_21627436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627436 = validateParameter(valid_21627436, JString, required = false,
                                   default = nil)
  if valid_21627436 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627436
  var valid_21627437 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627437 = validateParameter(valid_21627437, JString, required = false,
                                   default = nil)
  if valid_21627437 != nil:
    section.add "X-Amz-Algorithm", valid_21627437
  var valid_21627438 = header.getOrDefault("X-Amz-Signature")
  valid_21627438 = validateParameter(valid_21627438, JString, required = false,
                                   default = nil)
  if valid_21627438 != nil:
    section.add "X-Amz-Signature", valid_21627438
  var valid_21627439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627439 = validateParameter(valid_21627439, JString, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627439
  var valid_21627440 = header.getOrDefault("X-Amz-Credential")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Credential", valid_21627440
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

proc call*(call_21627442: Call_ListModelPackages_21627428; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_21627442.validator(path, query, header, formData, body, _)
  let scheme = call_21627442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627442.makeUrl(scheme.get, call_21627442.host, call_21627442.base,
                               call_21627442.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627442, uri, valid, _)

proc call*(call_21627443: Call_ListModelPackages_21627428; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627444 = newJObject()
  var body_21627445 = newJObject()
  add(query_21627444, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627445 = body
  add(query_21627444, "MaxResults", newJString(MaxResults))
  result = call_21627443.call(nil, query_21627444, nil, nil, body_21627445)

var listModelPackages* = Call_ListModelPackages_21627428(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_21627429, base: "/",
    makeUrl: url_ListModelPackages_21627430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_21627446 = ref object of OpenApiRestCall_21625435
proc url_ListModels_21627448(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModels_21627447(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627449 = query.getOrDefault("NextToken")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "NextToken", valid_21627449
  var valid_21627450 = query.getOrDefault("MaxResults")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "MaxResults", valid_21627450
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
  var valid_21627451 = header.getOrDefault("X-Amz-Date")
  valid_21627451 = validateParameter(valid_21627451, JString, required = false,
                                   default = nil)
  if valid_21627451 != nil:
    section.add "X-Amz-Date", valid_21627451
  var valid_21627452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627452 = validateParameter(valid_21627452, JString, required = false,
                                   default = nil)
  if valid_21627452 != nil:
    section.add "X-Amz-Security-Token", valid_21627452
  var valid_21627453 = header.getOrDefault("X-Amz-Target")
  valid_21627453 = validateParameter(valid_21627453, JString, required = true,
                                   default = newJString("SageMaker.ListModels"))
  if valid_21627453 != nil:
    section.add "X-Amz-Target", valid_21627453
  var valid_21627454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627454 = validateParameter(valid_21627454, JString, required = false,
                                   default = nil)
  if valid_21627454 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627454
  var valid_21627455 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627455 = validateParameter(valid_21627455, JString, required = false,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "X-Amz-Algorithm", valid_21627455
  var valid_21627456 = header.getOrDefault("X-Amz-Signature")
  valid_21627456 = validateParameter(valid_21627456, JString, required = false,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "X-Amz-Signature", valid_21627456
  var valid_21627457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-Credential")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Credential", valid_21627458
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

proc call*(call_21627460: Call_ListModels_21627446; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_21627460.validator(path, query, header, formData, body, _)
  let scheme = call_21627460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627460.makeUrl(scheme.get, call_21627460.host, call_21627460.base,
                               call_21627460.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627460, uri, valid, _)

proc call*(call_21627461: Call_ListModels_21627446; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627462 = newJObject()
  var body_21627463 = newJObject()
  add(query_21627462, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627463 = body
  add(query_21627462, "MaxResults", newJString(MaxResults))
  result = call_21627461.call(nil, query_21627462, nil, nil, body_21627463)

var listModels* = Call_ListModels_21627446(name: "listModels",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                        validator: validate_ListModels_21627447,
                                        base: "/", makeUrl: url_ListModels_21627448,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_21627464 = ref object of OpenApiRestCall_21625435
proc url_ListMonitoringExecutions_21627466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringExecutions_21627465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns list of all monitoring job executions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627467 = query.getOrDefault("NextToken")
  valid_21627467 = validateParameter(valid_21627467, JString, required = false,
                                   default = nil)
  if valid_21627467 != nil:
    section.add "NextToken", valid_21627467
  var valid_21627468 = query.getOrDefault("MaxResults")
  valid_21627468 = validateParameter(valid_21627468, JString, required = false,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "MaxResults", valid_21627468
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
  var valid_21627469 = header.getOrDefault("X-Amz-Date")
  valid_21627469 = validateParameter(valid_21627469, JString, required = false,
                                   default = nil)
  if valid_21627469 != nil:
    section.add "X-Amz-Date", valid_21627469
  var valid_21627470 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627470 = validateParameter(valid_21627470, JString, required = false,
                                   default = nil)
  if valid_21627470 != nil:
    section.add "X-Amz-Security-Token", valid_21627470
  var valid_21627471 = header.getOrDefault("X-Amz-Target")
  valid_21627471 = validateParameter(valid_21627471, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_21627471 != nil:
    section.add "X-Amz-Target", valid_21627471
  var valid_21627472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627472
  var valid_21627473 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "X-Amz-Algorithm", valid_21627473
  var valid_21627474 = header.getOrDefault("X-Amz-Signature")
  valid_21627474 = validateParameter(valid_21627474, JString, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "X-Amz-Signature", valid_21627474
  var valid_21627475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627475
  var valid_21627476 = header.getOrDefault("X-Amz-Credential")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "X-Amz-Credential", valid_21627476
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

proc call*(call_21627478: Call_ListMonitoringExecutions_21627464;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_21627478.validator(path, query, header, formData, body, _)
  let scheme = call_21627478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627478.makeUrl(scheme.get, call_21627478.host, call_21627478.base,
                               call_21627478.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627478, uri, valid, _)

proc call*(call_21627479: Call_ListMonitoringExecutions_21627464; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627480 = newJObject()
  var body_21627481 = newJObject()
  add(query_21627480, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627481 = body
  add(query_21627480, "MaxResults", newJString(MaxResults))
  result = call_21627479.call(nil, query_21627480, nil, nil, body_21627481)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_21627464(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_21627465, base: "/",
    makeUrl: url_ListMonitoringExecutions_21627466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_21627482 = ref object of OpenApiRestCall_21625435
proc url_ListMonitoringSchedules_21627484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMonitoringSchedules_21627483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns list of all monitoring schedules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627485 = query.getOrDefault("NextToken")
  valid_21627485 = validateParameter(valid_21627485, JString, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "NextToken", valid_21627485
  var valid_21627486 = query.getOrDefault("MaxResults")
  valid_21627486 = validateParameter(valid_21627486, JString, required = false,
                                   default = nil)
  if valid_21627486 != nil:
    section.add "MaxResults", valid_21627486
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
  var valid_21627487 = header.getOrDefault("X-Amz-Date")
  valid_21627487 = validateParameter(valid_21627487, JString, required = false,
                                   default = nil)
  if valid_21627487 != nil:
    section.add "X-Amz-Date", valid_21627487
  var valid_21627488 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-Security-Token", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Target")
  valid_21627489 = validateParameter(valid_21627489, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_21627489 != nil:
    section.add "X-Amz-Target", valid_21627489
  var valid_21627490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627490 = validateParameter(valid_21627490, JString, required = false,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627490
  var valid_21627491 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Algorithm", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Signature")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Signature", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-Credential")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-Credential", valid_21627494
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

proc call*(call_21627496: Call_ListMonitoringSchedules_21627482;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_21627496.validator(path, query, header, formData, body, _)
  let scheme = call_21627496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627496.makeUrl(scheme.get, call_21627496.host, call_21627496.base,
                               call_21627496.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627496, uri, valid, _)

proc call*(call_21627497: Call_ListMonitoringSchedules_21627482; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627498 = newJObject()
  var body_21627499 = newJObject()
  add(query_21627498, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627499 = body
  add(query_21627498, "MaxResults", newJString(MaxResults))
  result = call_21627497.call(nil, query_21627498, nil, nil, body_21627499)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_21627482(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_21627483, base: "/",
    makeUrl: url_ListMonitoringSchedules_21627484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_21627500 = ref object of OpenApiRestCall_21625435
proc url_ListNotebookInstanceLifecycleConfigs_21627502(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_21627501(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627503 = query.getOrDefault("NextToken")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "NextToken", valid_21627503
  var valid_21627504 = query.getOrDefault("MaxResults")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "MaxResults", valid_21627504
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
  var valid_21627505 = header.getOrDefault("X-Amz-Date")
  valid_21627505 = validateParameter(valid_21627505, JString, required = false,
                                   default = nil)
  if valid_21627505 != nil:
    section.add "X-Amz-Date", valid_21627505
  var valid_21627506 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Security-Token", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Target")
  valid_21627507 = validateParameter(valid_21627507, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_21627507 != nil:
    section.add "X-Amz-Target", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-Algorithm", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-Signature")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Signature", valid_21627510
  var valid_21627511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627511
  var valid_21627512 = header.getOrDefault("X-Amz-Credential")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "X-Amz-Credential", valid_21627512
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

proc call*(call_21627514: Call_ListNotebookInstanceLifecycleConfigs_21627500;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_21627514.validator(path, query, header, formData, body, _)
  let scheme = call_21627514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627514.makeUrl(scheme.get, call_21627514.host, call_21627514.base,
                               call_21627514.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627514, uri, valid, _)

proc call*(call_21627515: Call_ListNotebookInstanceLifecycleConfigs_21627500;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627516 = newJObject()
  var body_21627517 = newJObject()
  add(query_21627516, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627517 = body
  add(query_21627516, "MaxResults", newJString(MaxResults))
  result = call_21627515.call(nil, query_21627516, nil, nil, body_21627517)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_21627500(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_21627501, base: "/",
    makeUrl: url_ListNotebookInstanceLifecycleConfigs_21627502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_21627518 = ref object of OpenApiRestCall_21625435
proc url_ListNotebookInstances_21627520(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstances_21627519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627521 = query.getOrDefault("NextToken")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "NextToken", valid_21627521
  var valid_21627522 = query.getOrDefault("MaxResults")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "MaxResults", valid_21627522
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
  var valid_21627523 = header.getOrDefault("X-Amz-Date")
  valid_21627523 = validateParameter(valid_21627523, JString, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "X-Amz-Date", valid_21627523
  var valid_21627524 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "X-Amz-Security-Token", valid_21627524
  var valid_21627525 = header.getOrDefault("X-Amz-Target")
  valid_21627525 = validateParameter(valid_21627525, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_21627525 != nil:
    section.add "X-Amz-Target", valid_21627525
  var valid_21627526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627526 = validateParameter(valid_21627526, JString, required = false,
                                   default = nil)
  if valid_21627526 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627526
  var valid_21627527 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627527 = validateParameter(valid_21627527, JString, required = false,
                                   default = nil)
  if valid_21627527 != nil:
    section.add "X-Amz-Algorithm", valid_21627527
  var valid_21627528 = header.getOrDefault("X-Amz-Signature")
  valid_21627528 = validateParameter(valid_21627528, JString, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "X-Amz-Signature", valid_21627528
  var valid_21627529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627529 = validateParameter(valid_21627529, JString, required = false,
                                   default = nil)
  if valid_21627529 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627529
  var valid_21627530 = header.getOrDefault("X-Amz-Credential")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "X-Amz-Credential", valid_21627530
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

proc call*(call_21627532: Call_ListNotebookInstances_21627518;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_21627532.validator(path, query, header, formData, body, _)
  let scheme = call_21627532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627532.makeUrl(scheme.get, call_21627532.host, call_21627532.base,
                               call_21627532.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627532, uri, valid, _)

proc call*(call_21627533: Call_ListNotebookInstances_21627518; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627534 = newJObject()
  var body_21627535 = newJObject()
  add(query_21627534, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627535 = body
  add(query_21627534, "MaxResults", newJString(MaxResults))
  result = call_21627533.call(nil, query_21627534, nil, nil, body_21627535)

var listNotebookInstances* = Call_ListNotebookInstances_21627518(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_21627519, base: "/",
    makeUrl: url_ListNotebookInstances_21627520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_21627536 = ref object of OpenApiRestCall_21625435
proc url_ListProcessingJobs_21627538(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProcessingJobs_21627537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists processing jobs that satisfy various filters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627539 = query.getOrDefault("NextToken")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "NextToken", valid_21627539
  var valid_21627540 = query.getOrDefault("MaxResults")
  valid_21627540 = validateParameter(valid_21627540, JString, required = false,
                                   default = nil)
  if valid_21627540 != nil:
    section.add "MaxResults", valid_21627540
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
  var valid_21627541 = header.getOrDefault("X-Amz-Date")
  valid_21627541 = validateParameter(valid_21627541, JString, required = false,
                                   default = nil)
  if valid_21627541 != nil:
    section.add "X-Amz-Date", valid_21627541
  var valid_21627542 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627542 = validateParameter(valid_21627542, JString, required = false,
                                   default = nil)
  if valid_21627542 != nil:
    section.add "X-Amz-Security-Token", valid_21627542
  var valid_21627543 = header.getOrDefault("X-Amz-Target")
  valid_21627543 = validateParameter(valid_21627543, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_21627543 != nil:
    section.add "X-Amz-Target", valid_21627543
  var valid_21627544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627544 = validateParameter(valid_21627544, JString, required = false,
                                   default = nil)
  if valid_21627544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627544
  var valid_21627545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Algorithm", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-Signature")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-Signature", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-Credential")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Credential", valid_21627548
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

proc call*(call_21627550: Call_ListProcessingJobs_21627536; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_21627550.validator(path, query, header, formData, body, _)
  let scheme = call_21627550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627550.makeUrl(scheme.get, call_21627550.host, call_21627550.base,
                               call_21627550.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627550, uri, valid, _)

proc call*(call_21627551: Call_ListProcessingJobs_21627536; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627552 = newJObject()
  var body_21627553 = newJObject()
  add(query_21627552, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627553 = body
  add(query_21627552, "MaxResults", newJString(MaxResults))
  result = call_21627551.call(nil, query_21627552, nil, nil, body_21627553)

var listProcessingJobs* = Call_ListProcessingJobs_21627536(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_21627537, base: "/",
    makeUrl: url_ListProcessingJobs_21627538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_21627554 = ref object of OpenApiRestCall_21625435
proc url_ListSubscribedWorkteams_21627556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscribedWorkteams_21627555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627557 = query.getOrDefault("NextToken")
  valid_21627557 = validateParameter(valid_21627557, JString, required = false,
                                   default = nil)
  if valid_21627557 != nil:
    section.add "NextToken", valid_21627557
  var valid_21627558 = query.getOrDefault("MaxResults")
  valid_21627558 = validateParameter(valid_21627558, JString, required = false,
                                   default = nil)
  if valid_21627558 != nil:
    section.add "MaxResults", valid_21627558
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
  var valid_21627559 = header.getOrDefault("X-Amz-Date")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "X-Amz-Date", valid_21627559
  var valid_21627560 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627560 = validateParameter(valid_21627560, JString, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "X-Amz-Security-Token", valid_21627560
  var valid_21627561 = header.getOrDefault("X-Amz-Target")
  valid_21627561 = validateParameter(valid_21627561, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_21627561 != nil:
    section.add "X-Amz-Target", valid_21627561
  var valid_21627562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627562 = validateParameter(valid_21627562, JString, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627562
  var valid_21627563 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "X-Amz-Algorithm", valid_21627563
  var valid_21627564 = header.getOrDefault("X-Amz-Signature")
  valid_21627564 = validateParameter(valid_21627564, JString, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "X-Amz-Signature", valid_21627564
  var valid_21627565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627565 = validateParameter(valid_21627565, JString, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627565
  var valid_21627566 = header.getOrDefault("X-Amz-Credential")
  valid_21627566 = validateParameter(valid_21627566, JString, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "X-Amz-Credential", valid_21627566
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

proc call*(call_21627568: Call_ListSubscribedWorkteams_21627554;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_21627568.validator(path, query, header, formData, body, _)
  let scheme = call_21627568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627568.makeUrl(scheme.get, call_21627568.host, call_21627568.base,
                               call_21627568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627568, uri, valid, _)

proc call*(call_21627569: Call_ListSubscribedWorkteams_21627554; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627570 = newJObject()
  var body_21627571 = newJObject()
  add(query_21627570, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627571 = body
  add(query_21627570, "MaxResults", newJString(MaxResults))
  result = call_21627569.call(nil, query_21627570, nil, nil, body_21627571)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_21627554(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_21627555, base: "/",
    makeUrl: url_ListSubscribedWorkteams_21627556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_21627572 = ref object of OpenApiRestCall_21625435
proc url_ListTags_21627574(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_21627573(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627575 = query.getOrDefault("NextToken")
  valid_21627575 = validateParameter(valid_21627575, JString, required = false,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "NextToken", valid_21627575
  var valid_21627576 = query.getOrDefault("MaxResults")
  valid_21627576 = validateParameter(valid_21627576, JString, required = false,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "MaxResults", valid_21627576
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
  var valid_21627577 = header.getOrDefault("X-Amz-Date")
  valid_21627577 = validateParameter(valid_21627577, JString, required = false,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "X-Amz-Date", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Security-Token", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Target")
  valid_21627579 = validateParameter(valid_21627579, JString, required = true,
                                   default = newJString("SageMaker.ListTags"))
  if valid_21627579 != nil:
    section.add "X-Amz-Target", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-Algorithm", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Signature")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Signature", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627583
  var valid_21627584 = header.getOrDefault("X-Amz-Credential")
  valid_21627584 = validateParameter(valid_21627584, JString, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "X-Amz-Credential", valid_21627584
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

proc call*(call_21627586: Call_ListTags_21627572; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_21627586.validator(path, query, header, formData, body, _)
  let scheme = call_21627586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627586.makeUrl(scheme.get, call_21627586.host, call_21627586.base,
                               call_21627586.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627586, uri, valid, _)

proc call*(call_21627587: Call_ListTags_21627572; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627588 = newJObject()
  var body_21627589 = newJObject()
  add(query_21627588, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627589 = body
  add(query_21627588, "MaxResults", newJString(MaxResults))
  result = call_21627587.call(nil, query_21627588, nil, nil, body_21627589)

var listTags* = Call_ListTags_21627572(name: "listTags", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com",
                                    route: "/#X-Amz-Target=SageMaker.ListTags",
                                    validator: validate_ListTags_21627573,
                                    base: "/", makeUrl: url_ListTags_21627574,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_21627590 = ref object of OpenApiRestCall_21625435
proc url_ListTrainingJobs_21627592(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobs_21627591(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists training jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627593 = query.getOrDefault("NextToken")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "NextToken", valid_21627593
  var valid_21627594 = query.getOrDefault("MaxResults")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "MaxResults", valid_21627594
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
  var valid_21627595 = header.getOrDefault("X-Amz-Date")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Date", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Security-Token", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Target")
  valid_21627597 = validateParameter(valid_21627597, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_21627597 != nil:
    section.add "X-Amz-Target", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627598
  var valid_21627599 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627599 = validateParameter(valid_21627599, JString, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "X-Amz-Algorithm", valid_21627599
  var valid_21627600 = header.getOrDefault("X-Amz-Signature")
  valid_21627600 = validateParameter(valid_21627600, JString, required = false,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "X-Amz-Signature", valid_21627600
  var valid_21627601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627601 = validateParameter(valid_21627601, JString, required = false,
                                   default = nil)
  if valid_21627601 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627601
  var valid_21627602 = header.getOrDefault("X-Amz-Credential")
  valid_21627602 = validateParameter(valid_21627602, JString, required = false,
                                   default = nil)
  if valid_21627602 != nil:
    section.add "X-Amz-Credential", valid_21627602
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

proc call*(call_21627604: Call_ListTrainingJobs_21627590; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_21627604.validator(path, query, header, formData, body, _)
  let scheme = call_21627604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627604.makeUrl(scheme.get, call_21627604.host, call_21627604.base,
                               call_21627604.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627604, uri, valid, _)

proc call*(call_21627605: Call_ListTrainingJobs_21627590; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627606 = newJObject()
  var body_21627607 = newJObject()
  add(query_21627606, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627607 = body
  add(query_21627606, "MaxResults", newJString(MaxResults))
  result = call_21627605.call(nil, query_21627606, nil, nil, body_21627607)

var listTrainingJobs* = Call_ListTrainingJobs_21627590(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_21627591, base: "/",
    makeUrl: url_ListTrainingJobs_21627592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_21627608 = ref object of OpenApiRestCall_21625435
proc url_ListTrainingJobsForHyperParameterTuningJob_21627610(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_21627609(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627611 = query.getOrDefault("NextToken")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "NextToken", valid_21627611
  var valid_21627612 = query.getOrDefault("MaxResults")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "MaxResults", valid_21627612
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
  var valid_21627613 = header.getOrDefault("X-Amz-Date")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "X-Amz-Date", valid_21627613
  var valid_21627614 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "X-Amz-Security-Token", valid_21627614
  var valid_21627615 = header.getOrDefault("X-Amz-Target")
  valid_21627615 = validateParameter(valid_21627615, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_21627615 != nil:
    section.add "X-Amz-Target", valid_21627615
  var valid_21627616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627616 = validateParameter(valid_21627616, JString, required = false,
                                   default = nil)
  if valid_21627616 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627616
  var valid_21627617 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627617 = validateParameter(valid_21627617, JString, required = false,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "X-Amz-Algorithm", valid_21627617
  var valid_21627618 = header.getOrDefault("X-Amz-Signature")
  valid_21627618 = validateParameter(valid_21627618, JString, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "X-Amz-Signature", valid_21627618
  var valid_21627619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627619 = validateParameter(valid_21627619, JString, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627619
  var valid_21627620 = header.getOrDefault("X-Amz-Credential")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "X-Amz-Credential", valid_21627620
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

proc call*(call_21627622: Call_ListTrainingJobsForHyperParameterTuningJob_21627608;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_21627622.validator(path, query, header, formData, body, _)
  let scheme = call_21627622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627622.makeUrl(scheme.get, call_21627622.host, call_21627622.base,
                               call_21627622.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627622, uri, valid, _)

proc call*(call_21627623: Call_ListTrainingJobsForHyperParameterTuningJob_21627608;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627624 = newJObject()
  var body_21627625 = newJObject()
  add(query_21627624, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627625 = body
  add(query_21627624, "MaxResults", newJString(MaxResults))
  result = call_21627623.call(nil, query_21627624, nil, nil, body_21627625)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_21627608(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_21627609,
    base: "/", makeUrl: url_ListTrainingJobsForHyperParameterTuningJob_21627610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_21627626 = ref object of OpenApiRestCall_21625435
proc url_ListTransformJobs_21627628(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTransformJobs_21627627(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists transform jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627629 = query.getOrDefault("NextToken")
  valid_21627629 = validateParameter(valid_21627629, JString, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "NextToken", valid_21627629
  var valid_21627630 = query.getOrDefault("MaxResults")
  valid_21627630 = validateParameter(valid_21627630, JString, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "MaxResults", valid_21627630
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
  var valid_21627631 = header.getOrDefault("X-Amz-Date")
  valid_21627631 = validateParameter(valid_21627631, JString, required = false,
                                   default = nil)
  if valid_21627631 != nil:
    section.add "X-Amz-Date", valid_21627631
  var valid_21627632 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627632 = validateParameter(valid_21627632, JString, required = false,
                                   default = nil)
  if valid_21627632 != nil:
    section.add "X-Amz-Security-Token", valid_21627632
  var valid_21627633 = header.getOrDefault("X-Amz-Target")
  valid_21627633 = validateParameter(valid_21627633, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_21627633 != nil:
    section.add "X-Amz-Target", valid_21627633
  var valid_21627634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627634 = validateParameter(valid_21627634, JString, required = false,
                                   default = nil)
  if valid_21627634 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627634
  var valid_21627635 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627635 = validateParameter(valid_21627635, JString, required = false,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "X-Amz-Algorithm", valid_21627635
  var valid_21627636 = header.getOrDefault("X-Amz-Signature")
  valid_21627636 = validateParameter(valid_21627636, JString, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "X-Amz-Signature", valid_21627636
  var valid_21627637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627637 = validateParameter(valid_21627637, JString, required = false,
                                   default = nil)
  if valid_21627637 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627637
  var valid_21627638 = header.getOrDefault("X-Amz-Credential")
  valid_21627638 = validateParameter(valid_21627638, JString, required = false,
                                   default = nil)
  if valid_21627638 != nil:
    section.add "X-Amz-Credential", valid_21627638
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

proc call*(call_21627640: Call_ListTransformJobs_21627626; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_21627640.validator(path, query, header, formData, body, _)
  let scheme = call_21627640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627640.makeUrl(scheme.get, call_21627640.host, call_21627640.base,
                               call_21627640.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627640, uri, valid, _)

proc call*(call_21627641: Call_ListTransformJobs_21627626; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627642 = newJObject()
  var body_21627643 = newJObject()
  add(query_21627642, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627643 = body
  add(query_21627642, "MaxResults", newJString(MaxResults))
  result = call_21627641.call(nil, query_21627642, nil, nil, body_21627643)

var listTransformJobs* = Call_ListTransformJobs_21627626(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_21627627, base: "/",
    makeUrl: url_ListTransformJobs_21627628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_21627644 = ref object of OpenApiRestCall_21625435
proc url_ListTrialComponents_21627646(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrialComponents_21627645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627647 = query.getOrDefault("NextToken")
  valid_21627647 = validateParameter(valid_21627647, JString, required = false,
                                   default = nil)
  if valid_21627647 != nil:
    section.add "NextToken", valid_21627647
  var valid_21627648 = query.getOrDefault("MaxResults")
  valid_21627648 = validateParameter(valid_21627648, JString, required = false,
                                   default = nil)
  if valid_21627648 != nil:
    section.add "MaxResults", valid_21627648
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
  var valid_21627649 = header.getOrDefault("X-Amz-Date")
  valid_21627649 = validateParameter(valid_21627649, JString, required = false,
                                   default = nil)
  if valid_21627649 != nil:
    section.add "X-Amz-Date", valid_21627649
  var valid_21627650 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "X-Amz-Security-Token", valid_21627650
  var valid_21627651 = header.getOrDefault("X-Amz-Target")
  valid_21627651 = validateParameter(valid_21627651, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_21627651 != nil:
    section.add "X-Amz-Target", valid_21627651
  var valid_21627652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627652 = validateParameter(valid_21627652, JString, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627652
  var valid_21627653 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "X-Amz-Algorithm", valid_21627653
  var valid_21627654 = header.getOrDefault("X-Amz-Signature")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "X-Amz-Signature", valid_21627654
  var valid_21627655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627655
  var valid_21627656 = header.getOrDefault("X-Amz-Credential")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "X-Amz-Credential", valid_21627656
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

proc call*(call_21627658: Call_ListTrialComponents_21627644; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ## 
  let valid = call_21627658.validator(path, query, header, formData, body, _)
  let scheme = call_21627658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627658.makeUrl(scheme.get, call_21627658.host, call_21627658.base,
                               call_21627658.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627658, uri, valid, _)

proc call*(call_21627659: Call_ListTrialComponents_21627644; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrialComponents
  ## <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627660 = newJObject()
  var body_21627661 = newJObject()
  add(query_21627660, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627661 = body
  add(query_21627660, "MaxResults", newJString(MaxResults))
  result = call_21627659.call(nil, query_21627660, nil, nil, body_21627661)

var listTrialComponents* = Call_ListTrialComponents_21627644(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_21627645, base: "/",
    makeUrl: url_ListTrialComponents_21627646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_21627662 = ref object of OpenApiRestCall_21625435
proc url_ListTrials_21627664(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrials_21627663(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627665 = query.getOrDefault("NextToken")
  valid_21627665 = validateParameter(valid_21627665, JString, required = false,
                                   default = nil)
  if valid_21627665 != nil:
    section.add "NextToken", valid_21627665
  var valid_21627666 = query.getOrDefault("MaxResults")
  valid_21627666 = validateParameter(valid_21627666, JString, required = false,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "MaxResults", valid_21627666
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
  var valid_21627667 = header.getOrDefault("X-Amz-Date")
  valid_21627667 = validateParameter(valid_21627667, JString, required = false,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "X-Amz-Date", valid_21627667
  var valid_21627668 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Security-Token", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Target")
  valid_21627669 = validateParameter(valid_21627669, JString, required = true,
                                   default = newJString("SageMaker.ListTrials"))
  if valid_21627669 != nil:
    section.add "X-Amz-Target", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Algorithm", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Signature")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Signature", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Credential")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Credential", valid_21627674
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

proc call*(call_21627676: Call_ListTrials_21627662; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_21627676.validator(path, query, header, formData, body, _)
  let scheme = call_21627676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627676.makeUrl(scheme.get, call_21627676.host, call_21627676.base,
                               call_21627676.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627676, uri, valid, _)

proc call*(call_21627677: Call_ListTrials_21627662; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627678 = newJObject()
  var body_21627679 = newJObject()
  add(query_21627678, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627679 = body
  add(query_21627678, "MaxResults", newJString(MaxResults))
  result = call_21627677.call(nil, query_21627678, nil, nil, body_21627679)

var listTrials* = Call_ListTrials_21627662(name: "listTrials",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                        validator: validate_ListTrials_21627663,
                                        base: "/", makeUrl: url_ListTrials_21627664,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_21627680 = ref object of OpenApiRestCall_21625435
proc url_ListUserProfiles_21627682(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserProfiles_21627681(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists user profiles.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627683 = query.getOrDefault("NextToken")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "NextToken", valid_21627683
  var valid_21627684 = query.getOrDefault("MaxResults")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "MaxResults", valid_21627684
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
  var valid_21627685 = header.getOrDefault("X-Amz-Date")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Date", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Security-Token", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Target")
  valid_21627687 = validateParameter(valid_21627687, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_21627687 != nil:
    section.add "X-Amz-Target", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Algorithm", valid_21627689
  var valid_21627690 = header.getOrDefault("X-Amz-Signature")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "X-Amz-Signature", valid_21627690
  var valid_21627691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627691 = validateParameter(valid_21627691, JString, required = false,
                                   default = nil)
  if valid_21627691 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627691
  var valid_21627692 = header.getOrDefault("X-Amz-Credential")
  valid_21627692 = validateParameter(valid_21627692, JString, required = false,
                                   default = nil)
  if valid_21627692 != nil:
    section.add "X-Amz-Credential", valid_21627692
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

proc call*(call_21627694: Call_ListUserProfiles_21627680; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_21627694.validator(path, query, header, formData, body, _)
  let scheme = call_21627694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627694.makeUrl(scheme.get, call_21627694.host, call_21627694.base,
                               call_21627694.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627694, uri, valid, _)

proc call*(call_21627695: Call_ListUserProfiles_21627680; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627696 = newJObject()
  var body_21627697 = newJObject()
  add(query_21627696, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627697 = body
  add(query_21627696, "MaxResults", newJString(MaxResults))
  result = call_21627695.call(nil, query_21627696, nil, nil, body_21627697)

var listUserProfiles* = Call_ListUserProfiles_21627680(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_21627681, base: "/",
    makeUrl: url_ListUserProfiles_21627682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_21627698 = ref object of OpenApiRestCall_21625435
proc url_ListWorkteams_21627700(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkteams_21627699(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627701 = query.getOrDefault("NextToken")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "NextToken", valid_21627701
  var valid_21627702 = query.getOrDefault("MaxResults")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "MaxResults", valid_21627702
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
  var valid_21627703 = header.getOrDefault("X-Amz-Date")
  valid_21627703 = validateParameter(valid_21627703, JString, required = false,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "X-Amz-Date", valid_21627703
  var valid_21627704 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627704 = validateParameter(valid_21627704, JString, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "X-Amz-Security-Token", valid_21627704
  var valid_21627705 = header.getOrDefault("X-Amz-Target")
  valid_21627705 = validateParameter(valid_21627705, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_21627705 != nil:
    section.add "X-Amz-Target", valid_21627705
  var valid_21627706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627706 = validateParameter(valid_21627706, JString, required = false,
                                   default = nil)
  if valid_21627706 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627706
  var valid_21627707 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627707 = validateParameter(valid_21627707, JString, required = false,
                                   default = nil)
  if valid_21627707 != nil:
    section.add "X-Amz-Algorithm", valid_21627707
  var valid_21627708 = header.getOrDefault("X-Amz-Signature")
  valid_21627708 = validateParameter(valid_21627708, JString, required = false,
                                   default = nil)
  if valid_21627708 != nil:
    section.add "X-Amz-Signature", valid_21627708
  var valid_21627709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627709 = validateParameter(valid_21627709, JString, required = false,
                                   default = nil)
  if valid_21627709 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627709
  var valid_21627710 = header.getOrDefault("X-Amz-Credential")
  valid_21627710 = validateParameter(valid_21627710, JString, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "X-Amz-Credential", valid_21627710
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

proc call*(call_21627712: Call_ListWorkteams_21627698; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_21627712.validator(path, query, header, formData, body, _)
  let scheme = call_21627712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627712.makeUrl(scheme.get, call_21627712.host, call_21627712.base,
                               call_21627712.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627712, uri, valid, _)

proc call*(call_21627713: Call_ListWorkteams_21627698; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627714 = newJObject()
  var body_21627715 = newJObject()
  add(query_21627714, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627715 = body
  add(query_21627714, "MaxResults", newJString(MaxResults))
  result = call_21627713.call(nil, query_21627714, nil, nil, body_21627715)

var listWorkteams* = Call_ListWorkteams_21627698(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_21627699, base: "/",
    makeUrl: url_ListWorkteams_21627700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_21627716 = ref object of OpenApiRestCall_21625435
proc url_RenderUiTemplate_21627718(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenderUiTemplate_21627717(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627719 = header.getOrDefault("X-Amz-Date")
  valid_21627719 = validateParameter(valid_21627719, JString, required = false,
                                   default = nil)
  if valid_21627719 != nil:
    section.add "X-Amz-Date", valid_21627719
  var valid_21627720 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627720 = validateParameter(valid_21627720, JString, required = false,
                                   default = nil)
  if valid_21627720 != nil:
    section.add "X-Amz-Security-Token", valid_21627720
  var valid_21627721 = header.getOrDefault("X-Amz-Target")
  valid_21627721 = validateParameter(valid_21627721, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_21627721 != nil:
    section.add "X-Amz-Target", valid_21627721
  var valid_21627722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627722 = validateParameter(valid_21627722, JString, required = false,
                                   default = nil)
  if valid_21627722 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627722
  var valid_21627723 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627723 = validateParameter(valid_21627723, JString, required = false,
                                   default = nil)
  if valid_21627723 != nil:
    section.add "X-Amz-Algorithm", valid_21627723
  var valid_21627724 = header.getOrDefault("X-Amz-Signature")
  valid_21627724 = validateParameter(valid_21627724, JString, required = false,
                                   default = nil)
  if valid_21627724 != nil:
    section.add "X-Amz-Signature", valid_21627724
  var valid_21627725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627725
  var valid_21627726 = header.getOrDefault("X-Amz-Credential")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "X-Amz-Credential", valid_21627726
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

proc call*(call_21627728: Call_RenderUiTemplate_21627716; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_21627728.validator(path, query, header, formData, body, _)
  let scheme = call_21627728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627728.makeUrl(scheme.get, call_21627728.host, call_21627728.base,
                               call_21627728.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627728, uri, valid, _)

proc call*(call_21627729: Call_RenderUiTemplate_21627716; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_21627730 = newJObject()
  if body != nil:
    body_21627730 = body
  result = call_21627729.call(nil, nil, nil, nil, body_21627730)

var renderUiTemplate* = Call_RenderUiTemplate_21627716(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_21627717, base: "/",
    makeUrl: url_RenderUiTemplate_21627718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_21627731 = ref object of OpenApiRestCall_21625435
proc url_Search_21627733(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Search_21627732(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21627734 = query.getOrDefault("NextToken")
  valid_21627734 = validateParameter(valid_21627734, JString, required = false,
                                   default = nil)
  if valid_21627734 != nil:
    section.add "NextToken", valid_21627734
  var valid_21627735 = query.getOrDefault("MaxResults")
  valid_21627735 = validateParameter(valid_21627735, JString, required = false,
                                   default = nil)
  if valid_21627735 != nil:
    section.add "MaxResults", valid_21627735
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
  var valid_21627736 = header.getOrDefault("X-Amz-Date")
  valid_21627736 = validateParameter(valid_21627736, JString, required = false,
                                   default = nil)
  if valid_21627736 != nil:
    section.add "X-Amz-Date", valid_21627736
  var valid_21627737 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627737 = validateParameter(valid_21627737, JString, required = false,
                                   default = nil)
  if valid_21627737 != nil:
    section.add "X-Amz-Security-Token", valid_21627737
  var valid_21627738 = header.getOrDefault("X-Amz-Target")
  valid_21627738 = validateParameter(valid_21627738, JString, required = true,
                                   default = newJString("SageMaker.Search"))
  if valid_21627738 != nil:
    section.add "X-Amz-Target", valid_21627738
  var valid_21627739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627739 = validateParameter(valid_21627739, JString, required = false,
                                   default = nil)
  if valid_21627739 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627739
  var valid_21627740 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627740 = validateParameter(valid_21627740, JString, required = false,
                                   default = nil)
  if valid_21627740 != nil:
    section.add "X-Amz-Algorithm", valid_21627740
  var valid_21627741 = header.getOrDefault("X-Amz-Signature")
  valid_21627741 = validateParameter(valid_21627741, JString, required = false,
                                   default = nil)
  if valid_21627741 != nil:
    section.add "X-Amz-Signature", valid_21627741
  var valid_21627742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627742 = validateParameter(valid_21627742, JString, required = false,
                                   default = nil)
  if valid_21627742 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627742
  var valid_21627743 = header.getOrDefault("X-Amz-Credential")
  valid_21627743 = validateParameter(valid_21627743, JString, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "X-Amz-Credential", valid_21627743
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

proc call*(call_21627745: Call_Search_21627731; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  let valid = call_21627745.validator(path, query, header, formData, body, _)
  let scheme = call_21627745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627745.makeUrl(scheme.get, call_21627745.host, call_21627745.base,
                               call_21627745.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627745, uri, valid, _)

proc call*(call_21627746: Call_Search_21627731; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21627747 = newJObject()
  var body_21627748 = newJObject()
  add(query_21627747, "NextToken", newJString(NextToken))
  if body != nil:
    body_21627748 = body
  add(query_21627747, "MaxResults", newJString(MaxResults))
  result = call_21627746.call(nil, query_21627747, nil, nil, body_21627748)

var search* = Call_Search_21627731(name: "search", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.Search",
                                validator: validate_Search_21627732, base: "/",
                                makeUrl: url_Search_21627733,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_21627749 = ref object of OpenApiRestCall_21625435
proc url_StartMonitoringSchedule_21627751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMonitoringSchedule_21627750(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627752 = header.getOrDefault("X-Amz-Date")
  valid_21627752 = validateParameter(valid_21627752, JString, required = false,
                                   default = nil)
  if valid_21627752 != nil:
    section.add "X-Amz-Date", valid_21627752
  var valid_21627753 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627753 = validateParameter(valid_21627753, JString, required = false,
                                   default = nil)
  if valid_21627753 != nil:
    section.add "X-Amz-Security-Token", valid_21627753
  var valid_21627754 = header.getOrDefault("X-Amz-Target")
  valid_21627754 = validateParameter(valid_21627754, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_21627754 != nil:
    section.add "X-Amz-Target", valid_21627754
  var valid_21627755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627755 = validateParameter(valid_21627755, JString, required = false,
                                   default = nil)
  if valid_21627755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627755
  var valid_21627756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627756 = validateParameter(valid_21627756, JString, required = false,
                                   default = nil)
  if valid_21627756 != nil:
    section.add "X-Amz-Algorithm", valid_21627756
  var valid_21627757 = header.getOrDefault("X-Amz-Signature")
  valid_21627757 = validateParameter(valid_21627757, JString, required = false,
                                   default = nil)
  if valid_21627757 != nil:
    section.add "X-Amz-Signature", valid_21627757
  var valid_21627758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627758 = validateParameter(valid_21627758, JString, required = false,
                                   default = nil)
  if valid_21627758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627758
  var valid_21627759 = header.getOrDefault("X-Amz-Credential")
  valid_21627759 = validateParameter(valid_21627759, JString, required = false,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "X-Amz-Credential", valid_21627759
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

proc call*(call_21627761: Call_StartMonitoringSchedule_21627749;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_21627761.validator(path, query, header, formData, body, _)
  let scheme = call_21627761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627761.makeUrl(scheme.get, call_21627761.host, call_21627761.base,
                               call_21627761.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627761, uri, valid, _)

proc call*(call_21627762: Call_StartMonitoringSchedule_21627749; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_21627763 = newJObject()
  if body != nil:
    body_21627763 = body
  result = call_21627762.call(nil, nil, nil, nil, body_21627763)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_21627749(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_21627750, base: "/",
    makeUrl: url_StartMonitoringSchedule_21627751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_21627764 = ref object of OpenApiRestCall_21625435
proc url_StartNotebookInstance_21627766(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartNotebookInstance_21627765(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627767 = header.getOrDefault("X-Amz-Date")
  valid_21627767 = validateParameter(valid_21627767, JString, required = false,
                                   default = nil)
  if valid_21627767 != nil:
    section.add "X-Amz-Date", valid_21627767
  var valid_21627768 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627768 = validateParameter(valid_21627768, JString, required = false,
                                   default = nil)
  if valid_21627768 != nil:
    section.add "X-Amz-Security-Token", valid_21627768
  var valid_21627769 = header.getOrDefault("X-Amz-Target")
  valid_21627769 = validateParameter(valid_21627769, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_21627769 != nil:
    section.add "X-Amz-Target", valid_21627769
  var valid_21627770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627770 = validateParameter(valid_21627770, JString, required = false,
                                   default = nil)
  if valid_21627770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627770
  var valid_21627771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627771 = validateParameter(valid_21627771, JString, required = false,
                                   default = nil)
  if valid_21627771 != nil:
    section.add "X-Amz-Algorithm", valid_21627771
  var valid_21627772 = header.getOrDefault("X-Amz-Signature")
  valid_21627772 = validateParameter(valid_21627772, JString, required = false,
                                   default = nil)
  if valid_21627772 != nil:
    section.add "X-Amz-Signature", valid_21627772
  var valid_21627773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627773 = validateParameter(valid_21627773, JString, required = false,
                                   default = nil)
  if valid_21627773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627773
  var valid_21627774 = header.getOrDefault("X-Amz-Credential")
  valid_21627774 = validateParameter(valid_21627774, JString, required = false,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "X-Amz-Credential", valid_21627774
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

proc call*(call_21627776: Call_StartNotebookInstance_21627764;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_21627776.validator(path, query, header, formData, body, _)
  let scheme = call_21627776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627776.makeUrl(scheme.get, call_21627776.host, call_21627776.base,
                               call_21627776.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627776, uri, valid, _)

proc call*(call_21627777: Call_StartNotebookInstance_21627764; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_21627778 = newJObject()
  if body != nil:
    body_21627778 = body
  result = call_21627777.call(nil, nil, nil, nil, body_21627778)

var startNotebookInstance* = Call_StartNotebookInstance_21627764(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_21627765, base: "/",
    makeUrl: url_StartNotebookInstance_21627766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_21627779 = ref object of OpenApiRestCall_21625435
proc url_StopAutoMLJob_21627781(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutoMLJob_21627780(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## A method for forcing the termination of a running job.
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
  var valid_21627782 = header.getOrDefault("X-Amz-Date")
  valid_21627782 = validateParameter(valid_21627782, JString, required = false,
                                   default = nil)
  if valid_21627782 != nil:
    section.add "X-Amz-Date", valid_21627782
  var valid_21627783 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627783 = validateParameter(valid_21627783, JString, required = false,
                                   default = nil)
  if valid_21627783 != nil:
    section.add "X-Amz-Security-Token", valid_21627783
  var valid_21627784 = header.getOrDefault("X-Amz-Target")
  valid_21627784 = validateParameter(valid_21627784, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_21627784 != nil:
    section.add "X-Amz-Target", valid_21627784
  var valid_21627785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627785 = validateParameter(valid_21627785, JString, required = false,
                                   default = nil)
  if valid_21627785 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627785
  var valid_21627786 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627786 = validateParameter(valid_21627786, JString, required = false,
                                   default = nil)
  if valid_21627786 != nil:
    section.add "X-Amz-Algorithm", valid_21627786
  var valid_21627787 = header.getOrDefault("X-Amz-Signature")
  valid_21627787 = validateParameter(valid_21627787, JString, required = false,
                                   default = nil)
  if valid_21627787 != nil:
    section.add "X-Amz-Signature", valid_21627787
  var valid_21627788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627788 = validateParameter(valid_21627788, JString, required = false,
                                   default = nil)
  if valid_21627788 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627788
  var valid_21627789 = header.getOrDefault("X-Amz-Credential")
  valid_21627789 = validateParameter(valid_21627789, JString, required = false,
                                   default = nil)
  if valid_21627789 != nil:
    section.add "X-Amz-Credential", valid_21627789
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

proc call*(call_21627791: Call_StopAutoMLJob_21627779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_21627791.validator(path, query, header, formData, body, _)
  let scheme = call_21627791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627791.makeUrl(scheme.get, call_21627791.host, call_21627791.base,
                               call_21627791.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627791, uri, valid, _)

proc call*(call_21627792: Call_StopAutoMLJob_21627779; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_21627793 = newJObject()
  if body != nil:
    body_21627793 = body
  result = call_21627792.call(nil, nil, nil, nil, body_21627793)

var stopAutoMLJob* = Call_StopAutoMLJob_21627779(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_21627780, base: "/",
    makeUrl: url_StopAutoMLJob_21627781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_21627794 = ref object of OpenApiRestCall_21625435
proc url_StopCompilationJob_21627796(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCompilationJob_21627795(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627797 = header.getOrDefault("X-Amz-Date")
  valid_21627797 = validateParameter(valid_21627797, JString, required = false,
                                   default = nil)
  if valid_21627797 != nil:
    section.add "X-Amz-Date", valid_21627797
  var valid_21627798 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627798 = validateParameter(valid_21627798, JString, required = false,
                                   default = nil)
  if valid_21627798 != nil:
    section.add "X-Amz-Security-Token", valid_21627798
  var valid_21627799 = header.getOrDefault("X-Amz-Target")
  valid_21627799 = validateParameter(valid_21627799, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_21627799 != nil:
    section.add "X-Amz-Target", valid_21627799
  var valid_21627800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627800 = validateParameter(valid_21627800, JString, required = false,
                                   default = nil)
  if valid_21627800 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627800
  var valid_21627801 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627801 = validateParameter(valid_21627801, JString, required = false,
                                   default = nil)
  if valid_21627801 != nil:
    section.add "X-Amz-Algorithm", valid_21627801
  var valid_21627802 = header.getOrDefault("X-Amz-Signature")
  valid_21627802 = validateParameter(valid_21627802, JString, required = false,
                                   default = nil)
  if valid_21627802 != nil:
    section.add "X-Amz-Signature", valid_21627802
  var valid_21627803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Credential")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Credential", valid_21627804
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

proc call*(call_21627806: Call_StopCompilationJob_21627794; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_21627806.validator(path, query, header, formData, body, _)
  let scheme = call_21627806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627806.makeUrl(scheme.get, call_21627806.host, call_21627806.base,
                               call_21627806.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627806, uri, valid, _)

proc call*(call_21627807: Call_StopCompilationJob_21627794; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_21627808 = newJObject()
  if body != nil:
    body_21627808 = body
  result = call_21627807.call(nil, nil, nil, nil, body_21627808)

var stopCompilationJob* = Call_StopCompilationJob_21627794(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_21627795, base: "/",
    makeUrl: url_StopCompilationJob_21627796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_21627809 = ref object of OpenApiRestCall_21625435
proc url_StopHyperParameterTuningJob_21627811(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopHyperParameterTuningJob_21627810(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
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
  var valid_21627812 = header.getOrDefault("X-Amz-Date")
  valid_21627812 = validateParameter(valid_21627812, JString, required = false,
                                   default = nil)
  if valid_21627812 != nil:
    section.add "X-Amz-Date", valid_21627812
  var valid_21627813 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627813 = validateParameter(valid_21627813, JString, required = false,
                                   default = nil)
  if valid_21627813 != nil:
    section.add "X-Amz-Security-Token", valid_21627813
  var valid_21627814 = header.getOrDefault("X-Amz-Target")
  valid_21627814 = validateParameter(valid_21627814, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_21627814 != nil:
    section.add "X-Amz-Target", valid_21627814
  var valid_21627815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627815 = validateParameter(valid_21627815, JString, required = false,
                                   default = nil)
  if valid_21627815 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627815
  var valid_21627816 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627816 = validateParameter(valid_21627816, JString, required = false,
                                   default = nil)
  if valid_21627816 != nil:
    section.add "X-Amz-Algorithm", valid_21627816
  var valid_21627817 = header.getOrDefault("X-Amz-Signature")
  valid_21627817 = validateParameter(valid_21627817, JString, required = false,
                                   default = nil)
  if valid_21627817 != nil:
    section.add "X-Amz-Signature", valid_21627817
  var valid_21627818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627818 = validateParameter(valid_21627818, JString, required = false,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627818
  var valid_21627819 = header.getOrDefault("X-Amz-Credential")
  valid_21627819 = validateParameter(valid_21627819, JString, required = false,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "X-Amz-Credential", valid_21627819
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

proc call*(call_21627821: Call_StopHyperParameterTuningJob_21627809;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_21627821.validator(path, query, header, formData, body, _)
  let scheme = call_21627821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627821.makeUrl(scheme.get, call_21627821.host, call_21627821.base,
                               call_21627821.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627821, uri, valid, _)

proc call*(call_21627822: Call_StopHyperParameterTuningJob_21627809; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_21627823 = newJObject()
  if body != nil:
    body_21627823 = body
  result = call_21627822.call(nil, nil, nil, nil, body_21627823)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_21627809(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_21627810, base: "/",
    makeUrl: url_StopHyperParameterTuningJob_21627811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_21627824 = ref object of OpenApiRestCall_21625435
proc url_StopLabelingJob_21627826(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLabelingJob_21627825(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627827 = header.getOrDefault("X-Amz-Date")
  valid_21627827 = validateParameter(valid_21627827, JString, required = false,
                                   default = nil)
  if valid_21627827 != nil:
    section.add "X-Amz-Date", valid_21627827
  var valid_21627828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627828 = validateParameter(valid_21627828, JString, required = false,
                                   default = nil)
  if valid_21627828 != nil:
    section.add "X-Amz-Security-Token", valid_21627828
  var valid_21627829 = header.getOrDefault("X-Amz-Target")
  valid_21627829 = validateParameter(valid_21627829, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_21627829 != nil:
    section.add "X-Amz-Target", valid_21627829
  var valid_21627830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627830 = validateParameter(valid_21627830, JString, required = false,
                                   default = nil)
  if valid_21627830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627830
  var valid_21627831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627831 = validateParameter(valid_21627831, JString, required = false,
                                   default = nil)
  if valid_21627831 != nil:
    section.add "X-Amz-Algorithm", valid_21627831
  var valid_21627832 = header.getOrDefault("X-Amz-Signature")
  valid_21627832 = validateParameter(valid_21627832, JString, required = false,
                                   default = nil)
  if valid_21627832 != nil:
    section.add "X-Amz-Signature", valid_21627832
  var valid_21627833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627833 = validateParameter(valid_21627833, JString, required = false,
                                   default = nil)
  if valid_21627833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627833
  var valid_21627834 = header.getOrDefault("X-Amz-Credential")
  valid_21627834 = validateParameter(valid_21627834, JString, required = false,
                                   default = nil)
  if valid_21627834 != nil:
    section.add "X-Amz-Credential", valid_21627834
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

proc call*(call_21627836: Call_StopLabelingJob_21627824; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_21627836.validator(path, query, header, formData, body, _)
  let scheme = call_21627836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627836.makeUrl(scheme.get, call_21627836.host, call_21627836.base,
                               call_21627836.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627836, uri, valid, _)

proc call*(call_21627837: Call_StopLabelingJob_21627824; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_21627838 = newJObject()
  if body != nil:
    body_21627838 = body
  result = call_21627837.call(nil, nil, nil, nil, body_21627838)

var stopLabelingJob* = Call_StopLabelingJob_21627824(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_21627825, base: "/",
    makeUrl: url_StopLabelingJob_21627826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_21627839 = ref object of OpenApiRestCall_21625435
proc url_StopMonitoringSchedule_21627841(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopMonitoringSchedule_21627840(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627842 = header.getOrDefault("X-Amz-Date")
  valid_21627842 = validateParameter(valid_21627842, JString, required = false,
                                   default = nil)
  if valid_21627842 != nil:
    section.add "X-Amz-Date", valid_21627842
  var valid_21627843 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627843 = validateParameter(valid_21627843, JString, required = false,
                                   default = nil)
  if valid_21627843 != nil:
    section.add "X-Amz-Security-Token", valid_21627843
  var valid_21627844 = header.getOrDefault("X-Amz-Target")
  valid_21627844 = validateParameter(valid_21627844, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_21627844 != nil:
    section.add "X-Amz-Target", valid_21627844
  var valid_21627845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627845 = validateParameter(valid_21627845, JString, required = false,
                                   default = nil)
  if valid_21627845 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627845
  var valid_21627846 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627846 = validateParameter(valid_21627846, JString, required = false,
                                   default = nil)
  if valid_21627846 != nil:
    section.add "X-Amz-Algorithm", valid_21627846
  var valid_21627847 = header.getOrDefault("X-Amz-Signature")
  valid_21627847 = validateParameter(valid_21627847, JString, required = false,
                                   default = nil)
  if valid_21627847 != nil:
    section.add "X-Amz-Signature", valid_21627847
  var valid_21627848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627848 = validateParameter(valid_21627848, JString, required = false,
                                   default = nil)
  if valid_21627848 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627848
  var valid_21627849 = header.getOrDefault("X-Amz-Credential")
  valid_21627849 = validateParameter(valid_21627849, JString, required = false,
                                   default = nil)
  if valid_21627849 != nil:
    section.add "X-Amz-Credential", valid_21627849
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

proc call*(call_21627851: Call_StopMonitoringSchedule_21627839;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_21627851.validator(path, query, header, formData, body, _)
  let scheme = call_21627851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627851.makeUrl(scheme.get, call_21627851.host, call_21627851.base,
                               call_21627851.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627851, uri, valid, _)

proc call*(call_21627852: Call_StopMonitoringSchedule_21627839; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_21627853 = newJObject()
  if body != nil:
    body_21627853 = body
  result = call_21627852.call(nil, nil, nil, nil, body_21627853)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_21627839(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_21627840, base: "/",
    makeUrl: url_StopMonitoringSchedule_21627841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_21627854 = ref object of OpenApiRestCall_21625435
proc url_StopNotebookInstance_21627856(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopNotebookInstance_21627855(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627857 = header.getOrDefault("X-Amz-Date")
  valid_21627857 = validateParameter(valid_21627857, JString, required = false,
                                   default = nil)
  if valid_21627857 != nil:
    section.add "X-Amz-Date", valid_21627857
  var valid_21627858 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627858 = validateParameter(valid_21627858, JString, required = false,
                                   default = nil)
  if valid_21627858 != nil:
    section.add "X-Amz-Security-Token", valid_21627858
  var valid_21627859 = header.getOrDefault("X-Amz-Target")
  valid_21627859 = validateParameter(valid_21627859, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_21627859 != nil:
    section.add "X-Amz-Target", valid_21627859
  var valid_21627860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627860 = validateParameter(valid_21627860, JString, required = false,
                                   default = nil)
  if valid_21627860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627860
  var valid_21627861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627861 = validateParameter(valid_21627861, JString, required = false,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "X-Amz-Algorithm", valid_21627861
  var valid_21627862 = header.getOrDefault("X-Amz-Signature")
  valid_21627862 = validateParameter(valid_21627862, JString, required = false,
                                   default = nil)
  if valid_21627862 != nil:
    section.add "X-Amz-Signature", valid_21627862
  var valid_21627863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627863
  var valid_21627864 = header.getOrDefault("X-Amz-Credential")
  valid_21627864 = validateParameter(valid_21627864, JString, required = false,
                                   default = nil)
  if valid_21627864 != nil:
    section.add "X-Amz-Credential", valid_21627864
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

proc call*(call_21627866: Call_StopNotebookInstance_21627854; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_21627866.validator(path, query, header, formData, body, _)
  let scheme = call_21627866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627866.makeUrl(scheme.get, call_21627866.host, call_21627866.base,
                               call_21627866.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627866, uri, valid, _)

proc call*(call_21627867: Call_StopNotebookInstance_21627854; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_21627868 = newJObject()
  if body != nil:
    body_21627868 = body
  result = call_21627867.call(nil, nil, nil, nil, body_21627868)

var stopNotebookInstance* = Call_StopNotebookInstance_21627854(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_21627855, base: "/",
    makeUrl: url_StopNotebookInstance_21627856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_21627869 = ref object of OpenApiRestCall_21625435
proc url_StopProcessingJob_21627871(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopProcessingJob_21627870(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627872 = header.getOrDefault("X-Amz-Date")
  valid_21627872 = validateParameter(valid_21627872, JString, required = false,
                                   default = nil)
  if valid_21627872 != nil:
    section.add "X-Amz-Date", valid_21627872
  var valid_21627873 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627873 = validateParameter(valid_21627873, JString, required = false,
                                   default = nil)
  if valid_21627873 != nil:
    section.add "X-Amz-Security-Token", valid_21627873
  var valid_21627874 = header.getOrDefault("X-Amz-Target")
  valid_21627874 = validateParameter(valid_21627874, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_21627874 != nil:
    section.add "X-Amz-Target", valid_21627874
  var valid_21627875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627875 = validateParameter(valid_21627875, JString, required = false,
                                   default = nil)
  if valid_21627875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627875
  var valid_21627876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627876 = validateParameter(valid_21627876, JString, required = false,
                                   default = nil)
  if valid_21627876 != nil:
    section.add "X-Amz-Algorithm", valid_21627876
  var valid_21627877 = header.getOrDefault("X-Amz-Signature")
  valid_21627877 = validateParameter(valid_21627877, JString, required = false,
                                   default = nil)
  if valid_21627877 != nil:
    section.add "X-Amz-Signature", valid_21627877
  var valid_21627878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627878 = validateParameter(valid_21627878, JString, required = false,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627878
  var valid_21627879 = header.getOrDefault("X-Amz-Credential")
  valid_21627879 = validateParameter(valid_21627879, JString, required = false,
                                   default = nil)
  if valid_21627879 != nil:
    section.add "X-Amz-Credential", valid_21627879
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

proc call*(call_21627881: Call_StopProcessingJob_21627869; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_21627881.validator(path, query, header, formData, body, _)
  let scheme = call_21627881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627881.makeUrl(scheme.get, call_21627881.host, call_21627881.base,
                               call_21627881.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627881, uri, valid, _)

proc call*(call_21627882: Call_StopProcessingJob_21627869; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_21627883 = newJObject()
  if body != nil:
    body_21627883 = body
  result = call_21627882.call(nil, nil, nil, nil, body_21627883)

var stopProcessingJob* = Call_StopProcessingJob_21627869(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_21627870, base: "/",
    makeUrl: url_StopProcessingJob_21627871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_21627884 = ref object of OpenApiRestCall_21625435
proc url_StopTrainingJob_21627886(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingJob_21627885(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627887 = header.getOrDefault("X-Amz-Date")
  valid_21627887 = validateParameter(valid_21627887, JString, required = false,
                                   default = nil)
  if valid_21627887 != nil:
    section.add "X-Amz-Date", valid_21627887
  var valid_21627888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627888 = validateParameter(valid_21627888, JString, required = false,
                                   default = nil)
  if valid_21627888 != nil:
    section.add "X-Amz-Security-Token", valid_21627888
  var valid_21627889 = header.getOrDefault("X-Amz-Target")
  valid_21627889 = validateParameter(valid_21627889, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_21627889 != nil:
    section.add "X-Amz-Target", valid_21627889
  var valid_21627890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627890 = validateParameter(valid_21627890, JString, required = false,
                                   default = nil)
  if valid_21627890 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627890
  var valid_21627891 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627891 = validateParameter(valid_21627891, JString, required = false,
                                   default = nil)
  if valid_21627891 != nil:
    section.add "X-Amz-Algorithm", valid_21627891
  var valid_21627892 = header.getOrDefault("X-Amz-Signature")
  valid_21627892 = validateParameter(valid_21627892, JString, required = false,
                                   default = nil)
  if valid_21627892 != nil:
    section.add "X-Amz-Signature", valid_21627892
  var valid_21627893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627893 = validateParameter(valid_21627893, JString, required = false,
                                   default = nil)
  if valid_21627893 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627893
  var valid_21627894 = header.getOrDefault("X-Amz-Credential")
  valid_21627894 = validateParameter(valid_21627894, JString, required = false,
                                   default = nil)
  if valid_21627894 != nil:
    section.add "X-Amz-Credential", valid_21627894
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

proc call*(call_21627896: Call_StopTrainingJob_21627884; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_21627896.validator(path, query, header, formData, body, _)
  let scheme = call_21627896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627896.makeUrl(scheme.get, call_21627896.host, call_21627896.base,
                               call_21627896.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627896, uri, valid, _)

proc call*(call_21627897: Call_StopTrainingJob_21627884; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_21627898 = newJObject()
  if body != nil:
    body_21627898 = body
  result = call_21627897.call(nil, nil, nil, nil, body_21627898)

var stopTrainingJob* = Call_StopTrainingJob_21627884(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_21627885, base: "/",
    makeUrl: url_StopTrainingJob_21627886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_21627899 = ref object of OpenApiRestCall_21625435
proc url_StopTransformJob_21627901(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTransformJob_21627900(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627902 = header.getOrDefault("X-Amz-Date")
  valid_21627902 = validateParameter(valid_21627902, JString, required = false,
                                   default = nil)
  if valid_21627902 != nil:
    section.add "X-Amz-Date", valid_21627902
  var valid_21627903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627903 = validateParameter(valid_21627903, JString, required = false,
                                   default = nil)
  if valid_21627903 != nil:
    section.add "X-Amz-Security-Token", valid_21627903
  var valid_21627904 = header.getOrDefault("X-Amz-Target")
  valid_21627904 = validateParameter(valid_21627904, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_21627904 != nil:
    section.add "X-Amz-Target", valid_21627904
  var valid_21627905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627905 = validateParameter(valid_21627905, JString, required = false,
                                   default = nil)
  if valid_21627905 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627905
  var valid_21627906 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627906 = validateParameter(valid_21627906, JString, required = false,
                                   default = nil)
  if valid_21627906 != nil:
    section.add "X-Amz-Algorithm", valid_21627906
  var valid_21627907 = header.getOrDefault("X-Amz-Signature")
  valid_21627907 = validateParameter(valid_21627907, JString, required = false,
                                   default = nil)
  if valid_21627907 != nil:
    section.add "X-Amz-Signature", valid_21627907
  var valid_21627908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627908 = validateParameter(valid_21627908, JString, required = false,
                                   default = nil)
  if valid_21627908 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627908
  var valid_21627909 = header.getOrDefault("X-Amz-Credential")
  valid_21627909 = validateParameter(valid_21627909, JString, required = false,
                                   default = nil)
  if valid_21627909 != nil:
    section.add "X-Amz-Credential", valid_21627909
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

proc call*(call_21627911: Call_StopTransformJob_21627899; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_21627911.validator(path, query, header, formData, body, _)
  let scheme = call_21627911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627911.makeUrl(scheme.get, call_21627911.host, call_21627911.base,
                               call_21627911.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627911, uri, valid, _)

proc call*(call_21627912: Call_StopTransformJob_21627899; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_21627913 = newJObject()
  if body != nil:
    body_21627913 = body
  result = call_21627912.call(nil, nil, nil, nil, body_21627913)

var stopTransformJob* = Call_StopTransformJob_21627899(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_21627900, base: "/",
    makeUrl: url_StopTransformJob_21627901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_21627914 = ref object of OpenApiRestCall_21625435
proc url_UpdateCodeRepository_21627916(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCodeRepository_21627915(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627917 = header.getOrDefault("X-Amz-Date")
  valid_21627917 = validateParameter(valid_21627917, JString, required = false,
                                   default = nil)
  if valid_21627917 != nil:
    section.add "X-Amz-Date", valid_21627917
  var valid_21627918 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627918 = validateParameter(valid_21627918, JString, required = false,
                                   default = nil)
  if valid_21627918 != nil:
    section.add "X-Amz-Security-Token", valid_21627918
  var valid_21627919 = header.getOrDefault("X-Amz-Target")
  valid_21627919 = validateParameter(valid_21627919, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_21627919 != nil:
    section.add "X-Amz-Target", valid_21627919
  var valid_21627920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627920 = validateParameter(valid_21627920, JString, required = false,
                                   default = nil)
  if valid_21627920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627920
  var valid_21627921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627921 = validateParameter(valid_21627921, JString, required = false,
                                   default = nil)
  if valid_21627921 != nil:
    section.add "X-Amz-Algorithm", valid_21627921
  var valid_21627922 = header.getOrDefault("X-Amz-Signature")
  valid_21627922 = validateParameter(valid_21627922, JString, required = false,
                                   default = nil)
  if valid_21627922 != nil:
    section.add "X-Amz-Signature", valid_21627922
  var valid_21627923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627923 = validateParameter(valid_21627923, JString, required = false,
                                   default = nil)
  if valid_21627923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627923
  var valid_21627924 = header.getOrDefault("X-Amz-Credential")
  valid_21627924 = validateParameter(valid_21627924, JString, required = false,
                                   default = nil)
  if valid_21627924 != nil:
    section.add "X-Amz-Credential", valid_21627924
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

proc call*(call_21627926: Call_UpdateCodeRepository_21627914; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_21627926.validator(path, query, header, formData, body, _)
  let scheme = call_21627926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627926.makeUrl(scheme.get, call_21627926.host, call_21627926.base,
                               call_21627926.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627926, uri, valid, _)

proc call*(call_21627927: Call_UpdateCodeRepository_21627914; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_21627928 = newJObject()
  if body != nil:
    body_21627928 = body
  result = call_21627927.call(nil, nil, nil, nil, body_21627928)

var updateCodeRepository* = Call_UpdateCodeRepository_21627914(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_21627915, base: "/",
    makeUrl: url_UpdateCodeRepository_21627916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_21627929 = ref object of OpenApiRestCall_21625435
proc url_UpdateDomain_21627931(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomain_21627930(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates a domain. Changes will impact all of the people in the domain.
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
  var valid_21627932 = header.getOrDefault("X-Amz-Date")
  valid_21627932 = validateParameter(valid_21627932, JString, required = false,
                                   default = nil)
  if valid_21627932 != nil:
    section.add "X-Amz-Date", valid_21627932
  var valid_21627933 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627933 = validateParameter(valid_21627933, JString, required = false,
                                   default = nil)
  if valid_21627933 != nil:
    section.add "X-Amz-Security-Token", valid_21627933
  var valid_21627934 = header.getOrDefault("X-Amz-Target")
  valid_21627934 = validateParameter(valid_21627934, JString, required = true, default = newJString(
      "SageMaker.UpdateDomain"))
  if valid_21627934 != nil:
    section.add "X-Amz-Target", valid_21627934
  var valid_21627935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627935 = validateParameter(valid_21627935, JString, required = false,
                                   default = nil)
  if valid_21627935 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627935
  var valid_21627936 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627936 = validateParameter(valid_21627936, JString, required = false,
                                   default = nil)
  if valid_21627936 != nil:
    section.add "X-Amz-Algorithm", valid_21627936
  var valid_21627937 = header.getOrDefault("X-Amz-Signature")
  valid_21627937 = validateParameter(valid_21627937, JString, required = false,
                                   default = nil)
  if valid_21627937 != nil:
    section.add "X-Amz-Signature", valid_21627937
  var valid_21627938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627938 = validateParameter(valid_21627938, JString, required = false,
                                   default = nil)
  if valid_21627938 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627938
  var valid_21627939 = header.getOrDefault("X-Amz-Credential")
  valid_21627939 = validateParameter(valid_21627939, JString, required = false,
                                   default = nil)
  if valid_21627939 != nil:
    section.add "X-Amz-Credential", valid_21627939
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

proc call*(call_21627941: Call_UpdateDomain_21627929; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_21627941.validator(path, query, header, formData, body, _)
  let scheme = call_21627941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627941.makeUrl(scheme.get, call_21627941.host, call_21627941.base,
                               call_21627941.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627941, uri, valid, _)

proc call*(call_21627942: Call_UpdateDomain_21627929; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_21627943 = newJObject()
  if body != nil:
    body_21627943 = body
  result = call_21627942.call(nil, nil, nil, nil, body_21627943)

var updateDomain* = Call_UpdateDomain_21627929(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_21627930, base: "/", makeUrl: url_UpdateDomain_21627931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_21627944 = ref object of OpenApiRestCall_21625435
proc url_UpdateEndpoint_21627946(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_21627945(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627947 = header.getOrDefault("X-Amz-Date")
  valid_21627947 = validateParameter(valid_21627947, JString, required = false,
                                   default = nil)
  if valid_21627947 != nil:
    section.add "X-Amz-Date", valid_21627947
  var valid_21627948 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627948 = validateParameter(valid_21627948, JString, required = false,
                                   default = nil)
  if valid_21627948 != nil:
    section.add "X-Amz-Security-Token", valid_21627948
  var valid_21627949 = header.getOrDefault("X-Amz-Target")
  valid_21627949 = validateParameter(valid_21627949, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_21627949 != nil:
    section.add "X-Amz-Target", valid_21627949
  var valid_21627950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627950 = validateParameter(valid_21627950, JString, required = false,
                                   default = nil)
  if valid_21627950 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627950
  var valid_21627951 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627951 = validateParameter(valid_21627951, JString, required = false,
                                   default = nil)
  if valid_21627951 != nil:
    section.add "X-Amz-Algorithm", valid_21627951
  var valid_21627952 = header.getOrDefault("X-Amz-Signature")
  valid_21627952 = validateParameter(valid_21627952, JString, required = false,
                                   default = nil)
  if valid_21627952 != nil:
    section.add "X-Amz-Signature", valid_21627952
  var valid_21627953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627953 = validateParameter(valid_21627953, JString, required = false,
                                   default = nil)
  if valid_21627953 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627953
  var valid_21627954 = header.getOrDefault("X-Amz-Credential")
  valid_21627954 = validateParameter(valid_21627954, JString, required = false,
                                   default = nil)
  if valid_21627954 != nil:
    section.add "X-Amz-Credential", valid_21627954
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

proc call*(call_21627956: Call_UpdateEndpoint_21627944; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_21627956.validator(path, query, header, formData, body, _)
  let scheme = call_21627956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627956.makeUrl(scheme.get, call_21627956.host, call_21627956.base,
                               call_21627956.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627956, uri, valid, _)

proc call*(call_21627957: Call_UpdateEndpoint_21627944; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_21627958 = newJObject()
  if body != nil:
    body_21627958 = body
  result = call_21627957.call(nil, nil, nil, nil, body_21627958)

var updateEndpoint* = Call_UpdateEndpoint_21627944(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_21627945, base: "/",
    makeUrl: url_UpdateEndpoint_21627946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_21627959 = ref object of OpenApiRestCall_21625435
proc url_UpdateEndpointWeightsAndCapacities_21627961(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpointWeightsAndCapacities_21627960(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627962 = header.getOrDefault("X-Amz-Date")
  valid_21627962 = validateParameter(valid_21627962, JString, required = false,
                                   default = nil)
  if valid_21627962 != nil:
    section.add "X-Amz-Date", valid_21627962
  var valid_21627963 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627963 = validateParameter(valid_21627963, JString, required = false,
                                   default = nil)
  if valid_21627963 != nil:
    section.add "X-Amz-Security-Token", valid_21627963
  var valid_21627964 = header.getOrDefault("X-Amz-Target")
  valid_21627964 = validateParameter(valid_21627964, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_21627964 != nil:
    section.add "X-Amz-Target", valid_21627964
  var valid_21627965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627965 = validateParameter(valid_21627965, JString, required = false,
                                   default = nil)
  if valid_21627965 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627965
  var valid_21627966 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627966 = validateParameter(valid_21627966, JString, required = false,
                                   default = nil)
  if valid_21627966 != nil:
    section.add "X-Amz-Algorithm", valid_21627966
  var valid_21627967 = header.getOrDefault("X-Amz-Signature")
  valid_21627967 = validateParameter(valid_21627967, JString, required = false,
                                   default = nil)
  if valid_21627967 != nil:
    section.add "X-Amz-Signature", valid_21627967
  var valid_21627968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627968 = validateParameter(valid_21627968, JString, required = false,
                                   default = nil)
  if valid_21627968 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627968
  var valid_21627969 = header.getOrDefault("X-Amz-Credential")
  valid_21627969 = validateParameter(valid_21627969, JString, required = false,
                                   default = nil)
  if valid_21627969 != nil:
    section.add "X-Amz-Credential", valid_21627969
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

proc call*(call_21627971: Call_UpdateEndpointWeightsAndCapacities_21627959;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_21627971.validator(path, query, header, formData, body, _)
  let scheme = call_21627971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627971.makeUrl(scheme.get, call_21627971.host, call_21627971.base,
                               call_21627971.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627971, uri, valid, _)

proc call*(call_21627972: Call_UpdateEndpointWeightsAndCapacities_21627959;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_21627973 = newJObject()
  if body != nil:
    body_21627973 = body
  result = call_21627972.call(nil, nil, nil, nil, body_21627973)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_21627959(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_21627960, base: "/",
    makeUrl: url_UpdateEndpointWeightsAndCapacities_21627961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_21627974 = ref object of OpenApiRestCall_21625435
proc url_UpdateExperiment_21627976(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateExperiment_21627975(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627977 = header.getOrDefault("X-Amz-Date")
  valid_21627977 = validateParameter(valid_21627977, JString, required = false,
                                   default = nil)
  if valid_21627977 != nil:
    section.add "X-Amz-Date", valid_21627977
  var valid_21627978 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627978 = validateParameter(valid_21627978, JString, required = false,
                                   default = nil)
  if valid_21627978 != nil:
    section.add "X-Amz-Security-Token", valid_21627978
  var valid_21627979 = header.getOrDefault("X-Amz-Target")
  valid_21627979 = validateParameter(valid_21627979, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_21627979 != nil:
    section.add "X-Amz-Target", valid_21627979
  var valid_21627980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627980 = validateParameter(valid_21627980, JString, required = false,
                                   default = nil)
  if valid_21627980 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627980
  var valid_21627981 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627981 = validateParameter(valid_21627981, JString, required = false,
                                   default = nil)
  if valid_21627981 != nil:
    section.add "X-Amz-Algorithm", valid_21627981
  var valid_21627982 = header.getOrDefault("X-Amz-Signature")
  valid_21627982 = validateParameter(valid_21627982, JString, required = false,
                                   default = nil)
  if valid_21627982 != nil:
    section.add "X-Amz-Signature", valid_21627982
  var valid_21627983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627983 = validateParameter(valid_21627983, JString, required = false,
                                   default = nil)
  if valid_21627983 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627983
  var valid_21627984 = header.getOrDefault("X-Amz-Credential")
  valid_21627984 = validateParameter(valid_21627984, JString, required = false,
                                   default = nil)
  if valid_21627984 != nil:
    section.add "X-Amz-Credential", valid_21627984
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

proc call*(call_21627986: Call_UpdateExperiment_21627974; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_21627986.validator(path, query, header, formData, body, _)
  let scheme = call_21627986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627986.makeUrl(scheme.get, call_21627986.host, call_21627986.base,
                               call_21627986.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627986, uri, valid, _)

proc call*(call_21627987: Call_UpdateExperiment_21627974; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_21627988 = newJObject()
  if body != nil:
    body_21627988 = body
  result = call_21627987.call(nil, nil, nil, nil, body_21627988)

var updateExperiment* = Call_UpdateExperiment_21627974(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_21627975, base: "/",
    makeUrl: url_UpdateExperiment_21627976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_21627989 = ref object of OpenApiRestCall_21625435
proc url_UpdateMonitoringSchedule_21627991(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMonitoringSchedule_21627990(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a previously created schedule.
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
  var valid_21627992 = header.getOrDefault("X-Amz-Date")
  valid_21627992 = validateParameter(valid_21627992, JString, required = false,
                                   default = nil)
  if valid_21627992 != nil:
    section.add "X-Amz-Date", valid_21627992
  var valid_21627993 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627993 = validateParameter(valid_21627993, JString, required = false,
                                   default = nil)
  if valid_21627993 != nil:
    section.add "X-Amz-Security-Token", valid_21627993
  var valid_21627994 = header.getOrDefault("X-Amz-Target")
  valid_21627994 = validateParameter(valid_21627994, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_21627994 != nil:
    section.add "X-Amz-Target", valid_21627994
  var valid_21627995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627995 = validateParameter(valid_21627995, JString, required = false,
                                   default = nil)
  if valid_21627995 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627995
  var valid_21627996 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627996 = validateParameter(valid_21627996, JString, required = false,
                                   default = nil)
  if valid_21627996 != nil:
    section.add "X-Amz-Algorithm", valid_21627996
  var valid_21627997 = header.getOrDefault("X-Amz-Signature")
  valid_21627997 = validateParameter(valid_21627997, JString, required = false,
                                   default = nil)
  if valid_21627997 != nil:
    section.add "X-Amz-Signature", valid_21627997
  var valid_21627998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627998 = validateParameter(valid_21627998, JString, required = false,
                                   default = nil)
  if valid_21627998 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627998
  var valid_21627999 = header.getOrDefault("X-Amz-Credential")
  valid_21627999 = validateParameter(valid_21627999, JString, required = false,
                                   default = nil)
  if valid_21627999 != nil:
    section.add "X-Amz-Credential", valid_21627999
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

proc call*(call_21628001: Call_UpdateMonitoringSchedule_21627989;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_21628001.validator(path, query, header, formData, body, _)
  let scheme = call_21628001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628001.makeUrl(scheme.get, call_21628001.host, call_21628001.base,
                               call_21628001.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628001, uri, valid, _)

proc call*(call_21628002: Call_UpdateMonitoringSchedule_21627989; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_21628003 = newJObject()
  if body != nil:
    body_21628003 = body
  result = call_21628002.call(nil, nil, nil, nil, body_21628003)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_21627989(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_21627990, base: "/",
    makeUrl: url_UpdateMonitoringSchedule_21627991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_21628004 = ref object of OpenApiRestCall_21625435
proc url_UpdateNotebookInstance_21628006(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstance_21628005(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628007 = header.getOrDefault("X-Amz-Date")
  valid_21628007 = validateParameter(valid_21628007, JString, required = false,
                                   default = nil)
  if valid_21628007 != nil:
    section.add "X-Amz-Date", valid_21628007
  var valid_21628008 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628008 = validateParameter(valid_21628008, JString, required = false,
                                   default = nil)
  if valid_21628008 != nil:
    section.add "X-Amz-Security-Token", valid_21628008
  var valid_21628009 = header.getOrDefault("X-Amz-Target")
  valid_21628009 = validateParameter(valid_21628009, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_21628009 != nil:
    section.add "X-Amz-Target", valid_21628009
  var valid_21628010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628010 = validateParameter(valid_21628010, JString, required = false,
                                   default = nil)
  if valid_21628010 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628010
  var valid_21628011 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628011 = validateParameter(valid_21628011, JString, required = false,
                                   default = nil)
  if valid_21628011 != nil:
    section.add "X-Amz-Algorithm", valid_21628011
  var valid_21628012 = header.getOrDefault("X-Amz-Signature")
  valid_21628012 = validateParameter(valid_21628012, JString, required = false,
                                   default = nil)
  if valid_21628012 != nil:
    section.add "X-Amz-Signature", valid_21628012
  var valid_21628013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628013 = validateParameter(valid_21628013, JString, required = false,
                                   default = nil)
  if valid_21628013 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628013
  var valid_21628014 = header.getOrDefault("X-Amz-Credential")
  valid_21628014 = validateParameter(valid_21628014, JString, required = false,
                                   default = nil)
  if valid_21628014 != nil:
    section.add "X-Amz-Credential", valid_21628014
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

proc call*(call_21628016: Call_UpdateNotebookInstance_21628004;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_21628016.validator(path, query, header, formData, body, _)
  let scheme = call_21628016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628016.makeUrl(scheme.get, call_21628016.host, call_21628016.base,
                               call_21628016.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628016, uri, valid, _)

proc call*(call_21628017: Call_UpdateNotebookInstance_21628004; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_21628018 = newJObject()
  if body != nil:
    body_21628018 = body
  result = call_21628017.call(nil, nil, nil, nil, body_21628018)

var updateNotebookInstance* = Call_UpdateNotebookInstance_21628004(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_21628005, base: "/",
    makeUrl: url_UpdateNotebookInstance_21628006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_21628019 = ref object of OpenApiRestCall_21625435
proc url_UpdateNotebookInstanceLifecycleConfig_21628021(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_21628020(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628022 = header.getOrDefault("X-Amz-Date")
  valid_21628022 = validateParameter(valid_21628022, JString, required = false,
                                   default = nil)
  if valid_21628022 != nil:
    section.add "X-Amz-Date", valid_21628022
  var valid_21628023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628023 = validateParameter(valid_21628023, JString, required = false,
                                   default = nil)
  if valid_21628023 != nil:
    section.add "X-Amz-Security-Token", valid_21628023
  var valid_21628024 = header.getOrDefault("X-Amz-Target")
  valid_21628024 = validateParameter(valid_21628024, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_21628024 != nil:
    section.add "X-Amz-Target", valid_21628024
  var valid_21628025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628025 = validateParameter(valid_21628025, JString, required = false,
                                   default = nil)
  if valid_21628025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628025
  var valid_21628026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628026 = validateParameter(valid_21628026, JString, required = false,
                                   default = nil)
  if valid_21628026 != nil:
    section.add "X-Amz-Algorithm", valid_21628026
  var valid_21628027 = header.getOrDefault("X-Amz-Signature")
  valid_21628027 = validateParameter(valid_21628027, JString, required = false,
                                   default = nil)
  if valid_21628027 != nil:
    section.add "X-Amz-Signature", valid_21628027
  var valid_21628028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628028 = validateParameter(valid_21628028, JString, required = false,
                                   default = nil)
  if valid_21628028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628028
  var valid_21628029 = header.getOrDefault("X-Amz-Credential")
  valid_21628029 = validateParameter(valid_21628029, JString, required = false,
                                   default = nil)
  if valid_21628029 != nil:
    section.add "X-Amz-Credential", valid_21628029
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

proc call*(call_21628031: Call_UpdateNotebookInstanceLifecycleConfig_21628019;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_21628031.validator(path, query, header, formData, body, _)
  let scheme = call_21628031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628031.makeUrl(scheme.get, call_21628031.host, call_21628031.base,
                               call_21628031.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628031, uri, valid, _)

proc call*(call_21628032: Call_UpdateNotebookInstanceLifecycleConfig_21628019;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_21628033 = newJObject()
  if body != nil:
    body_21628033 = body
  result = call_21628032.call(nil, nil, nil, nil, body_21628033)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_21628019(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_21628020, base: "/",
    makeUrl: url_UpdateNotebookInstanceLifecycleConfig_21628021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_21628034 = ref object of OpenApiRestCall_21625435
proc url_UpdateTrial_21628036(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrial_21628035(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628037 = header.getOrDefault("X-Amz-Date")
  valid_21628037 = validateParameter(valid_21628037, JString, required = false,
                                   default = nil)
  if valid_21628037 != nil:
    section.add "X-Amz-Date", valid_21628037
  var valid_21628038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628038 = validateParameter(valid_21628038, JString, required = false,
                                   default = nil)
  if valid_21628038 != nil:
    section.add "X-Amz-Security-Token", valid_21628038
  var valid_21628039 = header.getOrDefault("X-Amz-Target")
  valid_21628039 = validateParameter(valid_21628039, JString, required = true, default = newJString(
      "SageMaker.UpdateTrial"))
  if valid_21628039 != nil:
    section.add "X-Amz-Target", valid_21628039
  var valid_21628040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628040 = validateParameter(valid_21628040, JString, required = false,
                                   default = nil)
  if valid_21628040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628040
  var valid_21628041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628041 = validateParameter(valid_21628041, JString, required = false,
                                   default = nil)
  if valid_21628041 != nil:
    section.add "X-Amz-Algorithm", valid_21628041
  var valid_21628042 = header.getOrDefault("X-Amz-Signature")
  valid_21628042 = validateParameter(valid_21628042, JString, required = false,
                                   default = nil)
  if valid_21628042 != nil:
    section.add "X-Amz-Signature", valid_21628042
  var valid_21628043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628043 = validateParameter(valid_21628043, JString, required = false,
                                   default = nil)
  if valid_21628043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628043
  var valid_21628044 = header.getOrDefault("X-Amz-Credential")
  valid_21628044 = validateParameter(valid_21628044, JString, required = false,
                                   default = nil)
  if valid_21628044 != nil:
    section.add "X-Amz-Credential", valid_21628044
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

proc call*(call_21628046: Call_UpdateTrial_21628034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_21628046.validator(path, query, header, formData, body, _)
  let scheme = call_21628046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628046.makeUrl(scheme.get, call_21628046.host, call_21628046.base,
                               call_21628046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628046, uri, valid, _)

proc call*(call_21628047: Call_UpdateTrial_21628034; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_21628048 = newJObject()
  if body != nil:
    body_21628048 = body
  result = call_21628047.call(nil, nil, nil, nil, body_21628048)

var updateTrial* = Call_UpdateTrial_21628034(name: "updateTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrial",
    validator: validate_UpdateTrial_21628035, base: "/", makeUrl: url_UpdateTrial_21628036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_21628049 = ref object of OpenApiRestCall_21625435
proc url_UpdateTrialComponent_21628051(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrialComponent_21628050(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628052 = header.getOrDefault("X-Amz-Date")
  valid_21628052 = validateParameter(valid_21628052, JString, required = false,
                                   default = nil)
  if valid_21628052 != nil:
    section.add "X-Amz-Date", valid_21628052
  var valid_21628053 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628053 = validateParameter(valid_21628053, JString, required = false,
                                   default = nil)
  if valid_21628053 != nil:
    section.add "X-Amz-Security-Token", valid_21628053
  var valid_21628054 = header.getOrDefault("X-Amz-Target")
  valid_21628054 = validateParameter(valid_21628054, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_21628054 != nil:
    section.add "X-Amz-Target", valid_21628054
  var valid_21628055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628055 = validateParameter(valid_21628055, JString, required = false,
                                   default = nil)
  if valid_21628055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628055
  var valid_21628056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628056 = validateParameter(valid_21628056, JString, required = false,
                                   default = nil)
  if valid_21628056 != nil:
    section.add "X-Amz-Algorithm", valid_21628056
  var valid_21628057 = header.getOrDefault("X-Amz-Signature")
  valid_21628057 = validateParameter(valid_21628057, JString, required = false,
                                   default = nil)
  if valid_21628057 != nil:
    section.add "X-Amz-Signature", valid_21628057
  var valid_21628058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628058 = validateParameter(valid_21628058, JString, required = false,
                                   default = nil)
  if valid_21628058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628058
  var valid_21628059 = header.getOrDefault("X-Amz-Credential")
  valid_21628059 = validateParameter(valid_21628059, JString, required = false,
                                   default = nil)
  if valid_21628059 != nil:
    section.add "X-Amz-Credential", valid_21628059
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

proc call*(call_21628061: Call_UpdateTrialComponent_21628049; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_21628061.validator(path, query, header, formData, body, _)
  let scheme = call_21628061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628061.makeUrl(scheme.get, call_21628061.host, call_21628061.base,
                               call_21628061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628061, uri, valid, _)

proc call*(call_21628062: Call_UpdateTrialComponent_21628049; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_21628063 = newJObject()
  if body != nil:
    body_21628063 = body
  result = call_21628062.call(nil, nil, nil, nil, body_21628063)

var updateTrialComponent* = Call_UpdateTrialComponent_21628049(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_21628050, base: "/",
    makeUrl: url_UpdateTrialComponent_21628051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_21628064 = ref object of OpenApiRestCall_21625435
proc url_UpdateUserProfile_21628066(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserProfile_21628065(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628067 = header.getOrDefault("X-Amz-Date")
  valid_21628067 = validateParameter(valid_21628067, JString, required = false,
                                   default = nil)
  if valid_21628067 != nil:
    section.add "X-Amz-Date", valid_21628067
  var valid_21628068 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628068 = validateParameter(valid_21628068, JString, required = false,
                                   default = nil)
  if valid_21628068 != nil:
    section.add "X-Amz-Security-Token", valid_21628068
  var valid_21628069 = header.getOrDefault("X-Amz-Target")
  valid_21628069 = validateParameter(valid_21628069, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_21628069 != nil:
    section.add "X-Amz-Target", valid_21628069
  var valid_21628070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628070 = validateParameter(valid_21628070, JString, required = false,
                                   default = nil)
  if valid_21628070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628070
  var valid_21628071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628071 = validateParameter(valid_21628071, JString, required = false,
                                   default = nil)
  if valid_21628071 != nil:
    section.add "X-Amz-Algorithm", valid_21628071
  var valid_21628072 = header.getOrDefault("X-Amz-Signature")
  valid_21628072 = validateParameter(valid_21628072, JString, required = false,
                                   default = nil)
  if valid_21628072 != nil:
    section.add "X-Amz-Signature", valid_21628072
  var valid_21628073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628073 = validateParameter(valid_21628073, JString, required = false,
                                   default = nil)
  if valid_21628073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628073
  var valid_21628074 = header.getOrDefault("X-Amz-Credential")
  valid_21628074 = validateParameter(valid_21628074, JString, required = false,
                                   default = nil)
  if valid_21628074 != nil:
    section.add "X-Amz-Credential", valid_21628074
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

proc call*(call_21628076: Call_UpdateUserProfile_21628064; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_21628076.validator(path, query, header, formData, body, _)
  let scheme = call_21628076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628076.makeUrl(scheme.get, call_21628076.host, call_21628076.base,
                               call_21628076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628076, uri, valid, _)

proc call*(call_21628077: Call_UpdateUserProfile_21628064; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_21628078 = newJObject()
  if body != nil:
    body_21628078 = body
  result = call_21628077.call(nil, nil, nil, nil, body_21628078)

var updateUserProfile* = Call_UpdateUserProfile_21628064(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_21628065, base: "/",
    makeUrl: url_UpdateUserProfile_21628066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkforce_21628079 = ref object of OpenApiRestCall_21625435
proc url_UpdateWorkforce_21628081(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkforce_21628080(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628082 = header.getOrDefault("X-Amz-Date")
  valid_21628082 = validateParameter(valid_21628082, JString, required = false,
                                   default = nil)
  if valid_21628082 != nil:
    section.add "X-Amz-Date", valid_21628082
  var valid_21628083 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628083 = validateParameter(valid_21628083, JString, required = false,
                                   default = nil)
  if valid_21628083 != nil:
    section.add "X-Amz-Security-Token", valid_21628083
  var valid_21628084 = header.getOrDefault("X-Amz-Target")
  valid_21628084 = validateParameter(valid_21628084, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkforce"))
  if valid_21628084 != nil:
    section.add "X-Amz-Target", valid_21628084
  var valid_21628085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628085 = validateParameter(valid_21628085, JString, required = false,
                                   default = nil)
  if valid_21628085 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628085
  var valid_21628086 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628086 = validateParameter(valid_21628086, JString, required = false,
                                   default = nil)
  if valid_21628086 != nil:
    section.add "X-Amz-Algorithm", valid_21628086
  var valid_21628087 = header.getOrDefault("X-Amz-Signature")
  valid_21628087 = validateParameter(valid_21628087, JString, required = false,
                                   default = nil)
  if valid_21628087 != nil:
    section.add "X-Amz-Signature", valid_21628087
  var valid_21628088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628088 = validateParameter(valid_21628088, JString, required = false,
                                   default = nil)
  if valid_21628088 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628088
  var valid_21628089 = header.getOrDefault("X-Amz-Credential")
  valid_21628089 = validateParameter(valid_21628089, JString, required = false,
                                   default = nil)
  if valid_21628089 != nil:
    section.add "X-Amz-Credential", valid_21628089
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

proc call*(call_21628091: Call_UpdateWorkforce_21628079; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ## 
  let valid = call_21628091.validator(path, query, header, formData, body, _)
  let scheme = call_21628091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628091.makeUrl(scheme.get, call_21628091.host, call_21628091.base,
                               call_21628091.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628091, uri, valid, _)

proc call*(call_21628092: Call_UpdateWorkforce_21628079; body: JsonNode): Recallable =
  ## updateWorkforce
  ## <p>Restricts access to tasks assigned to workers in the specified workforce to those within specific ranges of IP addresses. You specify allowed IP addresses by creating a list of up to four <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>.</p> <p>By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied access and get a <code>Not Found</code> error message on the worker portal. After restricting access with this operation, you can see the allowed IP values for a private workforce with the operation.</p> <important> <p>This operation applies only to private workforces.</p> </important>
  ##   body: JObject (required)
  var body_21628093 = newJObject()
  if body != nil:
    body_21628093 = body
  result = call_21628092.call(nil, nil, nil, nil, body_21628093)

var updateWorkforce* = Call_UpdateWorkforce_21628079(name: "updateWorkforce",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkforce",
    validator: validate_UpdateWorkforce_21628080, base: "/",
    makeUrl: url_UpdateWorkforce_21628081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_21628094 = ref object of OpenApiRestCall_21625435
proc url_UpdateWorkteam_21628096(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkteam_21628095(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21628097 = header.getOrDefault("X-Amz-Date")
  valid_21628097 = validateParameter(valid_21628097, JString, required = false,
                                   default = nil)
  if valid_21628097 != nil:
    section.add "X-Amz-Date", valid_21628097
  var valid_21628098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628098 = validateParameter(valid_21628098, JString, required = false,
                                   default = nil)
  if valid_21628098 != nil:
    section.add "X-Amz-Security-Token", valid_21628098
  var valid_21628099 = header.getOrDefault("X-Amz-Target")
  valid_21628099 = validateParameter(valid_21628099, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_21628099 != nil:
    section.add "X-Amz-Target", valid_21628099
  var valid_21628100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628100 = validateParameter(valid_21628100, JString, required = false,
                                   default = nil)
  if valid_21628100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628100
  var valid_21628101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628101 = validateParameter(valid_21628101, JString, required = false,
                                   default = nil)
  if valid_21628101 != nil:
    section.add "X-Amz-Algorithm", valid_21628101
  var valid_21628102 = header.getOrDefault("X-Amz-Signature")
  valid_21628102 = validateParameter(valid_21628102, JString, required = false,
                                   default = nil)
  if valid_21628102 != nil:
    section.add "X-Amz-Signature", valid_21628102
  var valid_21628103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628103 = validateParameter(valid_21628103, JString, required = false,
                                   default = nil)
  if valid_21628103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628103
  var valid_21628104 = header.getOrDefault("X-Amz-Credential")
  valid_21628104 = validateParameter(valid_21628104, JString, required = false,
                                   default = nil)
  if valid_21628104 != nil:
    section.add "X-Amz-Credential", valid_21628104
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

proc call*(call_21628106: Call_UpdateWorkteam_21628094; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_21628106.validator(path, query, header, formData, body, _)
  let scheme = call_21628106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628106.makeUrl(scheme.get, call_21628106.host, call_21628106.base,
                               call_21628106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628106, uri, valid, _)

proc call*(call_21628107: Call_UpdateWorkteam_21628094; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_21628108 = newJObject()
  if body != nil:
    body_21628108 = body
  result = call_21628107.call(nil, nil, nil, nil, body_21628108)

var updateWorkteam* = Call_UpdateWorkteam_21628094(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_21628095, base: "/",
    makeUrl: url_UpdateWorkteam_21628096, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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