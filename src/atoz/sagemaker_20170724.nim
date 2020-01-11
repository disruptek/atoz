
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

  OpenApiRestCall_603389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_603389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_603389): Option[Scheme] {.used.} =
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
  Call_AddTags_603727 = ref object of OpenApiRestCall_603389
proc url_AddTags_603729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_603728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603854 = header.getOrDefault("X-Amz-Target")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
  if valid_603854 != nil:
    section.add "X-Amz-Target", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Content-Sha256", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Date")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Date", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Security-Token")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Security-Token", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Algorithm")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Algorithm", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603885: Call_AddTags_603727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_603885.validator(path, query, header, formData, body)
  let scheme = call_603885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603885.url(scheme.get, call_603885.host, call_603885.base,
                         call_603885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603885, url, valid)

proc call*(call_603956: Call_AddTags_603727; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_603957 = newJObject()
  if body != nil:
    body_603957 = body
  result = call_603956.call(nil, nil, nil, nil, body_603957)

var addTags* = Call_AddTags_603727(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_603728, base: "/",
                                url: url_AddTags_603729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_603996 = ref object of OpenApiRestCall_603389
proc url_AssociateTrialComponent_603998(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateTrialComponent_603997(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603999 = header.getOrDefault("X-Amz-Target")
  valid_603999 = validateParameter(valid_603999, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
  if valid_603999 != nil:
    section.add "X-Amz-Target", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Signature")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Signature", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Content-Sha256", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Date")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Date", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Credential")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Credential", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-Security-Token")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-Security-Token", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Algorithm")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Algorithm", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-SignedHeaders", valid_604006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604008: Call_AssociateTrialComponent_603996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_604008.validator(path, query, header, formData, body)
  let scheme = call_604008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604008.url(scheme.get, call_604008.host, call_604008.base,
                         call_604008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604008, url, valid)

proc call*(call_604009: Call_AssociateTrialComponent_603996; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_604010 = newJObject()
  if body != nil:
    body_604010 = body
  result = call_604009.call(nil, nil, nil, nil, body_604010)

var associateTrialComponent* = Call_AssociateTrialComponent_603996(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_603997, base: "/",
    url: url_AssociateTrialComponent_603998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_604011 = ref object of OpenApiRestCall_603389
proc url_CreateAlgorithm_604013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlgorithm_604012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604014 = header.getOrDefault("X-Amz-Target")
  valid_604014 = validateParameter(valid_604014, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_604014 != nil:
    section.add "X-Amz-Target", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-Signature")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-Signature", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Content-Sha256", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Date")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Date", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Credential")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Credential", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-Security-Token")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-Security-Token", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Algorithm")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Algorithm", valid_604020
  var valid_604021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-SignedHeaders", valid_604021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604023: Call_CreateAlgorithm_604011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_604023.validator(path, query, header, formData, body)
  let scheme = call_604023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604023.url(scheme.get, call_604023.host, call_604023.base,
                         call_604023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604023, url, valid)

proc call*(call_604024: Call_CreateAlgorithm_604011; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_604025 = newJObject()
  if body != nil:
    body_604025 = body
  result = call_604024.call(nil, nil, nil, nil, body_604025)

var createAlgorithm* = Call_CreateAlgorithm_604011(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_604012, base: "/", url: url_CreateAlgorithm_604013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_604026 = ref object of OpenApiRestCall_603389
proc url_CreateApp_604028(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_604027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604029 = header.getOrDefault("X-Amz-Target")
  valid_604029 = validateParameter(valid_604029, JString, required = true,
                                 default = newJString("SageMaker.CreateApp"))
  if valid_604029 != nil:
    section.add "X-Amz-Target", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Signature")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Signature", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Content-Sha256", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Date")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Date", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Credential")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Credential", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Security-Token")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Security-Token", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Algorithm")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Algorithm", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-SignedHeaders", valid_604036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604038: Call_CreateApp_604026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_604038.validator(path, query, header, formData, body)
  let scheme = call_604038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604038.url(scheme.get, call_604038.host, call_604038.base,
                         call_604038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604038, url, valid)

proc call*(call_604039: Call_CreateApp_604026; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_604040 = newJObject()
  if body != nil:
    body_604040 = body
  result = call_604039.call(nil, nil, nil, nil, body_604040)

var createApp* = Call_CreateApp_604026(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                    validator: validate_CreateApp_604027,
                                    base: "/", url: url_CreateApp_604028,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_604041 = ref object of OpenApiRestCall_603389
proc url_CreateAutoMLJob_604043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAutoMLJob_604042(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604044 = header.getOrDefault("X-Amz-Target")
  valid_604044 = validateParameter(valid_604044, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
  if valid_604044 != nil:
    section.add "X-Amz-Target", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Signature")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Signature", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Content-Sha256", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Date")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Date", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Credential")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Credential", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Security-Token")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Security-Token", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Algorithm")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Algorithm", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-SignedHeaders", valid_604051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604053: Call_CreateAutoMLJob_604041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_604053.validator(path, query, header, formData, body)
  let scheme = call_604053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604053.url(scheme.get, call_604053.host, call_604053.base,
                         call_604053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604053, url, valid)

proc call*(call_604054: Call_CreateAutoMLJob_604041; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_604055 = newJObject()
  if body != nil:
    body_604055 = body
  result = call_604054.call(nil, nil, nil, nil, body_604055)

var createAutoMLJob* = Call_CreateAutoMLJob_604041(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_604042, base: "/", url: url_CreateAutoMLJob_604043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_604056 = ref object of OpenApiRestCall_603389
proc url_CreateCodeRepository_604058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCodeRepository_604057(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604059 = header.getOrDefault("X-Amz-Target")
  valid_604059 = validateParameter(valid_604059, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_604059 != nil:
    section.add "X-Amz-Target", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Signature")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Signature", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Content-Sha256", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Date")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Date", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Credential")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Credential", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Security-Token")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Security-Token", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Algorithm")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Algorithm", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-SignedHeaders", valid_604066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604068: Call_CreateCodeRepository_604056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_604068.validator(path, query, header, formData, body)
  let scheme = call_604068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604068.url(scheme.get, call_604068.host, call_604068.base,
                         call_604068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604068, url, valid)

proc call*(call_604069: Call_CreateCodeRepository_604056; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_604070 = newJObject()
  if body != nil:
    body_604070 = body
  result = call_604069.call(nil, nil, nil, nil, body_604070)

var createCodeRepository* = Call_CreateCodeRepository_604056(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_604057, base: "/",
    url: url_CreateCodeRepository_604058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_604071 = ref object of OpenApiRestCall_603389
proc url_CreateCompilationJob_604073(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCompilationJob_604072(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604074 = header.getOrDefault("X-Amz-Target")
  valid_604074 = validateParameter(valid_604074, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_604074 != nil:
    section.add "X-Amz-Target", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Signature")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Signature", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Content-Sha256", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Date")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Date", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Credential")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Credential", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Security-Token")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Security-Token", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Algorithm")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Algorithm", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-SignedHeaders", valid_604081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_CreateCompilationJob_604071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604083, url, valid)

proc call*(call_604084: Call_CreateCompilationJob_604071; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_604085 = newJObject()
  if body != nil:
    body_604085 = body
  result = call_604084.call(nil, nil, nil, nil, body_604085)

var createCompilationJob* = Call_CreateCompilationJob_604071(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_604072, base: "/",
    url: url_CreateCompilationJob_604073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_604086 = ref object of OpenApiRestCall_603389
proc url_CreateDomain_604088(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDomain_604087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604089 = header.getOrDefault("X-Amz-Target")
  valid_604089 = validateParameter(valid_604089, JString, required = true,
                                 default = newJString("SageMaker.CreateDomain"))
  if valid_604089 != nil:
    section.add "X-Amz-Target", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-Signature")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Signature", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Content-Sha256", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Date")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Date", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Credential")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Credential", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Security-Token")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Security-Token", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Algorithm")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Algorithm", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-SignedHeaders", valid_604096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604098: Call_CreateDomain_604086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_604098.validator(path, query, header, formData, body)
  let scheme = call_604098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604098.url(scheme.get, call_604098.host, call_604098.base,
                         call_604098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604098, url, valid)

proc call*(call_604099: Call_CreateDomain_604086; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_604100 = newJObject()
  if body != nil:
    body_604100 = body
  result = call_604099.call(nil, nil, nil, nil, body_604100)

var createDomain* = Call_CreateDomain_604086(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_604087, base: "/", url: url_CreateDomain_604088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_604101 = ref object of OpenApiRestCall_603389
proc url_CreateEndpoint_604103(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEndpoint_604102(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604104 = header.getOrDefault("X-Amz-Target")
  valid_604104 = validateParameter(valid_604104, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_604104 != nil:
    section.add "X-Amz-Target", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Signature")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Signature", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Content-Sha256", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Date")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Date", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Credential")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Credential", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Security-Token")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Security-Token", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Algorithm")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Algorithm", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-SignedHeaders", valid_604111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604113: Call_CreateEndpoint_604101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_604113.validator(path, query, header, formData, body)
  let scheme = call_604113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604113.url(scheme.get, call_604113.host, call_604113.base,
                         call_604113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604113, url, valid)

proc call*(call_604114: Call_CreateEndpoint_604101; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_604115 = newJObject()
  if body != nil:
    body_604115 = body
  result = call_604114.call(nil, nil, nil, nil, body_604115)

var createEndpoint* = Call_CreateEndpoint_604101(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_604102, base: "/", url: url_CreateEndpoint_604103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_604116 = ref object of OpenApiRestCall_603389
proc url_CreateEndpointConfig_604118(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEndpointConfig_604117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604119 = header.getOrDefault("X-Amz-Target")
  valid_604119 = validateParameter(valid_604119, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_604119 != nil:
    section.add "X-Amz-Target", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Signature")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Signature", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Content-Sha256", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Date")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Date", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Credential")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Credential", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Security-Token")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Security-Token", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Algorithm")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Algorithm", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-SignedHeaders", valid_604126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604128: Call_CreateEndpointConfig_604116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_604128.validator(path, query, header, formData, body)
  let scheme = call_604128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604128.url(scheme.get, call_604128.host, call_604128.base,
                         call_604128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604128, url, valid)

proc call*(call_604129: Call_CreateEndpointConfig_604116; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_604130 = newJObject()
  if body != nil:
    body_604130 = body
  result = call_604129.call(nil, nil, nil, nil, body_604130)

var createEndpointConfig* = Call_CreateEndpointConfig_604116(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_604117, base: "/",
    url: url_CreateEndpointConfig_604118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_604131 = ref object of OpenApiRestCall_603389
proc url_CreateExperiment_604133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateExperiment_604132(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604134 = header.getOrDefault("X-Amz-Target")
  valid_604134 = validateParameter(valid_604134, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
  if valid_604134 != nil:
    section.add "X-Amz-Target", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-Signature")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-Signature", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Content-Sha256", valid_604136
  var valid_604137 = header.getOrDefault("X-Amz-Date")
  valid_604137 = validateParameter(valid_604137, JString, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "X-Amz-Date", valid_604137
  var valid_604138 = header.getOrDefault("X-Amz-Credential")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Credential", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Security-Token")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Security-Token", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Algorithm")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Algorithm", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-SignedHeaders", valid_604141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604143: Call_CreateExperiment_604131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_604143.validator(path, query, header, formData, body)
  let scheme = call_604143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604143.url(scheme.get, call_604143.host, call_604143.base,
                         call_604143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604143, url, valid)

proc call*(call_604144: Call_CreateExperiment_604131; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_604145 = newJObject()
  if body != nil:
    body_604145 = body
  result = call_604144.call(nil, nil, nil, nil, body_604145)

var createExperiment* = Call_CreateExperiment_604131(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_604132, base: "/",
    url: url_CreateExperiment_604133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_604146 = ref object of OpenApiRestCall_603389
proc url_CreateFlowDefinition_604148(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFlowDefinition_604147(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604149 = header.getOrDefault("X-Amz-Target")
  valid_604149 = validateParameter(valid_604149, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
  if valid_604149 != nil:
    section.add "X-Amz-Target", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Signature")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Signature", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Content-Sha256", valid_604151
  var valid_604152 = header.getOrDefault("X-Amz-Date")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Date", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Credential")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Credential", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Security-Token")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Security-Token", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Algorithm")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Algorithm", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-SignedHeaders", valid_604156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604158: Call_CreateFlowDefinition_604146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_604158.validator(path, query, header, formData, body)
  let scheme = call_604158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604158.url(scheme.get, call_604158.host, call_604158.base,
                         call_604158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604158, url, valid)

proc call*(call_604159: Call_CreateFlowDefinition_604146; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_604160 = newJObject()
  if body != nil:
    body_604160 = body
  result = call_604159.call(nil, nil, nil, nil, body_604160)

var createFlowDefinition* = Call_CreateFlowDefinition_604146(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_604147, base: "/",
    url: url_CreateFlowDefinition_604148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_604161 = ref object of OpenApiRestCall_603389
proc url_CreateHumanTaskUi_604163(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHumanTaskUi_604162(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604164 = header.getOrDefault("X-Amz-Target")
  valid_604164 = validateParameter(valid_604164, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_604164 != nil:
    section.add "X-Amz-Target", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Signature")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Signature", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Content-Sha256", valid_604166
  var valid_604167 = header.getOrDefault("X-Amz-Date")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Date", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Credential")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Credential", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-Security-Token")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Security-Token", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Algorithm")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Algorithm", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-SignedHeaders", valid_604171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604173: Call_CreateHumanTaskUi_604161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_604173.validator(path, query, header, formData, body)
  let scheme = call_604173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604173.url(scheme.get, call_604173.host, call_604173.base,
                         call_604173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604173, url, valid)

proc call*(call_604174: Call_CreateHumanTaskUi_604161; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_604175 = newJObject()
  if body != nil:
    body_604175 = body
  result = call_604174.call(nil, nil, nil, nil, body_604175)

var createHumanTaskUi* = Call_CreateHumanTaskUi_604161(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_604162, base: "/",
    url: url_CreateHumanTaskUi_604163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_604176 = ref object of OpenApiRestCall_603389
proc url_CreateHyperParameterTuningJob_604178(protocol: Scheme; host: string;
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

proc validate_CreateHyperParameterTuningJob_604177(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604179 = header.getOrDefault("X-Amz-Target")
  valid_604179 = validateParameter(valid_604179, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_604179 != nil:
    section.add "X-Amz-Target", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Signature")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Signature", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Content-Sha256", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Date")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Date", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Credential")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Credential", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Security-Token")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Security-Token", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Algorithm")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Algorithm", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-SignedHeaders", valid_604186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604188: Call_CreateHyperParameterTuningJob_604176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_604188.validator(path, query, header, formData, body)
  let scheme = call_604188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604188.url(scheme.get, call_604188.host, call_604188.base,
                         call_604188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604188, url, valid)

proc call*(call_604189: Call_CreateHyperParameterTuningJob_604176; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_604190 = newJObject()
  if body != nil:
    body_604190 = body
  result = call_604189.call(nil, nil, nil, nil, body_604190)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_604176(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_604177, base: "/",
    url: url_CreateHyperParameterTuningJob_604178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_604191 = ref object of OpenApiRestCall_603389
proc url_CreateLabelingJob_604193(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLabelingJob_604192(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604194 = header.getOrDefault("X-Amz-Target")
  valid_604194 = validateParameter(valid_604194, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_604194 != nil:
    section.add "X-Amz-Target", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Signature")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Signature", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Content-Sha256", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Date")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Date", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Credential")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Credential", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Security-Token")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Security-Token", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Algorithm")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Algorithm", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-SignedHeaders", valid_604201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604203: Call_CreateLabelingJob_604191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_604203.validator(path, query, header, formData, body)
  let scheme = call_604203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604203.url(scheme.get, call_604203.host, call_604203.base,
                         call_604203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604203, url, valid)

proc call*(call_604204: Call_CreateLabelingJob_604191; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_604205 = newJObject()
  if body != nil:
    body_604205 = body
  result = call_604204.call(nil, nil, nil, nil, body_604205)

var createLabelingJob* = Call_CreateLabelingJob_604191(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_604192, base: "/",
    url: url_CreateLabelingJob_604193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_604206 = ref object of OpenApiRestCall_603389
proc url_CreateModel_604208(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModel_604207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604209 = header.getOrDefault("X-Amz-Target")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_604209 != nil:
    section.add "X-Amz-Target", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Signature")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Signature", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Content-Sha256", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Date")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Date", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Credential")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Credential", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Security-Token")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Security-Token", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Algorithm")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Algorithm", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-SignedHeaders", valid_604216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604218: Call_CreateModel_604206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_604218.validator(path, query, header, formData, body)
  let scheme = call_604218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604218.url(scheme.get, call_604218.host, call_604218.base,
                         call_604218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604218, url, valid)

proc call*(call_604219: Call_CreateModel_604206; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_604220 = newJObject()
  if body != nil:
    body_604220 = body
  result = call_604219.call(nil, nil, nil, nil, body_604220)

var createModel* = Call_CreateModel_604206(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_604207,
                                        base: "/", url: url_CreateModel_604208,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_604221 = ref object of OpenApiRestCall_603389
proc url_CreateModelPackage_604223(protocol: Scheme; host: string; base: string;
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

proc validate_CreateModelPackage_604222(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604224 = header.getOrDefault("X-Amz-Target")
  valid_604224 = validateParameter(valid_604224, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_604224 != nil:
    section.add "X-Amz-Target", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Signature")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Signature", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Content-Sha256", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Date")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Date", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Credential")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Credential", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Security-Token")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Security-Token", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Algorithm")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Algorithm", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-SignedHeaders", valid_604231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604233: Call_CreateModelPackage_604221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_604233.validator(path, query, header, formData, body)
  let scheme = call_604233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604233.url(scheme.get, call_604233.host, call_604233.base,
                         call_604233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604233, url, valid)

proc call*(call_604234: Call_CreateModelPackage_604221; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_604235 = newJObject()
  if body != nil:
    body_604235 = body
  result = call_604234.call(nil, nil, nil, nil, body_604235)

var createModelPackage* = Call_CreateModelPackage_604221(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_604222, base: "/",
    url: url_CreateModelPackage_604223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_604236 = ref object of OpenApiRestCall_603389
proc url_CreateMonitoringSchedule_604238(protocol: Scheme; host: string;
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

proc validate_CreateMonitoringSchedule_604237(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604239 = header.getOrDefault("X-Amz-Target")
  valid_604239 = validateParameter(valid_604239, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
  if valid_604239 != nil:
    section.add "X-Amz-Target", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Signature")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Signature", valid_604240
  var valid_604241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "X-Amz-Content-Sha256", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Date")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Date", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-Credential")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Credential", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Security-Token")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Security-Token", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Algorithm")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Algorithm", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-SignedHeaders", valid_604246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604248: Call_CreateMonitoringSchedule_604236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_604248.validator(path, query, header, formData, body)
  let scheme = call_604248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604248.url(scheme.get, call_604248.host, call_604248.base,
                         call_604248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604248, url, valid)

proc call*(call_604249: Call_CreateMonitoringSchedule_604236; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_604250 = newJObject()
  if body != nil:
    body_604250 = body
  result = call_604249.call(nil, nil, nil, nil, body_604250)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_604236(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_604237, base: "/",
    url: url_CreateMonitoringSchedule_604238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_604251 = ref object of OpenApiRestCall_603389
proc url_CreateNotebookInstance_604253(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNotebookInstance_604252(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604254 = header.getOrDefault("X-Amz-Target")
  valid_604254 = validateParameter(valid_604254, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_604254 != nil:
    section.add "X-Amz-Target", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Signature")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Signature", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Content-Sha256", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Date")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Date", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-Credential")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-Credential", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Security-Token")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Security-Token", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Algorithm")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Algorithm", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-SignedHeaders", valid_604261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604263: Call_CreateNotebookInstance_604251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_604263.validator(path, query, header, formData, body)
  let scheme = call_604263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604263.url(scheme.get, call_604263.host, call_604263.base,
                         call_604263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604263, url, valid)

proc call*(call_604264: Call_CreateNotebookInstance_604251; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_604265 = newJObject()
  if body != nil:
    body_604265 = body
  result = call_604264.call(nil, nil, nil, nil, body_604265)

var createNotebookInstance* = Call_CreateNotebookInstance_604251(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_604252, base: "/",
    url: url_CreateNotebookInstance_604253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_604266 = ref object of OpenApiRestCall_603389
proc url_CreateNotebookInstanceLifecycleConfig_604268(protocol: Scheme;
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

proc validate_CreateNotebookInstanceLifecycleConfig_604267(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604269 = header.getOrDefault("X-Amz-Target")
  valid_604269 = validateParameter(valid_604269, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_604269 != nil:
    section.add "X-Amz-Target", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Signature")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Signature", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Content-Sha256", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Date")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Date", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-Credential")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-Credential", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Security-Token")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Security-Token", valid_604274
  var valid_604275 = header.getOrDefault("X-Amz-Algorithm")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "X-Amz-Algorithm", valid_604275
  var valid_604276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "X-Amz-SignedHeaders", valid_604276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604278: Call_CreateNotebookInstanceLifecycleConfig_604266;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_604278.validator(path, query, header, formData, body)
  let scheme = call_604278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604278.url(scheme.get, call_604278.host, call_604278.base,
                         call_604278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604278, url, valid)

proc call*(call_604279: Call_CreateNotebookInstanceLifecycleConfig_604266;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_604280 = newJObject()
  if body != nil:
    body_604280 = body
  result = call_604279.call(nil, nil, nil, nil, body_604280)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_604266(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_604267, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_604268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_604281 = ref object of OpenApiRestCall_603389
proc url_CreatePresignedDomainUrl_604283(protocol: Scheme; host: string;
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

proc validate_CreatePresignedDomainUrl_604282(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604284 = header.getOrDefault("X-Amz-Target")
  valid_604284 = validateParameter(valid_604284, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_604284 != nil:
    section.add "X-Amz-Target", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Signature")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Signature", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Content-Sha256", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Date")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Date", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-Credential")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-Credential", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Security-Token")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Security-Token", valid_604289
  var valid_604290 = header.getOrDefault("X-Amz-Algorithm")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "X-Amz-Algorithm", valid_604290
  var valid_604291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "X-Amz-SignedHeaders", valid_604291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604293: Call_CreatePresignedDomainUrl_604281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_604293.validator(path, query, header, formData, body)
  let scheme = call_604293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604293.url(scheme.get, call_604293.host, call_604293.base,
                         call_604293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604293, url, valid)

proc call*(call_604294: Call_CreatePresignedDomainUrl_604281; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_604295 = newJObject()
  if body != nil:
    body_604295 = body
  result = call_604294.call(nil, nil, nil, nil, body_604295)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_604281(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_604282, base: "/",
    url: url_CreatePresignedDomainUrl_604283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_604296 = ref object of OpenApiRestCall_603389
proc url_CreatePresignedNotebookInstanceUrl_604298(protocol: Scheme; host: string;
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

proc validate_CreatePresignedNotebookInstanceUrl_604297(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604299 = header.getOrDefault("X-Amz-Target")
  valid_604299 = validateParameter(valid_604299, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_604299 != nil:
    section.add "X-Amz-Target", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Signature")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Signature", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-Content-Sha256", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Date")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Date", valid_604302
  var valid_604303 = header.getOrDefault("X-Amz-Credential")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "X-Amz-Credential", valid_604303
  var valid_604304 = header.getOrDefault("X-Amz-Security-Token")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "X-Amz-Security-Token", valid_604304
  var valid_604305 = header.getOrDefault("X-Amz-Algorithm")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "X-Amz-Algorithm", valid_604305
  var valid_604306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-SignedHeaders", valid_604306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604308: Call_CreatePresignedNotebookInstanceUrl_604296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_604308.validator(path, query, header, formData, body)
  let scheme = call_604308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604308.url(scheme.get, call_604308.host, call_604308.base,
                         call_604308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604308, url, valid)

proc call*(call_604309: Call_CreatePresignedNotebookInstanceUrl_604296;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_604310 = newJObject()
  if body != nil:
    body_604310 = body
  result = call_604309.call(nil, nil, nil, nil, body_604310)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_604296(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_604297, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_604298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_604311 = ref object of OpenApiRestCall_603389
proc url_CreateProcessingJob_604313(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProcessingJob_604312(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604314 = header.getOrDefault("X-Amz-Target")
  valid_604314 = validateParameter(valid_604314, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_604314 != nil:
    section.add "X-Amz-Target", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Signature")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Signature", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Content-Sha256", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Date")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Date", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Credential")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Credential", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Security-Token")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Security-Token", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Algorithm")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Algorithm", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-SignedHeaders", valid_604321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604323: Call_CreateProcessingJob_604311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_604323.validator(path, query, header, formData, body)
  let scheme = call_604323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604323.url(scheme.get, call_604323.host, call_604323.base,
                         call_604323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604323, url, valid)

proc call*(call_604324: Call_CreateProcessingJob_604311; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_604325 = newJObject()
  if body != nil:
    body_604325 = body
  result = call_604324.call(nil, nil, nil, nil, body_604325)

var createProcessingJob* = Call_CreateProcessingJob_604311(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_604312, base: "/",
    url: url_CreateProcessingJob_604313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_604326 = ref object of OpenApiRestCall_603389
proc url_CreateTrainingJob_604328(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrainingJob_604327(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604329 = header.getOrDefault("X-Amz-Target")
  valid_604329 = validateParameter(valid_604329, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_604329 != nil:
    section.add "X-Amz-Target", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Signature")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Signature", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Content-Sha256", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Date")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Date", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Credential")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Credential", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Security-Token")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Security-Token", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Algorithm")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Algorithm", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-SignedHeaders", valid_604336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604338: Call_CreateTrainingJob_604326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_604338.validator(path, query, header, formData, body)
  let scheme = call_604338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604338.url(scheme.get, call_604338.host, call_604338.base,
                         call_604338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604338, url, valid)

proc call*(call_604339: Call_CreateTrainingJob_604326; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_604340 = newJObject()
  if body != nil:
    body_604340 = body
  result = call_604339.call(nil, nil, nil, nil, body_604340)

var createTrainingJob* = Call_CreateTrainingJob_604326(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_604327, base: "/",
    url: url_CreateTrainingJob_604328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_604341 = ref object of OpenApiRestCall_603389
proc url_CreateTransformJob_604343(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTransformJob_604342(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604344 = header.getOrDefault("X-Amz-Target")
  valid_604344 = validateParameter(valid_604344, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_604344 != nil:
    section.add "X-Amz-Target", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Signature")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Signature", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Content-Sha256", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Date")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Date", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-Credential")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-Credential", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Security-Token")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Security-Token", valid_604349
  var valid_604350 = header.getOrDefault("X-Amz-Algorithm")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Algorithm", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-SignedHeaders", valid_604351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604353: Call_CreateTransformJob_604341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_604353.validator(path, query, header, formData, body)
  let scheme = call_604353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604353.url(scheme.get, call_604353.host, call_604353.base,
                         call_604353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604353, url, valid)

proc call*(call_604354: Call_CreateTransformJob_604341; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_604355 = newJObject()
  if body != nil:
    body_604355 = body
  result = call_604354.call(nil, nil, nil, nil, body_604355)

var createTransformJob* = Call_CreateTransformJob_604341(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_604342, base: "/",
    url: url_CreateTransformJob_604343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_604356 = ref object of OpenApiRestCall_603389
proc url_CreateTrial_604358(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrial_604357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604359 = header.getOrDefault("X-Amz-Target")
  valid_604359 = validateParameter(valid_604359, JString, required = true,
                                 default = newJString("SageMaker.CreateTrial"))
  if valid_604359 != nil:
    section.add "X-Amz-Target", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Signature")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Signature", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Content-Sha256", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-Date")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-Date", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-Credential")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-Credential", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Security-Token")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Security-Token", valid_604364
  var valid_604365 = header.getOrDefault("X-Amz-Algorithm")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Algorithm", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-SignedHeaders", valid_604366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604368: Call_CreateTrial_604356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_604368.validator(path, query, header, formData, body)
  let scheme = call_604368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604368.url(scheme.get, call_604368.host, call_604368.base,
                         call_604368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604368, url, valid)

proc call*(call_604369: Call_CreateTrial_604356; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_604370 = newJObject()
  if body != nil:
    body_604370 = body
  result = call_604369.call(nil, nil, nil, nil, body_604370)

var createTrial* = Call_CreateTrial_604356(name: "createTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateTrial",
                                        validator: validate_CreateTrial_604357,
                                        base: "/", url: url_CreateTrial_604358,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_604371 = ref object of OpenApiRestCall_603389
proc url_CreateTrialComponent_604373(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrialComponent_604372(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604374 = header.getOrDefault("X-Amz-Target")
  valid_604374 = validateParameter(valid_604374, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_604374 != nil:
    section.add "X-Amz-Target", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-Signature")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Signature", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Content-Sha256", valid_604376
  var valid_604377 = header.getOrDefault("X-Amz-Date")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "X-Amz-Date", valid_604377
  var valid_604378 = header.getOrDefault("X-Amz-Credential")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "X-Amz-Credential", valid_604378
  var valid_604379 = header.getOrDefault("X-Amz-Security-Token")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "X-Amz-Security-Token", valid_604379
  var valid_604380 = header.getOrDefault("X-Amz-Algorithm")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "X-Amz-Algorithm", valid_604380
  var valid_604381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "X-Amz-SignedHeaders", valid_604381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604383: Call_CreateTrialComponent_604371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ## 
  let valid = call_604383.validator(path, query, header, formData, body)
  let scheme = call_604383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604383.url(scheme.get, call_604383.host, call_604383.base,
                         call_604383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604383, url, valid)

proc call*(call_604384: Call_CreateTrialComponent_604371; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   body: JObject (required)
  var body_604385 = newJObject()
  if body != nil:
    body_604385 = body
  result = call_604384.call(nil, nil, nil, nil, body_604385)

var createTrialComponent* = Call_CreateTrialComponent_604371(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_604372, base: "/",
    url: url_CreateTrialComponent_604373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_604386 = ref object of OpenApiRestCall_603389
proc url_CreateUserProfile_604388(protocol: Scheme; host: string; base: string;
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

proc validate_CreateUserProfile_604387(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604389 = header.getOrDefault("X-Amz-Target")
  valid_604389 = validateParameter(valid_604389, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_604389 != nil:
    section.add "X-Amz-Target", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Signature")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Signature", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Content-Sha256", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Date")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Date", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Credential")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Credential", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Security-Token")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Security-Token", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Algorithm")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Algorithm", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-SignedHeaders", valid_604396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604398: Call_CreateUserProfile_604386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_604398.validator(path, query, header, formData, body)
  let scheme = call_604398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604398.url(scheme.get, call_604398.host, call_604398.base,
                         call_604398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604398, url, valid)

proc call*(call_604399: Call_CreateUserProfile_604386; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_604400 = newJObject()
  if body != nil:
    body_604400 = body
  result = call_604399.call(nil, nil, nil, nil, body_604400)

var createUserProfile* = Call_CreateUserProfile_604386(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_604387, base: "/",
    url: url_CreateUserProfile_604388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_604401 = ref object of OpenApiRestCall_603389
proc url_CreateWorkteam_604403(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkteam_604402(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604404 = header.getOrDefault("X-Amz-Target")
  valid_604404 = validateParameter(valid_604404, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_604404 != nil:
    section.add "X-Amz-Target", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Signature")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Signature", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Content-Sha256", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Date")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Date", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Credential")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Credential", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Security-Token")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Security-Token", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Algorithm")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Algorithm", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-SignedHeaders", valid_604411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604413: Call_CreateWorkteam_604401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_604413.validator(path, query, header, formData, body)
  let scheme = call_604413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604413.url(scheme.get, call_604413.host, call_604413.base,
                         call_604413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604413, url, valid)

proc call*(call_604414: Call_CreateWorkteam_604401; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_604415 = newJObject()
  if body != nil:
    body_604415 = body
  result = call_604414.call(nil, nil, nil, nil, body_604415)

var createWorkteam* = Call_CreateWorkteam_604401(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_604402, base: "/", url: url_CreateWorkteam_604403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_604416 = ref object of OpenApiRestCall_603389
proc url_DeleteAlgorithm_604418(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlgorithm_604417(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604419 = header.getOrDefault("X-Amz-Target")
  valid_604419 = validateParameter(valid_604419, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_604419 != nil:
    section.add "X-Amz-Target", valid_604419
  var valid_604420 = header.getOrDefault("X-Amz-Signature")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Signature", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Content-Sha256", valid_604421
  var valid_604422 = header.getOrDefault("X-Amz-Date")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Date", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Credential")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Credential", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-Security-Token")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Security-Token", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Algorithm")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Algorithm", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-SignedHeaders", valid_604426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604428: Call_DeleteAlgorithm_604416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_604428.validator(path, query, header, formData, body)
  let scheme = call_604428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604428.url(scheme.get, call_604428.host, call_604428.base,
                         call_604428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604428, url, valid)

proc call*(call_604429: Call_DeleteAlgorithm_604416; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_604430 = newJObject()
  if body != nil:
    body_604430 = body
  result = call_604429.call(nil, nil, nil, nil, body_604430)

var deleteAlgorithm* = Call_DeleteAlgorithm_604416(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_604417, base: "/", url: url_DeleteAlgorithm_604418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_604431 = ref object of OpenApiRestCall_603389
proc url_DeleteApp_604433(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_604432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604434 = header.getOrDefault("X-Amz-Target")
  valid_604434 = validateParameter(valid_604434, JString, required = true,
                                 default = newJString("SageMaker.DeleteApp"))
  if valid_604434 != nil:
    section.add "X-Amz-Target", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-Signature")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Signature", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Content-Sha256", valid_604436
  var valid_604437 = header.getOrDefault("X-Amz-Date")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Date", valid_604437
  var valid_604438 = header.getOrDefault("X-Amz-Credential")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "X-Amz-Credential", valid_604438
  var valid_604439 = header.getOrDefault("X-Amz-Security-Token")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Security-Token", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Algorithm")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Algorithm", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-SignedHeaders", valid_604441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604443: Call_DeleteApp_604431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_604443.validator(path, query, header, formData, body)
  let scheme = call_604443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604443.url(scheme.get, call_604443.host, call_604443.base,
                         call_604443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604443, url, valid)

proc call*(call_604444: Call_DeleteApp_604431; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_604445 = newJObject()
  if body != nil:
    body_604445 = body
  result = call_604444.call(nil, nil, nil, nil, body_604445)

var deleteApp* = Call_DeleteApp_604431(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                    validator: validate_DeleteApp_604432,
                                    base: "/", url: url_DeleteApp_604433,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_604446 = ref object of OpenApiRestCall_603389
proc url_DeleteCodeRepository_604448(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCodeRepository_604447(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604449 = header.getOrDefault("X-Amz-Target")
  valid_604449 = validateParameter(valid_604449, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_604449 != nil:
    section.add "X-Amz-Target", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Signature")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Signature", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Content-Sha256", valid_604451
  var valid_604452 = header.getOrDefault("X-Amz-Date")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-Date", valid_604452
  var valid_604453 = header.getOrDefault("X-Amz-Credential")
  valid_604453 = validateParameter(valid_604453, JString, required = false,
                                 default = nil)
  if valid_604453 != nil:
    section.add "X-Amz-Credential", valid_604453
  var valid_604454 = header.getOrDefault("X-Amz-Security-Token")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Security-Token", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Algorithm")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Algorithm", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-SignedHeaders", valid_604456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604458: Call_DeleteCodeRepository_604446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_604458.validator(path, query, header, formData, body)
  let scheme = call_604458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604458.url(scheme.get, call_604458.host, call_604458.base,
                         call_604458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604458, url, valid)

proc call*(call_604459: Call_DeleteCodeRepository_604446; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_604460 = newJObject()
  if body != nil:
    body_604460 = body
  result = call_604459.call(nil, nil, nil, nil, body_604460)

var deleteCodeRepository* = Call_DeleteCodeRepository_604446(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_604447, base: "/",
    url: url_DeleteCodeRepository_604448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_604461 = ref object of OpenApiRestCall_603389
proc url_DeleteDomain_604463(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDomain_604462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604464 = header.getOrDefault("X-Amz-Target")
  valid_604464 = validateParameter(valid_604464, JString, required = true,
                                 default = newJString("SageMaker.DeleteDomain"))
  if valid_604464 != nil:
    section.add "X-Amz-Target", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Signature")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Signature", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Content-Sha256", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Date")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Date", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-Credential")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Credential", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Security-Token")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Security-Token", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Algorithm")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Algorithm", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-SignedHeaders", valid_604471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604473: Call_DeleteDomain_604461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_604473.validator(path, query, header, formData, body)
  let scheme = call_604473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604473.url(scheme.get, call_604473.host, call_604473.base,
                         call_604473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604473, url, valid)

proc call*(call_604474: Call_DeleteDomain_604461; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_604475 = newJObject()
  if body != nil:
    body_604475 = body
  result = call_604474.call(nil, nil, nil, nil, body_604475)

var deleteDomain* = Call_DeleteDomain_604461(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_604462, base: "/", url: url_DeleteDomain_604463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_604476 = ref object of OpenApiRestCall_603389
proc url_DeleteEndpoint_604478(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpoint_604477(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604479 = header.getOrDefault("X-Amz-Target")
  valid_604479 = validateParameter(valid_604479, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_604479 != nil:
    section.add "X-Amz-Target", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Signature")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Signature", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Content-Sha256", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Date")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Date", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Credential")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Credential", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Security-Token")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Security-Token", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Algorithm")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Algorithm", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-SignedHeaders", valid_604486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604488: Call_DeleteEndpoint_604476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_604488.validator(path, query, header, formData, body)
  let scheme = call_604488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604488.url(scheme.get, call_604488.host, call_604488.base,
                         call_604488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604488, url, valid)

proc call*(call_604489: Call_DeleteEndpoint_604476; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_604490 = newJObject()
  if body != nil:
    body_604490 = body
  result = call_604489.call(nil, nil, nil, nil, body_604490)

var deleteEndpoint* = Call_DeleteEndpoint_604476(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_604477, base: "/", url: url_DeleteEndpoint_604478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_604491 = ref object of OpenApiRestCall_603389
proc url_DeleteEndpointConfig_604493(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteEndpointConfig_604492(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604494 = header.getOrDefault("X-Amz-Target")
  valid_604494 = validateParameter(valid_604494, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_604494 != nil:
    section.add "X-Amz-Target", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-Signature")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Signature", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Content-Sha256", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Date")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Date", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Credential")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Credential", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Security-Token")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Security-Token", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Algorithm")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Algorithm", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-SignedHeaders", valid_604501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604503: Call_DeleteEndpointConfig_604491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_604503.validator(path, query, header, formData, body)
  let scheme = call_604503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604503.url(scheme.get, call_604503.host, call_604503.base,
                         call_604503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604503, url, valid)

proc call*(call_604504: Call_DeleteEndpointConfig_604491; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_604505 = newJObject()
  if body != nil:
    body_604505 = body
  result = call_604504.call(nil, nil, nil, nil, body_604505)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_604491(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_604492, base: "/",
    url: url_DeleteEndpointConfig_604493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_604506 = ref object of OpenApiRestCall_603389
proc url_DeleteExperiment_604508(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteExperiment_604507(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604509 = header.getOrDefault("X-Amz-Target")
  valid_604509 = validateParameter(valid_604509, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_604509 != nil:
    section.add "X-Amz-Target", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-Signature")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-Signature", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Content-Sha256", valid_604511
  var valid_604512 = header.getOrDefault("X-Amz-Date")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "X-Amz-Date", valid_604512
  var valid_604513 = header.getOrDefault("X-Amz-Credential")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Credential", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Security-Token")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Security-Token", valid_604514
  var valid_604515 = header.getOrDefault("X-Amz-Algorithm")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Algorithm", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-SignedHeaders", valid_604516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604518: Call_DeleteExperiment_604506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_604518.validator(path, query, header, formData, body)
  let scheme = call_604518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604518.url(scheme.get, call_604518.host, call_604518.base,
                         call_604518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604518, url, valid)

proc call*(call_604519: Call_DeleteExperiment_604506; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_604520 = newJObject()
  if body != nil:
    body_604520 = body
  result = call_604519.call(nil, nil, nil, nil, body_604520)

var deleteExperiment* = Call_DeleteExperiment_604506(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_604507, base: "/",
    url: url_DeleteExperiment_604508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_604521 = ref object of OpenApiRestCall_603389
proc url_DeleteFlowDefinition_604523(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFlowDefinition_604522(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604524 = header.getOrDefault("X-Amz-Target")
  valid_604524 = validateParameter(valid_604524, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_604524 != nil:
    section.add "X-Amz-Target", valid_604524
  var valid_604525 = header.getOrDefault("X-Amz-Signature")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "X-Amz-Signature", valid_604525
  var valid_604526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "X-Amz-Content-Sha256", valid_604526
  var valid_604527 = header.getOrDefault("X-Amz-Date")
  valid_604527 = validateParameter(valid_604527, JString, required = false,
                                 default = nil)
  if valid_604527 != nil:
    section.add "X-Amz-Date", valid_604527
  var valid_604528 = header.getOrDefault("X-Amz-Credential")
  valid_604528 = validateParameter(valid_604528, JString, required = false,
                                 default = nil)
  if valid_604528 != nil:
    section.add "X-Amz-Credential", valid_604528
  var valid_604529 = header.getOrDefault("X-Amz-Security-Token")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "X-Amz-Security-Token", valid_604529
  var valid_604530 = header.getOrDefault("X-Amz-Algorithm")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Algorithm", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-SignedHeaders", valid_604531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604533: Call_DeleteFlowDefinition_604521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_604533.validator(path, query, header, formData, body)
  let scheme = call_604533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604533.url(scheme.get, call_604533.host, call_604533.base,
                         call_604533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604533, url, valid)

proc call*(call_604534: Call_DeleteFlowDefinition_604521; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_604535 = newJObject()
  if body != nil:
    body_604535 = body
  result = call_604534.call(nil, nil, nil, nil, body_604535)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_604521(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_604522, base: "/",
    url: url_DeleteFlowDefinition_604523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_604536 = ref object of OpenApiRestCall_603389
proc url_DeleteModel_604538(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModel_604537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604539 = header.getOrDefault("X-Amz-Target")
  valid_604539 = validateParameter(valid_604539, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_604539 != nil:
    section.add "X-Amz-Target", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Signature")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Signature", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Content-Sha256", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Date")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Date", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-Credential")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Credential", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Security-Token")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Security-Token", valid_604544
  var valid_604545 = header.getOrDefault("X-Amz-Algorithm")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-Algorithm", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-SignedHeaders", valid_604546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604548: Call_DeleteModel_604536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_604548.validator(path, query, header, formData, body)
  let scheme = call_604548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604548.url(scheme.get, call_604548.host, call_604548.base,
                         call_604548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604548, url, valid)

proc call*(call_604549: Call_DeleteModel_604536; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_604550 = newJObject()
  if body != nil:
    body_604550 = body
  result = call_604549.call(nil, nil, nil, nil, body_604550)

var deleteModel* = Call_DeleteModel_604536(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_604537,
                                        base: "/", url: url_DeleteModel_604538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_604551 = ref object of OpenApiRestCall_603389
proc url_DeleteModelPackage_604553(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteModelPackage_604552(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604554 = header.getOrDefault("X-Amz-Target")
  valid_604554 = validateParameter(valid_604554, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_604554 != nil:
    section.add "X-Amz-Target", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-Signature")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Signature", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Content-Sha256", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-Date")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Date", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Credential")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Credential", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Security-Token")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Security-Token", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-Algorithm")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-Algorithm", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-SignedHeaders", valid_604561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604563: Call_DeleteModelPackage_604551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_604563.validator(path, query, header, formData, body)
  let scheme = call_604563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604563.url(scheme.get, call_604563.host, call_604563.base,
                         call_604563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604563, url, valid)

proc call*(call_604564: Call_DeleteModelPackage_604551; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_604565 = newJObject()
  if body != nil:
    body_604565 = body
  result = call_604564.call(nil, nil, nil, nil, body_604565)

var deleteModelPackage* = Call_DeleteModelPackage_604551(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_604552, base: "/",
    url: url_DeleteModelPackage_604553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_604566 = ref object of OpenApiRestCall_603389
proc url_DeleteMonitoringSchedule_604568(protocol: Scheme; host: string;
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

proc validate_DeleteMonitoringSchedule_604567(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604569 = header.getOrDefault("X-Amz-Target")
  valid_604569 = validateParameter(valid_604569, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_604569 != nil:
    section.add "X-Amz-Target", valid_604569
  var valid_604570 = header.getOrDefault("X-Amz-Signature")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "X-Amz-Signature", valid_604570
  var valid_604571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Content-Sha256", valid_604571
  var valid_604572 = header.getOrDefault("X-Amz-Date")
  valid_604572 = validateParameter(valid_604572, JString, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "X-Amz-Date", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-Credential")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Credential", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Security-Token")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Security-Token", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Algorithm")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Algorithm", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-SignedHeaders", valid_604576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604578: Call_DeleteMonitoringSchedule_604566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_604578.validator(path, query, header, formData, body)
  let scheme = call_604578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604578.url(scheme.get, call_604578.host, call_604578.base,
                         call_604578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604578, url, valid)

proc call*(call_604579: Call_DeleteMonitoringSchedule_604566; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_604580 = newJObject()
  if body != nil:
    body_604580 = body
  result = call_604579.call(nil, nil, nil, nil, body_604580)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_604566(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_604567, base: "/",
    url: url_DeleteMonitoringSchedule_604568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_604581 = ref object of OpenApiRestCall_603389
proc url_DeleteNotebookInstance_604583(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNotebookInstance_604582(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604584 = header.getOrDefault("X-Amz-Target")
  valid_604584 = validateParameter(valid_604584, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_604584 != nil:
    section.add "X-Amz-Target", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Signature")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Signature", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Content-Sha256", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Date")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Date", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Credential")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Credential", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Security-Token")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Security-Token", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Algorithm")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Algorithm", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-SignedHeaders", valid_604591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604593: Call_DeleteNotebookInstance_604581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_604593.validator(path, query, header, formData, body)
  let scheme = call_604593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604593.url(scheme.get, call_604593.host, call_604593.base,
                         call_604593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604593, url, valid)

proc call*(call_604594: Call_DeleteNotebookInstance_604581; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_604595 = newJObject()
  if body != nil:
    body_604595 = body
  result = call_604594.call(nil, nil, nil, nil, body_604595)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_604581(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_604582, base: "/",
    url: url_DeleteNotebookInstance_604583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_604596 = ref object of OpenApiRestCall_603389
proc url_DeleteNotebookInstanceLifecycleConfig_604598(protocol: Scheme;
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

proc validate_DeleteNotebookInstanceLifecycleConfig_604597(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604599 = header.getOrDefault("X-Amz-Target")
  valid_604599 = validateParameter(valid_604599, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_604599 != nil:
    section.add "X-Amz-Target", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Signature")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Signature", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Content-Sha256", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Date")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Date", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Credential")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Credential", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Security-Token")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Security-Token", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Algorithm")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Algorithm", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-SignedHeaders", valid_604606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604608: Call_DeleteNotebookInstanceLifecycleConfig_604596;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_604608.validator(path, query, header, formData, body)
  let scheme = call_604608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604608.url(scheme.get, call_604608.host, call_604608.base,
                         call_604608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604608, url, valid)

proc call*(call_604609: Call_DeleteNotebookInstanceLifecycleConfig_604596;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_604610 = newJObject()
  if body != nil:
    body_604610 = body
  result = call_604609.call(nil, nil, nil, nil, body_604610)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_604596(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_604597, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_604598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_604611 = ref object of OpenApiRestCall_603389
proc url_DeleteTags_604613(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_604612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604614 = header.getOrDefault("X-Amz-Target")
  valid_604614 = validateParameter(valid_604614, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_604614 != nil:
    section.add "X-Amz-Target", valid_604614
  var valid_604615 = header.getOrDefault("X-Amz-Signature")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Signature", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Content-Sha256", valid_604616
  var valid_604617 = header.getOrDefault("X-Amz-Date")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-Date", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Credential")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Credential", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Security-Token")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Security-Token", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Algorithm")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Algorithm", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-SignedHeaders", valid_604621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604623: Call_DeleteTags_604611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_604623.validator(path, query, header, formData, body)
  let scheme = call_604623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604623.url(scheme.get, call_604623.host, call_604623.base,
                         call_604623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604623, url, valid)

proc call*(call_604624: Call_DeleteTags_604611; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_604625 = newJObject()
  if body != nil:
    body_604625 = body
  result = call_604624.call(nil, nil, nil, nil, body_604625)

var deleteTags* = Call_DeleteTags_604611(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_604612,
                                      base: "/", url: url_DeleteTags_604613,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_604626 = ref object of OpenApiRestCall_603389
proc url_DeleteTrial_604628(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrial_604627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604629 = header.getOrDefault("X-Amz-Target")
  valid_604629 = validateParameter(valid_604629, JString, required = true,
                                 default = newJString("SageMaker.DeleteTrial"))
  if valid_604629 != nil:
    section.add "X-Amz-Target", valid_604629
  var valid_604630 = header.getOrDefault("X-Amz-Signature")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Signature", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Content-Sha256", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-Date")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Date", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Credential")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Credential", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Security-Token")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Security-Token", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Algorithm")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Algorithm", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-SignedHeaders", valid_604636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604638: Call_DeleteTrial_604626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_604638.validator(path, query, header, formData, body)
  let scheme = call_604638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604638.url(scheme.get, call_604638.host, call_604638.base,
                         call_604638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604638, url, valid)

proc call*(call_604639: Call_DeleteTrial_604626; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_604640 = newJObject()
  if body != nil:
    body_604640 = body
  result = call_604639.call(nil, nil, nil, nil, body_604640)

var deleteTrial* = Call_DeleteTrial_604626(name: "deleteTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTrial",
                                        validator: validate_DeleteTrial_604627,
                                        base: "/", url: url_DeleteTrial_604628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_604641 = ref object of OpenApiRestCall_603389
proc url_DeleteTrialComponent_604643(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrialComponent_604642(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604644 = header.getOrDefault("X-Amz-Target")
  valid_604644 = validateParameter(valid_604644, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_604644 != nil:
    section.add "X-Amz-Target", valid_604644
  var valid_604645 = header.getOrDefault("X-Amz-Signature")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Signature", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Content-Sha256", valid_604646
  var valid_604647 = header.getOrDefault("X-Amz-Date")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "X-Amz-Date", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Credential")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Credential", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Security-Token")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Security-Token", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-Algorithm")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Algorithm", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-SignedHeaders", valid_604651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604653: Call_DeleteTrialComponent_604641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_604653.validator(path, query, header, formData, body)
  let scheme = call_604653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604653.url(scheme.get, call_604653.host, call_604653.base,
                         call_604653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604653, url, valid)

proc call*(call_604654: Call_DeleteTrialComponent_604641; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_604655 = newJObject()
  if body != nil:
    body_604655 = body
  result = call_604654.call(nil, nil, nil, nil, body_604655)

var deleteTrialComponent* = Call_DeleteTrialComponent_604641(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_604642, base: "/",
    url: url_DeleteTrialComponent_604643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_604656 = ref object of OpenApiRestCall_603389
proc url_DeleteUserProfile_604658(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserProfile_604657(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604659 = header.getOrDefault("X-Amz-Target")
  valid_604659 = validateParameter(valid_604659, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_604659 != nil:
    section.add "X-Amz-Target", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-Signature")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Signature", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-Content-Sha256", valid_604661
  var valid_604662 = header.getOrDefault("X-Amz-Date")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Date", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Credential")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Credential", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Security-Token")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Security-Token", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Algorithm")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Algorithm", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-SignedHeaders", valid_604666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604668: Call_DeleteUserProfile_604656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_604668.validator(path, query, header, formData, body)
  let scheme = call_604668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604668.url(scheme.get, call_604668.host, call_604668.base,
                         call_604668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604668, url, valid)

proc call*(call_604669: Call_DeleteUserProfile_604656; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_604670 = newJObject()
  if body != nil:
    body_604670 = body
  result = call_604669.call(nil, nil, nil, nil, body_604670)

var deleteUserProfile* = Call_DeleteUserProfile_604656(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_604657, base: "/",
    url: url_DeleteUserProfile_604658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_604671 = ref object of OpenApiRestCall_603389
proc url_DeleteWorkteam_604673(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkteam_604672(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604674 = header.getOrDefault("X-Amz-Target")
  valid_604674 = validateParameter(valid_604674, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_604674 != nil:
    section.add "X-Amz-Target", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-Signature")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Signature", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Content-Sha256", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Date")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Date", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Credential")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Credential", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Security-Token")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Security-Token", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Algorithm")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Algorithm", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-SignedHeaders", valid_604681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604683: Call_DeleteWorkteam_604671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_604683.validator(path, query, header, formData, body)
  let scheme = call_604683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604683.url(scheme.get, call_604683.host, call_604683.base,
                         call_604683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604683, url, valid)

proc call*(call_604684: Call_DeleteWorkteam_604671; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_604685 = newJObject()
  if body != nil:
    body_604685 = body
  result = call_604684.call(nil, nil, nil, nil, body_604685)

var deleteWorkteam* = Call_DeleteWorkteam_604671(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_604672, base: "/", url: url_DeleteWorkteam_604673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_604686 = ref object of OpenApiRestCall_603389
proc url_DescribeAlgorithm_604688(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAlgorithm_604687(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604689 = header.getOrDefault("X-Amz-Target")
  valid_604689 = validateParameter(valid_604689, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_604689 != nil:
    section.add "X-Amz-Target", valid_604689
  var valid_604690 = header.getOrDefault("X-Amz-Signature")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Signature", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Content-Sha256", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Date")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Date", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Credential")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Credential", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Security-Token")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Security-Token", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Algorithm")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Algorithm", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-SignedHeaders", valid_604696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604698: Call_DescribeAlgorithm_604686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_604698.validator(path, query, header, formData, body)
  let scheme = call_604698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604698.url(scheme.get, call_604698.host, call_604698.base,
                         call_604698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604698, url, valid)

proc call*(call_604699: Call_DescribeAlgorithm_604686; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_604700 = newJObject()
  if body != nil:
    body_604700 = body
  result = call_604699.call(nil, nil, nil, nil, body_604700)

var describeAlgorithm* = Call_DescribeAlgorithm_604686(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_604687, base: "/",
    url: url_DescribeAlgorithm_604688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_604701 = ref object of OpenApiRestCall_603389
proc url_DescribeApp_604703(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeApp_604702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604704 = header.getOrDefault("X-Amz-Target")
  valid_604704 = validateParameter(valid_604704, JString, required = true,
                                 default = newJString("SageMaker.DescribeApp"))
  if valid_604704 != nil:
    section.add "X-Amz-Target", valid_604704
  var valid_604705 = header.getOrDefault("X-Amz-Signature")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-Signature", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Content-Sha256", valid_604706
  var valid_604707 = header.getOrDefault("X-Amz-Date")
  valid_604707 = validateParameter(valid_604707, JString, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "X-Amz-Date", valid_604707
  var valid_604708 = header.getOrDefault("X-Amz-Credential")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "X-Amz-Credential", valid_604708
  var valid_604709 = header.getOrDefault("X-Amz-Security-Token")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "X-Amz-Security-Token", valid_604709
  var valid_604710 = header.getOrDefault("X-Amz-Algorithm")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Algorithm", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-SignedHeaders", valid_604711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604713: Call_DescribeApp_604701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the app.
  ## 
  let valid = call_604713.validator(path, query, header, formData, body)
  let scheme = call_604713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604713.url(scheme.get, call_604713.host, call_604713.base,
                         call_604713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604713, url, valid)

proc call*(call_604714: Call_DescribeApp_604701; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_604715 = newJObject()
  if body != nil:
    body_604715 = body
  result = call_604714.call(nil, nil, nil, nil, body_604715)

var describeApp* = Call_DescribeApp_604701(name: "describeApp",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DescribeApp",
                                        validator: validate_DescribeApp_604702,
                                        base: "/", url: url_DescribeApp_604703,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_604716 = ref object of OpenApiRestCall_603389
proc url_DescribeAutoMLJob_604718(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAutoMLJob_604717(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604719 = header.getOrDefault("X-Amz-Target")
  valid_604719 = validateParameter(valid_604719, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_604719 != nil:
    section.add "X-Amz-Target", valid_604719
  var valid_604720 = header.getOrDefault("X-Amz-Signature")
  valid_604720 = validateParameter(valid_604720, JString, required = false,
                                 default = nil)
  if valid_604720 != nil:
    section.add "X-Amz-Signature", valid_604720
  var valid_604721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Content-Sha256", valid_604721
  var valid_604722 = header.getOrDefault("X-Amz-Date")
  valid_604722 = validateParameter(valid_604722, JString, required = false,
                                 default = nil)
  if valid_604722 != nil:
    section.add "X-Amz-Date", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Credential")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Credential", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Security-Token")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Security-Token", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Algorithm")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Algorithm", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-SignedHeaders", valid_604726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604728: Call_DescribeAutoMLJob_604716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_604728.validator(path, query, header, formData, body)
  let scheme = call_604728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604728.url(scheme.get, call_604728.host, call_604728.base,
                         call_604728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604728, url, valid)

proc call*(call_604729: Call_DescribeAutoMLJob_604716; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_604730 = newJObject()
  if body != nil:
    body_604730 = body
  result = call_604729.call(nil, nil, nil, nil, body_604730)

var describeAutoMLJob* = Call_DescribeAutoMLJob_604716(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_604717, base: "/",
    url: url_DescribeAutoMLJob_604718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_604731 = ref object of OpenApiRestCall_603389
proc url_DescribeCodeRepository_604733(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCodeRepository_604732(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604734 = header.getOrDefault("X-Amz-Target")
  valid_604734 = validateParameter(valid_604734, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_604734 != nil:
    section.add "X-Amz-Target", valid_604734
  var valid_604735 = header.getOrDefault("X-Amz-Signature")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Signature", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Content-Sha256", valid_604736
  var valid_604737 = header.getOrDefault("X-Amz-Date")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "X-Amz-Date", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Credential")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Credential", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Security-Token")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Security-Token", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-Algorithm")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-Algorithm", valid_604740
  var valid_604741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "X-Amz-SignedHeaders", valid_604741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604743: Call_DescribeCodeRepository_604731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_604743.validator(path, query, header, formData, body)
  let scheme = call_604743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604743.url(scheme.get, call_604743.host, call_604743.base,
                         call_604743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604743, url, valid)

proc call*(call_604744: Call_DescribeCodeRepository_604731; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_604745 = newJObject()
  if body != nil:
    body_604745 = body
  result = call_604744.call(nil, nil, nil, nil, body_604745)

var describeCodeRepository* = Call_DescribeCodeRepository_604731(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_604732, base: "/",
    url: url_DescribeCodeRepository_604733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_604746 = ref object of OpenApiRestCall_603389
proc url_DescribeCompilationJob_604748(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCompilationJob_604747(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604749 = header.getOrDefault("X-Amz-Target")
  valid_604749 = validateParameter(valid_604749, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_604749 != nil:
    section.add "X-Amz-Target", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-Signature")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Signature", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Content-Sha256", valid_604751
  var valid_604752 = header.getOrDefault("X-Amz-Date")
  valid_604752 = validateParameter(valid_604752, JString, required = false,
                                 default = nil)
  if valid_604752 != nil:
    section.add "X-Amz-Date", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-Credential")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Credential", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Security-Token")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Security-Token", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Algorithm")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Algorithm", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-SignedHeaders", valid_604756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604758: Call_DescribeCompilationJob_604746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_604758.validator(path, query, header, formData, body)
  let scheme = call_604758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604758.url(scheme.get, call_604758.host, call_604758.base,
                         call_604758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604758, url, valid)

proc call*(call_604759: Call_DescribeCompilationJob_604746; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_604760 = newJObject()
  if body != nil:
    body_604760 = body
  result = call_604759.call(nil, nil, nil, nil, body_604760)

var describeCompilationJob* = Call_DescribeCompilationJob_604746(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_604747, base: "/",
    url: url_DescribeCompilationJob_604748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_604761 = ref object of OpenApiRestCall_603389
proc url_DescribeDomain_604763(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDomain_604762(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604764 = header.getOrDefault("X-Amz-Target")
  valid_604764 = validateParameter(valid_604764, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_604764 != nil:
    section.add "X-Amz-Target", valid_604764
  var valid_604765 = header.getOrDefault("X-Amz-Signature")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Signature", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Content-Sha256", valid_604766
  var valid_604767 = header.getOrDefault("X-Amz-Date")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "X-Amz-Date", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Credential")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Credential", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Security-Token")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Security-Token", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Algorithm")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Algorithm", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-SignedHeaders", valid_604771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604773: Call_DescribeDomain_604761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_604773.validator(path, query, header, formData, body)
  let scheme = call_604773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604773.url(scheme.get, call_604773.host, call_604773.base,
                         call_604773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604773, url, valid)

proc call*(call_604774: Call_DescribeDomain_604761; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_604775 = newJObject()
  if body != nil:
    body_604775 = body
  result = call_604774.call(nil, nil, nil, nil, body_604775)

var describeDomain* = Call_DescribeDomain_604761(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_604762, base: "/", url: url_DescribeDomain_604763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_604776 = ref object of OpenApiRestCall_603389
proc url_DescribeEndpoint_604778(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpoint_604777(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604779 = header.getOrDefault("X-Amz-Target")
  valid_604779 = validateParameter(valid_604779, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_604779 != nil:
    section.add "X-Amz-Target", valid_604779
  var valid_604780 = header.getOrDefault("X-Amz-Signature")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Signature", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-Content-Sha256", valid_604781
  var valid_604782 = header.getOrDefault("X-Amz-Date")
  valid_604782 = validateParameter(valid_604782, JString, required = false,
                                 default = nil)
  if valid_604782 != nil:
    section.add "X-Amz-Date", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Credential")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Credential", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Security-Token")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Security-Token", valid_604784
  var valid_604785 = header.getOrDefault("X-Amz-Algorithm")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-Algorithm", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-SignedHeaders", valid_604786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604788: Call_DescribeEndpoint_604776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_604788.validator(path, query, header, formData, body)
  let scheme = call_604788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604788.url(scheme.get, call_604788.host, call_604788.base,
                         call_604788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604788, url, valid)

proc call*(call_604789: Call_DescribeEndpoint_604776; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_604790 = newJObject()
  if body != nil:
    body_604790 = body
  result = call_604789.call(nil, nil, nil, nil, body_604790)

var describeEndpoint* = Call_DescribeEndpoint_604776(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_604777, base: "/",
    url: url_DescribeEndpoint_604778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_604791 = ref object of OpenApiRestCall_603389
proc url_DescribeEndpointConfig_604793(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEndpointConfig_604792(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604794 = header.getOrDefault("X-Amz-Target")
  valid_604794 = validateParameter(valid_604794, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_604794 != nil:
    section.add "X-Amz-Target", valid_604794
  var valid_604795 = header.getOrDefault("X-Amz-Signature")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-Signature", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Content-Sha256", valid_604796
  var valid_604797 = header.getOrDefault("X-Amz-Date")
  valid_604797 = validateParameter(valid_604797, JString, required = false,
                                 default = nil)
  if valid_604797 != nil:
    section.add "X-Amz-Date", valid_604797
  var valid_604798 = header.getOrDefault("X-Amz-Credential")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-Credential", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Security-Token")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Security-Token", valid_604799
  var valid_604800 = header.getOrDefault("X-Amz-Algorithm")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "X-Amz-Algorithm", valid_604800
  var valid_604801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604801 = validateParameter(valid_604801, JString, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "X-Amz-SignedHeaders", valid_604801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604803: Call_DescribeEndpointConfig_604791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_604803.validator(path, query, header, formData, body)
  let scheme = call_604803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604803.url(scheme.get, call_604803.host, call_604803.base,
                         call_604803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604803, url, valid)

proc call*(call_604804: Call_DescribeEndpointConfig_604791; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_604805 = newJObject()
  if body != nil:
    body_604805 = body
  result = call_604804.call(nil, nil, nil, nil, body_604805)

var describeEndpointConfig* = Call_DescribeEndpointConfig_604791(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_604792, base: "/",
    url: url_DescribeEndpointConfig_604793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_604806 = ref object of OpenApiRestCall_603389
proc url_DescribeExperiment_604808(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeExperiment_604807(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604809 = header.getOrDefault("X-Amz-Target")
  valid_604809 = validateParameter(valid_604809, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_604809 != nil:
    section.add "X-Amz-Target", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Signature")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Signature", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Content-Sha256", valid_604811
  var valid_604812 = header.getOrDefault("X-Amz-Date")
  valid_604812 = validateParameter(valid_604812, JString, required = false,
                                 default = nil)
  if valid_604812 != nil:
    section.add "X-Amz-Date", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-Credential")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Credential", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Security-Token")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Security-Token", valid_604814
  var valid_604815 = header.getOrDefault("X-Amz-Algorithm")
  valid_604815 = validateParameter(valid_604815, JString, required = false,
                                 default = nil)
  if valid_604815 != nil:
    section.add "X-Amz-Algorithm", valid_604815
  var valid_604816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604816 = validateParameter(valid_604816, JString, required = false,
                                 default = nil)
  if valid_604816 != nil:
    section.add "X-Amz-SignedHeaders", valid_604816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604818: Call_DescribeExperiment_604806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_604818.validator(path, query, header, formData, body)
  let scheme = call_604818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604818.url(scheme.get, call_604818.host, call_604818.base,
                         call_604818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604818, url, valid)

proc call*(call_604819: Call_DescribeExperiment_604806; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_604820 = newJObject()
  if body != nil:
    body_604820 = body
  result = call_604819.call(nil, nil, nil, nil, body_604820)

var describeExperiment* = Call_DescribeExperiment_604806(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_604807, base: "/",
    url: url_DescribeExperiment_604808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_604821 = ref object of OpenApiRestCall_603389
proc url_DescribeFlowDefinition_604823(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFlowDefinition_604822(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604824 = header.getOrDefault("X-Amz-Target")
  valid_604824 = validateParameter(valid_604824, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_604824 != nil:
    section.add "X-Amz-Target", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Signature")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Signature", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Content-Sha256", valid_604826
  var valid_604827 = header.getOrDefault("X-Amz-Date")
  valid_604827 = validateParameter(valid_604827, JString, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "X-Amz-Date", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-Credential")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Credential", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Security-Token")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Security-Token", valid_604829
  var valid_604830 = header.getOrDefault("X-Amz-Algorithm")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "X-Amz-Algorithm", valid_604830
  var valid_604831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604831 = validateParameter(valid_604831, JString, required = false,
                                 default = nil)
  if valid_604831 != nil:
    section.add "X-Amz-SignedHeaders", valid_604831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604833: Call_DescribeFlowDefinition_604821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_604833.validator(path, query, header, formData, body)
  let scheme = call_604833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604833.url(scheme.get, call_604833.host, call_604833.base,
                         call_604833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604833, url, valid)

proc call*(call_604834: Call_DescribeFlowDefinition_604821; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_604835 = newJObject()
  if body != nil:
    body_604835 = body
  result = call_604834.call(nil, nil, nil, nil, body_604835)

var describeFlowDefinition* = Call_DescribeFlowDefinition_604821(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_604822, base: "/",
    url: url_DescribeFlowDefinition_604823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_604836 = ref object of OpenApiRestCall_603389
proc url_DescribeHumanTaskUi_604838(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHumanTaskUi_604837(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604839 = header.getOrDefault("X-Amz-Target")
  valid_604839 = validateParameter(valid_604839, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_604839 != nil:
    section.add "X-Amz-Target", valid_604839
  var valid_604840 = header.getOrDefault("X-Amz-Signature")
  valid_604840 = validateParameter(valid_604840, JString, required = false,
                                 default = nil)
  if valid_604840 != nil:
    section.add "X-Amz-Signature", valid_604840
  var valid_604841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604841 = validateParameter(valid_604841, JString, required = false,
                                 default = nil)
  if valid_604841 != nil:
    section.add "X-Amz-Content-Sha256", valid_604841
  var valid_604842 = header.getOrDefault("X-Amz-Date")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Date", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Credential")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Credential", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Security-Token")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Security-Token", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Algorithm")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Algorithm", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-SignedHeaders", valid_604846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604848: Call_DescribeHumanTaskUi_604836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_604848.validator(path, query, header, formData, body)
  let scheme = call_604848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604848.url(scheme.get, call_604848.host, call_604848.base,
                         call_604848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604848, url, valid)

proc call*(call_604849: Call_DescribeHumanTaskUi_604836; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_604850 = newJObject()
  if body != nil:
    body_604850 = body
  result = call_604849.call(nil, nil, nil, nil, body_604850)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_604836(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_604837, base: "/",
    url: url_DescribeHumanTaskUi_604838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_604851 = ref object of OpenApiRestCall_603389
proc url_DescribeHyperParameterTuningJob_604853(protocol: Scheme; host: string;
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

proc validate_DescribeHyperParameterTuningJob_604852(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604854 = header.getOrDefault("X-Amz-Target")
  valid_604854 = validateParameter(valid_604854, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_604854 != nil:
    section.add "X-Amz-Target", valid_604854
  var valid_604855 = header.getOrDefault("X-Amz-Signature")
  valid_604855 = validateParameter(valid_604855, JString, required = false,
                                 default = nil)
  if valid_604855 != nil:
    section.add "X-Amz-Signature", valid_604855
  var valid_604856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604856 = validateParameter(valid_604856, JString, required = false,
                                 default = nil)
  if valid_604856 != nil:
    section.add "X-Amz-Content-Sha256", valid_604856
  var valid_604857 = header.getOrDefault("X-Amz-Date")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-Date", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Credential")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Credential", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Security-Token")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Security-Token", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-Algorithm")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-Algorithm", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-SignedHeaders", valid_604861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604863: Call_DescribeHyperParameterTuningJob_604851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_604863.validator(path, query, header, formData, body)
  let scheme = call_604863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604863.url(scheme.get, call_604863.host, call_604863.base,
                         call_604863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604863, url, valid)

proc call*(call_604864: Call_DescribeHyperParameterTuningJob_604851; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_604865 = newJObject()
  if body != nil:
    body_604865 = body
  result = call_604864.call(nil, nil, nil, nil, body_604865)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_604851(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_604852, base: "/",
    url: url_DescribeHyperParameterTuningJob_604853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_604866 = ref object of OpenApiRestCall_603389
proc url_DescribeLabelingJob_604868(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLabelingJob_604867(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604869 = header.getOrDefault("X-Amz-Target")
  valid_604869 = validateParameter(valid_604869, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_604869 != nil:
    section.add "X-Amz-Target", valid_604869
  var valid_604870 = header.getOrDefault("X-Amz-Signature")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-Signature", valid_604870
  var valid_604871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604871 = validateParameter(valid_604871, JString, required = false,
                                 default = nil)
  if valid_604871 != nil:
    section.add "X-Amz-Content-Sha256", valid_604871
  var valid_604872 = header.getOrDefault("X-Amz-Date")
  valid_604872 = validateParameter(valid_604872, JString, required = false,
                                 default = nil)
  if valid_604872 != nil:
    section.add "X-Amz-Date", valid_604872
  var valid_604873 = header.getOrDefault("X-Amz-Credential")
  valid_604873 = validateParameter(valid_604873, JString, required = false,
                                 default = nil)
  if valid_604873 != nil:
    section.add "X-Amz-Credential", valid_604873
  var valid_604874 = header.getOrDefault("X-Amz-Security-Token")
  valid_604874 = validateParameter(valid_604874, JString, required = false,
                                 default = nil)
  if valid_604874 != nil:
    section.add "X-Amz-Security-Token", valid_604874
  var valid_604875 = header.getOrDefault("X-Amz-Algorithm")
  valid_604875 = validateParameter(valid_604875, JString, required = false,
                                 default = nil)
  if valid_604875 != nil:
    section.add "X-Amz-Algorithm", valid_604875
  var valid_604876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604876 = validateParameter(valid_604876, JString, required = false,
                                 default = nil)
  if valid_604876 != nil:
    section.add "X-Amz-SignedHeaders", valid_604876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604878: Call_DescribeLabelingJob_604866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_604878.validator(path, query, header, formData, body)
  let scheme = call_604878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604878.url(scheme.get, call_604878.host, call_604878.base,
                         call_604878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604878, url, valid)

proc call*(call_604879: Call_DescribeLabelingJob_604866; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_604880 = newJObject()
  if body != nil:
    body_604880 = body
  result = call_604879.call(nil, nil, nil, nil, body_604880)

var describeLabelingJob* = Call_DescribeLabelingJob_604866(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_604867, base: "/",
    url: url_DescribeLabelingJob_604868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_604881 = ref object of OpenApiRestCall_603389
proc url_DescribeModel_604883(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModel_604882(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604884 = header.getOrDefault("X-Amz-Target")
  valid_604884 = validateParameter(valid_604884, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_604884 != nil:
    section.add "X-Amz-Target", valid_604884
  var valid_604885 = header.getOrDefault("X-Amz-Signature")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-Signature", valid_604885
  var valid_604886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "X-Amz-Content-Sha256", valid_604886
  var valid_604887 = header.getOrDefault("X-Amz-Date")
  valid_604887 = validateParameter(valid_604887, JString, required = false,
                                 default = nil)
  if valid_604887 != nil:
    section.add "X-Amz-Date", valid_604887
  var valid_604888 = header.getOrDefault("X-Amz-Credential")
  valid_604888 = validateParameter(valid_604888, JString, required = false,
                                 default = nil)
  if valid_604888 != nil:
    section.add "X-Amz-Credential", valid_604888
  var valid_604889 = header.getOrDefault("X-Amz-Security-Token")
  valid_604889 = validateParameter(valid_604889, JString, required = false,
                                 default = nil)
  if valid_604889 != nil:
    section.add "X-Amz-Security-Token", valid_604889
  var valid_604890 = header.getOrDefault("X-Amz-Algorithm")
  valid_604890 = validateParameter(valid_604890, JString, required = false,
                                 default = nil)
  if valid_604890 != nil:
    section.add "X-Amz-Algorithm", valid_604890
  var valid_604891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604891 = validateParameter(valid_604891, JString, required = false,
                                 default = nil)
  if valid_604891 != nil:
    section.add "X-Amz-SignedHeaders", valid_604891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604893: Call_DescribeModel_604881; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_604893.validator(path, query, header, formData, body)
  let scheme = call_604893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604893.url(scheme.get, call_604893.host, call_604893.base,
                         call_604893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604893, url, valid)

proc call*(call_604894: Call_DescribeModel_604881; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_604895 = newJObject()
  if body != nil:
    body_604895 = body
  result = call_604894.call(nil, nil, nil, nil, body_604895)

var describeModel* = Call_DescribeModel_604881(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_604882, base: "/", url: url_DescribeModel_604883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_604896 = ref object of OpenApiRestCall_603389
proc url_DescribeModelPackage_604898(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeModelPackage_604897(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604899 = header.getOrDefault("X-Amz-Target")
  valid_604899 = validateParameter(valid_604899, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_604899 != nil:
    section.add "X-Amz-Target", valid_604899
  var valid_604900 = header.getOrDefault("X-Amz-Signature")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Signature", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-Content-Sha256", valid_604901
  var valid_604902 = header.getOrDefault("X-Amz-Date")
  valid_604902 = validateParameter(valid_604902, JString, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "X-Amz-Date", valid_604902
  var valid_604903 = header.getOrDefault("X-Amz-Credential")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-Credential", valid_604903
  var valid_604904 = header.getOrDefault("X-Amz-Security-Token")
  valid_604904 = validateParameter(valid_604904, JString, required = false,
                                 default = nil)
  if valid_604904 != nil:
    section.add "X-Amz-Security-Token", valid_604904
  var valid_604905 = header.getOrDefault("X-Amz-Algorithm")
  valid_604905 = validateParameter(valid_604905, JString, required = false,
                                 default = nil)
  if valid_604905 != nil:
    section.add "X-Amz-Algorithm", valid_604905
  var valid_604906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604906 = validateParameter(valid_604906, JString, required = false,
                                 default = nil)
  if valid_604906 != nil:
    section.add "X-Amz-SignedHeaders", valid_604906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604908: Call_DescribeModelPackage_604896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_604908.validator(path, query, header, formData, body)
  let scheme = call_604908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604908.url(scheme.get, call_604908.host, call_604908.base,
                         call_604908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604908, url, valid)

proc call*(call_604909: Call_DescribeModelPackage_604896; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_604910 = newJObject()
  if body != nil:
    body_604910 = body
  result = call_604909.call(nil, nil, nil, nil, body_604910)

var describeModelPackage* = Call_DescribeModelPackage_604896(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_604897, base: "/",
    url: url_DescribeModelPackage_604898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_604911 = ref object of OpenApiRestCall_603389
proc url_DescribeMonitoringSchedule_604913(protocol: Scheme; host: string;
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

proc validate_DescribeMonitoringSchedule_604912(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604914 = header.getOrDefault("X-Amz-Target")
  valid_604914 = validateParameter(valid_604914, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_604914 != nil:
    section.add "X-Amz-Target", valid_604914
  var valid_604915 = header.getOrDefault("X-Amz-Signature")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-Signature", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Content-Sha256", valid_604916
  var valid_604917 = header.getOrDefault("X-Amz-Date")
  valid_604917 = validateParameter(valid_604917, JString, required = false,
                                 default = nil)
  if valid_604917 != nil:
    section.add "X-Amz-Date", valid_604917
  var valid_604918 = header.getOrDefault("X-Amz-Credential")
  valid_604918 = validateParameter(valid_604918, JString, required = false,
                                 default = nil)
  if valid_604918 != nil:
    section.add "X-Amz-Credential", valid_604918
  var valid_604919 = header.getOrDefault("X-Amz-Security-Token")
  valid_604919 = validateParameter(valid_604919, JString, required = false,
                                 default = nil)
  if valid_604919 != nil:
    section.add "X-Amz-Security-Token", valid_604919
  var valid_604920 = header.getOrDefault("X-Amz-Algorithm")
  valid_604920 = validateParameter(valid_604920, JString, required = false,
                                 default = nil)
  if valid_604920 != nil:
    section.add "X-Amz-Algorithm", valid_604920
  var valid_604921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604921 = validateParameter(valid_604921, JString, required = false,
                                 default = nil)
  if valid_604921 != nil:
    section.add "X-Amz-SignedHeaders", valid_604921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604923: Call_DescribeMonitoringSchedule_604911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_604923.validator(path, query, header, formData, body)
  let scheme = call_604923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604923.url(scheme.get, call_604923.host, call_604923.base,
                         call_604923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604923, url, valid)

proc call*(call_604924: Call_DescribeMonitoringSchedule_604911; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_604925 = newJObject()
  if body != nil:
    body_604925 = body
  result = call_604924.call(nil, nil, nil, nil, body_604925)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_604911(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_604912, base: "/",
    url: url_DescribeMonitoringSchedule_604913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_604926 = ref object of OpenApiRestCall_603389
proc url_DescribeNotebookInstance_604928(protocol: Scheme; host: string;
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

proc validate_DescribeNotebookInstance_604927(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604929 = header.getOrDefault("X-Amz-Target")
  valid_604929 = validateParameter(valid_604929, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_604929 != nil:
    section.add "X-Amz-Target", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-Signature")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Signature", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Content-Sha256", valid_604931
  var valid_604932 = header.getOrDefault("X-Amz-Date")
  valid_604932 = validateParameter(valid_604932, JString, required = false,
                                 default = nil)
  if valid_604932 != nil:
    section.add "X-Amz-Date", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-Credential")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Credential", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Security-Token")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Security-Token", valid_604934
  var valid_604935 = header.getOrDefault("X-Amz-Algorithm")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-Algorithm", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-SignedHeaders", valid_604936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604938: Call_DescribeNotebookInstance_604926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_604938.validator(path, query, header, formData, body)
  let scheme = call_604938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604938.url(scheme.get, call_604938.host, call_604938.base,
                         call_604938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604938, url, valid)

proc call*(call_604939: Call_DescribeNotebookInstance_604926; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_604940 = newJObject()
  if body != nil:
    body_604940 = body
  result = call_604939.call(nil, nil, nil, nil, body_604940)

var describeNotebookInstance* = Call_DescribeNotebookInstance_604926(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_604927, base: "/",
    url: url_DescribeNotebookInstance_604928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_604941 = ref object of OpenApiRestCall_603389
proc url_DescribeNotebookInstanceLifecycleConfig_604943(protocol: Scheme;
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

proc validate_DescribeNotebookInstanceLifecycleConfig_604942(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604944 = header.getOrDefault("X-Amz-Target")
  valid_604944 = validateParameter(valid_604944, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_604944 != nil:
    section.add "X-Amz-Target", valid_604944
  var valid_604945 = header.getOrDefault("X-Amz-Signature")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "X-Amz-Signature", valid_604945
  var valid_604946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "X-Amz-Content-Sha256", valid_604946
  var valid_604947 = header.getOrDefault("X-Amz-Date")
  valid_604947 = validateParameter(valid_604947, JString, required = false,
                                 default = nil)
  if valid_604947 != nil:
    section.add "X-Amz-Date", valid_604947
  var valid_604948 = header.getOrDefault("X-Amz-Credential")
  valid_604948 = validateParameter(valid_604948, JString, required = false,
                                 default = nil)
  if valid_604948 != nil:
    section.add "X-Amz-Credential", valid_604948
  var valid_604949 = header.getOrDefault("X-Amz-Security-Token")
  valid_604949 = validateParameter(valid_604949, JString, required = false,
                                 default = nil)
  if valid_604949 != nil:
    section.add "X-Amz-Security-Token", valid_604949
  var valid_604950 = header.getOrDefault("X-Amz-Algorithm")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Algorithm", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-SignedHeaders", valid_604951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604953: Call_DescribeNotebookInstanceLifecycleConfig_604941;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_604953.validator(path, query, header, formData, body)
  let scheme = call_604953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604953.url(scheme.get, call_604953.host, call_604953.base,
                         call_604953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604953, url, valid)

proc call*(call_604954: Call_DescribeNotebookInstanceLifecycleConfig_604941;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_604955 = newJObject()
  if body != nil:
    body_604955 = body
  result = call_604954.call(nil, nil, nil, nil, body_604955)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_604941(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_604942, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_604943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_604956 = ref object of OpenApiRestCall_603389
proc url_DescribeProcessingJob_604958(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProcessingJob_604957(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604959 = header.getOrDefault("X-Amz-Target")
  valid_604959 = validateParameter(valid_604959, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_604959 != nil:
    section.add "X-Amz-Target", valid_604959
  var valid_604960 = header.getOrDefault("X-Amz-Signature")
  valid_604960 = validateParameter(valid_604960, JString, required = false,
                                 default = nil)
  if valid_604960 != nil:
    section.add "X-Amz-Signature", valid_604960
  var valid_604961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "X-Amz-Content-Sha256", valid_604961
  var valid_604962 = header.getOrDefault("X-Amz-Date")
  valid_604962 = validateParameter(valid_604962, JString, required = false,
                                 default = nil)
  if valid_604962 != nil:
    section.add "X-Amz-Date", valid_604962
  var valid_604963 = header.getOrDefault("X-Amz-Credential")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "X-Amz-Credential", valid_604963
  var valid_604964 = header.getOrDefault("X-Amz-Security-Token")
  valid_604964 = validateParameter(valid_604964, JString, required = false,
                                 default = nil)
  if valid_604964 != nil:
    section.add "X-Amz-Security-Token", valid_604964
  var valid_604965 = header.getOrDefault("X-Amz-Algorithm")
  valid_604965 = validateParameter(valid_604965, JString, required = false,
                                 default = nil)
  if valid_604965 != nil:
    section.add "X-Amz-Algorithm", valid_604965
  var valid_604966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604966 = validateParameter(valid_604966, JString, required = false,
                                 default = nil)
  if valid_604966 != nil:
    section.add "X-Amz-SignedHeaders", valid_604966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604968: Call_DescribeProcessingJob_604956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_604968.validator(path, query, header, formData, body)
  let scheme = call_604968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604968.url(scheme.get, call_604968.host, call_604968.base,
                         call_604968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604968, url, valid)

proc call*(call_604969: Call_DescribeProcessingJob_604956; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_604970 = newJObject()
  if body != nil:
    body_604970 = body
  result = call_604969.call(nil, nil, nil, nil, body_604970)

var describeProcessingJob* = Call_DescribeProcessingJob_604956(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_604957, base: "/",
    url: url_DescribeProcessingJob_604958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_604971 = ref object of OpenApiRestCall_603389
proc url_DescribeSubscribedWorkteam_604973(protocol: Scheme; host: string;
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

proc validate_DescribeSubscribedWorkteam_604972(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604974 = header.getOrDefault("X-Amz-Target")
  valid_604974 = validateParameter(valid_604974, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_604974 != nil:
    section.add "X-Amz-Target", valid_604974
  var valid_604975 = header.getOrDefault("X-Amz-Signature")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "X-Amz-Signature", valid_604975
  var valid_604976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604976 = validateParameter(valid_604976, JString, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "X-Amz-Content-Sha256", valid_604976
  var valid_604977 = header.getOrDefault("X-Amz-Date")
  valid_604977 = validateParameter(valid_604977, JString, required = false,
                                 default = nil)
  if valid_604977 != nil:
    section.add "X-Amz-Date", valid_604977
  var valid_604978 = header.getOrDefault("X-Amz-Credential")
  valid_604978 = validateParameter(valid_604978, JString, required = false,
                                 default = nil)
  if valid_604978 != nil:
    section.add "X-Amz-Credential", valid_604978
  var valid_604979 = header.getOrDefault("X-Amz-Security-Token")
  valid_604979 = validateParameter(valid_604979, JString, required = false,
                                 default = nil)
  if valid_604979 != nil:
    section.add "X-Amz-Security-Token", valid_604979
  var valid_604980 = header.getOrDefault("X-Amz-Algorithm")
  valid_604980 = validateParameter(valid_604980, JString, required = false,
                                 default = nil)
  if valid_604980 != nil:
    section.add "X-Amz-Algorithm", valid_604980
  var valid_604981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604981 = validateParameter(valid_604981, JString, required = false,
                                 default = nil)
  if valid_604981 != nil:
    section.add "X-Amz-SignedHeaders", valid_604981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604983: Call_DescribeSubscribedWorkteam_604971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_604983.validator(path, query, header, formData, body)
  let scheme = call_604983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604983.url(scheme.get, call_604983.host, call_604983.base,
                         call_604983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604983, url, valid)

proc call*(call_604984: Call_DescribeSubscribedWorkteam_604971; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_604985 = newJObject()
  if body != nil:
    body_604985 = body
  result = call_604984.call(nil, nil, nil, nil, body_604985)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_604971(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_604972, base: "/",
    url: url_DescribeSubscribedWorkteam_604973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_604986 = ref object of OpenApiRestCall_603389
proc url_DescribeTrainingJob_604988(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrainingJob_604987(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604989 = header.getOrDefault("X-Amz-Target")
  valid_604989 = validateParameter(valid_604989, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_604989 != nil:
    section.add "X-Amz-Target", valid_604989
  var valid_604990 = header.getOrDefault("X-Amz-Signature")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Signature", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-Content-Sha256", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Date")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Date", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-Credential")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-Credential", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Security-Token")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Security-Token", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-Algorithm")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-Algorithm", valid_604995
  var valid_604996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604996 = validateParameter(valid_604996, JString, required = false,
                                 default = nil)
  if valid_604996 != nil:
    section.add "X-Amz-SignedHeaders", valid_604996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604998: Call_DescribeTrainingJob_604986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_604998.validator(path, query, header, formData, body)
  let scheme = call_604998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604998.url(scheme.get, call_604998.host, call_604998.base,
                         call_604998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_604998, url, valid)

proc call*(call_604999: Call_DescribeTrainingJob_604986; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_605000 = newJObject()
  if body != nil:
    body_605000 = body
  result = call_604999.call(nil, nil, nil, nil, body_605000)

var describeTrainingJob* = Call_DescribeTrainingJob_604986(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_604987, base: "/",
    url: url_DescribeTrainingJob_604988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_605001 = ref object of OpenApiRestCall_603389
proc url_DescribeTransformJob_605003(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTransformJob_605002(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605004 = header.getOrDefault("X-Amz-Target")
  valid_605004 = validateParameter(valid_605004, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_605004 != nil:
    section.add "X-Amz-Target", valid_605004
  var valid_605005 = header.getOrDefault("X-Amz-Signature")
  valid_605005 = validateParameter(valid_605005, JString, required = false,
                                 default = nil)
  if valid_605005 != nil:
    section.add "X-Amz-Signature", valid_605005
  var valid_605006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605006 = validateParameter(valid_605006, JString, required = false,
                                 default = nil)
  if valid_605006 != nil:
    section.add "X-Amz-Content-Sha256", valid_605006
  var valid_605007 = header.getOrDefault("X-Amz-Date")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "X-Amz-Date", valid_605007
  var valid_605008 = header.getOrDefault("X-Amz-Credential")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "X-Amz-Credential", valid_605008
  var valid_605009 = header.getOrDefault("X-Amz-Security-Token")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-Security-Token", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-Algorithm")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-Algorithm", valid_605010
  var valid_605011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "X-Amz-SignedHeaders", valid_605011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605013: Call_DescribeTransformJob_605001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_605013.validator(path, query, header, formData, body)
  let scheme = call_605013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605013.url(scheme.get, call_605013.host, call_605013.base,
                         call_605013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605013, url, valid)

proc call*(call_605014: Call_DescribeTransformJob_605001; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_605015 = newJObject()
  if body != nil:
    body_605015 = body
  result = call_605014.call(nil, nil, nil, nil, body_605015)

var describeTransformJob* = Call_DescribeTransformJob_605001(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_605002, base: "/",
    url: url_DescribeTransformJob_605003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_605016 = ref object of OpenApiRestCall_603389
proc url_DescribeTrial_605018(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrial_605017(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605019 = header.getOrDefault("X-Amz-Target")
  valid_605019 = validateParameter(valid_605019, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_605019 != nil:
    section.add "X-Amz-Target", valid_605019
  var valid_605020 = header.getOrDefault("X-Amz-Signature")
  valid_605020 = validateParameter(valid_605020, JString, required = false,
                                 default = nil)
  if valid_605020 != nil:
    section.add "X-Amz-Signature", valid_605020
  var valid_605021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "X-Amz-Content-Sha256", valid_605021
  var valid_605022 = header.getOrDefault("X-Amz-Date")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "X-Amz-Date", valid_605022
  var valid_605023 = header.getOrDefault("X-Amz-Credential")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Credential", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-Security-Token")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-Security-Token", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-Algorithm")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Algorithm", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-SignedHeaders", valid_605026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605028: Call_DescribeTrial_605016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_605028.validator(path, query, header, formData, body)
  let scheme = call_605028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605028.url(scheme.get, call_605028.host, call_605028.base,
                         call_605028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605028, url, valid)

proc call*(call_605029: Call_DescribeTrial_605016; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_605030 = newJObject()
  if body != nil:
    body_605030 = body
  result = call_605029.call(nil, nil, nil, nil, body_605030)

var describeTrial* = Call_DescribeTrial_605016(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_605017, base: "/", url: url_DescribeTrial_605018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_605031 = ref object of OpenApiRestCall_603389
proc url_DescribeTrialComponent_605033(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrialComponent_605032(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605034 = header.getOrDefault("X-Amz-Target")
  valid_605034 = validateParameter(valid_605034, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_605034 != nil:
    section.add "X-Amz-Target", valid_605034
  var valid_605035 = header.getOrDefault("X-Amz-Signature")
  valid_605035 = validateParameter(valid_605035, JString, required = false,
                                 default = nil)
  if valid_605035 != nil:
    section.add "X-Amz-Signature", valid_605035
  var valid_605036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605036 = validateParameter(valid_605036, JString, required = false,
                                 default = nil)
  if valid_605036 != nil:
    section.add "X-Amz-Content-Sha256", valid_605036
  var valid_605037 = header.getOrDefault("X-Amz-Date")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "X-Amz-Date", valid_605037
  var valid_605038 = header.getOrDefault("X-Amz-Credential")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "X-Amz-Credential", valid_605038
  var valid_605039 = header.getOrDefault("X-Amz-Security-Token")
  valid_605039 = validateParameter(valid_605039, JString, required = false,
                                 default = nil)
  if valid_605039 != nil:
    section.add "X-Amz-Security-Token", valid_605039
  var valid_605040 = header.getOrDefault("X-Amz-Algorithm")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-Algorithm", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-SignedHeaders", valid_605041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605043: Call_DescribeTrialComponent_605031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_605043.validator(path, query, header, formData, body)
  let scheme = call_605043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605043.url(scheme.get, call_605043.host, call_605043.base,
                         call_605043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605043, url, valid)

proc call*(call_605044: Call_DescribeTrialComponent_605031; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_605045 = newJObject()
  if body != nil:
    body_605045 = body
  result = call_605044.call(nil, nil, nil, nil, body_605045)

var describeTrialComponent* = Call_DescribeTrialComponent_605031(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_605032, base: "/",
    url: url_DescribeTrialComponent_605033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_605046 = ref object of OpenApiRestCall_603389
proc url_DescribeUserProfile_605048(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUserProfile_605047(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605049 = header.getOrDefault("X-Amz-Target")
  valid_605049 = validateParameter(valid_605049, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_605049 != nil:
    section.add "X-Amz-Target", valid_605049
  var valid_605050 = header.getOrDefault("X-Amz-Signature")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "X-Amz-Signature", valid_605050
  var valid_605051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605051 = validateParameter(valid_605051, JString, required = false,
                                 default = nil)
  if valid_605051 != nil:
    section.add "X-Amz-Content-Sha256", valid_605051
  var valid_605052 = header.getOrDefault("X-Amz-Date")
  valid_605052 = validateParameter(valid_605052, JString, required = false,
                                 default = nil)
  if valid_605052 != nil:
    section.add "X-Amz-Date", valid_605052
  var valid_605053 = header.getOrDefault("X-Amz-Credential")
  valid_605053 = validateParameter(valid_605053, JString, required = false,
                                 default = nil)
  if valid_605053 != nil:
    section.add "X-Amz-Credential", valid_605053
  var valid_605054 = header.getOrDefault("X-Amz-Security-Token")
  valid_605054 = validateParameter(valid_605054, JString, required = false,
                                 default = nil)
  if valid_605054 != nil:
    section.add "X-Amz-Security-Token", valid_605054
  var valid_605055 = header.getOrDefault("X-Amz-Algorithm")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "X-Amz-Algorithm", valid_605055
  var valid_605056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "X-Amz-SignedHeaders", valid_605056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605058: Call_DescribeUserProfile_605046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_605058.validator(path, query, header, formData, body)
  let scheme = call_605058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605058.url(scheme.get, call_605058.host, call_605058.base,
                         call_605058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605058, url, valid)

proc call*(call_605059: Call_DescribeUserProfile_605046; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_605060 = newJObject()
  if body != nil:
    body_605060 = body
  result = call_605059.call(nil, nil, nil, nil, body_605060)

var describeUserProfile* = Call_DescribeUserProfile_605046(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_605047, base: "/",
    url: url_DescribeUserProfile_605048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_605061 = ref object of OpenApiRestCall_603389
proc url_DescribeWorkteam_605063(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeWorkteam_605062(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605064 = header.getOrDefault("X-Amz-Target")
  valid_605064 = validateParameter(valid_605064, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_605064 != nil:
    section.add "X-Amz-Target", valid_605064
  var valid_605065 = header.getOrDefault("X-Amz-Signature")
  valid_605065 = validateParameter(valid_605065, JString, required = false,
                                 default = nil)
  if valid_605065 != nil:
    section.add "X-Amz-Signature", valid_605065
  var valid_605066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605066 = validateParameter(valid_605066, JString, required = false,
                                 default = nil)
  if valid_605066 != nil:
    section.add "X-Amz-Content-Sha256", valid_605066
  var valid_605067 = header.getOrDefault("X-Amz-Date")
  valid_605067 = validateParameter(valid_605067, JString, required = false,
                                 default = nil)
  if valid_605067 != nil:
    section.add "X-Amz-Date", valid_605067
  var valid_605068 = header.getOrDefault("X-Amz-Credential")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "X-Amz-Credential", valid_605068
  var valid_605069 = header.getOrDefault("X-Amz-Security-Token")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "X-Amz-Security-Token", valid_605069
  var valid_605070 = header.getOrDefault("X-Amz-Algorithm")
  valid_605070 = validateParameter(valid_605070, JString, required = false,
                                 default = nil)
  if valid_605070 != nil:
    section.add "X-Amz-Algorithm", valid_605070
  var valid_605071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605071 = validateParameter(valid_605071, JString, required = false,
                                 default = nil)
  if valid_605071 != nil:
    section.add "X-Amz-SignedHeaders", valid_605071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605073: Call_DescribeWorkteam_605061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_605073.validator(path, query, header, formData, body)
  let scheme = call_605073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605073.url(scheme.get, call_605073.host, call_605073.base,
                         call_605073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605073, url, valid)

proc call*(call_605074: Call_DescribeWorkteam_605061; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_605075 = newJObject()
  if body != nil:
    body_605075 = body
  result = call_605074.call(nil, nil, nil, nil, body_605075)

var describeWorkteam* = Call_DescribeWorkteam_605061(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_605062, base: "/",
    url: url_DescribeWorkteam_605063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_605076 = ref object of OpenApiRestCall_603389
proc url_DisassociateTrialComponent_605078(protocol: Scheme; host: string;
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

proc validate_DisassociateTrialComponent_605077(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605079 = header.getOrDefault("X-Amz-Target")
  valid_605079 = validateParameter(valid_605079, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_605079 != nil:
    section.add "X-Amz-Target", valid_605079
  var valid_605080 = header.getOrDefault("X-Amz-Signature")
  valid_605080 = validateParameter(valid_605080, JString, required = false,
                                 default = nil)
  if valid_605080 != nil:
    section.add "X-Amz-Signature", valid_605080
  var valid_605081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "X-Amz-Content-Sha256", valid_605081
  var valid_605082 = header.getOrDefault("X-Amz-Date")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "X-Amz-Date", valid_605082
  var valid_605083 = header.getOrDefault("X-Amz-Credential")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "X-Amz-Credential", valid_605083
  var valid_605084 = header.getOrDefault("X-Amz-Security-Token")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Security-Token", valid_605084
  var valid_605085 = header.getOrDefault("X-Amz-Algorithm")
  valid_605085 = validateParameter(valid_605085, JString, required = false,
                                 default = nil)
  if valid_605085 != nil:
    section.add "X-Amz-Algorithm", valid_605085
  var valid_605086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "X-Amz-SignedHeaders", valid_605086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605088: Call_DisassociateTrialComponent_605076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ## 
  let valid = call_605088.validator(path, query, header, formData, body)
  let scheme = call_605088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605088.url(scheme.get, call_605088.host, call_605088.base,
                         call_605088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605088, url, valid)

proc call*(call_605089: Call_DisassociateTrialComponent_605076; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_605090 = newJObject()
  if body != nil:
    body_605090 = body
  result = call_605089.call(nil, nil, nil, nil, body_605090)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_605076(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_605077, base: "/",
    url: url_DisassociateTrialComponent_605078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_605091 = ref object of OpenApiRestCall_603389
proc url_GetSearchSuggestions_605093(protocol: Scheme; host: string; base: string;
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

proc validate_GetSearchSuggestions_605092(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605094 = header.getOrDefault("X-Amz-Target")
  valid_605094 = validateParameter(valid_605094, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_605094 != nil:
    section.add "X-Amz-Target", valid_605094
  var valid_605095 = header.getOrDefault("X-Amz-Signature")
  valid_605095 = validateParameter(valid_605095, JString, required = false,
                                 default = nil)
  if valid_605095 != nil:
    section.add "X-Amz-Signature", valid_605095
  var valid_605096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605096 = validateParameter(valid_605096, JString, required = false,
                                 default = nil)
  if valid_605096 != nil:
    section.add "X-Amz-Content-Sha256", valid_605096
  var valid_605097 = header.getOrDefault("X-Amz-Date")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "X-Amz-Date", valid_605097
  var valid_605098 = header.getOrDefault("X-Amz-Credential")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "X-Amz-Credential", valid_605098
  var valid_605099 = header.getOrDefault("X-Amz-Security-Token")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Security-Token", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Algorithm")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Algorithm", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-SignedHeaders", valid_605101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605103: Call_GetSearchSuggestions_605091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_605103.validator(path, query, header, formData, body)
  let scheme = call_605103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605103.url(scheme.get, call_605103.host, call_605103.base,
                         call_605103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605103, url, valid)

proc call*(call_605104: Call_GetSearchSuggestions_605091; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_605105 = newJObject()
  if body != nil:
    body_605105 = body
  result = call_605104.call(nil, nil, nil, nil, body_605105)

var getSearchSuggestions* = Call_GetSearchSuggestions_605091(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_605092, base: "/",
    url: url_GetSearchSuggestions_605093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_605106 = ref object of OpenApiRestCall_603389
proc url_ListAlgorithms_605108(protocol: Scheme; host: string; base: string;
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

proc validate_ListAlgorithms_605107(path: JsonNode; query: JsonNode;
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
  var valid_605109 = query.getOrDefault("MaxResults")
  valid_605109 = validateParameter(valid_605109, JString, required = false,
                                 default = nil)
  if valid_605109 != nil:
    section.add "MaxResults", valid_605109
  var valid_605110 = query.getOrDefault("NextToken")
  valid_605110 = validateParameter(valid_605110, JString, required = false,
                                 default = nil)
  if valid_605110 != nil:
    section.add "NextToken", valid_605110
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605111 = header.getOrDefault("X-Amz-Target")
  valid_605111 = validateParameter(valid_605111, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_605111 != nil:
    section.add "X-Amz-Target", valid_605111
  var valid_605112 = header.getOrDefault("X-Amz-Signature")
  valid_605112 = validateParameter(valid_605112, JString, required = false,
                                 default = nil)
  if valid_605112 != nil:
    section.add "X-Amz-Signature", valid_605112
  var valid_605113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "X-Amz-Content-Sha256", valid_605113
  var valid_605114 = header.getOrDefault("X-Amz-Date")
  valid_605114 = validateParameter(valid_605114, JString, required = false,
                                 default = nil)
  if valid_605114 != nil:
    section.add "X-Amz-Date", valid_605114
  var valid_605115 = header.getOrDefault("X-Amz-Credential")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Credential", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-Security-Token")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Security-Token", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Algorithm")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Algorithm", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-SignedHeaders", valid_605118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605120: Call_ListAlgorithms_605106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_605120.validator(path, query, header, formData, body)
  let scheme = call_605120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605120.url(scheme.get, call_605120.host, call_605120.base,
                         call_605120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605120, url, valid)

proc call*(call_605121: Call_ListAlgorithms_605106; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605122 = newJObject()
  var body_605123 = newJObject()
  add(query_605122, "MaxResults", newJString(MaxResults))
  add(query_605122, "NextToken", newJString(NextToken))
  if body != nil:
    body_605123 = body
  result = call_605121.call(nil, query_605122, nil, nil, body_605123)

var listAlgorithms* = Call_ListAlgorithms_605106(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_605107, base: "/", url: url_ListAlgorithms_605108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_605125 = ref object of OpenApiRestCall_603389
proc url_ListApps_605127(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListApps_605126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605128 = query.getOrDefault("MaxResults")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "MaxResults", valid_605128
  var valid_605129 = query.getOrDefault("NextToken")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "NextToken", valid_605129
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605130 = header.getOrDefault("X-Amz-Target")
  valid_605130 = validateParameter(valid_605130, JString, required = true,
                                 default = newJString("SageMaker.ListApps"))
  if valid_605130 != nil:
    section.add "X-Amz-Target", valid_605130
  var valid_605131 = header.getOrDefault("X-Amz-Signature")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Signature", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Content-Sha256", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-Date")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-Date", valid_605133
  var valid_605134 = header.getOrDefault("X-Amz-Credential")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "X-Amz-Credential", valid_605134
  var valid_605135 = header.getOrDefault("X-Amz-Security-Token")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "X-Amz-Security-Token", valid_605135
  var valid_605136 = header.getOrDefault("X-Amz-Algorithm")
  valid_605136 = validateParameter(valid_605136, JString, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "X-Amz-Algorithm", valid_605136
  var valid_605137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605137 = validateParameter(valid_605137, JString, required = false,
                                 default = nil)
  if valid_605137 != nil:
    section.add "X-Amz-SignedHeaders", valid_605137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605139: Call_ListApps_605125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists apps.
  ## 
  let valid = call_605139.validator(path, query, header, formData, body)
  let scheme = call_605139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605139.url(scheme.get, call_605139.host, call_605139.base,
                         call_605139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605139, url, valid)

proc call*(call_605140: Call_ListApps_605125; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605141 = newJObject()
  var body_605142 = newJObject()
  add(query_605141, "MaxResults", newJString(MaxResults))
  add(query_605141, "NextToken", newJString(NextToken))
  if body != nil:
    body_605142 = body
  result = call_605140.call(nil, query_605141, nil, nil, body_605142)

var listApps* = Call_ListApps_605125(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListApps",
                                  validator: validate_ListApps_605126, base: "/",
                                  url: url_ListApps_605127,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_605143 = ref object of OpenApiRestCall_603389
proc url_ListAutoMLJobs_605145(protocol: Scheme; host: string; base: string;
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

proc validate_ListAutoMLJobs_605144(path: JsonNode; query: JsonNode;
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
  var valid_605146 = query.getOrDefault("MaxResults")
  valid_605146 = validateParameter(valid_605146, JString, required = false,
                                 default = nil)
  if valid_605146 != nil:
    section.add "MaxResults", valid_605146
  var valid_605147 = query.getOrDefault("NextToken")
  valid_605147 = validateParameter(valid_605147, JString, required = false,
                                 default = nil)
  if valid_605147 != nil:
    section.add "NextToken", valid_605147
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605148 = header.getOrDefault("X-Amz-Target")
  valid_605148 = validateParameter(valid_605148, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_605148 != nil:
    section.add "X-Amz-Target", valid_605148
  var valid_605149 = header.getOrDefault("X-Amz-Signature")
  valid_605149 = validateParameter(valid_605149, JString, required = false,
                                 default = nil)
  if valid_605149 != nil:
    section.add "X-Amz-Signature", valid_605149
  var valid_605150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605150 = validateParameter(valid_605150, JString, required = false,
                                 default = nil)
  if valid_605150 != nil:
    section.add "X-Amz-Content-Sha256", valid_605150
  var valid_605151 = header.getOrDefault("X-Amz-Date")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "X-Amz-Date", valid_605151
  var valid_605152 = header.getOrDefault("X-Amz-Credential")
  valid_605152 = validateParameter(valid_605152, JString, required = false,
                                 default = nil)
  if valid_605152 != nil:
    section.add "X-Amz-Credential", valid_605152
  var valid_605153 = header.getOrDefault("X-Amz-Security-Token")
  valid_605153 = validateParameter(valid_605153, JString, required = false,
                                 default = nil)
  if valid_605153 != nil:
    section.add "X-Amz-Security-Token", valid_605153
  var valid_605154 = header.getOrDefault("X-Amz-Algorithm")
  valid_605154 = validateParameter(valid_605154, JString, required = false,
                                 default = nil)
  if valid_605154 != nil:
    section.add "X-Amz-Algorithm", valid_605154
  var valid_605155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605155 = validateParameter(valid_605155, JString, required = false,
                                 default = nil)
  if valid_605155 != nil:
    section.add "X-Amz-SignedHeaders", valid_605155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605157: Call_ListAutoMLJobs_605143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_605157.validator(path, query, header, formData, body)
  let scheme = call_605157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605157.url(scheme.get, call_605157.host, call_605157.base,
                         call_605157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605157, url, valid)

proc call*(call_605158: Call_ListAutoMLJobs_605143; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605159 = newJObject()
  var body_605160 = newJObject()
  add(query_605159, "MaxResults", newJString(MaxResults))
  add(query_605159, "NextToken", newJString(NextToken))
  if body != nil:
    body_605160 = body
  result = call_605158.call(nil, query_605159, nil, nil, body_605160)

var listAutoMLJobs* = Call_ListAutoMLJobs_605143(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_605144, base: "/", url: url_ListAutoMLJobs_605145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_605161 = ref object of OpenApiRestCall_603389
proc url_ListCandidatesForAutoMLJob_605163(protocol: Scheme; host: string;
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

proc validate_ListCandidatesForAutoMLJob_605162(path: JsonNode; query: JsonNode;
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
  var valid_605164 = query.getOrDefault("MaxResults")
  valid_605164 = validateParameter(valid_605164, JString, required = false,
                                 default = nil)
  if valid_605164 != nil:
    section.add "MaxResults", valid_605164
  var valid_605165 = query.getOrDefault("NextToken")
  valid_605165 = validateParameter(valid_605165, JString, required = false,
                                 default = nil)
  if valid_605165 != nil:
    section.add "NextToken", valid_605165
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605166 = header.getOrDefault("X-Amz-Target")
  valid_605166 = validateParameter(valid_605166, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_605166 != nil:
    section.add "X-Amz-Target", valid_605166
  var valid_605167 = header.getOrDefault("X-Amz-Signature")
  valid_605167 = validateParameter(valid_605167, JString, required = false,
                                 default = nil)
  if valid_605167 != nil:
    section.add "X-Amz-Signature", valid_605167
  var valid_605168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605168 = validateParameter(valid_605168, JString, required = false,
                                 default = nil)
  if valid_605168 != nil:
    section.add "X-Amz-Content-Sha256", valid_605168
  var valid_605169 = header.getOrDefault("X-Amz-Date")
  valid_605169 = validateParameter(valid_605169, JString, required = false,
                                 default = nil)
  if valid_605169 != nil:
    section.add "X-Amz-Date", valid_605169
  var valid_605170 = header.getOrDefault("X-Amz-Credential")
  valid_605170 = validateParameter(valid_605170, JString, required = false,
                                 default = nil)
  if valid_605170 != nil:
    section.add "X-Amz-Credential", valid_605170
  var valid_605171 = header.getOrDefault("X-Amz-Security-Token")
  valid_605171 = validateParameter(valid_605171, JString, required = false,
                                 default = nil)
  if valid_605171 != nil:
    section.add "X-Amz-Security-Token", valid_605171
  var valid_605172 = header.getOrDefault("X-Amz-Algorithm")
  valid_605172 = validateParameter(valid_605172, JString, required = false,
                                 default = nil)
  if valid_605172 != nil:
    section.add "X-Amz-Algorithm", valid_605172
  var valid_605173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605173 = validateParameter(valid_605173, JString, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "X-Amz-SignedHeaders", valid_605173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605175: Call_ListCandidatesForAutoMLJob_605161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_605175.validator(path, query, header, formData, body)
  let scheme = call_605175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605175.url(scheme.get, call_605175.host, call_605175.base,
                         call_605175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605175, url, valid)

proc call*(call_605176: Call_ListCandidatesForAutoMLJob_605161; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605177 = newJObject()
  var body_605178 = newJObject()
  add(query_605177, "MaxResults", newJString(MaxResults))
  add(query_605177, "NextToken", newJString(NextToken))
  if body != nil:
    body_605178 = body
  result = call_605176.call(nil, query_605177, nil, nil, body_605178)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_605161(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_605162, base: "/",
    url: url_ListCandidatesForAutoMLJob_605163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_605179 = ref object of OpenApiRestCall_603389
proc url_ListCodeRepositories_605181(protocol: Scheme; host: string; base: string;
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

proc validate_ListCodeRepositories_605180(path: JsonNode; query: JsonNode;
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
  var valid_605182 = query.getOrDefault("MaxResults")
  valid_605182 = validateParameter(valid_605182, JString, required = false,
                                 default = nil)
  if valid_605182 != nil:
    section.add "MaxResults", valid_605182
  var valid_605183 = query.getOrDefault("NextToken")
  valid_605183 = validateParameter(valid_605183, JString, required = false,
                                 default = nil)
  if valid_605183 != nil:
    section.add "NextToken", valid_605183
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605184 = header.getOrDefault("X-Amz-Target")
  valid_605184 = validateParameter(valid_605184, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_605184 != nil:
    section.add "X-Amz-Target", valid_605184
  var valid_605185 = header.getOrDefault("X-Amz-Signature")
  valid_605185 = validateParameter(valid_605185, JString, required = false,
                                 default = nil)
  if valid_605185 != nil:
    section.add "X-Amz-Signature", valid_605185
  var valid_605186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605186 = validateParameter(valid_605186, JString, required = false,
                                 default = nil)
  if valid_605186 != nil:
    section.add "X-Amz-Content-Sha256", valid_605186
  var valid_605187 = header.getOrDefault("X-Amz-Date")
  valid_605187 = validateParameter(valid_605187, JString, required = false,
                                 default = nil)
  if valid_605187 != nil:
    section.add "X-Amz-Date", valid_605187
  var valid_605188 = header.getOrDefault("X-Amz-Credential")
  valid_605188 = validateParameter(valid_605188, JString, required = false,
                                 default = nil)
  if valid_605188 != nil:
    section.add "X-Amz-Credential", valid_605188
  var valid_605189 = header.getOrDefault("X-Amz-Security-Token")
  valid_605189 = validateParameter(valid_605189, JString, required = false,
                                 default = nil)
  if valid_605189 != nil:
    section.add "X-Amz-Security-Token", valid_605189
  var valid_605190 = header.getOrDefault("X-Amz-Algorithm")
  valid_605190 = validateParameter(valid_605190, JString, required = false,
                                 default = nil)
  if valid_605190 != nil:
    section.add "X-Amz-Algorithm", valid_605190
  var valid_605191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605191 = validateParameter(valid_605191, JString, required = false,
                                 default = nil)
  if valid_605191 != nil:
    section.add "X-Amz-SignedHeaders", valid_605191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605193: Call_ListCodeRepositories_605179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_605193.validator(path, query, header, formData, body)
  let scheme = call_605193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605193.url(scheme.get, call_605193.host, call_605193.base,
                         call_605193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605193, url, valid)

proc call*(call_605194: Call_ListCodeRepositories_605179; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605195 = newJObject()
  var body_605196 = newJObject()
  add(query_605195, "MaxResults", newJString(MaxResults))
  add(query_605195, "NextToken", newJString(NextToken))
  if body != nil:
    body_605196 = body
  result = call_605194.call(nil, query_605195, nil, nil, body_605196)

var listCodeRepositories* = Call_ListCodeRepositories_605179(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_605180, base: "/",
    url: url_ListCodeRepositories_605181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_605197 = ref object of OpenApiRestCall_603389
proc url_ListCompilationJobs_605199(protocol: Scheme; host: string; base: string;
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

proc validate_ListCompilationJobs_605198(path: JsonNode; query: JsonNode;
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
  var valid_605200 = query.getOrDefault("MaxResults")
  valid_605200 = validateParameter(valid_605200, JString, required = false,
                                 default = nil)
  if valid_605200 != nil:
    section.add "MaxResults", valid_605200
  var valid_605201 = query.getOrDefault("NextToken")
  valid_605201 = validateParameter(valid_605201, JString, required = false,
                                 default = nil)
  if valid_605201 != nil:
    section.add "NextToken", valid_605201
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605202 = header.getOrDefault("X-Amz-Target")
  valid_605202 = validateParameter(valid_605202, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_605202 != nil:
    section.add "X-Amz-Target", valid_605202
  var valid_605203 = header.getOrDefault("X-Amz-Signature")
  valid_605203 = validateParameter(valid_605203, JString, required = false,
                                 default = nil)
  if valid_605203 != nil:
    section.add "X-Amz-Signature", valid_605203
  var valid_605204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "X-Amz-Content-Sha256", valid_605204
  var valid_605205 = header.getOrDefault("X-Amz-Date")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "X-Amz-Date", valid_605205
  var valid_605206 = header.getOrDefault("X-Amz-Credential")
  valid_605206 = validateParameter(valid_605206, JString, required = false,
                                 default = nil)
  if valid_605206 != nil:
    section.add "X-Amz-Credential", valid_605206
  var valid_605207 = header.getOrDefault("X-Amz-Security-Token")
  valid_605207 = validateParameter(valid_605207, JString, required = false,
                                 default = nil)
  if valid_605207 != nil:
    section.add "X-Amz-Security-Token", valid_605207
  var valid_605208 = header.getOrDefault("X-Amz-Algorithm")
  valid_605208 = validateParameter(valid_605208, JString, required = false,
                                 default = nil)
  if valid_605208 != nil:
    section.add "X-Amz-Algorithm", valid_605208
  var valid_605209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605209 = validateParameter(valid_605209, JString, required = false,
                                 default = nil)
  if valid_605209 != nil:
    section.add "X-Amz-SignedHeaders", valid_605209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605211: Call_ListCompilationJobs_605197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_605211.validator(path, query, header, formData, body)
  let scheme = call_605211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605211.url(scheme.get, call_605211.host, call_605211.base,
                         call_605211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605211, url, valid)

proc call*(call_605212: Call_ListCompilationJobs_605197; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605213 = newJObject()
  var body_605214 = newJObject()
  add(query_605213, "MaxResults", newJString(MaxResults))
  add(query_605213, "NextToken", newJString(NextToken))
  if body != nil:
    body_605214 = body
  result = call_605212.call(nil, query_605213, nil, nil, body_605214)

var listCompilationJobs* = Call_ListCompilationJobs_605197(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_605198, base: "/",
    url: url_ListCompilationJobs_605199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_605215 = ref object of OpenApiRestCall_603389
proc url_ListDomains_605217(protocol: Scheme; host: string; base: string;
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

proc validate_ListDomains_605216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605218 = query.getOrDefault("MaxResults")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "MaxResults", valid_605218
  var valid_605219 = query.getOrDefault("NextToken")
  valid_605219 = validateParameter(valid_605219, JString, required = false,
                                 default = nil)
  if valid_605219 != nil:
    section.add "NextToken", valid_605219
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605220 = header.getOrDefault("X-Amz-Target")
  valid_605220 = validateParameter(valid_605220, JString, required = true,
                                 default = newJString("SageMaker.ListDomains"))
  if valid_605220 != nil:
    section.add "X-Amz-Target", valid_605220
  var valid_605221 = header.getOrDefault("X-Amz-Signature")
  valid_605221 = validateParameter(valid_605221, JString, required = false,
                                 default = nil)
  if valid_605221 != nil:
    section.add "X-Amz-Signature", valid_605221
  var valid_605222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605222 = validateParameter(valid_605222, JString, required = false,
                                 default = nil)
  if valid_605222 != nil:
    section.add "X-Amz-Content-Sha256", valid_605222
  var valid_605223 = header.getOrDefault("X-Amz-Date")
  valid_605223 = validateParameter(valid_605223, JString, required = false,
                                 default = nil)
  if valid_605223 != nil:
    section.add "X-Amz-Date", valid_605223
  var valid_605224 = header.getOrDefault("X-Amz-Credential")
  valid_605224 = validateParameter(valid_605224, JString, required = false,
                                 default = nil)
  if valid_605224 != nil:
    section.add "X-Amz-Credential", valid_605224
  var valid_605225 = header.getOrDefault("X-Amz-Security-Token")
  valid_605225 = validateParameter(valid_605225, JString, required = false,
                                 default = nil)
  if valid_605225 != nil:
    section.add "X-Amz-Security-Token", valid_605225
  var valid_605226 = header.getOrDefault("X-Amz-Algorithm")
  valid_605226 = validateParameter(valid_605226, JString, required = false,
                                 default = nil)
  if valid_605226 != nil:
    section.add "X-Amz-Algorithm", valid_605226
  var valid_605227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605227 = validateParameter(valid_605227, JString, required = false,
                                 default = nil)
  if valid_605227 != nil:
    section.add "X-Amz-SignedHeaders", valid_605227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605229: Call_ListDomains_605215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_605229.validator(path, query, header, formData, body)
  let scheme = call_605229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605229.url(scheme.get, call_605229.host, call_605229.base,
                         call_605229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605229, url, valid)

proc call*(call_605230: Call_ListDomains_605215; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605231 = newJObject()
  var body_605232 = newJObject()
  add(query_605231, "MaxResults", newJString(MaxResults))
  add(query_605231, "NextToken", newJString(NextToken))
  if body != nil:
    body_605232 = body
  result = call_605230.call(nil, query_605231, nil, nil, body_605232)

var listDomains* = Call_ListDomains_605215(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListDomains",
                                        validator: validate_ListDomains_605216,
                                        base: "/", url: url_ListDomains_605217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_605233 = ref object of OpenApiRestCall_603389
proc url_ListEndpointConfigs_605235(protocol: Scheme; host: string; base: string;
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

proc validate_ListEndpointConfigs_605234(path: JsonNode; query: JsonNode;
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
  var valid_605236 = query.getOrDefault("MaxResults")
  valid_605236 = validateParameter(valid_605236, JString, required = false,
                                 default = nil)
  if valid_605236 != nil:
    section.add "MaxResults", valid_605236
  var valid_605237 = query.getOrDefault("NextToken")
  valid_605237 = validateParameter(valid_605237, JString, required = false,
                                 default = nil)
  if valid_605237 != nil:
    section.add "NextToken", valid_605237
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605238 = header.getOrDefault("X-Amz-Target")
  valid_605238 = validateParameter(valid_605238, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_605238 != nil:
    section.add "X-Amz-Target", valid_605238
  var valid_605239 = header.getOrDefault("X-Amz-Signature")
  valid_605239 = validateParameter(valid_605239, JString, required = false,
                                 default = nil)
  if valid_605239 != nil:
    section.add "X-Amz-Signature", valid_605239
  var valid_605240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605240 = validateParameter(valid_605240, JString, required = false,
                                 default = nil)
  if valid_605240 != nil:
    section.add "X-Amz-Content-Sha256", valid_605240
  var valid_605241 = header.getOrDefault("X-Amz-Date")
  valid_605241 = validateParameter(valid_605241, JString, required = false,
                                 default = nil)
  if valid_605241 != nil:
    section.add "X-Amz-Date", valid_605241
  var valid_605242 = header.getOrDefault("X-Amz-Credential")
  valid_605242 = validateParameter(valid_605242, JString, required = false,
                                 default = nil)
  if valid_605242 != nil:
    section.add "X-Amz-Credential", valid_605242
  var valid_605243 = header.getOrDefault("X-Amz-Security-Token")
  valid_605243 = validateParameter(valid_605243, JString, required = false,
                                 default = nil)
  if valid_605243 != nil:
    section.add "X-Amz-Security-Token", valid_605243
  var valid_605244 = header.getOrDefault("X-Amz-Algorithm")
  valid_605244 = validateParameter(valid_605244, JString, required = false,
                                 default = nil)
  if valid_605244 != nil:
    section.add "X-Amz-Algorithm", valid_605244
  var valid_605245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605245 = validateParameter(valid_605245, JString, required = false,
                                 default = nil)
  if valid_605245 != nil:
    section.add "X-Amz-SignedHeaders", valid_605245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605247: Call_ListEndpointConfigs_605233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_605247.validator(path, query, header, formData, body)
  let scheme = call_605247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605247.url(scheme.get, call_605247.host, call_605247.base,
                         call_605247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605247, url, valid)

proc call*(call_605248: Call_ListEndpointConfigs_605233; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605249 = newJObject()
  var body_605250 = newJObject()
  add(query_605249, "MaxResults", newJString(MaxResults))
  add(query_605249, "NextToken", newJString(NextToken))
  if body != nil:
    body_605250 = body
  result = call_605248.call(nil, query_605249, nil, nil, body_605250)

var listEndpointConfigs* = Call_ListEndpointConfigs_605233(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_605234, base: "/",
    url: url_ListEndpointConfigs_605235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_605251 = ref object of OpenApiRestCall_603389
proc url_ListEndpoints_605253(protocol: Scheme; host: string; base: string;
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

proc validate_ListEndpoints_605252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605254 = query.getOrDefault("MaxResults")
  valid_605254 = validateParameter(valid_605254, JString, required = false,
                                 default = nil)
  if valid_605254 != nil:
    section.add "MaxResults", valid_605254
  var valid_605255 = query.getOrDefault("NextToken")
  valid_605255 = validateParameter(valid_605255, JString, required = false,
                                 default = nil)
  if valid_605255 != nil:
    section.add "NextToken", valid_605255
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605256 = header.getOrDefault("X-Amz-Target")
  valid_605256 = validateParameter(valid_605256, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_605256 != nil:
    section.add "X-Amz-Target", valid_605256
  var valid_605257 = header.getOrDefault("X-Amz-Signature")
  valid_605257 = validateParameter(valid_605257, JString, required = false,
                                 default = nil)
  if valid_605257 != nil:
    section.add "X-Amz-Signature", valid_605257
  var valid_605258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605258 = validateParameter(valid_605258, JString, required = false,
                                 default = nil)
  if valid_605258 != nil:
    section.add "X-Amz-Content-Sha256", valid_605258
  var valid_605259 = header.getOrDefault("X-Amz-Date")
  valid_605259 = validateParameter(valid_605259, JString, required = false,
                                 default = nil)
  if valid_605259 != nil:
    section.add "X-Amz-Date", valid_605259
  var valid_605260 = header.getOrDefault("X-Amz-Credential")
  valid_605260 = validateParameter(valid_605260, JString, required = false,
                                 default = nil)
  if valid_605260 != nil:
    section.add "X-Amz-Credential", valid_605260
  var valid_605261 = header.getOrDefault("X-Amz-Security-Token")
  valid_605261 = validateParameter(valid_605261, JString, required = false,
                                 default = nil)
  if valid_605261 != nil:
    section.add "X-Amz-Security-Token", valid_605261
  var valid_605262 = header.getOrDefault("X-Amz-Algorithm")
  valid_605262 = validateParameter(valid_605262, JString, required = false,
                                 default = nil)
  if valid_605262 != nil:
    section.add "X-Amz-Algorithm", valid_605262
  var valid_605263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "X-Amz-SignedHeaders", valid_605263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605265: Call_ListEndpoints_605251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_605265.validator(path, query, header, formData, body)
  let scheme = call_605265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605265.url(scheme.get, call_605265.host, call_605265.base,
                         call_605265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605265, url, valid)

proc call*(call_605266: Call_ListEndpoints_605251; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605267 = newJObject()
  var body_605268 = newJObject()
  add(query_605267, "MaxResults", newJString(MaxResults))
  add(query_605267, "NextToken", newJString(NextToken))
  if body != nil:
    body_605268 = body
  result = call_605266.call(nil, query_605267, nil, nil, body_605268)

var listEndpoints* = Call_ListEndpoints_605251(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_605252, base: "/", url: url_ListEndpoints_605253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_605269 = ref object of OpenApiRestCall_603389
proc url_ListExperiments_605271(protocol: Scheme; host: string; base: string;
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

proc validate_ListExperiments_605270(path: JsonNode; query: JsonNode;
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
  var valid_605272 = query.getOrDefault("MaxResults")
  valid_605272 = validateParameter(valid_605272, JString, required = false,
                                 default = nil)
  if valid_605272 != nil:
    section.add "MaxResults", valid_605272
  var valid_605273 = query.getOrDefault("NextToken")
  valid_605273 = validateParameter(valid_605273, JString, required = false,
                                 default = nil)
  if valid_605273 != nil:
    section.add "NextToken", valid_605273
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605274 = header.getOrDefault("X-Amz-Target")
  valid_605274 = validateParameter(valid_605274, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_605274 != nil:
    section.add "X-Amz-Target", valid_605274
  var valid_605275 = header.getOrDefault("X-Amz-Signature")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "X-Amz-Signature", valid_605275
  var valid_605276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605276 = validateParameter(valid_605276, JString, required = false,
                                 default = nil)
  if valid_605276 != nil:
    section.add "X-Amz-Content-Sha256", valid_605276
  var valid_605277 = header.getOrDefault("X-Amz-Date")
  valid_605277 = validateParameter(valid_605277, JString, required = false,
                                 default = nil)
  if valid_605277 != nil:
    section.add "X-Amz-Date", valid_605277
  var valid_605278 = header.getOrDefault("X-Amz-Credential")
  valid_605278 = validateParameter(valid_605278, JString, required = false,
                                 default = nil)
  if valid_605278 != nil:
    section.add "X-Amz-Credential", valid_605278
  var valid_605279 = header.getOrDefault("X-Amz-Security-Token")
  valid_605279 = validateParameter(valid_605279, JString, required = false,
                                 default = nil)
  if valid_605279 != nil:
    section.add "X-Amz-Security-Token", valid_605279
  var valid_605280 = header.getOrDefault("X-Amz-Algorithm")
  valid_605280 = validateParameter(valid_605280, JString, required = false,
                                 default = nil)
  if valid_605280 != nil:
    section.add "X-Amz-Algorithm", valid_605280
  var valid_605281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605281 = validateParameter(valid_605281, JString, required = false,
                                 default = nil)
  if valid_605281 != nil:
    section.add "X-Amz-SignedHeaders", valid_605281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605283: Call_ListExperiments_605269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_605283.validator(path, query, header, formData, body)
  let scheme = call_605283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605283.url(scheme.get, call_605283.host, call_605283.base,
                         call_605283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605283, url, valid)

proc call*(call_605284: Call_ListExperiments_605269; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605285 = newJObject()
  var body_605286 = newJObject()
  add(query_605285, "MaxResults", newJString(MaxResults))
  add(query_605285, "NextToken", newJString(NextToken))
  if body != nil:
    body_605286 = body
  result = call_605284.call(nil, query_605285, nil, nil, body_605286)

var listExperiments* = Call_ListExperiments_605269(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_605270, base: "/", url: url_ListExperiments_605271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_605287 = ref object of OpenApiRestCall_603389
proc url_ListFlowDefinitions_605289(protocol: Scheme; host: string; base: string;
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

proc validate_ListFlowDefinitions_605288(path: JsonNode; query: JsonNode;
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
  var valid_605290 = query.getOrDefault("MaxResults")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "MaxResults", valid_605290
  var valid_605291 = query.getOrDefault("NextToken")
  valid_605291 = validateParameter(valid_605291, JString, required = false,
                                 default = nil)
  if valid_605291 != nil:
    section.add "NextToken", valid_605291
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605292 = header.getOrDefault("X-Amz-Target")
  valid_605292 = validateParameter(valid_605292, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_605292 != nil:
    section.add "X-Amz-Target", valid_605292
  var valid_605293 = header.getOrDefault("X-Amz-Signature")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "X-Amz-Signature", valid_605293
  var valid_605294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-Content-Sha256", valid_605294
  var valid_605295 = header.getOrDefault("X-Amz-Date")
  valid_605295 = validateParameter(valid_605295, JString, required = false,
                                 default = nil)
  if valid_605295 != nil:
    section.add "X-Amz-Date", valid_605295
  var valid_605296 = header.getOrDefault("X-Amz-Credential")
  valid_605296 = validateParameter(valid_605296, JString, required = false,
                                 default = nil)
  if valid_605296 != nil:
    section.add "X-Amz-Credential", valid_605296
  var valid_605297 = header.getOrDefault("X-Amz-Security-Token")
  valid_605297 = validateParameter(valid_605297, JString, required = false,
                                 default = nil)
  if valid_605297 != nil:
    section.add "X-Amz-Security-Token", valid_605297
  var valid_605298 = header.getOrDefault("X-Amz-Algorithm")
  valid_605298 = validateParameter(valid_605298, JString, required = false,
                                 default = nil)
  if valid_605298 != nil:
    section.add "X-Amz-Algorithm", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-SignedHeaders", valid_605299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605301: Call_ListFlowDefinitions_605287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_605301.validator(path, query, header, formData, body)
  let scheme = call_605301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605301.url(scheme.get, call_605301.host, call_605301.base,
                         call_605301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605301, url, valid)

proc call*(call_605302: Call_ListFlowDefinitions_605287; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605303 = newJObject()
  var body_605304 = newJObject()
  add(query_605303, "MaxResults", newJString(MaxResults))
  add(query_605303, "NextToken", newJString(NextToken))
  if body != nil:
    body_605304 = body
  result = call_605302.call(nil, query_605303, nil, nil, body_605304)

var listFlowDefinitions* = Call_ListFlowDefinitions_605287(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_605288, base: "/",
    url: url_ListFlowDefinitions_605289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_605305 = ref object of OpenApiRestCall_603389
proc url_ListHumanTaskUis_605307(protocol: Scheme; host: string; base: string;
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

proc validate_ListHumanTaskUis_605306(path: JsonNode; query: JsonNode;
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
  var valid_605308 = query.getOrDefault("MaxResults")
  valid_605308 = validateParameter(valid_605308, JString, required = false,
                                 default = nil)
  if valid_605308 != nil:
    section.add "MaxResults", valid_605308
  var valid_605309 = query.getOrDefault("NextToken")
  valid_605309 = validateParameter(valid_605309, JString, required = false,
                                 default = nil)
  if valid_605309 != nil:
    section.add "NextToken", valid_605309
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605310 = header.getOrDefault("X-Amz-Target")
  valid_605310 = validateParameter(valid_605310, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_605310 != nil:
    section.add "X-Amz-Target", valid_605310
  var valid_605311 = header.getOrDefault("X-Amz-Signature")
  valid_605311 = validateParameter(valid_605311, JString, required = false,
                                 default = nil)
  if valid_605311 != nil:
    section.add "X-Amz-Signature", valid_605311
  var valid_605312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605312 = validateParameter(valid_605312, JString, required = false,
                                 default = nil)
  if valid_605312 != nil:
    section.add "X-Amz-Content-Sha256", valid_605312
  var valid_605313 = header.getOrDefault("X-Amz-Date")
  valid_605313 = validateParameter(valid_605313, JString, required = false,
                                 default = nil)
  if valid_605313 != nil:
    section.add "X-Amz-Date", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-Credential")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-Credential", valid_605314
  var valid_605315 = header.getOrDefault("X-Amz-Security-Token")
  valid_605315 = validateParameter(valid_605315, JString, required = false,
                                 default = nil)
  if valid_605315 != nil:
    section.add "X-Amz-Security-Token", valid_605315
  var valid_605316 = header.getOrDefault("X-Amz-Algorithm")
  valid_605316 = validateParameter(valid_605316, JString, required = false,
                                 default = nil)
  if valid_605316 != nil:
    section.add "X-Amz-Algorithm", valid_605316
  var valid_605317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605317 = validateParameter(valid_605317, JString, required = false,
                                 default = nil)
  if valid_605317 != nil:
    section.add "X-Amz-SignedHeaders", valid_605317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605319: Call_ListHumanTaskUis_605305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_605319.validator(path, query, header, formData, body)
  let scheme = call_605319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605319.url(scheme.get, call_605319.host, call_605319.base,
                         call_605319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605319, url, valid)

proc call*(call_605320: Call_ListHumanTaskUis_605305; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605321 = newJObject()
  var body_605322 = newJObject()
  add(query_605321, "MaxResults", newJString(MaxResults))
  add(query_605321, "NextToken", newJString(NextToken))
  if body != nil:
    body_605322 = body
  result = call_605320.call(nil, query_605321, nil, nil, body_605322)

var listHumanTaskUis* = Call_ListHumanTaskUis_605305(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_605306, base: "/",
    url: url_ListHumanTaskUis_605307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_605323 = ref object of OpenApiRestCall_603389
proc url_ListHyperParameterTuningJobs_605325(protocol: Scheme; host: string;
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

proc validate_ListHyperParameterTuningJobs_605324(path: JsonNode; query: JsonNode;
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
  var valid_605326 = query.getOrDefault("MaxResults")
  valid_605326 = validateParameter(valid_605326, JString, required = false,
                                 default = nil)
  if valid_605326 != nil:
    section.add "MaxResults", valid_605326
  var valid_605327 = query.getOrDefault("NextToken")
  valid_605327 = validateParameter(valid_605327, JString, required = false,
                                 default = nil)
  if valid_605327 != nil:
    section.add "NextToken", valid_605327
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605328 = header.getOrDefault("X-Amz-Target")
  valid_605328 = validateParameter(valid_605328, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_605328 != nil:
    section.add "X-Amz-Target", valid_605328
  var valid_605329 = header.getOrDefault("X-Amz-Signature")
  valid_605329 = validateParameter(valid_605329, JString, required = false,
                                 default = nil)
  if valid_605329 != nil:
    section.add "X-Amz-Signature", valid_605329
  var valid_605330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605330 = validateParameter(valid_605330, JString, required = false,
                                 default = nil)
  if valid_605330 != nil:
    section.add "X-Amz-Content-Sha256", valid_605330
  var valid_605331 = header.getOrDefault("X-Amz-Date")
  valid_605331 = validateParameter(valid_605331, JString, required = false,
                                 default = nil)
  if valid_605331 != nil:
    section.add "X-Amz-Date", valid_605331
  var valid_605332 = header.getOrDefault("X-Amz-Credential")
  valid_605332 = validateParameter(valid_605332, JString, required = false,
                                 default = nil)
  if valid_605332 != nil:
    section.add "X-Amz-Credential", valid_605332
  var valid_605333 = header.getOrDefault("X-Amz-Security-Token")
  valid_605333 = validateParameter(valid_605333, JString, required = false,
                                 default = nil)
  if valid_605333 != nil:
    section.add "X-Amz-Security-Token", valid_605333
  var valid_605334 = header.getOrDefault("X-Amz-Algorithm")
  valid_605334 = validateParameter(valid_605334, JString, required = false,
                                 default = nil)
  if valid_605334 != nil:
    section.add "X-Amz-Algorithm", valid_605334
  var valid_605335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605335 = validateParameter(valid_605335, JString, required = false,
                                 default = nil)
  if valid_605335 != nil:
    section.add "X-Amz-SignedHeaders", valid_605335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605337: Call_ListHyperParameterTuningJobs_605323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_605337.validator(path, query, header, formData, body)
  let scheme = call_605337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605337.url(scheme.get, call_605337.host, call_605337.base,
                         call_605337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605337, url, valid)

proc call*(call_605338: Call_ListHyperParameterTuningJobs_605323; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605339 = newJObject()
  var body_605340 = newJObject()
  add(query_605339, "MaxResults", newJString(MaxResults))
  add(query_605339, "NextToken", newJString(NextToken))
  if body != nil:
    body_605340 = body
  result = call_605338.call(nil, query_605339, nil, nil, body_605340)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_605323(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_605324, base: "/",
    url: url_ListHyperParameterTuningJobs_605325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_605341 = ref object of OpenApiRestCall_603389
proc url_ListLabelingJobs_605343(protocol: Scheme; host: string; base: string;
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

proc validate_ListLabelingJobs_605342(path: JsonNode; query: JsonNode;
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
  var valid_605344 = query.getOrDefault("MaxResults")
  valid_605344 = validateParameter(valid_605344, JString, required = false,
                                 default = nil)
  if valid_605344 != nil:
    section.add "MaxResults", valid_605344
  var valid_605345 = query.getOrDefault("NextToken")
  valid_605345 = validateParameter(valid_605345, JString, required = false,
                                 default = nil)
  if valid_605345 != nil:
    section.add "NextToken", valid_605345
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605346 = header.getOrDefault("X-Amz-Target")
  valid_605346 = validateParameter(valid_605346, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_605346 != nil:
    section.add "X-Amz-Target", valid_605346
  var valid_605347 = header.getOrDefault("X-Amz-Signature")
  valid_605347 = validateParameter(valid_605347, JString, required = false,
                                 default = nil)
  if valid_605347 != nil:
    section.add "X-Amz-Signature", valid_605347
  var valid_605348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605348 = validateParameter(valid_605348, JString, required = false,
                                 default = nil)
  if valid_605348 != nil:
    section.add "X-Amz-Content-Sha256", valid_605348
  var valid_605349 = header.getOrDefault("X-Amz-Date")
  valid_605349 = validateParameter(valid_605349, JString, required = false,
                                 default = nil)
  if valid_605349 != nil:
    section.add "X-Amz-Date", valid_605349
  var valid_605350 = header.getOrDefault("X-Amz-Credential")
  valid_605350 = validateParameter(valid_605350, JString, required = false,
                                 default = nil)
  if valid_605350 != nil:
    section.add "X-Amz-Credential", valid_605350
  var valid_605351 = header.getOrDefault("X-Amz-Security-Token")
  valid_605351 = validateParameter(valid_605351, JString, required = false,
                                 default = nil)
  if valid_605351 != nil:
    section.add "X-Amz-Security-Token", valid_605351
  var valid_605352 = header.getOrDefault("X-Amz-Algorithm")
  valid_605352 = validateParameter(valid_605352, JString, required = false,
                                 default = nil)
  if valid_605352 != nil:
    section.add "X-Amz-Algorithm", valid_605352
  var valid_605353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605353 = validateParameter(valid_605353, JString, required = false,
                                 default = nil)
  if valid_605353 != nil:
    section.add "X-Amz-SignedHeaders", valid_605353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605355: Call_ListLabelingJobs_605341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_605355.validator(path, query, header, formData, body)
  let scheme = call_605355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605355.url(scheme.get, call_605355.host, call_605355.base,
                         call_605355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605355, url, valid)

proc call*(call_605356: Call_ListLabelingJobs_605341; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605357 = newJObject()
  var body_605358 = newJObject()
  add(query_605357, "MaxResults", newJString(MaxResults))
  add(query_605357, "NextToken", newJString(NextToken))
  if body != nil:
    body_605358 = body
  result = call_605356.call(nil, query_605357, nil, nil, body_605358)

var listLabelingJobs* = Call_ListLabelingJobs_605341(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_605342, base: "/",
    url: url_ListLabelingJobs_605343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_605359 = ref object of OpenApiRestCall_603389
proc url_ListLabelingJobsForWorkteam_605361(protocol: Scheme; host: string;
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

proc validate_ListLabelingJobsForWorkteam_605360(path: JsonNode; query: JsonNode;
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
  var valid_605362 = query.getOrDefault("MaxResults")
  valid_605362 = validateParameter(valid_605362, JString, required = false,
                                 default = nil)
  if valid_605362 != nil:
    section.add "MaxResults", valid_605362
  var valid_605363 = query.getOrDefault("NextToken")
  valid_605363 = validateParameter(valid_605363, JString, required = false,
                                 default = nil)
  if valid_605363 != nil:
    section.add "NextToken", valid_605363
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605364 = header.getOrDefault("X-Amz-Target")
  valid_605364 = validateParameter(valid_605364, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_605364 != nil:
    section.add "X-Amz-Target", valid_605364
  var valid_605365 = header.getOrDefault("X-Amz-Signature")
  valid_605365 = validateParameter(valid_605365, JString, required = false,
                                 default = nil)
  if valid_605365 != nil:
    section.add "X-Amz-Signature", valid_605365
  var valid_605366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605366 = validateParameter(valid_605366, JString, required = false,
                                 default = nil)
  if valid_605366 != nil:
    section.add "X-Amz-Content-Sha256", valid_605366
  var valid_605367 = header.getOrDefault("X-Amz-Date")
  valid_605367 = validateParameter(valid_605367, JString, required = false,
                                 default = nil)
  if valid_605367 != nil:
    section.add "X-Amz-Date", valid_605367
  var valid_605368 = header.getOrDefault("X-Amz-Credential")
  valid_605368 = validateParameter(valid_605368, JString, required = false,
                                 default = nil)
  if valid_605368 != nil:
    section.add "X-Amz-Credential", valid_605368
  var valid_605369 = header.getOrDefault("X-Amz-Security-Token")
  valid_605369 = validateParameter(valid_605369, JString, required = false,
                                 default = nil)
  if valid_605369 != nil:
    section.add "X-Amz-Security-Token", valid_605369
  var valid_605370 = header.getOrDefault("X-Amz-Algorithm")
  valid_605370 = validateParameter(valid_605370, JString, required = false,
                                 default = nil)
  if valid_605370 != nil:
    section.add "X-Amz-Algorithm", valid_605370
  var valid_605371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605371 = validateParameter(valid_605371, JString, required = false,
                                 default = nil)
  if valid_605371 != nil:
    section.add "X-Amz-SignedHeaders", valid_605371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605373: Call_ListLabelingJobsForWorkteam_605359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_605373.validator(path, query, header, formData, body)
  let scheme = call_605373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605373.url(scheme.get, call_605373.host, call_605373.base,
                         call_605373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605373, url, valid)

proc call*(call_605374: Call_ListLabelingJobsForWorkteam_605359; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605375 = newJObject()
  var body_605376 = newJObject()
  add(query_605375, "MaxResults", newJString(MaxResults))
  add(query_605375, "NextToken", newJString(NextToken))
  if body != nil:
    body_605376 = body
  result = call_605374.call(nil, query_605375, nil, nil, body_605376)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_605359(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_605360, base: "/",
    url: url_ListLabelingJobsForWorkteam_605361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_605377 = ref object of OpenApiRestCall_603389
proc url_ListModelPackages_605379(protocol: Scheme; host: string; base: string;
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

proc validate_ListModelPackages_605378(path: JsonNode; query: JsonNode;
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
  var valid_605380 = query.getOrDefault("MaxResults")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "MaxResults", valid_605380
  var valid_605381 = query.getOrDefault("NextToken")
  valid_605381 = validateParameter(valid_605381, JString, required = false,
                                 default = nil)
  if valid_605381 != nil:
    section.add "NextToken", valid_605381
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605382 = header.getOrDefault("X-Amz-Target")
  valid_605382 = validateParameter(valid_605382, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_605382 != nil:
    section.add "X-Amz-Target", valid_605382
  var valid_605383 = header.getOrDefault("X-Amz-Signature")
  valid_605383 = validateParameter(valid_605383, JString, required = false,
                                 default = nil)
  if valid_605383 != nil:
    section.add "X-Amz-Signature", valid_605383
  var valid_605384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605384 = validateParameter(valid_605384, JString, required = false,
                                 default = nil)
  if valid_605384 != nil:
    section.add "X-Amz-Content-Sha256", valid_605384
  var valid_605385 = header.getOrDefault("X-Amz-Date")
  valid_605385 = validateParameter(valid_605385, JString, required = false,
                                 default = nil)
  if valid_605385 != nil:
    section.add "X-Amz-Date", valid_605385
  var valid_605386 = header.getOrDefault("X-Amz-Credential")
  valid_605386 = validateParameter(valid_605386, JString, required = false,
                                 default = nil)
  if valid_605386 != nil:
    section.add "X-Amz-Credential", valid_605386
  var valid_605387 = header.getOrDefault("X-Amz-Security-Token")
  valid_605387 = validateParameter(valid_605387, JString, required = false,
                                 default = nil)
  if valid_605387 != nil:
    section.add "X-Amz-Security-Token", valid_605387
  var valid_605388 = header.getOrDefault("X-Amz-Algorithm")
  valid_605388 = validateParameter(valid_605388, JString, required = false,
                                 default = nil)
  if valid_605388 != nil:
    section.add "X-Amz-Algorithm", valid_605388
  var valid_605389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605389 = validateParameter(valid_605389, JString, required = false,
                                 default = nil)
  if valid_605389 != nil:
    section.add "X-Amz-SignedHeaders", valid_605389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605391: Call_ListModelPackages_605377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_605391.validator(path, query, header, formData, body)
  let scheme = call_605391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605391.url(scheme.get, call_605391.host, call_605391.base,
                         call_605391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605391, url, valid)

proc call*(call_605392: Call_ListModelPackages_605377; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605393 = newJObject()
  var body_605394 = newJObject()
  add(query_605393, "MaxResults", newJString(MaxResults))
  add(query_605393, "NextToken", newJString(NextToken))
  if body != nil:
    body_605394 = body
  result = call_605392.call(nil, query_605393, nil, nil, body_605394)

var listModelPackages* = Call_ListModelPackages_605377(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_605378, base: "/",
    url: url_ListModelPackages_605379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_605395 = ref object of OpenApiRestCall_603389
proc url_ListModels_605397(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListModels_605396(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605398 = query.getOrDefault("MaxResults")
  valid_605398 = validateParameter(valid_605398, JString, required = false,
                                 default = nil)
  if valid_605398 != nil:
    section.add "MaxResults", valid_605398
  var valid_605399 = query.getOrDefault("NextToken")
  valid_605399 = validateParameter(valid_605399, JString, required = false,
                                 default = nil)
  if valid_605399 != nil:
    section.add "NextToken", valid_605399
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605400 = header.getOrDefault("X-Amz-Target")
  valid_605400 = validateParameter(valid_605400, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_605400 != nil:
    section.add "X-Amz-Target", valid_605400
  var valid_605401 = header.getOrDefault("X-Amz-Signature")
  valid_605401 = validateParameter(valid_605401, JString, required = false,
                                 default = nil)
  if valid_605401 != nil:
    section.add "X-Amz-Signature", valid_605401
  var valid_605402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605402 = validateParameter(valid_605402, JString, required = false,
                                 default = nil)
  if valid_605402 != nil:
    section.add "X-Amz-Content-Sha256", valid_605402
  var valid_605403 = header.getOrDefault("X-Amz-Date")
  valid_605403 = validateParameter(valid_605403, JString, required = false,
                                 default = nil)
  if valid_605403 != nil:
    section.add "X-Amz-Date", valid_605403
  var valid_605404 = header.getOrDefault("X-Amz-Credential")
  valid_605404 = validateParameter(valid_605404, JString, required = false,
                                 default = nil)
  if valid_605404 != nil:
    section.add "X-Amz-Credential", valid_605404
  var valid_605405 = header.getOrDefault("X-Amz-Security-Token")
  valid_605405 = validateParameter(valid_605405, JString, required = false,
                                 default = nil)
  if valid_605405 != nil:
    section.add "X-Amz-Security-Token", valid_605405
  var valid_605406 = header.getOrDefault("X-Amz-Algorithm")
  valid_605406 = validateParameter(valid_605406, JString, required = false,
                                 default = nil)
  if valid_605406 != nil:
    section.add "X-Amz-Algorithm", valid_605406
  var valid_605407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-SignedHeaders", valid_605407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605409: Call_ListModels_605395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_605409.validator(path, query, header, formData, body)
  let scheme = call_605409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605409.url(scheme.get, call_605409.host, call_605409.base,
                         call_605409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605409, url, valid)

proc call*(call_605410: Call_ListModels_605395; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605411 = newJObject()
  var body_605412 = newJObject()
  add(query_605411, "MaxResults", newJString(MaxResults))
  add(query_605411, "NextToken", newJString(NextToken))
  if body != nil:
    body_605412 = body
  result = call_605410.call(nil, query_605411, nil, nil, body_605412)

var listModels* = Call_ListModels_605395(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_605396,
                                      base: "/", url: url_ListModels_605397,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_605413 = ref object of OpenApiRestCall_603389
proc url_ListMonitoringExecutions_605415(protocol: Scheme; host: string;
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

proc validate_ListMonitoringExecutions_605414(path: JsonNode; query: JsonNode;
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
  var valid_605416 = query.getOrDefault("MaxResults")
  valid_605416 = validateParameter(valid_605416, JString, required = false,
                                 default = nil)
  if valid_605416 != nil:
    section.add "MaxResults", valid_605416
  var valid_605417 = query.getOrDefault("NextToken")
  valid_605417 = validateParameter(valid_605417, JString, required = false,
                                 default = nil)
  if valid_605417 != nil:
    section.add "NextToken", valid_605417
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605418 = header.getOrDefault("X-Amz-Target")
  valid_605418 = validateParameter(valid_605418, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_605418 != nil:
    section.add "X-Amz-Target", valid_605418
  var valid_605419 = header.getOrDefault("X-Amz-Signature")
  valid_605419 = validateParameter(valid_605419, JString, required = false,
                                 default = nil)
  if valid_605419 != nil:
    section.add "X-Amz-Signature", valid_605419
  var valid_605420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605420 = validateParameter(valid_605420, JString, required = false,
                                 default = nil)
  if valid_605420 != nil:
    section.add "X-Amz-Content-Sha256", valid_605420
  var valid_605421 = header.getOrDefault("X-Amz-Date")
  valid_605421 = validateParameter(valid_605421, JString, required = false,
                                 default = nil)
  if valid_605421 != nil:
    section.add "X-Amz-Date", valid_605421
  var valid_605422 = header.getOrDefault("X-Amz-Credential")
  valid_605422 = validateParameter(valid_605422, JString, required = false,
                                 default = nil)
  if valid_605422 != nil:
    section.add "X-Amz-Credential", valid_605422
  var valid_605423 = header.getOrDefault("X-Amz-Security-Token")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Security-Token", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Algorithm")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Algorithm", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-SignedHeaders", valid_605425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605427: Call_ListMonitoringExecutions_605413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_605427.validator(path, query, header, formData, body)
  let scheme = call_605427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605427.url(scheme.get, call_605427.host, call_605427.base,
                         call_605427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605427, url, valid)

proc call*(call_605428: Call_ListMonitoringExecutions_605413; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605429 = newJObject()
  var body_605430 = newJObject()
  add(query_605429, "MaxResults", newJString(MaxResults))
  add(query_605429, "NextToken", newJString(NextToken))
  if body != nil:
    body_605430 = body
  result = call_605428.call(nil, query_605429, nil, nil, body_605430)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_605413(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_605414, base: "/",
    url: url_ListMonitoringExecutions_605415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_605431 = ref object of OpenApiRestCall_603389
proc url_ListMonitoringSchedules_605433(protocol: Scheme; host: string; base: string;
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

proc validate_ListMonitoringSchedules_605432(path: JsonNode; query: JsonNode;
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
  var valid_605434 = query.getOrDefault("MaxResults")
  valid_605434 = validateParameter(valid_605434, JString, required = false,
                                 default = nil)
  if valid_605434 != nil:
    section.add "MaxResults", valid_605434
  var valid_605435 = query.getOrDefault("NextToken")
  valid_605435 = validateParameter(valid_605435, JString, required = false,
                                 default = nil)
  if valid_605435 != nil:
    section.add "NextToken", valid_605435
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605436 = header.getOrDefault("X-Amz-Target")
  valid_605436 = validateParameter(valid_605436, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_605436 != nil:
    section.add "X-Amz-Target", valid_605436
  var valid_605437 = header.getOrDefault("X-Amz-Signature")
  valid_605437 = validateParameter(valid_605437, JString, required = false,
                                 default = nil)
  if valid_605437 != nil:
    section.add "X-Amz-Signature", valid_605437
  var valid_605438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605438 = validateParameter(valid_605438, JString, required = false,
                                 default = nil)
  if valid_605438 != nil:
    section.add "X-Amz-Content-Sha256", valid_605438
  var valid_605439 = header.getOrDefault("X-Amz-Date")
  valid_605439 = validateParameter(valid_605439, JString, required = false,
                                 default = nil)
  if valid_605439 != nil:
    section.add "X-Amz-Date", valid_605439
  var valid_605440 = header.getOrDefault("X-Amz-Credential")
  valid_605440 = validateParameter(valid_605440, JString, required = false,
                                 default = nil)
  if valid_605440 != nil:
    section.add "X-Amz-Credential", valid_605440
  var valid_605441 = header.getOrDefault("X-Amz-Security-Token")
  valid_605441 = validateParameter(valid_605441, JString, required = false,
                                 default = nil)
  if valid_605441 != nil:
    section.add "X-Amz-Security-Token", valid_605441
  var valid_605442 = header.getOrDefault("X-Amz-Algorithm")
  valid_605442 = validateParameter(valid_605442, JString, required = false,
                                 default = nil)
  if valid_605442 != nil:
    section.add "X-Amz-Algorithm", valid_605442
  var valid_605443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605443 = validateParameter(valid_605443, JString, required = false,
                                 default = nil)
  if valid_605443 != nil:
    section.add "X-Amz-SignedHeaders", valid_605443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605445: Call_ListMonitoringSchedules_605431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_605445.validator(path, query, header, formData, body)
  let scheme = call_605445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605445.url(scheme.get, call_605445.host, call_605445.base,
                         call_605445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605445, url, valid)

proc call*(call_605446: Call_ListMonitoringSchedules_605431; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605447 = newJObject()
  var body_605448 = newJObject()
  add(query_605447, "MaxResults", newJString(MaxResults))
  add(query_605447, "NextToken", newJString(NextToken))
  if body != nil:
    body_605448 = body
  result = call_605446.call(nil, query_605447, nil, nil, body_605448)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_605431(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_605432, base: "/",
    url: url_ListMonitoringSchedules_605433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_605449 = ref object of OpenApiRestCall_603389
proc url_ListNotebookInstanceLifecycleConfigs_605451(protocol: Scheme;
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

proc validate_ListNotebookInstanceLifecycleConfigs_605450(path: JsonNode;
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
  var valid_605452 = query.getOrDefault("MaxResults")
  valid_605452 = validateParameter(valid_605452, JString, required = false,
                                 default = nil)
  if valid_605452 != nil:
    section.add "MaxResults", valid_605452
  var valid_605453 = query.getOrDefault("NextToken")
  valid_605453 = validateParameter(valid_605453, JString, required = false,
                                 default = nil)
  if valid_605453 != nil:
    section.add "NextToken", valid_605453
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605454 = header.getOrDefault("X-Amz-Target")
  valid_605454 = validateParameter(valid_605454, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_605454 != nil:
    section.add "X-Amz-Target", valid_605454
  var valid_605455 = header.getOrDefault("X-Amz-Signature")
  valid_605455 = validateParameter(valid_605455, JString, required = false,
                                 default = nil)
  if valid_605455 != nil:
    section.add "X-Amz-Signature", valid_605455
  var valid_605456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605456 = validateParameter(valid_605456, JString, required = false,
                                 default = nil)
  if valid_605456 != nil:
    section.add "X-Amz-Content-Sha256", valid_605456
  var valid_605457 = header.getOrDefault("X-Amz-Date")
  valid_605457 = validateParameter(valid_605457, JString, required = false,
                                 default = nil)
  if valid_605457 != nil:
    section.add "X-Amz-Date", valid_605457
  var valid_605458 = header.getOrDefault("X-Amz-Credential")
  valid_605458 = validateParameter(valid_605458, JString, required = false,
                                 default = nil)
  if valid_605458 != nil:
    section.add "X-Amz-Credential", valid_605458
  var valid_605459 = header.getOrDefault("X-Amz-Security-Token")
  valid_605459 = validateParameter(valid_605459, JString, required = false,
                                 default = nil)
  if valid_605459 != nil:
    section.add "X-Amz-Security-Token", valid_605459
  var valid_605460 = header.getOrDefault("X-Amz-Algorithm")
  valid_605460 = validateParameter(valid_605460, JString, required = false,
                                 default = nil)
  if valid_605460 != nil:
    section.add "X-Amz-Algorithm", valid_605460
  var valid_605461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605461 = validateParameter(valid_605461, JString, required = false,
                                 default = nil)
  if valid_605461 != nil:
    section.add "X-Amz-SignedHeaders", valid_605461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605463: Call_ListNotebookInstanceLifecycleConfigs_605449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_605463.validator(path, query, header, formData, body)
  let scheme = call_605463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605463.url(scheme.get, call_605463.host, call_605463.base,
                         call_605463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605463, url, valid)

proc call*(call_605464: Call_ListNotebookInstanceLifecycleConfigs_605449;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605465 = newJObject()
  var body_605466 = newJObject()
  add(query_605465, "MaxResults", newJString(MaxResults))
  add(query_605465, "NextToken", newJString(NextToken))
  if body != nil:
    body_605466 = body
  result = call_605464.call(nil, query_605465, nil, nil, body_605466)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_605449(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_605450, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_605451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_605467 = ref object of OpenApiRestCall_603389
proc url_ListNotebookInstances_605469(protocol: Scheme; host: string; base: string;
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

proc validate_ListNotebookInstances_605468(path: JsonNode; query: JsonNode;
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
  var valid_605470 = query.getOrDefault("MaxResults")
  valid_605470 = validateParameter(valid_605470, JString, required = false,
                                 default = nil)
  if valid_605470 != nil:
    section.add "MaxResults", valid_605470
  var valid_605471 = query.getOrDefault("NextToken")
  valid_605471 = validateParameter(valid_605471, JString, required = false,
                                 default = nil)
  if valid_605471 != nil:
    section.add "NextToken", valid_605471
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605472 = header.getOrDefault("X-Amz-Target")
  valid_605472 = validateParameter(valid_605472, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_605472 != nil:
    section.add "X-Amz-Target", valid_605472
  var valid_605473 = header.getOrDefault("X-Amz-Signature")
  valid_605473 = validateParameter(valid_605473, JString, required = false,
                                 default = nil)
  if valid_605473 != nil:
    section.add "X-Amz-Signature", valid_605473
  var valid_605474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605474 = validateParameter(valid_605474, JString, required = false,
                                 default = nil)
  if valid_605474 != nil:
    section.add "X-Amz-Content-Sha256", valid_605474
  var valid_605475 = header.getOrDefault("X-Amz-Date")
  valid_605475 = validateParameter(valid_605475, JString, required = false,
                                 default = nil)
  if valid_605475 != nil:
    section.add "X-Amz-Date", valid_605475
  var valid_605476 = header.getOrDefault("X-Amz-Credential")
  valid_605476 = validateParameter(valid_605476, JString, required = false,
                                 default = nil)
  if valid_605476 != nil:
    section.add "X-Amz-Credential", valid_605476
  var valid_605477 = header.getOrDefault("X-Amz-Security-Token")
  valid_605477 = validateParameter(valid_605477, JString, required = false,
                                 default = nil)
  if valid_605477 != nil:
    section.add "X-Amz-Security-Token", valid_605477
  var valid_605478 = header.getOrDefault("X-Amz-Algorithm")
  valid_605478 = validateParameter(valid_605478, JString, required = false,
                                 default = nil)
  if valid_605478 != nil:
    section.add "X-Amz-Algorithm", valid_605478
  var valid_605479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605479 = validateParameter(valid_605479, JString, required = false,
                                 default = nil)
  if valid_605479 != nil:
    section.add "X-Amz-SignedHeaders", valid_605479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605481: Call_ListNotebookInstances_605467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_605481.validator(path, query, header, formData, body)
  let scheme = call_605481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605481.url(scheme.get, call_605481.host, call_605481.base,
                         call_605481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605481, url, valid)

proc call*(call_605482: Call_ListNotebookInstances_605467; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605483 = newJObject()
  var body_605484 = newJObject()
  add(query_605483, "MaxResults", newJString(MaxResults))
  add(query_605483, "NextToken", newJString(NextToken))
  if body != nil:
    body_605484 = body
  result = call_605482.call(nil, query_605483, nil, nil, body_605484)

var listNotebookInstances* = Call_ListNotebookInstances_605467(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_605468, base: "/",
    url: url_ListNotebookInstances_605469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_605485 = ref object of OpenApiRestCall_603389
proc url_ListProcessingJobs_605487(protocol: Scheme; host: string; base: string;
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

proc validate_ListProcessingJobs_605486(path: JsonNode; query: JsonNode;
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
  var valid_605488 = query.getOrDefault("MaxResults")
  valid_605488 = validateParameter(valid_605488, JString, required = false,
                                 default = nil)
  if valid_605488 != nil:
    section.add "MaxResults", valid_605488
  var valid_605489 = query.getOrDefault("NextToken")
  valid_605489 = validateParameter(valid_605489, JString, required = false,
                                 default = nil)
  if valid_605489 != nil:
    section.add "NextToken", valid_605489
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605490 = header.getOrDefault("X-Amz-Target")
  valid_605490 = validateParameter(valid_605490, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_605490 != nil:
    section.add "X-Amz-Target", valid_605490
  var valid_605491 = header.getOrDefault("X-Amz-Signature")
  valid_605491 = validateParameter(valid_605491, JString, required = false,
                                 default = nil)
  if valid_605491 != nil:
    section.add "X-Amz-Signature", valid_605491
  var valid_605492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605492 = validateParameter(valid_605492, JString, required = false,
                                 default = nil)
  if valid_605492 != nil:
    section.add "X-Amz-Content-Sha256", valid_605492
  var valid_605493 = header.getOrDefault("X-Amz-Date")
  valid_605493 = validateParameter(valid_605493, JString, required = false,
                                 default = nil)
  if valid_605493 != nil:
    section.add "X-Amz-Date", valid_605493
  var valid_605494 = header.getOrDefault("X-Amz-Credential")
  valid_605494 = validateParameter(valid_605494, JString, required = false,
                                 default = nil)
  if valid_605494 != nil:
    section.add "X-Amz-Credential", valid_605494
  var valid_605495 = header.getOrDefault("X-Amz-Security-Token")
  valid_605495 = validateParameter(valid_605495, JString, required = false,
                                 default = nil)
  if valid_605495 != nil:
    section.add "X-Amz-Security-Token", valid_605495
  var valid_605496 = header.getOrDefault("X-Amz-Algorithm")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "X-Amz-Algorithm", valid_605496
  var valid_605497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605497 = validateParameter(valid_605497, JString, required = false,
                                 default = nil)
  if valid_605497 != nil:
    section.add "X-Amz-SignedHeaders", valid_605497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605499: Call_ListProcessingJobs_605485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_605499.validator(path, query, header, formData, body)
  let scheme = call_605499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605499.url(scheme.get, call_605499.host, call_605499.base,
                         call_605499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605499, url, valid)

proc call*(call_605500: Call_ListProcessingJobs_605485; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605501 = newJObject()
  var body_605502 = newJObject()
  add(query_605501, "MaxResults", newJString(MaxResults))
  add(query_605501, "NextToken", newJString(NextToken))
  if body != nil:
    body_605502 = body
  result = call_605500.call(nil, query_605501, nil, nil, body_605502)

var listProcessingJobs* = Call_ListProcessingJobs_605485(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_605486, base: "/",
    url: url_ListProcessingJobs_605487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_605503 = ref object of OpenApiRestCall_603389
proc url_ListSubscribedWorkteams_605505(protocol: Scheme; host: string; base: string;
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

proc validate_ListSubscribedWorkteams_605504(path: JsonNode; query: JsonNode;
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
  var valid_605506 = query.getOrDefault("MaxResults")
  valid_605506 = validateParameter(valid_605506, JString, required = false,
                                 default = nil)
  if valid_605506 != nil:
    section.add "MaxResults", valid_605506
  var valid_605507 = query.getOrDefault("NextToken")
  valid_605507 = validateParameter(valid_605507, JString, required = false,
                                 default = nil)
  if valid_605507 != nil:
    section.add "NextToken", valid_605507
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605508 = header.getOrDefault("X-Amz-Target")
  valid_605508 = validateParameter(valid_605508, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_605508 != nil:
    section.add "X-Amz-Target", valid_605508
  var valid_605509 = header.getOrDefault("X-Amz-Signature")
  valid_605509 = validateParameter(valid_605509, JString, required = false,
                                 default = nil)
  if valid_605509 != nil:
    section.add "X-Amz-Signature", valid_605509
  var valid_605510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605510 = validateParameter(valid_605510, JString, required = false,
                                 default = nil)
  if valid_605510 != nil:
    section.add "X-Amz-Content-Sha256", valid_605510
  var valid_605511 = header.getOrDefault("X-Amz-Date")
  valid_605511 = validateParameter(valid_605511, JString, required = false,
                                 default = nil)
  if valid_605511 != nil:
    section.add "X-Amz-Date", valid_605511
  var valid_605512 = header.getOrDefault("X-Amz-Credential")
  valid_605512 = validateParameter(valid_605512, JString, required = false,
                                 default = nil)
  if valid_605512 != nil:
    section.add "X-Amz-Credential", valid_605512
  var valid_605513 = header.getOrDefault("X-Amz-Security-Token")
  valid_605513 = validateParameter(valid_605513, JString, required = false,
                                 default = nil)
  if valid_605513 != nil:
    section.add "X-Amz-Security-Token", valid_605513
  var valid_605514 = header.getOrDefault("X-Amz-Algorithm")
  valid_605514 = validateParameter(valid_605514, JString, required = false,
                                 default = nil)
  if valid_605514 != nil:
    section.add "X-Amz-Algorithm", valid_605514
  var valid_605515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605515 = validateParameter(valid_605515, JString, required = false,
                                 default = nil)
  if valid_605515 != nil:
    section.add "X-Amz-SignedHeaders", valid_605515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605517: Call_ListSubscribedWorkteams_605503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_605517.validator(path, query, header, formData, body)
  let scheme = call_605517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605517.url(scheme.get, call_605517.host, call_605517.base,
                         call_605517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605517, url, valid)

proc call*(call_605518: Call_ListSubscribedWorkteams_605503; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605519 = newJObject()
  var body_605520 = newJObject()
  add(query_605519, "MaxResults", newJString(MaxResults))
  add(query_605519, "NextToken", newJString(NextToken))
  if body != nil:
    body_605520 = body
  result = call_605518.call(nil, query_605519, nil, nil, body_605520)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_605503(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_605504, base: "/",
    url: url_ListSubscribedWorkteams_605505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_605521 = ref object of OpenApiRestCall_603389
proc url_ListTags_605523(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_605522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605524 = query.getOrDefault("MaxResults")
  valid_605524 = validateParameter(valid_605524, JString, required = false,
                                 default = nil)
  if valid_605524 != nil:
    section.add "MaxResults", valid_605524
  var valid_605525 = query.getOrDefault("NextToken")
  valid_605525 = validateParameter(valid_605525, JString, required = false,
                                 default = nil)
  if valid_605525 != nil:
    section.add "NextToken", valid_605525
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605526 = header.getOrDefault("X-Amz-Target")
  valid_605526 = validateParameter(valid_605526, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_605526 != nil:
    section.add "X-Amz-Target", valid_605526
  var valid_605527 = header.getOrDefault("X-Amz-Signature")
  valid_605527 = validateParameter(valid_605527, JString, required = false,
                                 default = nil)
  if valid_605527 != nil:
    section.add "X-Amz-Signature", valid_605527
  var valid_605528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605528 = validateParameter(valid_605528, JString, required = false,
                                 default = nil)
  if valid_605528 != nil:
    section.add "X-Amz-Content-Sha256", valid_605528
  var valid_605529 = header.getOrDefault("X-Amz-Date")
  valid_605529 = validateParameter(valid_605529, JString, required = false,
                                 default = nil)
  if valid_605529 != nil:
    section.add "X-Amz-Date", valid_605529
  var valid_605530 = header.getOrDefault("X-Amz-Credential")
  valid_605530 = validateParameter(valid_605530, JString, required = false,
                                 default = nil)
  if valid_605530 != nil:
    section.add "X-Amz-Credential", valid_605530
  var valid_605531 = header.getOrDefault("X-Amz-Security-Token")
  valid_605531 = validateParameter(valid_605531, JString, required = false,
                                 default = nil)
  if valid_605531 != nil:
    section.add "X-Amz-Security-Token", valid_605531
  var valid_605532 = header.getOrDefault("X-Amz-Algorithm")
  valid_605532 = validateParameter(valid_605532, JString, required = false,
                                 default = nil)
  if valid_605532 != nil:
    section.add "X-Amz-Algorithm", valid_605532
  var valid_605533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605533 = validateParameter(valid_605533, JString, required = false,
                                 default = nil)
  if valid_605533 != nil:
    section.add "X-Amz-SignedHeaders", valid_605533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605535: Call_ListTags_605521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_605535.validator(path, query, header, formData, body)
  let scheme = call_605535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605535.url(scheme.get, call_605535.host, call_605535.base,
                         call_605535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605535, url, valid)

proc call*(call_605536: Call_ListTags_605521; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605537 = newJObject()
  var body_605538 = newJObject()
  add(query_605537, "MaxResults", newJString(MaxResults))
  add(query_605537, "NextToken", newJString(NextToken))
  if body != nil:
    body_605538 = body
  result = call_605536.call(nil, query_605537, nil, nil, body_605538)

var listTags* = Call_ListTags_605521(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_605522, base: "/",
                                  url: url_ListTags_605523,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_605539 = ref object of OpenApiRestCall_603389
proc url_ListTrainingJobs_605541(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrainingJobs_605540(path: JsonNode; query: JsonNode;
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
  var valid_605542 = query.getOrDefault("MaxResults")
  valid_605542 = validateParameter(valid_605542, JString, required = false,
                                 default = nil)
  if valid_605542 != nil:
    section.add "MaxResults", valid_605542
  var valid_605543 = query.getOrDefault("NextToken")
  valid_605543 = validateParameter(valid_605543, JString, required = false,
                                 default = nil)
  if valid_605543 != nil:
    section.add "NextToken", valid_605543
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605544 = header.getOrDefault("X-Amz-Target")
  valid_605544 = validateParameter(valid_605544, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_605544 != nil:
    section.add "X-Amz-Target", valid_605544
  var valid_605545 = header.getOrDefault("X-Amz-Signature")
  valid_605545 = validateParameter(valid_605545, JString, required = false,
                                 default = nil)
  if valid_605545 != nil:
    section.add "X-Amz-Signature", valid_605545
  var valid_605546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605546 = validateParameter(valid_605546, JString, required = false,
                                 default = nil)
  if valid_605546 != nil:
    section.add "X-Amz-Content-Sha256", valid_605546
  var valid_605547 = header.getOrDefault("X-Amz-Date")
  valid_605547 = validateParameter(valid_605547, JString, required = false,
                                 default = nil)
  if valid_605547 != nil:
    section.add "X-Amz-Date", valid_605547
  var valid_605548 = header.getOrDefault("X-Amz-Credential")
  valid_605548 = validateParameter(valid_605548, JString, required = false,
                                 default = nil)
  if valid_605548 != nil:
    section.add "X-Amz-Credential", valid_605548
  var valid_605549 = header.getOrDefault("X-Amz-Security-Token")
  valid_605549 = validateParameter(valid_605549, JString, required = false,
                                 default = nil)
  if valid_605549 != nil:
    section.add "X-Amz-Security-Token", valid_605549
  var valid_605550 = header.getOrDefault("X-Amz-Algorithm")
  valid_605550 = validateParameter(valid_605550, JString, required = false,
                                 default = nil)
  if valid_605550 != nil:
    section.add "X-Amz-Algorithm", valid_605550
  var valid_605551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605551 = validateParameter(valid_605551, JString, required = false,
                                 default = nil)
  if valid_605551 != nil:
    section.add "X-Amz-SignedHeaders", valid_605551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605553: Call_ListTrainingJobs_605539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_605553.validator(path, query, header, formData, body)
  let scheme = call_605553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605553.url(scheme.get, call_605553.host, call_605553.base,
                         call_605553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605553, url, valid)

proc call*(call_605554: Call_ListTrainingJobs_605539; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605555 = newJObject()
  var body_605556 = newJObject()
  add(query_605555, "MaxResults", newJString(MaxResults))
  add(query_605555, "NextToken", newJString(NextToken))
  if body != nil:
    body_605556 = body
  result = call_605554.call(nil, query_605555, nil, nil, body_605556)

var listTrainingJobs* = Call_ListTrainingJobs_605539(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_605540, base: "/",
    url: url_ListTrainingJobs_605541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_605557 = ref object of OpenApiRestCall_603389
proc url_ListTrainingJobsForHyperParameterTuningJob_605559(protocol: Scheme;
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

proc validate_ListTrainingJobsForHyperParameterTuningJob_605558(path: JsonNode;
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
  var valid_605560 = query.getOrDefault("MaxResults")
  valid_605560 = validateParameter(valid_605560, JString, required = false,
                                 default = nil)
  if valid_605560 != nil:
    section.add "MaxResults", valid_605560
  var valid_605561 = query.getOrDefault("NextToken")
  valid_605561 = validateParameter(valid_605561, JString, required = false,
                                 default = nil)
  if valid_605561 != nil:
    section.add "NextToken", valid_605561
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605562 = header.getOrDefault("X-Amz-Target")
  valid_605562 = validateParameter(valid_605562, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_605562 != nil:
    section.add "X-Amz-Target", valid_605562
  var valid_605563 = header.getOrDefault("X-Amz-Signature")
  valid_605563 = validateParameter(valid_605563, JString, required = false,
                                 default = nil)
  if valid_605563 != nil:
    section.add "X-Amz-Signature", valid_605563
  var valid_605564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605564 = validateParameter(valid_605564, JString, required = false,
                                 default = nil)
  if valid_605564 != nil:
    section.add "X-Amz-Content-Sha256", valid_605564
  var valid_605565 = header.getOrDefault("X-Amz-Date")
  valid_605565 = validateParameter(valid_605565, JString, required = false,
                                 default = nil)
  if valid_605565 != nil:
    section.add "X-Amz-Date", valid_605565
  var valid_605566 = header.getOrDefault("X-Amz-Credential")
  valid_605566 = validateParameter(valid_605566, JString, required = false,
                                 default = nil)
  if valid_605566 != nil:
    section.add "X-Amz-Credential", valid_605566
  var valid_605567 = header.getOrDefault("X-Amz-Security-Token")
  valid_605567 = validateParameter(valid_605567, JString, required = false,
                                 default = nil)
  if valid_605567 != nil:
    section.add "X-Amz-Security-Token", valid_605567
  var valid_605568 = header.getOrDefault("X-Amz-Algorithm")
  valid_605568 = validateParameter(valid_605568, JString, required = false,
                                 default = nil)
  if valid_605568 != nil:
    section.add "X-Amz-Algorithm", valid_605568
  var valid_605569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605569 = validateParameter(valid_605569, JString, required = false,
                                 default = nil)
  if valid_605569 != nil:
    section.add "X-Amz-SignedHeaders", valid_605569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605571: Call_ListTrainingJobsForHyperParameterTuningJob_605557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_605571.validator(path, query, header, formData, body)
  let scheme = call_605571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605571.url(scheme.get, call_605571.host, call_605571.base,
                         call_605571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605571, url, valid)

proc call*(call_605572: Call_ListTrainingJobsForHyperParameterTuningJob_605557;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605573 = newJObject()
  var body_605574 = newJObject()
  add(query_605573, "MaxResults", newJString(MaxResults))
  add(query_605573, "NextToken", newJString(NextToken))
  if body != nil:
    body_605574 = body
  result = call_605572.call(nil, query_605573, nil, nil, body_605574)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_605557(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_605558,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_605559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_605575 = ref object of OpenApiRestCall_603389
proc url_ListTransformJobs_605577(protocol: Scheme; host: string; base: string;
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

proc validate_ListTransformJobs_605576(path: JsonNode; query: JsonNode;
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
  var valid_605578 = query.getOrDefault("MaxResults")
  valid_605578 = validateParameter(valid_605578, JString, required = false,
                                 default = nil)
  if valid_605578 != nil:
    section.add "MaxResults", valid_605578
  var valid_605579 = query.getOrDefault("NextToken")
  valid_605579 = validateParameter(valid_605579, JString, required = false,
                                 default = nil)
  if valid_605579 != nil:
    section.add "NextToken", valid_605579
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605580 = header.getOrDefault("X-Amz-Target")
  valid_605580 = validateParameter(valid_605580, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_605580 != nil:
    section.add "X-Amz-Target", valid_605580
  var valid_605581 = header.getOrDefault("X-Amz-Signature")
  valid_605581 = validateParameter(valid_605581, JString, required = false,
                                 default = nil)
  if valid_605581 != nil:
    section.add "X-Amz-Signature", valid_605581
  var valid_605582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605582 = validateParameter(valid_605582, JString, required = false,
                                 default = nil)
  if valid_605582 != nil:
    section.add "X-Amz-Content-Sha256", valid_605582
  var valid_605583 = header.getOrDefault("X-Amz-Date")
  valid_605583 = validateParameter(valid_605583, JString, required = false,
                                 default = nil)
  if valid_605583 != nil:
    section.add "X-Amz-Date", valid_605583
  var valid_605584 = header.getOrDefault("X-Amz-Credential")
  valid_605584 = validateParameter(valid_605584, JString, required = false,
                                 default = nil)
  if valid_605584 != nil:
    section.add "X-Amz-Credential", valid_605584
  var valid_605585 = header.getOrDefault("X-Amz-Security-Token")
  valid_605585 = validateParameter(valid_605585, JString, required = false,
                                 default = nil)
  if valid_605585 != nil:
    section.add "X-Amz-Security-Token", valid_605585
  var valid_605586 = header.getOrDefault("X-Amz-Algorithm")
  valid_605586 = validateParameter(valid_605586, JString, required = false,
                                 default = nil)
  if valid_605586 != nil:
    section.add "X-Amz-Algorithm", valid_605586
  var valid_605587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605587 = validateParameter(valid_605587, JString, required = false,
                                 default = nil)
  if valid_605587 != nil:
    section.add "X-Amz-SignedHeaders", valid_605587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605589: Call_ListTransformJobs_605575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_605589.validator(path, query, header, formData, body)
  let scheme = call_605589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605589.url(scheme.get, call_605589.host, call_605589.base,
                         call_605589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605589, url, valid)

proc call*(call_605590: Call_ListTransformJobs_605575; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605591 = newJObject()
  var body_605592 = newJObject()
  add(query_605591, "MaxResults", newJString(MaxResults))
  add(query_605591, "NextToken", newJString(NextToken))
  if body != nil:
    body_605592 = body
  result = call_605590.call(nil, query_605591, nil, nil, body_605592)

var listTransformJobs* = Call_ListTransformJobs_605575(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_605576, base: "/",
    url: url_ListTransformJobs_605577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_605593 = ref object of OpenApiRestCall_603389
proc url_ListTrialComponents_605595(protocol: Scheme; host: string; base: string;
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

proc validate_ListTrialComponents_605594(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
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
  var valid_605596 = query.getOrDefault("MaxResults")
  valid_605596 = validateParameter(valid_605596, JString, required = false,
                                 default = nil)
  if valid_605596 != nil:
    section.add "MaxResults", valid_605596
  var valid_605597 = query.getOrDefault("NextToken")
  valid_605597 = validateParameter(valid_605597, JString, required = false,
                                 default = nil)
  if valid_605597 != nil:
    section.add "NextToken", valid_605597
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605598 = header.getOrDefault("X-Amz-Target")
  valid_605598 = validateParameter(valid_605598, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_605598 != nil:
    section.add "X-Amz-Target", valid_605598
  var valid_605599 = header.getOrDefault("X-Amz-Signature")
  valid_605599 = validateParameter(valid_605599, JString, required = false,
                                 default = nil)
  if valid_605599 != nil:
    section.add "X-Amz-Signature", valid_605599
  var valid_605600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605600 = validateParameter(valid_605600, JString, required = false,
                                 default = nil)
  if valid_605600 != nil:
    section.add "X-Amz-Content-Sha256", valid_605600
  var valid_605601 = header.getOrDefault("X-Amz-Date")
  valid_605601 = validateParameter(valid_605601, JString, required = false,
                                 default = nil)
  if valid_605601 != nil:
    section.add "X-Amz-Date", valid_605601
  var valid_605602 = header.getOrDefault("X-Amz-Credential")
  valid_605602 = validateParameter(valid_605602, JString, required = false,
                                 default = nil)
  if valid_605602 != nil:
    section.add "X-Amz-Credential", valid_605602
  var valid_605603 = header.getOrDefault("X-Amz-Security-Token")
  valid_605603 = validateParameter(valid_605603, JString, required = false,
                                 default = nil)
  if valid_605603 != nil:
    section.add "X-Amz-Security-Token", valid_605603
  var valid_605604 = header.getOrDefault("X-Amz-Algorithm")
  valid_605604 = validateParameter(valid_605604, JString, required = false,
                                 default = nil)
  if valid_605604 != nil:
    section.add "X-Amz-Algorithm", valid_605604
  var valid_605605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605605 = validateParameter(valid_605605, JString, required = false,
                                 default = nil)
  if valid_605605 != nil:
    section.add "X-Amz-SignedHeaders", valid_605605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605607: Call_ListTrialComponents_605593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ## 
  let valid = call_605607.validator(path, query, header, formData, body)
  let scheme = call_605607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605607.url(scheme.get, call_605607.host, call_605607.base,
                         call_605607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605607, url, valid)

proc call*(call_605608: Call_ListTrialComponents_605593; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605609 = newJObject()
  var body_605610 = newJObject()
  add(query_605609, "MaxResults", newJString(MaxResults))
  add(query_605609, "NextToken", newJString(NextToken))
  if body != nil:
    body_605610 = body
  result = call_605608.call(nil, query_605609, nil, nil, body_605610)

var listTrialComponents* = Call_ListTrialComponents_605593(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_605594, base: "/",
    url: url_ListTrialComponents_605595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_605611 = ref object of OpenApiRestCall_603389
proc url_ListTrials_605613(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTrials_605612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605614 = query.getOrDefault("MaxResults")
  valid_605614 = validateParameter(valid_605614, JString, required = false,
                                 default = nil)
  if valid_605614 != nil:
    section.add "MaxResults", valid_605614
  var valid_605615 = query.getOrDefault("NextToken")
  valid_605615 = validateParameter(valid_605615, JString, required = false,
                                 default = nil)
  if valid_605615 != nil:
    section.add "NextToken", valid_605615
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605616 = header.getOrDefault("X-Amz-Target")
  valid_605616 = validateParameter(valid_605616, JString, required = true,
                                 default = newJString("SageMaker.ListTrials"))
  if valid_605616 != nil:
    section.add "X-Amz-Target", valid_605616
  var valid_605617 = header.getOrDefault("X-Amz-Signature")
  valid_605617 = validateParameter(valid_605617, JString, required = false,
                                 default = nil)
  if valid_605617 != nil:
    section.add "X-Amz-Signature", valid_605617
  var valid_605618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605618 = validateParameter(valid_605618, JString, required = false,
                                 default = nil)
  if valid_605618 != nil:
    section.add "X-Amz-Content-Sha256", valid_605618
  var valid_605619 = header.getOrDefault("X-Amz-Date")
  valid_605619 = validateParameter(valid_605619, JString, required = false,
                                 default = nil)
  if valid_605619 != nil:
    section.add "X-Amz-Date", valid_605619
  var valid_605620 = header.getOrDefault("X-Amz-Credential")
  valid_605620 = validateParameter(valid_605620, JString, required = false,
                                 default = nil)
  if valid_605620 != nil:
    section.add "X-Amz-Credential", valid_605620
  var valid_605621 = header.getOrDefault("X-Amz-Security-Token")
  valid_605621 = validateParameter(valid_605621, JString, required = false,
                                 default = nil)
  if valid_605621 != nil:
    section.add "X-Amz-Security-Token", valid_605621
  var valid_605622 = header.getOrDefault("X-Amz-Algorithm")
  valid_605622 = validateParameter(valid_605622, JString, required = false,
                                 default = nil)
  if valid_605622 != nil:
    section.add "X-Amz-Algorithm", valid_605622
  var valid_605623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605623 = validateParameter(valid_605623, JString, required = false,
                                 default = nil)
  if valid_605623 != nil:
    section.add "X-Amz-SignedHeaders", valid_605623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605625: Call_ListTrials_605611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_605625.validator(path, query, header, formData, body)
  let scheme = call_605625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605625.url(scheme.get, call_605625.host, call_605625.base,
                         call_605625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605625, url, valid)

proc call*(call_605626: Call_ListTrials_605611; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605627 = newJObject()
  var body_605628 = newJObject()
  add(query_605627, "MaxResults", newJString(MaxResults))
  add(query_605627, "NextToken", newJString(NextToken))
  if body != nil:
    body_605628 = body
  result = call_605626.call(nil, query_605627, nil, nil, body_605628)

var listTrials* = Call_ListTrials_605611(name: "listTrials",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                      validator: validate_ListTrials_605612,
                                      base: "/", url: url_ListTrials_605613,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_605629 = ref object of OpenApiRestCall_603389
proc url_ListUserProfiles_605631(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserProfiles_605630(path: JsonNode; query: JsonNode;
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
  var valid_605632 = query.getOrDefault("MaxResults")
  valid_605632 = validateParameter(valid_605632, JString, required = false,
                                 default = nil)
  if valid_605632 != nil:
    section.add "MaxResults", valid_605632
  var valid_605633 = query.getOrDefault("NextToken")
  valid_605633 = validateParameter(valid_605633, JString, required = false,
                                 default = nil)
  if valid_605633 != nil:
    section.add "NextToken", valid_605633
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605634 = header.getOrDefault("X-Amz-Target")
  valid_605634 = validateParameter(valid_605634, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_605634 != nil:
    section.add "X-Amz-Target", valid_605634
  var valid_605635 = header.getOrDefault("X-Amz-Signature")
  valid_605635 = validateParameter(valid_605635, JString, required = false,
                                 default = nil)
  if valid_605635 != nil:
    section.add "X-Amz-Signature", valid_605635
  var valid_605636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605636 = validateParameter(valid_605636, JString, required = false,
                                 default = nil)
  if valid_605636 != nil:
    section.add "X-Amz-Content-Sha256", valid_605636
  var valid_605637 = header.getOrDefault("X-Amz-Date")
  valid_605637 = validateParameter(valid_605637, JString, required = false,
                                 default = nil)
  if valid_605637 != nil:
    section.add "X-Amz-Date", valid_605637
  var valid_605638 = header.getOrDefault("X-Amz-Credential")
  valid_605638 = validateParameter(valid_605638, JString, required = false,
                                 default = nil)
  if valid_605638 != nil:
    section.add "X-Amz-Credential", valid_605638
  var valid_605639 = header.getOrDefault("X-Amz-Security-Token")
  valid_605639 = validateParameter(valid_605639, JString, required = false,
                                 default = nil)
  if valid_605639 != nil:
    section.add "X-Amz-Security-Token", valid_605639
  var valid_605640 = header.getOrDefault("X-Amz-Algorithm")
  valid_605640 = validateParameter(valid_605640, JString, required = false,
                                 default = nil)
  if valid_605640 != nil:
    section.add "X-Amz-Algorithm", valid_605640
  var valid_605641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605641 = validateParameter(valid_605641, JString, required = false,
                                 default = nil)
  if valid_605641 != nil:
    section.add "X-Amz-SignedHeaders", valid_605641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605643: Call_ListUserProfiles_605629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_605643.validator(path, query, header, formData, body)
  let scheme = call_605643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605643.url(scheme.get, call_605643.host, call_605643.base,
                         call_605643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605643, url, valid)

proc call*(call_605644: Call_ListUserProfiles_605629; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605645 = newJObject()
  var body_605646 = newJObject()
  add(query_605645, "MaxResults", newJString(MaxResults))
  add(query_605645, "NextToken", newJString(NextToken))
  if body != nil:
    body_605646 = body
  result = call_605644.call(nil, query_605645, nil, nil, body_605646)

var listUserProfiles* = Call_ListUserProfiles_605629(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_605630, base: "/",
    url: url_ListUserProfiles_605631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_605647 = ref object of OpenApiRestCall_603389
proc url_ListWorkteams_605649(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkteams_605648(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605650 = query.getOrDefault("MaxResults")
  valid_605650 = validateParameter(valid_605650, JString, required = false,
                                 default = nil)
  if valid_605650 != nil:
    section.add "MaxResults", valid_605650
  var valid_605651 = query.getOrDefault("NextToken")
  valid_605651 = validateParameter(valid_605651, JString, required = false,
                                 default = nil)
  if valid_605651 != nil:
    section.add "NextToken", valid_605651
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605652 = header.getOrDefault("X-Amz-Target")
  valid_605652 = validateParameter(valid_605652, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_605652 != nil:
    section.add "X-Amz-Target", valid_605652
  var valid_605653 = header.getOrDefault("X-Amz-Signature")
  valid_605653 = validateParameter(valid_605653, JString, required = false,
                                 default = nil)
  if valid_605653 != nil:
    section.add "X-Amz-Signature", valid_605653
  var valid_605654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605654 = validateParameter(valid_605654, JString, required = false,
                                 default = nil)
  if valid_605654 != nil:
    section.add "X-Amz-Content-Sha256", valid_605654
  var valid_605655 = header.getOrDefault("X-Amz-Date")
  valid_605655 = validateParameter(valid_605655, JString, required = false,
                                 default = nil)
  if valid_605655 != nil:
    section.add "X-Amz-Date", valid_605655
  var valid_605656 = header.getOrDefault("X-Amz-Credential")
  valid_605656 = validateParameter(valid_605656, JString, required = false,
                                 default = nil)
  if valid_605656 != nil:
    section.add "X-Amz-Credential", valid_605656
  var valid_605657 = header.getOrDefault("X-Amz-Security-Token")
  valid_605657 = validateParameter(valid_605657, JString, required = false,
                                 default = nil)
  if valid_605657 != nil:
    section.add "X-Amz-Security-Token", valid_605657
  var valid_605658 = header.getOrDefault("X-Amz-Algorithm")
  valid_605658 = validateParameter(valid_605658, JString, required = false,
                                 default = nil)
  if valid_605658 != nil:
    section.add "X-Amz-Algorithm", valid_605658
  var valid_605659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605659 = validateParameter(valid_605659, JString, required = false,
                                 default = nil)
  if valid_605659 != nil:
    section.add "X-Amz-SignedHeaders", valid_605659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605661: Call_ListWorkteams_605647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_605661.validator(path, query, header, formData, body)
  let scheme = call_605661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605661.url(scheme.get, call_605661.host, call_605661.base,
                         call_605661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605661, url, valid)

proc call*(call_605662: Call_ListWorkteams_605647; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605663 = newJObject()
  var body_605664 = newJObject()
  add(query_605663, "MaxResults", newJString(MaxResults))
  add(query_605663, "NextToken", newJString(NextToken))
  if body != nil:
    body_605664 = body
  result = call_605662.call(nil, query_605663, nil, nil, body_605664)

var listWorkteams* = Call_ListWorkteams_605647(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_605648, base: "/", url: url_ListWorkteams_605649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_605665 = ref object of OpenApiRestCall_603389
proc url_RenderUiTemplate_605667(protocol: Scheme; host: string; base: string;
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

proc validate_RenderUiTemplate_605666(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605668 = header.getOrDefault("X-Amz-Target")
  valid_605668 = validateParameter(valid_605668, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_605668 != nil:
    section.add "X-Amz-Target", valid_605668
  var valid_605669 = header.getOrDefault("X-Amz-Signature")
  valid_605669 = validateParameter(valid_605669, JString, required = false,
                                 default = nil)
  if valid_605669 != nil:
    section.add "X-Amz-Signature", valid_605669
  var valid_605670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605670 = validateParameter(valid_605670, JString, required = false,
                                 default = nil)
  if valid_605670 != nil:
    section.add "X-Amz-Content-Sha256", valid_605670
  var valid_605671 = header.getOrDefault("X-Amz-Date")
  valid_605671 = validateParameter(valid_605671, JString, required = false,
                                 default = nil)
  if valid_605671 != nil:
    section.add "X-Amz-Date", valid_605671
  var valid_605672 = header.getOrDefault("X-Amz-Credential")
  valid_605672 = validateParameter(valid_605672, JString, required = false,
                                 default = nil)
  if valid_605672 != nil:
    section.add "X-Amz-Credential", valid_605672
  var valid_605673 = header.getOrDefault("X-Amz-Security-Token")
  valid_605673 = validateParameter(valid_605673, JString, required = false,
                                 default = nil)
  if valid_605673 != nil:
    section.add "X-Amz-Security-Token", valid_605673
  var valid_605674 = header.getOrDefault("X-Amz-Algorithm")
  valid_605674 = validateParameter(valid_605674, JString, required = false,
                                 default = nil)
  if valid_605674 != nil:
    section.add "X-Amz-Algorithm", valid_605674
  var valid_605675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605675 = validateParameter(valid_605675, JString, required = false,
                                 default = nil)
  if valid_605675 != nil:
    section.add "X-Amz-SignedHeaders", valid_605675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605677: Call_RenderUiTemplate_605665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_605677.validator(path, query, header, formData, body)
  let scheme = call_605677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605677.url(scheme.get, call_605677.host, call_605677.base,
                         call_605677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605677, url, valid)

proc call*(call_605678: Call_RenderUiTemplate_605665; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_605679 = newJObject()
  if body != nil:
    body_605679 = body
  result = call_605678.call(nil, nil, nil, nil, body_605679)

var renderUiTemplate* = Call_RenderUiTemplate_605665(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_605666, base: "/",
    url: url_RenderUiTemplate_605667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_605680 = ref object of OpenApiRestCall_603389
proc url_Search_605682(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Search_605681(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_605683 = query.getOrDefault("MaxResults")
  valid_605683 = validateParameter(valid_605683, JString, required = false,
                                 default = nil)
  if valid_605683 != nil:
    section.add "MaxResults", valid_605683
  var valid_605684 = query.getOrDefault("NextToken")
  valid_605684 = validateParameter(valid_605684, JString, required = false,
                                 default = nil)
  if valid_605684 != nil:
    section.add "NextToken", valid_605684
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_605685 = header.getOrDefault("X-Amz-Target")
  valid_605685 = validateParameter(valid_605685, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_605685 != nil:
    section.add "X-Amz-Target", valid_605685
  var valid_605686 = header.getOrDefault("X-Amz-Signature")
  valid_605686 = validateParameter(valid_605686, JString, required = false,
                                 default = nil)
  if valid_605686 != nil:
    section.add "X-Amz-Signature", valid_605686
  var valid_605687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605687 = validateParameter(valid_605687, JString, required = false,
                                 default = nil)
  if valid_605687 != nil:
    section.add "X-Amz-Content-Sha256", valid_605687
  var valid_605688 = header.getOrDefault("X-Amz-Date")
  valid_605688 = validateParameter(valid_605688, JString, required = false,
                                 default = nil)
  if valid_605688 != nil:
    section.add "X-Amz-Date", valid_605688
  var valid_605689 = header.getOrDefault("X-Amz-Credential")
  valid_605689 = validateParameter(valid_605689, JString, required = false,
                                 default = nil)
  if valid_605689 != nil:
    section.add "X-Amz-Credential", valid_605689
  var valid_605690 = header.getOrDefault("X-Amz-Security-Token")
  valid_605690 = validateParameter(valid_605690, JString, required = false,
                                 default = nil)
  if valid_605690 != nil:
    section.add "X-Amz-Security-Token", valid_605690
  var valid_605691 = header.getOrDefault("X-Amz-Algorithm")
  valid_605691 = validateParameter(valid_605691, JString, required = false,
                                 default = nil)
  if valid_605691 != nil:
    section.add "X-Amz-Algorithm", valid_605691
  var valid_605692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605692 = validateParameter(valid_605692, JString, required = false,
                                 default = nil)
  if valid_605692 != nil:
    section.add "X-Amz-SignedHeaders", valid_605692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605694: Call_Search_605680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  let valid = call_605694.validator(path, query, header, formData, body)
  let scheme = call_605694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605694.url(scheme.get, call_605694.host, call_605694.base,
                         call_605694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605694, url, valid)

proc call*(call_605695: Call_Search_605680; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605696 = newJObject()
  var body_605697 = newJObject()
  add(query_605696, "MaxResults", newJString(MaxResults))
  add(query_605696, "NextToken", newJString(NextToken))
  if body != nil:
    body_605697 = body
  result = call_605695.call(nil, query_605696, nil, nil, body_605697)

var search* = Call_Search_605680(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_605681, base: "/",
                              url: url_Search_605682,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_605698 = ref object of OpenApiRestCall_603389
proc url_StartMonitoringSchedule_605700(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringSchedule_605699(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605701 = header.getOrDefault("X-Amz-Target")
  valid_605701 = validateParameter(valid_605701, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_605701 != nil:
    section.add "X-Amz-Target", valid_605701
  var valid_605702 = header.getOrDefault("X-Amz-Signature")
  valid_605702 = validateParameter(valid_605702, JString, required = false,
                                 default = nil)
  if valid_605702 != nil:
    section.add "X-Amz-Signature", valid_605702
  var valid_605703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605703 = validateParameter(valid_605703, JString, required = false,
                                 default = nil)
  if valid_605703 != nil:
    section.add "X-Amz-Content-Sha256", valid_605703
  var valid_605704 = header.getOrDefault("X-Amz-Date")
  valid_605704 = validateParameter(valid_605704, JString, required = false,
                                 default = nil)
  if valid_605704 != nil:
    section.add "X-Amz-Date", valid_605704
  var valid_605705 = header.getOrDefault("X-Amz-Credential")
  valid_605705 = validateParameter(valid_605705, JString, required = false,
                                 default = nil)
  if valid_605705 != nil:
    section.add "X-Amz-Credential", valid_605705
  var valid_605706 = header.getOrDefault("X-Amz-Security-Token")
  valid_605706 = validateParameter(valid_605706, JString, required = false,
                                 default = nil)
  if valid_605706 != nil:
    section.add "X-Amz-Security-Token", valid_605706
  var valid_605707 = header.getOrDefault("X-Amz-Algorithm")
  valid_605707 = validateParameter(valid_605707, JString, required = false,
                                 default = nil)
  if valid_605707 != nil:
    section.add "X-Amz-Algorithm", valid_605707
  var valid_605708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605708 = validateParameter(valid_605708, JString, required = false,
                                 default = nil)
  if valid_605708 != nil:
    section.add "X-Amz-SignedHeaders", valid_605708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605710: Call_StartMonitoringSchedule_605698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_605710.validator(path, query, header, formData, body)
  let scheme = call_605710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605710.url(scheme.get, call_605710.host, call_605710.base,
                         call_605710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605710, url, valid)

proc call*(call_605711: Call_StartMonitoringSchedule_605698; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_605712 = newJObject()
  if body != nil:
    body_605712 = body
  result = call_605711.call(nil, nil, nil, nil, body_605712)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_605698(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_605699, base: "/",
    url: url_StartMonitoringSchedule_605700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_605713 = ref object of OpenApiRestCall_603389
proc url_StartNotebookInstance_605715(protocol: Scheme; host: string; base: string;
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

proc validate_StartNotebookInstance_605714(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605716 = header.getOrDefault("X-Amz-Target")
  valid_605716 = validateParameter(valid_605716, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_605716 != nil:
    section.add "X-Amz-Target", valid_605716
  var valid_605717 = header.getOrDefault("X-Amz-Signature")
  valid_605717 = validateParameter(valid_605717, JString, required = false,
                                 default = nil)
  if valid_605717 != nil:
    section.add "X-Amz-Signature", valid_605717
  var valid_605718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605718 = validateParameter(valid_605718, JString, required = false,
                                 default = nil)
  if valid_605718 != nil:
    section.add "X-Amz-Content-Sha256", valid_605718
  var valid_605719 = header.getOrDefault("X-Amz-Date")
  valid_605719 = validateParameter(valid_605719, JString, required = false,
                                 default = nil)
  if valid_605719 != nil:
    section.add "X-Amz-Date", valid_605719
  var valid_605720 = header.getOrDefault("X-Amz-Credential")
  valid_605720 = validateParameter(valid_605720, JString, required = false,
                                 default = nil)
  if valid_605720 != nil:
    section.add "X-Amz-Credential", valid_605720
  var valid_605721 = header.getOrDefault("X-Amz-Security-Token")
  valid_605721 = validateParameter(valid_605721, JString, required = false,
                                 default = nil)
  if valid_605721 != nil:
    section.add "X-Amz-Security-Token", valid_605721
  var valid_605722 = header.getOrDefault("X-Amz-Algorithm")
  valid_605722 = validateParameter(valid_605722, JString, required = false,
                                 default = nil)
  if valid_605722 != nil:
    section.add "X-Amz-Algorithm", valid_605722
  var valid_605723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605723 = validateParameter(valid_605723, JString, required = false,
                                 default = nil)
  if valid_605723 != nil:
    section.add "X-Amz-SignedHeaders", valid_605723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605725: Call_StartNotebookInstance_605713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_605725.validator(path, query, header, formData, body)
  let scheme = call_605725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605725.url(scheme.get, call_605725.host, call_605725.base,
                         call_605725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605725, url, valid)

proc call*(call_605726: Call_StartNotebookInstance_605713; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_605727 = newJObject()
  if body != nil:
    body_605727 = body
  result = call_605726.call(nil, nil, nil, nil, body_605727)

var startNotebookInstance* = Call_StartNotebookInstance_605713(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_605714, base: "/",
    url: url_StartNotebookInstance_605715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_605728 = ref object of OpenApiRestCall_603389
proc url_StopAutoMLJob_605730(protocol: Scheme; host: string; base: string;
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

proc validate_StopAutoMLJob_605729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605731 = header.getOrDefault("X-Amz-Target")
  valid_605731 = validateParameter(valid_605731, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_605731 != nil:
    section.add "X-Amz-Target", valid_605731
  var valid_605732 = header.getOrDefault("X-Amz-Signature")
  valid_605732 = validateParameter(valid_605732, JString, required = false,
                                 default = nil)
  if valid_605732 != nil:
    section.add "X-Amz-Signature", valid_605732
  var valid_605733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605733 = validateParameter(valid_605733, JString, required = false,
                                 default = nil)
  if valid_605733 != nil:
    section.add "X-Amz-Content-Sha256", valid_605733
  var valid_605734 = header.getOrDefault("X-Amz-Date")
  valid_605734 = validateParameter(valid_605734, JString, required = false,
                                 default = nil)
  if valid_605734 != nil:
    section.add "X-Amz-Date", valid_605734
  var valid_605735 = header.getOrDefault("X-Amz-Credential")
  valid_605735 = validateParameter(valid_605735, JString, required = false,
                                 default = nil)
  if valid_605735 != nil:
    section.add "X-Amz-Credential", valid_605735
  var valid_605736 = header.getOrDefault("X-Amz-Security-Token")
  valid_605736 = validateParameter(valid_605736, JString, required = false,
                                 default = nil)
  if valid_605736 != nil:
    section.add "X-Amz-Security-Token", valid_605736
  var valid_605737 = header.getOrDefault("X-Amz-Algorithm")
  valid_605737 = validateParameter(valid_605737, JString, required = false,
                                 default = nil)
  if valid_605737 != nil:
    section.add "X-Amz-Algorithm", valid_605737
  var valid_605738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605738 = validateParameter(valid_605738, JString, required = false,
                                 default = nil)
  if valid_605738 != nil:
    section.add "X-Amz-SignedHeaders", valid_605738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605740: Call_StopAutoMLJob_605728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_605740.validator(path, query, header, formData, body)
  let scheme = call_605740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605740.url(scheme.get, call_605740.host, call_605740.base,
                         call_605740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605740, url, valid)

proc call*(call_605741: Call_StopAutoMLJob_605728; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_605742 = newJObject()
  if body != nil:
    body_605742 = body
  result = call_605741.call(nil, nil, nil, nil, body_605742)

var stopAutoMLJob* = Call_StopAutoMLJob_605728(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_605729, base: "/", url: url_StopAutoMLJob_605730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_605743 = ref object of OpenApiRestCall_603389
proc url_StopCompilationJob_605745(protocol: Scheme; host: string; base: string;
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

proc validate_StopCompilationJob_605744(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605746 = header.getOrDefault("X-Amz-Target")
  valid_605746 = validateParameter(valid_605746, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_605746 != nil:
    section.add "X-Amz-Target", valid_605746
  var valid_605747 = header.getOrDefault("X-Amz-Signature")
  valid_605747 = validateParameter(valid_605747, JString, required = false,
                                 default = nil)
  if valid_605747 != nil:
    section.add "X-Amz-Signature", valid_605747
  var valid_605748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605748 = validateParameter(valid_605748, JString, required = false,
                                 default = nil)
  if valid_605748 != nil:
    section.add "X-Amz-Content-Sha256", valid_605748
  var valid_605749 = header.getOrDefault("X-Amz-Date")
  valid_605749 = validateParameter(valid_605749, JString, required = false,
                                 default = nil)
  if valid_605749 != nil:
    section.add "X-Amz-Date", valid_605749
  var valid_605750 = header.getOrDefault("X-Amz-Credential")
  valid_605750 = validateParameter(valid_605750, JString, required = false,
                                 default = nil)
  if valid_605750 != nil:
    section.add "X-Amz-Credential", valid_605750
  var valid_605751 = header.getOrDefault("X-Amz-Security-Token")
  valid_605751 = validateParameter(valid_605751, JString, required = false,
                                 default = nil)
  if valid_605751 != nil:
    section.add "X-Amz-Security-Token", valid_605751
  var valid_605752 = header.getOrDefault("X-Amz-Algorithm")
  valid_605752 = validateParameter(valid_605752, JString, required = false,
                                 default = nil)
  if valid_605752 != nil:
    section.add "X-Amz-Algorithm", valid_605752
  var valid_605753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605753 = validateParameter(valid_605753, JString, required = false,
                                 default = nil)
  if valid_605753 != nil:
    section.add "X-Amz-SignedHeaders", valid_605753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605755: Call_StopCompilationJob_605743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_605755.validator(path, query, header, formData, body)
  let scheme = call_605755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605755.url(scheme.get, call_605755.host, call_605755.base,
                         call_605755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605755, url, valid)

proc call*(call_605756: Call_StopCompilationJob_605743; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_605757 = newJObject()
  if body != nil:
    body_605757 = body
  result = call_605756.call(nil, nil, nil, nil, body_605757)

var stopCompilationJob* = Call_StopCompilationJob_605743(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_605744, base: "/",
    url: url_StopCompilationJob_605745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_605758 = ref object of OpenApiRestCall_603389
proc url_StopHyperParameterTuningJob_605760(protocol: Scheme; host: string;
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

proc validate_StopHyperParameterTuningJob_605759(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605761 = header.getOrDefault("X-Amz-Target")
  valid_605761 = validateParameter(valid_605761, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_605761 != nil:
    section.add "X-Amz-Target", valid_605761
  var valid_605762 = header.getOrDefault("X-Amz-Signature")
  valid_605762 = validateParameter(valid_605762, JString, required = false,
                                 default = nil)
  if valid_605762 != nil:
    section.add "X-Amz-Signature", valid_605762
  var valid_605763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605763 = validateParameter(valid_605763, JString, required = false,
                                 default = nil)
  if valid_605763 != nil:
    section.add "X-Amz-Content-Sha256", valid_605763
  var valid_605764 = header.getOrDefault("X-Amz-Date")
  valid_605764 = validateParameter(valid_605764, JString, required = false,
                                 default = nil)
  if valid_605764 != nil:
    section.add "X-Amz-Date", valid_605764
  var valid_605765 = header.getOrDefault("X-Amz-Credential")
  valid_605765 = validateParameter(valid_605765, JString, required = false,
                                 default = nil)
  if valid_605765 != nil:
    section.add "X-Amz-Credential", valid_605765
  var valid_605766 = header.getOrDefault("X-Amz-Security-Token")
  valid_605766 = validateParameter(valid_605766, JString, required = false,
                                 default = nil)
  if valid_605766 != nil:
    section.add "X-Amz-Security-Token", valid_605766
  var valid_605767 = header.getOrDefault("X-Amz-Algorithm")
  valid_605767 = validateParameter(valid_605767, JString, required = false,
                                 default = nil)
  if valid_605767 != nil:
    section.add "X-Amz-Algorithm", valid_605767
  var valid_605768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605768 = validateParameter(valid_605768, JString, required = false,
                                 default = nil)
  if valid_605768 != nil:
    section.add "X-Amz-SignedHeaders", valid_605768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605770: Call_StopHyperParameterTuningJob_605758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_605770.validator(path, query, header, formData, body)
  let scheme = call_605770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605770.url(scheme.get, call_605770.host, call_605770.base,
                         call_605770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605770, url, valid)

proc call*(call_605771: Call_StopHyperParameterTuningJob_605758; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_605772 = newJObject()
  if body != nil:
    body_605772 = body
  result = call_605771.call(nil, nil, nil, nil, body_605772)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_605758(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_605759, base: "/",
    url: url_StopHyperParameterTuningJob_605760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_605773 = ref object of OpenApiRestCall_603389
proc url_StopLabelingJob_605775(protocol: Scheme; host: string; base: string;
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

proc validate_StopLabelingJob_605774(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605776 = header.getOrDefault("X-Amz-Target")
  valid_605776 = validateParameter(valid_605776, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_605776 != nil:
    section.add "X-Amz-Target", valid_605776
  var valid_605777 = header.getOrDefault("X-Amz-Signature")
  valid_605777 = validateParameter(valid_605777, JString, required = false,
                                 default = nil)
  if valid_605777 != nil:
    section.add "X-Amz-Signature", valid_605777
  var valid_605778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605778 = validateParameter(valid_605778, JString, required = false,
                                 default = nil)
  if valid_605778 != nil:
    section.add "X-Amz-Content-Sha256", valid_605778
  var valid_605779 = header.getOrDefault("X-Amz-Date")
  valid_605779 = validateParameter(valid_605779, JString, required = false,
                                 default = nil)
  if valid_605779 != nil:
    section.add "X-Amz-Date", valid_605779
  var valid_605780 = header.getOrDefault("X-Amz-Credential")
  valid_605780 = validateParameter(valid_605780, JString, required = false,
                                 default = nil)
  if valid_605780 != nil:
    section.add "X-Amz-Credential", valid_605780
  var valid_605781 = header.getOrDefault("X-Amz-Security-Token")
  valid_605781 = validateParameter(valid_605781, JString, required = false,
                                 default = nil)
  if valid_605781 != nil:
    section.add "X-Amz-Security-Token", valid_605781
  var valid_605782 = header.getOrDefault("X-Amz-Algorithm")
  valid_605782 = validateParameter(valid_605782, JString, required = false,
                                 default = nil)
  if valid_605782 != nil:
    section.add "X-Amz-Algorithm", valid_605782
  var valid_605783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605783 = validateParameter(valid_605783, JString, required = false,
                                 default = nil)
  if valid_605783 != nil:
    section.add "X-Amz-SignedHeaders", valid_605783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605785: Call_StopLabelingJob_605773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_605785.validator(path, query, header, formData, body)
  let scheme = call_605785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605785.url(scheme.get, call_605785.host, call_605785.base,
                         call_605785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605785, url, valid)

proc call*(call_605786: Call_StopLabelingJob_605773; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_605787 = newJObject()
  if body != nil:
    body_605787 = body
  result = call_605786.call(nil, nil, nil, nil, body_605787)

var stopLabelingJob* = Call_StopLabelingJob_605773(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_605774, base: "/", url: url_StopLabelingJob_605775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_605788 = ref object of OpenApiRestCall_603389
proc url_StopMonitoringSchedule_605790(protocol: Scheme; host: string; base: string;
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

proc validate_StopMonitoringSchedule_605789(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605791 = header.getOrDefault("X-Amz-Target")
  valid_605791 = validateParameter(valid_605791, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_605791 != nil:
    section.add "X-Amz-Target", valid_605791
  var valid_605792 = header.getOrDefault("X-Amz-Signature")
  valid_605792 = validateParameter(valid_605792, JString, required = false,
                                 default = nil)
  if valid_605792 != nil:
    section.add "X-Amz-Signature", valid_605792
  var valid_605793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605793 = validateParameter(valid_605793, JString, required = false,
                                 default = nil)
  if valid_605793 != nil:
    section.add "X-Amz-Content-Sha256", valid_605793
  var valid_605794 = header.getOrDefault("X-Amz-Date")
  valid_605794 = validateParameter(valid_605794, JString, required = false,
                                 default = nil)
  if valid_605794 != nil:
    section.add "X-Amz-Date", valid_605794
  var valid_605795 = header.getOrDefault("X-Amz-Credential")
  valid_605795 = validateParameter(valid_605795, JString, required = false,
                                 default = nil)
  if valid_605795 != nil:
    section.add "X-Amz-Credential", valid_605795
  var valid_605796 = header.getOrDefault("X-Amz-Security-Token")
  valid_605796 = validateParameter(valid_605796, JString, required = false,
                                 default = nil)
  if valid_605796 != nil:
    section.add "X-Amz-Security-Token", valid_605796
  var valid_605797 = header.getOrDefault("X-Amz-Algorithm")
  valid_605797 = validateParameter(valid_605797, JString, required = false,
                                 default = nil)
  if valid_605797 != nil:
    section.add "X-Amz-Algorithm", valid_605797
  var valid_605798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605798 = validateParameter(valid_605798, JString, required = false,
                                 default = nil)
  if valid_605798 != nil:
    section.add "X-Amz-SignedHeaders", valid_605798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605800: Call_StopMonitoringSchedule_605788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_605800.validator(path, query, header, formData, body)
  let scheme = call_605800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605800.url(scheme.get, call_605800.host, call_605800.base,
                         call_605800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605800, url, valid)

proc call*(call_605801: Call_StopMonitoringSchedule_605788; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_605802 = newJObject()
  if body != nil:
    body_605802 = body
  result = call_605801.call(nil, nil, nil, nil, body_605802)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_605788(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_605789, base: "/",
    url: url_StopMonitoringSchedule_605790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_605803 = ref object of OpenApiRestCall_603389
proc url_StopNotebookInstance_605805(protocol: Scheme; host: string; base: string;
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

proc validate_StopNotebookInstance_605804(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605806 = header.getOrDefault("X-Amz-Target")
  valid_605806 = validateParameter(valid_605806, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_605806 != nil:
    section.add "X-Amz-Target", valid_605806
  var valid_605807 = header.getOrDefault("X-Amz-Signature")
  valid_605807 = validateParameter(valid_605807, JString, required = false,
                                 default = nil)
  if valid_605807 != nil:
    section.add "X-Amz-Signature", valid_605807
  var valid_605808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605808 = validateParameter(valid_605808, JString, required = false,
                                 default = nil)
  if valid_605808 != nil:
    section.add "X-Amz-Content-Sha256", valid_605808
  var valid_605809 = header.getOrDefault("X-Amz-Date")
  valid_605809 = validateParameter(valid_605809, JString, required = false,
                                 default = nil)
  if valid_605809 != nil:
    section.add "X-Amz-Date", valid_605809
  var valid_605810 = header.getOrDefault("X-Amz-Credential")
  valid_605810 = validateParameter(valid_605810, JString, required = false,
                                 default = nil)
  if valid_605810 != nil:
    section.add "X-Amz-Credential", valid_605810
  var valid_605811 = header.getOrDefault("X-Amz-Security-Token")
  valid_605811 = validateParameter(valid_605811, JString, required = false,
                                 default = nil)
  if valid_605811 != nil:
    section.add "X-Amz-Security-Token", valid_605811
  var valid_605812 = header.getOrDefault("X-Amz-Algorithm")
  valid_605812 = validateParameter(valid_605812, JString, required = false,
                                 default = nil)
  if valid_605812 != nil:
    section.add "X-Amz-Algorithm", valid_605812
  var valid_605813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605813 = validateParameter(valid_605813, JString, required = false,
                                 default = nil)
  if valid_605813 != nil:
    section.add "X-Amz-SignedHeaders", valid_605813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605815: Call_StopNotebookInstance_605803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_605815.validator(path, query, header, formData, body)
  let scheme = call_605815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605815.url(scheme.get, call_605815.host, call_605815.base,
                         call_605815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605815, url, valid)

proc call*(call_605816: Call_StopNotebookInstance_605803; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_605817 = newJObject()
  if body != nil:
    body_605817 = body
  result = call_605816.call(nil, nil, nil, nil, body_605817)

var stopNotebookInstance* = Call_StopNotebookInstance_605803(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_605804, base: "/",
    url: url_StopNotebookInstance_605805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_605818 = ref object of OpenApiRestCall_603389
proc url_StopProcessingJob_605820(protocol: Scheme; host: string; base: string;
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

proc validate_StopProcessingJob_605819(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605821 = header.getOrDefault("X-Amz-Target")
  valid_605821 = validateParameter(valid_605821, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_605821 != nil:
    section.add "X-Amz-Target", valid_605821
  var valid_605822 = header.getOrDefault("X-Amz-Signature")
  valid_605822 = validateParameter(valid_605822, JString, required = false,
                                 default = nil)
  if valid_605822 != nil:
    section.add "X-Amz-Signature", valid_605822
  var valid_605823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605823 = validateParameter(valid_605823, JString, required = false,
                                 default = nil)
  if valid_605823 != nil:
    section.add "X-Amz-Content-Sha256", valid_605823
  var valid_605824 = header.getOrDefault("X-Amz-Date")
  valid_605824 = validateParameter(valid_605824, JString, required = false,
                                 default = nil)
  if valid_605824 != nil:
    section.add "X-Amz-Date", valid_605824
  var valid_605825 = header.getOrDefault("X-Amz-Credential")
  valid_605825 = validateParameter(valid_605825, JString, required = false,
                                 default = nil)
  if valid_605825 != nil:
    section.add "X-Amz-Credential", valid_605825
  var valid_605826 = header.getOrDefault("X-Amz-Security-Token")
  valid_605826 = validateParameter(valid_605826, JString, required = false,
                                 default = nil)
  if valid_605826 != nil:
    section.add "X-Amz-Security-Token", valid_605826
  var valid_605827 = header.getOrDefault("X-Amz-Algorithm")
  valid_605827 = validateParameter(valid_605827, JString, required = false,
                                 default = nil)
  if valid_605827 != nil:
    section.add "X-Amz-Algorithm", valid_605827
  var valid_605828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605828 = validateParameter(valid_605828, JString, required = false,
                                 default = nil)
  if valid_605828 != nil:
    section.add "X-Amz-SignedHeaders", valid_605828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605830: Call_StopProcessingJob_605818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_605830.validator(path, query, header, formData, body)
  let scheme = call_605830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605830.url(scheme.get, call_605830.host, call_605830.base,
                         call_605830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605830, url, valid)

proc call*(call_605831: Call_StopProcessingJob_605818; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_605832 = newJObject()
  if body != nil:
    body_605832 = body
  result = call_605831.call(nil, nil, nil, nil, body_605832)

var stopProcessingJob* = Call_StopProcessingJob_605818(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_605819, base: "/",
    url: url_StopProcessingJob_605820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_605833 = ref object of OpenApiRestCall_603389
proc url_StopTrainingJob_605835(protocol: Scheme; host: string; base: string;
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

proc validate_StopTrainingJob_605834(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605836 = header.getOrDefault("X-Amz-Target")
  valid_605836 = validateParameter(valid_605836, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_605836 != nil:
    section.add "X-Amz-Target", valid_605836
  var valid_605837 = header.getOrDefault("X-Amz-Signature")
  valid_605837 = validateParameter(valid_605837, JString, required = false,
                                 default = nil)
  if valid_605837 != nil:
    section.add "X-Amz-Signature", valid_605837
  var valid_605838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605838 = validateParameter(valid_605838, JString, required = false,
                                 default = nil)
  if valid_605838 != nil:
    section.add "X-Amz-Content-Sha256", valid_605838
  var valid_605839 = header.getOrDefault("X-Amz-Date")
  valid_605839 = validateParameter(valid_605839, JString, required = false,
                                 default = nil)
  if valid_605839 != nil:
    section.add "X-Amz-Date", valid_605839
  var valid_605840 = header.getOrDefault("X-Amz-Credential")
  valid_605840 = validateParameter(valid_605840, JString, required = false,
                                 default = nil)
  if valid_605840 != nil:
    section.add "X-Amz-Credential", valid_605840
  var valid_605841 = header.getOrDefault("X-Amz-Security-Token")
  valid_605841 = validateParameter(valid_605841, JString, required = false,
                                 default = nil)
  if valid_605841 != nil:
    section.add "X-Amz-Security-Token", valid_605841
  var valid_605842 = header.getOrDefault("X-Amz-Algorithm")
  valid_605842 = validateParameter(valid_605842, JString, required = false,
                                 default = nil)
  if valid_605842 != nil:
    section.add "X-Amz-Algorithm", valid_605842
  var valid_605843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605843 = validateParameter(valid_605843, JString, required = false,
                                 default = nil)
  if valid_605843 != nil:
    section.add "X-Amz-SignedHeaders", valid_605843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605845: Call_StopTrainingJob_605833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_605845.validator(path, query, header, formData, body)
  let scheme = call_605845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605845.url(scheme.get, call_605845.host, call_605845.base,
                         call_605845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605845, url, valid)

proc call*(call_605846: Call_StopTrainingJob_605833; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_605847 = newJObject()
  if body != nil:
    body_605847 = body
  result = call_605846.call(nil, nil, nil, nil, body_605847)

var stopTrainingJob* = Call_StopTrainingJob_605833(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_605834, base: "/", url: url_StopTrainingJob_605835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_605848 = ref object of OpenApiRestCall_603389
proc url_StopTransformJob_605850(protocol: Scheme; host: string; base: string;
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

proc validate_StopTransformJob_605849(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605851 = header.getOrDefault("X-Amz-Target")
  valid_605851 = validateParameter(valid_605851, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_605851 != nil:
    section.add "X-Amz-Target", valid_605851
  var valid_605852 = header.getOrDefault("X-Amz-Signature")
  valid_605852 = validateParameter(valid_605852, JString, required = false,
                                 default = nil)
  if valid_605852 != nil:
    section.add "X-Amz-Signature", valid_605852
  var valid_605853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605853 = validateParameter(valid_605853, JString, required = false,
                                 default = nil)
  if valid_605853 != nil:
    section.add "X-Amz-Content-Sha256", valid_605853
  var valid_605854 = header.getOrDefault("X-Amz-Date")
  valid_605854 = validateParameter(valid_605854, JString, required = false,
                                 default = nil)
  if valid_605854 != nil:
    section.add "X-Amz-Date", valid_605854
  var valid_605855 = header.getOrDefault("X-Amz-Credential")
  valid_605855 = validateParameter(valid_605855, JString, required = false,
                                 default = nil)
  if valid_605855 != nil:
    section.add "X-Amz-Credential", valid_605855
  var valid_605856 = header.getOrDefault("X-Amz-Security-Token")
  valid_605856 = validateParameter(valid_605856, JString, required = false,
                                 default = nil)
  if valid_605856 != nil:
    section.add "X-Amz-Security-Token", valid_605856
  var valid_605857 = header.getOrDefault("X-Amz-Algorithm")
  valid_605857 = validateParameter(valid_605857, JString, required = false,
                                 default = nil)
  if valid_605857 != nil:
    section.add "X-Amz-Algorithm", valid_605857
  var valid_605858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605858 = validateParameter(valid_605858, JString, required = false,
                                 default = nil)
  if valid_605858 != nil:
    section.add "X-Amz-SignedHeaders", valid_605858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605860: Call_StopTransformJob_605848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_605860.validator(path, query, header, formData, body)
  let scheme = call_605860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605860.url(scheme.get, call_605860.host, call_605860.base,
                         call_605860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605860, url, valid)

proc call*(call_605861: Call_StopTransformJob_605848; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_605862 = newJObject()
  if body != nil:
    body_605862 = body
  result = call_605861.call(nil, nil, nil, nil, body_605862)

var stopTransformJob* = Call_StopTransformJob_605848(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_605849, base: "/",
    url: url_StopTransformJob_605850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_605863 = ref object of OpenApiRestCall_603389
proc url_UpdateCodeRepository_605865(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCodeRepository_605864(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605866 = header.getOrDefault("X-Amz-Target")
  valid_605866 = validateParameter(valid_605866, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_605866 != nil:
    section.add "X-Amz-Target", valid_605866
  var valid_605867 = header.getOrDefault("X-Amz-Signature")
  valid_605867 = validateParameter(valid_605867, JString, required = false,
                                 default = nil)
  if valid_605867 != nil:
    section.add "X-Amz-Signature", valid_605867
  var valid_605868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605868 = validateParameter(valid_605868, JString, required = false,
                                 default = nil)
  if valid_605868 != nil:
    section.add "X-Amz-Content-Sha256", valid_605868
  var valid_605869 = header.getOrDefault("X-Amz-Date")
  valid_605869 = validateParameter(valid_605869, JString, required = false,
                                 default = nil)
  if valid_605869 != nil:
    section.add "X-Amz-Date", valid_605869
  var valid_605870 = header.getOrDefault("X-Amz-Credential")
  valid_605870 = validateParameter(valid_605870, JString, required = false,
                                 default = nil)
  if valid_605870 != nil:
    section.add "X-Amz-Credential", valid_605870
  var valid_605871 = header.getOrDefault("X-Amz-Security-Token")
  valid_605871 = validateParameter(valid_605871, JString, required = false,
                                 default = nil)
  if valid_605871 != nil:
    section.add "X-Amz-Security-Token", valid_605871
  var valid_605872 = header.getOrDefault("X-Amz-Algorithm")
  valid_605872 = validateParameter(valid_605872, JString, required = false,
                                 default = nil)
  if valid_605872 != nil:
    section.add "X-Amz-Algorithm", valid_605872
  var valid_605873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605873 = validateParameter(valid_605873, JString, required = false,
                                 default = nil)
  if valid_605873 != nil:
    section.add "X-Amz-SignedHeaders", valid_605873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605875: Call_UpdateCodeRepository_605863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_605875.validator(path, query, header, formData, body)
  let scheme = call_605875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605875.url(scheme.get, call_605875.host, call_605875.base,
                         call_605875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605875, url, valid)

proc call*(call_605876: Call_UpdateCodeRepository_605863; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_605877 = newJObject()
  if body != nil:
    body_605877 = body
  result = call_605876.call(nil, nil, nil, nil, body_605877)

var updateCodeRepository* = Call_UpdateCodeRepository_605863(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_605864, base: "/",
    url: url_UpdateCodeRepository_605865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_605878 = ref object of OpenApiRestCall_603389
proc url_UpdateDomain_605880(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDomain_605879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605881 = header.getOrDefault("X-Amz-Target")
  valid_605881 = validateParameter(valid_605881, JString, required = true,
                                 default = newJString("SageMaker.UpdateDomain"))
  if valid_605881 != nil:
    section.add "X-Amz-Target", valid_605881
  var valid_605882 = header.getOrDefault("X-Amz-Signature")
  valid_605882 = validateParameter(valid_605882, JString, required = false,
                                 default = nil)
  if valid_605882 != nil:
    section.add "X-Amz-Signature", valid_605882
  var valid_605883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605883 = validateParameter(valid_605883, JString, required = false,
                                 default = nil)
  if valid_605883 != nil:
    section.add "X-Amz-Content-Sha256", valid_605883
  var valid_605884 = header.getOrDefault("X-Amz-Date")
  valid_605884 = validateParameter(valid_605884, JString, required = false,
                                 default = nil)
  if valid_605884 != nil:
    section.add "X-Amz-Date", valid_605884
  var valid_605885 = header.getOrDefault("X-Amz-Credential")
  valid_605885 = validateParameter(valid_605885, JString, required = false,
                                 default = nil)
  if valid_605885 != nil:
    section.add "X-Amz-Credential", valid_605885
  var valid_605886 = header.getOrDefault("X-Amz-Security-Token")
  valid_605886 = validateParameter(valid_605886, JString, required = false,
                                 default = nil)
  if valid_605886 != nil:
    section.add "X-Amz-Security-Token", valid_605886
  var valid_605887 = header.getOrDefault("X-Amz-Algorithm")
  valid_605887 = validateParameter(valid_605887, JString, required = false,
                                 default = nil)
  if valid_605887 != nil:
    section.add "X-Amz-Algorithm", valid_605887
  var valid_605888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605888 = validateParameter(valid_605888, JString, required = false,
                                 default = nil)
  if valid_605888 != nil:
    section.add "X-Amz-SignedHeaders", valid_605888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605890: Call_UpdateDomain_605878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_605890.validator(path, query, header, formData, body)
  let scheme = call_605890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605890.url(scheme.get, call_605890.host, call_605890.base,
                         call_605890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605890, url, valid)

proc call*(call_605891: Call_UpdateDomain_605878; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_605892 = newJObject()
  if body != nil:
    body_605892 = body
  result = call_605891.call(nil, nil, nil, nil, body_605892)

var updateDomain* = Call_UpdateDomain_605878(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_605879, base: "/", url: url_UpdateDomain_605880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_605893 = ref object of OpenApiRestCall_603389
proc url_UpdateEndpoint_605895(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateEndpoint_605894(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605896 = header.getOrDefault("X-Amz-Target")
  valid_605896 = validateParameter(valid_605896, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_605896 != nil:
    section.add "X-Amz-Target", valid_605896
  var valid_605897 = header.getOrDefault("X-Amz-Signature")
  valid_605897 = validateParameter(valid_605897, JString, required = false,
                                 default = nil)
  if valid_605897 != nil:
    section.add "X-Amz-Signature", valid_605897
  var valid_605898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605898 = validateParameter(valid_605898, JString, required = false,
                                 default = nil)
  if valid_605898 != nil:
    section.add "X-Amz-Content-Sha256", valid_605898
  var valid_605899 = header.getOrDefault("X-Amz-Date")
  valid_605899 = validateParameter(valid_605899, JString, required = false,
                                 default = nil)
  if valid_605899 != nil:
    section.add "X-Amz-Date", valid_605899
  var valid_605900 = header.getOrDefault("X-Amz-Credential")
  valid_605900 = validateParameter(valid_605900, JString, required = false,
                                 default = nil)
  if valid_605900 != nil:
    section.add "X-Amz-Credential", valid_605900
  var valid_605901 = header.getOrDefault("X-Amz-Security-Token")
  valid_605901 = validateParameter(valid_605901, JString, required = false,
                                 default = nil)
  if valid_605901 != nil:
    section.add "X-Amz-Security-Token", valid_605901
  var valid_605902 = header.getOrDefault("X-Amz-Algorithm")
  valid_605902 = validateParameter(valid_605902, JString, required = false,
                                 default = nil)
  if valid_605902 != nil:
    section.add "X-Amz-Algorithm", valid_605902
  var valid_605903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605903 = validateParameter(valid_605903, JString, required = false,
                                 default = nil)
  if valid_605903 != nil:
    section.add "X-Amz-SignedHeaders", valid_605903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605905: Call_UpdateEndpoint_605893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_605905.validator(path, query, header, formData, body)
  let scheme = call_605905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605905.url(scheme.get, call_605905.host, call_605905.base,
                         call_605905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605905, url, valid)

proc call*(call_605906: Call_UpdateEndpoint_605893; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_605907 = newJObject()
  if body != nil:
    body_605907 = body
  result = call_605906.call(nil, nil, nil, nil, body_605907)

var updateEndpoint* = Call_UpdateEndpoint_605893(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_605894, base: "/", url: url_UpdateEndpoint_605895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_605908 = ref object of OpenApiRestCall_603389
proc url_UpdateEndpointWeightsAndCapacities_605910(protocol: Scheme; host: string;
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

proc validate_UpdateEndpointWeightsAndCapacities_605909(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605911 = header.getOrDefault("X-Amz-Target")
  valid_605911 = validateParameter(valid_605911, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_605911 != nil:
    section.add "X-Amz-Target", valid_605911
  var valid_605912 = header.getOrDefault("X-Amz-Signature")
  valid_605912 = validateParameter(valid_605912, JString, required = false,
                                 default = nil)
  if valid_605912 != nil:
    section.add "X-Amz-Signature", valid_605912
  var valid_605913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605913 = validateParameter(valid_605913, JString, required = false,
                                 default = nil)
  if valid_605913 != nil:
    section.add "X-Amz-Content-Sha256", valid_605913
  var valid_605914 = header.getOrDefault("X-Amz-Date")
  valid_605914 = validateParameter(valid_605914, JString, required = false,
                                 default = nil)
  if valid_605914 != nil:
    section.add "X-Amz-Date", valid_605914
  var valid_605915 = header.getOrDefault("X-Amz-Credential")
  valid_605915 = validateParameter(valid_605915, JString, required = false,
                                 default = nil)
  if valid_605915 != nil:
    section.add "X-Amz-Credential", valid_605915
  var valid_605916 = header.getOrDefault("X-Amz-Security-Token")
  valid_605916 = validateParameter(valid_605916, JString, required = false,
                                 default = nil)
  if valid_605916 != nil:
    section.add "X-Amz-Security-Token", valid_605916
  var valid_605917 = header.getOrDefault("X-Amz-Algorithm")
  valid_605917 = validateParameter(valid_605917, JString, required = false,
                                 default = nil)
  if valid_605917 != nil:
    section.add "X-Amz-Algorithm", valid_605917
  var valid_605918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605918 = validateParameter(valid_605918, JString, required = false,
                                 default = nil)
  if valid_605918 != nil:
    section.add "X-Amz-SignedHeaders", valid_605918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605920: Call_UpdateEndpointWeightsAndCapacities_605908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_605920.validator(path, query, header, formData, body)
  let scheme = call_605920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605920.url(scheme.get, call_605920.host, call_605920.base,
                         call_605920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605920, url, valid)

proc call*(call_605921: Call_UpdateEndpointWeightsAndCapacities_605908;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_605922 = newJObject()
  if body != nil:
    body_605922 = body
  result = call_605921.call(nil, nil, nil, nil, body_605922)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_605908(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_605909, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_605910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_605923 = ref object of OpenApiRestCall_603389
proc url_UpdateExperiment_605925(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateExperiment_605924(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605926 = header.getOrDefault("X-Amz-Target")
  valid_605926 = validateParameter(valid_605926, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_605926 != nil:
    section.add "X-Amz-Target", valid_605926
  var valid_605927 = header.getOrDefault("X-Amz-Signature")
  valid_605927 = validateParameter(valid_605927, JString, required = false,
                                 default = nil)
  if valid_605927 != nil:
    section.add "X-Amz-Signature", valid_605927
  var valid_605928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605928 = validateParameter(valid_605928, JString, required = false,
                                 default = nil)
  if valid_605928 != nil:
    section.add "X-Amz-Content-Sha256", valid_605928
  var valid_605929 = header.getOrDefault("X-Amz-Date")
  valid_605929 = validateParameter(valid_605929, JString, required = false,
                                 default = nil)
  if valid_605929 != nil:
    section.add "X-Amz-Date", valid_605929
  var valid_605930 = header.getOrDefault("X-Amz-Credential")
  valid_605930 = validateParameter(valid_605930, JString, required = false,
                                 default = nil)
  if valid_605930 != nil:
    section.add "X-Amz-Credential", valid_605930
  var valid_605931 = header.getOrDefault("X-Amz-Security-Token")
  valid_605931 = validateParameter(valid_605931, JString, required = false,
                                 default = nil)
  if valid_605931 != nil:
    section.add "X-Amz-Security-Token", valid_605931
  var valid_605932 = header.getOrDefault("X-Amz-Algorithm")
  valid_605932 = validateParameter(valid_605932, JString, required = false,
                                 default = nil)
  if valid_605932 != nil:
    section.add "X-Amz-Algorithm", valid_605932
  var valid_605933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605933 = validateParameter(valid_605933, JString, required = false,
                                 default = nil)
  if valid_605933 != nil:
    section.add "X-Amz-SignedHeaders", valid_605933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605935: Call_UpdateExperiment_605923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_605935.validator(path, query, header, formData, body)
  let scheme = call_605935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605935.url(scheme.get, call_605935.host, call_605935.base,
                         call_605935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605935, url, valid)

proc call*(call_605936: Call_UpdateExperiment_605923; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_605937 = newJObject()
  if body != nil:
    body_605937 = body
  result = call_605936.call(nil, nil, nil, nil, body_605937)

var updateExperiment* = Call_UpdateExperiment_605923(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_605924, base: "/",
    url: url_UpdateExperiment_605925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_605938 = ref object of OpenApiRestCall_603389
proc url_UpdateMonitoringSchedule_605940(protocol: Scheme; host: string;
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

proc validate_UpdateMonitoringSchedule_605939(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605941 = header.getOrDefault("X-Amz-Target")
  valid_605941 = validateParameter(valid_605941, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_605941 != nil:
    section.add "X-Amz-Target", valid_605941
  var valid_605942 = header.getOrDefault("X-Amz-Signature")
  valid_605942 = validateParameter(valid_605942, JString, required = false,
                                 default = nil)
  if valid_605942 != nil:
    section.add "X-Amz-Signature", valid_605942
  var valid_605943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605943 = validateParameter(valid_605943, JString, required = false,
                                 default = nil)
  if valid_605943 != nil:
    section.add "X-Amz-Content-Sha256", valid_605943
  var valid_605944 = header.getOrDefault("X-Amz-Date")
  valid_605944 = validateParameter(valid_605944, JString, required = false,
                                 default = nil)
  if valid_605944 != nil:
    section.add "X-Amz-Date", valid_605944
  var valid_605945 = header.getOrDefault("X-Amz-Credential")
  valid_605945 = validateParameter(valid_605945, JString, required = false,
                                 default = nil)
  if valid_605945 != nil:
    section.add "X-Amz-Credential", valid_605945
  var valid_605946 = header.getOrDefault("X-Amz-Security-Token")
  valid_605946 = validateParameter(valid_605946, JString, required = false,
                                 default = nil)
  if valid_605946 != nil:
    section.add "X-Amz-Security-Token", valid_605946
  var valid_605947 = header.getOrDefault("X-Amz-Algorithm")
  valid_605947 = validateParameter(valid_605947, JString, required = false,
                                 default = nil)
  if valid_605947 != nil:
    section.add "X-Amz-Algorithm", valid_605947
  var valid_605948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605948 = validateParameter(valid_605948, JString, required = false,
                                 default = nil)
  if valid_605948 != nil:
    section.add "X-Amz-SignedHeaders", valid_605948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605950: Call_UpdateMonitoringSchedule_605938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_605950.validator(path, query, header, formData, body)
  let scheme = call_605950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605950.url(scheme.get, call_605950.host, call_605950.base,
                         call_605950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605950, url, valid)

proc call*(call_605951: Call_UpdateMonitoringSchedule_605938; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_605952 = newJObject()
  if body != nil:
    body_605952 = body
  result = call_605951.call(nil, nil, nil, nil, body_605952)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_605938(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_605939, base: "/",
    url: url_UpdateMonitoringSchedule_605940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_605953 = ref object of OpenApiRestCall_603389
proc url_UpdateNotebookInstance_605955(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNotebookInstance_605954(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605956 = header.getOrDefault("X-Amz-Target")
  valid_605956 = validateParameter(valid_605956, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_605956 != nil:
    section.add "X-Amz-Target", valid_605956
  var valid_605957 = header.getOrDefault("X-Amz-Signature")
  valid_605957 = validateParameter(valid_605957, JString, required = false,
                                 default = nil)
  if valid_605957 != nil:
    section.add "X-Amz-Signature", valid_605957
  var valid_605958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605958 = validateParameter(valid_605958, JString, required = false,
                                 default = nil)
  if valid_605958 != nil:
    section.add "X-Amz-Content-Sha256", valid_605958
  var valid_605959 = header.getOrDefault("X-Amz-Date")
  valid_605959 = validateParameter(valid_605959, JString, required = false,
                                 default = nil)
  if valid_605959 != nil:
    section.add "X-Amz-Date", valid_605959
  var valid_605960 = header.getOrDefault("X-Amz-Credential")
  valid_605960 = validateParameter(valid_605960, JString, required = false,
                                 default = nil)
  if valid_605960 != nil:
    section.add "X-Amz-Credential", valid_605960
  var valid_605961 = header.getOrDefault("X-Amz-Security-Token")
  valid_605961 = validateParameter(valid_605961, JString, required = false,
                                 default = nil)
  if valid_605961 != nil:
    section.add "X-Amz-Security-Token", valid_605961
  var valid_605962 = header.getOrDefault("X-Amz-Algorithm")
  valid_605962 = validateParameter(valid_605962, JString, required = false,
                                 default = nil)
  if valid_605962 != nil:
    section.add "X-Amz-Algorithm", valid_605962
  var valid_605963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605963 = validateParameter(valid_605963, JString, required = false,
                                 default = nil)
  if valid_605963 != nil:
    section.add "X-Amz-SignedHeaders", valid_605963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605965: Call_UpdateNotebookInstance_605953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_605965.validator(path, query, header, formData, body)
  let scheme = call_605965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605965.url(scheme.get, call_605965.host, call_605965.base,
                         call_605965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605965, url, valid)

proc call*(call_605966: Call_UpdateNotebookInstance_605953; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_605967 = newJObject()
  if body != nil:
    body_605967 = body
  result = call_605966.call(nil, nil, nil, nil, body_605967)

var updateNotebookInstance* = Call_UpdateNotebookInstance_605953(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_605954, base: "/",
    url: url_UpdateNotebookInstance_605955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_605968 = ref object of OpenApiRestCall_603389
proc url_UpdateNotebookInstanceLifecycleConfig_605970(protocol: Scheme;
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

proc validate_UpdateNotebookInstanceLifecycleConfig_605969(path: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605971 = header.getOrDefault("X-Amz-Target")
  valid_605971 = validateParameter(valid_605971, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_605971 != nil:
    section.add "X-Amz-Target", valid_605971
  var valid_605972 = header.getOrDefault("X-Amz-Signature")
  valid_605972 = validateParameter(valid_605972, JString, required = false,
                                 default = nil)
  if valid_605972 != nil:
    section.add "X-Amz-Signature", valid_605972
  var valid_605973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605973 = validateParameter(valid_605973, JString, required = false,
                                 default = nil)
  if valid_605973 != nil:
    section.add "X-Amz-Content-Sha256", valid_605973
  var valid_605974 = header.getOrDefault("X-Amz-Date")
  valid_605974 = validateParameter(valid_605974, JString, required = false,
                                 default = nil)
  if valid_605974 != nil:
    section.add "X-Amz-Date", valid_605974
  var valid_605975 = header.getOrDefault("X-Amz-Credential")
  valid_605975 = validateParameter(valid_605975, JString, required = false,
                                 default = nil)
  if valid_605975 != nil:
    section.add "X-Amz-Credential", valid_605975
  var valid_605976 = header.getOrDefault("X-Amz-Security-Token")
  valid_605976 = validateParameter(valid_605976, JString, required = false,
                                 default = nil)
  if valid_605976 != nil:
    section.add "X-Amz-Security-Token", valid_605976
  var valid_605977 = header.getOrDefault("X-Amz-Algorithm")
  valid_605977 = validateParameter(valid_605977, JString, required = false,
                                 default = nil)
  if valid_605977 != nil:
    section.add "X-Amz-Algorithm", valid_605977
  var valid_605978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605978 = validateParameter(valid_605978, JString, required = false,
                                 default = nil)
  if valid_605978 != nil:
    section.add "X-Amz-SignedHeaders", valid_605978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605980: Call_UpdateNotebookInstanceLifecycleConfig_605968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_605980.validator(path, query, header, formData, body)
  let scheme = call_605980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605980.url(scheme.get, call_605980.host, call_605980.base,
                         call_605980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605980, url, valid)

proc call*(call_605981: Call_UpdateNotebookInstanceLifecycleConfig_605968;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_605982 = newJObject()
  if body != nil:
    body_605982 = body
  result = call_605981.call(nil, nil, nil, nil, body_605982)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_605968(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_605969, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_605970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_605983 = ref object of OpenApiRestCall_603389
proc url_UpdateTrial_605985(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrial_605984(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_605986 = header.getOrDefault("X-Amz-Target")
  valid_605986 = validateParameter(valid_605986, JString, required = true,
                                 default = newJString("SageMaker.UpdateTrial"))
  if valid_605986 != nil:
    section.add "X-Amz-Target", valid_605986
  var valid_605987 = header.getOrDefault("X-Amz-Signature")
  valid_605987 = validateParameter(valid_605987, JString, required = false,
                                 default = nil)
  if valid_605987 != nil:
    section.add "X-Amz-Signature", valid_605987
  var valid_605988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605988 = validateParameter(valid_605988, JString, required = false,
                                 default = nil)
  if valid_605988 != nil:
    section.add "X-Amz-Content-Sha256", valid_605988
  var valid_605989 = header.getOrDefault("X-Amz-Date")
  valid_605989 = validateParameter(valid_605989, JString, required = false,
                                 default = nil)
  if valid_605989 != nil:
    section.add "X-Amz-Date", valid_605989
  var valid_605990 = header.getOrDefault("X-Amz-Credential")
  valid_605990 = validateParameter(valid_605990, JString, required = false,
                                 default = nil)
  if valid_605990 != nil:
    section.add "X-Amz-Credential", valid_605990
  var valid_605991 = header.getOrDefault("X-Amz-Security-Token")
  valid_605991 = validateParameter(valid_605991, JString, required = false,
                                 default = nil)
  if valid_605991 != nil:
    section.add "X-Amz-Security-Token", valid_605991
  var valid_605992 = header.getOrDefault("X-Amz-Algorithm")
  valid_605992 = validateParameter(valid_605992, JString, required = false,
                                 default = nil)
  if valid_605992 != nil:
    section.add "X-Amz-Algorithm", valid_605992
  var valid_605993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605993 = validateParameter(valid_605993, JString, required = false,
                                 default = nil)
  if valid_605993 != nil:
    section.add "X-Amz-SignedHeaders", valid_605993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605995: Call_UpdateTrial_605983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_605995.validator(path, query, header, formData, body)
  let scheme = call_605995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605995.url(scheme.get, call_605995.host, call_605995.base,
                         call_605995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605995, url, valid)

proc call*(call_605996: Call_UpdateTrial_605983; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_605997 = newJObject()
  if body != nil:
    body_605997 = body
  result = call_605996.call(nil, nil, nil, nil, body_605997)

var updateTrial* = Call_UpdateTrial_605983(name: "updateTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.UpdateTrial",
                                        validator: validate_UpdateTrial_605984,
                                        base: "/", url: url_UpdateTrial_605985,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_605998 = ref object of OpenApiRestCall_603389
proc url_UpdateTrialComponent_606000(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrialComponent_605999(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606001 = header.getOrDefault("X-Amz-Target")
  valid_606001 = validateParameter(valid_606001, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_606001 != nil:
    section.add "X-Amz-Target", valid_606001
  var valid_606002 = header.getOrDefault("X-Amz-Signature")
  valid_606002 = validateParameter(valid_606002, JString, required = false,
                                 default = nil)
  if valid_606002 != nil:
    section.add "X-Amz-Signature", valid_606002
  var valid_606003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606003 = validateParameter(valid_606003, JString, required = false,
                                 default = nil)
  if valid_606003 != nil:
    section.add "X-Amz-Content-Sha256", valid_606003
  var valid_606004 = header.getOrDefault("X-Amz-Date")
  valid_606004 = validateParameter(valid_606004, JString, required = false,
                                 default = nil)
  if valid_606004 != nil:
    section.add "X-Amz-Date", valid_606004
  var valid_606005 = header.getOrDefault("X-Amz-Credential")
  valid_606005 = validateParameter(valid_606005, JString, required = false,
                                 default = nil)
  if valid_606005 != nil:
    section.add "X-Amz-Credential", valid_606005
  var valid_606006 = header.getOrDefault("X-Amz-Security-Token")
  valid_606006 = validateParameter(valid_606006, JString, required = false,
                                 default = nil)
  if valid_606006 != nil:
    section.add "X-Amz-Security-Token", valid_606006
  var valid_606007 = header.getOrDefault("X-Amz-Algorithm")
  valid_606007 = validateParameter(valid_606007, JString, required = false,
                                 default = nil)
  if valid_606007 != nil:
    section.add "X-Amz-Algorithm", valid_606007
  var valid_606008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606008 = validateParameter(valid_606008, JString, required = false,
                                 default = nil)
  if valid_606008 != nil:
    section.add "X-Amz-SignedHeaders", valid_606008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606010: Call_UpdateTrialComponent_605998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_606010.validator(path, query, header, formData, body)
  let scheme = call_606010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606010.url(scheme.get, call_606010.host, call_606010.base,
                         call_606010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606010, url, valid)

proc call*(call_606011: Call_UpdateTrialComponent_605998; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_606012 = newJObject()
  if body != nil:
    body_606012 = body
  result = call_606011.call(nil, nil, nil, nil, body_606012)

var updateTrialComponent* = Call_UpdateTrialComponent_605998(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_605999, base: "/",
    url: url_UpdateTrialComponent_606000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_606013 = ref object of OpenApiRestCall_603389
proc url_UpdateUserProfile_606015(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateUserProfile_606014(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606016 = header.getOrDefault("X-Amz-Target")
  valid_606016 = validateParameter(valid_606016, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_606016 != nil:
    section.add "X-Amz-Target", valid_606016
  var valid_606017 = header.getOrDefault("X-Amz-Signature")
  valid_606017 = validateParameter(valid_606017, JString, required = false,
                                 default = nil)
  if valid_606017 != nil:
    section.add "X-Amz-Signature", valid_606017
  var valid_606018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606018 = validateParameter(valid_606018, JString, required = false,
                                 default = nil)
  if valid_606018 != nil:
    section.add "X-Amz-Content-Sha256", valid_606018
  var valid_606019 = header.getOrDefault("X-Amz-Date")
  valid_606019 = validateParameter(valid_606019, JString, required = false,
                                 default = nil)
  if valid_606019 != nil:
    section.add "X-Amz-Date", valid_606019
  var valid_606020 = header.getOrDefault("X-Amz-Credential")
  valid_606020 = validateParameter(valid_606020, JString, required = false,
                                 default = nil)
  if valid_606020 != nil:
    section.add "X-Amz-Credential", valid_606020
  var valid_606021 = header.getOrDefault("X-Amz-Security-Token")
  valid_606021 = validateParameter(valid_606021, JString, required = false,
                                 default = nil)
  if valid_606021 != nil:
    section.add "X-Amz-Security-Token", valid_606021
  var valid_606022 = header.getOrDefault("X-Amz-Algorithm")
  valid_606022 = validateParameter(valid_606022, JString, required = false,
                                 default = nil)
  if valid_606022 != nil:
    section.add "X-Amz-Algorithm", valid_606022
  var valid_606023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606023 = validateParameter(valid_606023, JString, required = false,
                                 default = nil)
  if valid_606023 != nil:
    section.add "X-Amz-SignedHeaders", valid_606023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606025: Call_UpdateUserProfile_606013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_606025.validator(path, query, header, formData, body)
  let scheme = call_606025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606025.url(scheme.get, call_606025.host, call_606025.base,
                         call_606025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606025, url, valid)

proc call*(call_606026: Call_UpdateUserProfile_606013; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_606027 = newJObject()
  if body != nil:
    body_606027 = body
  result = call_606026.call(nil, nil, nil, nil, body_606027)

var updateUserProfile* = Call_UpdateUserProfile_606013(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_606014, base: "/",
    url: url_UpdateUserProfile_606015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_606028 = ref object of OpenApiRestCall_603389
proc url_UpdateWorkteam_606030(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkteam_606029(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606031 = header.getOrDefault("X-Amz-Target")
  valid_606031 = validateParameter(valid_606031, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_606031 != nil:
    section.add "X-Amz-Target", valid_606031
  var valid_606032 = header.getOrDefault("X-Amz-Signature")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "X-Amz-Signature", valid_606032
  var valid_606033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "X-Amz-Content-Sha256", valid_606033
  var valid_606034 = header.getOrDefault("X-Amz-Date")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "X-Amz-Date", valid_606034
  var valid_606035 = header.getOrDefault("X-Amz-Credential")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "X-Amz-Credential", valid_606035
  var valid_606036 = header.getOrDefault("X-Amz-Security-Token")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-Security-Token", valid_606036
  var valid_606037 = header.getOrDefault("X-Amz-Algorithm")
  valid_606037 = validateParameter(valid_606037, JString, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "X-Amz-Algorithm", valid_606037
  var valid_606038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-SignedHeaders", valid_606038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606040: Call_UpdateWorkteam_606028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_606040.validator(path, query, header, formData, body)
  let scheme = call_606040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606040.url(scheme.get, call_606040.host, call_606040.base,
                         call_606040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606040, url, valid)

proc call*(call_606041: Call_UpdateWorkteam_606028; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_606042 = newJObject()
  if body != nil:
    body_606042 = body
  result = call_606041.call(nil, nil, nil, nil, body_606042)

var updateWorkteam* = Call_UpdateWorkteam_606028(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_606029, base: "/", url: url_UpdateWorkteam_606030,
    schemes: {Scheme.Https, Scheme.Http})
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
