
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
  Call_AddTags_605927 = ref object of OpenApiRestCall_605589
proc url_AddTags_605929(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
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

proc call*(call_606085: Call_AddTags_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AddTags_605927; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var addTags* = Call_AddTags_605927(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_605928, base: "/",
                                url: url_AddTags_605929,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_606196 = ref object of OpenApiRestCall_605589
proc url_AssociateTrialComponent_606198(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateTrialComponent_606197(path: JsonNode; query: JsonNode;
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
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
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

proc call*(call_606208: Call_AssociateTrialComponent_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_AssociateTrialComponent_606196; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var associateTrialComponent* = Call_AssociateTrialComponent_606196(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_606197, base: "/",
    url: url_AssociateTrialComponent_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_606211 = ref object of OpenApiRestCall_605589
proc url_CreateAlgorithm_606213(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlgorithm_606212(path: JsonNode; query: JsonNode;
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
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
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

proc call*(call_606223: Call_CreateAlgorithm_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateAlgorithm_606211; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createAlgorithm* = Call_CreateAlgorithm_606211(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_606212, base: "/", url: url_CreateAlgorithm_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_606226 = ref object of OpenApiRestCall_605589
proc url_CreateApp_606228(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_606227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true,
                                 default = newJString("SageMaker.CreateApp"))
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

proc call*(call_606238: Call_CreateApp_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateApp_606226; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createApp* = Call_CreateApp_606226(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                    validator: validate_CreateApp_606227,
                                    base: "/", url: url_CreateApp_606228,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_606241 = ref object of OpenApiRestCall_605589
proc url_CreateAutoMLJob_606243(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAutoMLJob_606242(path: JsonNode; query: JsonNode;
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
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
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

proc call*(call_606253: Call_CreateAutoMLJob_606241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_CreateAutoMLJob_606241; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var createAutoMLJob* = Call_CreateAutoMLJob_606241(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_606242, base: "/", url: url_CreateAutoMLJob_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_606256 = ref object of OpenApiRestCall_605589
proc url_CreateCodeRepository_606258(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCodeRepository_606257(path: JsonNode; query: JsonNode;
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
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
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

proc call*(call_606268: Call_CreateCodeRepository_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_CreateCodeRepository_606256; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var createCodeRepository* = Call_CreateCodeRepository_606256(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_606257, base: "/",
    url: url_CreateCodeRepository_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_606271 = ref object of OpenApiRestCall_605589
proc url_CreateCompilationJob_606273(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCompilationJob_606272(path: JsonNode; query: JsonNode;
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
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
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

proc call*(call_606283: Call_CreateCompilationJob_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_CreateCompilationJob_606271; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var createCompilationJob* = Call_CreateCompilationJob_606271(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_606272, base: "/",
    url: url_CreateCompilationJob_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_606286 = ref object of OpenApiRestCall_605589
proc url_CreateDomain_606288(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_606287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true,
                                 default = newJString("SageMaker.CreateDomain"))
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

proc call*(call_606298: Call_CreateDomain_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_CreateDomain_606286; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var createDomain* = Call_CreateDomain_606286(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_606287, base: "/", url: url_CreateDomain_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_606301 = ref object of OpenApiRestCall_605589
proc url_CreateEndpoint_606303(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_606302(path: JsonNode; query: JsonNode;
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
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
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

proc call*(call_606313: Call_CreateEndpoint_606301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateEndpoint_606301; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createEndpoint* = Call_CreateEndpoint_606301(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_606302, base: "/", url: url_CreateEndpoint_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_606316 = ref object of OpenApiRestCall_605589
proc url_CreateEndpointConfig_606318(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpointConfig_606317(path: JsonNode; query: JsonNode;
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
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
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

proc call*(call_606328: Call_CreateEndpointConfig_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_CreateEndpointConfig_606316; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var createEndpointConfig* = Call_CreateEndpointConfig_606316(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_606317, base: "/",
    url: url_CreateEndpointConfig_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_606331 = ref object of OpenApiRestCall_605589
proc url_CreateExperiment_606333(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExperiment_606332(path: JsonNode; query: JsonNode;
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
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
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

proc call*(call_606343: Call_CreateExperiment_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_CreateExperiment_606331; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var createExperiment* = Call_CreateExperiment_606331(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_606332, base: "/",
    url: url_CreateExperiment_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_606346 = ref object of OpenApiRestCall_605589
proc url_CreateFlowDefinition_606348(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowDefinition_606347(path: JsonNode; query: JsonNode;
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
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_CreateFlowDefinition_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_CreateFlowDefinition_606346; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var createFlowDefinition* = Call_CreateFlowDefinition_606346(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_606347, base: "/",
    url: url_CreateFlowDefinition_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_606361 = ref object of OpenApiRestCall_605589
proc url_CreateHumanTaskUi_606363(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHumanTaskUi_606362(path: JsonNode; query: JsonNode;
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
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CreateHumanTaskUi_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CreateHumanTaskUi_606361; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var createHumanTaskUi* = Call_CreateHumanTaskUi_606361(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_606362, base: "/",
    url: url_CreateHumanTaskUi_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_606376 = ref object of OpenApiRestCall_605589
proc url_CreateHyperParameterTuningJob_606378(protocol: Scheme; host: string;
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

proc validate_CreateHyperParameterTuningJob_606377(path: JsonNode; query: JsonNode;
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
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_CreateHyperParameterTuningJob_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_CreateHyperParameterTuningJob_606376; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_606376(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_606377, base: "/",
    url: url_CreateHyperParameterTuningJob_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_606391 = ref object of OpenApiRestCall_605589
proc url_CreateLabelingJob_606393(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLabelingJob_606392(path: JsonNode; query: JsonNode;
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
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_CreateLabelingJob_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_CreateLabelingJob_606391; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var createLabelingJob* = Call_CreateLabelingJob_606391(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_606392, base: "/",
    url: url_CreateLabelingJob_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_606406 = ref object of OpenApiRestCall_605589
proc url_CreateModel_606408(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModel_606407(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_CreateModel_606406; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_CreateModel_606406; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var createModel* = Call_CreateModel_606406(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_606407,
                                        base: "/", url: url_CreateModel_606408,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_606421 = ref object of OpenApiRestCall_605589
proc url_CreateModelPackage_606423(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelPackage_606422(path: JsonNode; query: JsonNode;
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
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_CreateModelPackage_606421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_CreateModelPackage_606421; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var createModelPackage* = Call_CreateModelPackage_606421(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_606422, base: "/",
    url: url_CreateModelPackage_606423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_606436 = ref object of OpenApiRestCall_605589
proc url_CreateMonitoringSchedule_606438(protocol: Scheme; host: string;
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

proc validate_CreateMonitoringSchedule_606437(path: JsonNode; query: JsonNode;
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
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
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

proc call*(call_606448: Call_CreateMonitoringSchedule_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_CreateMonitoringSchedule_606436; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_606436(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_606437, base: "/",
    url: url_CreateMonitoringSchedule_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_606451 = ref object of OpenApiRestCall_605589
proc url_CreateNotebookInstance_606453(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstance_606452(path: JsonNode; query: JsonNode;
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
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_CreateNotebookInstance_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_CreateNotebookInstance_606451; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var createNotebookInstance* = Call_CreateNotebookInstance_606451(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_606452, base: "/",
    url: url_CreateNotebookInstance_606453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_606466 = ref object of OpenApiRestCall_605589
proc url_CreateNotebookInstanceLifecycleConfig_606468(protocol: Scheme;
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

proc validate_CreateNotebookInstanceLifecycleConfig_606467(path: JsonNode;
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
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_CreateNotebookInstanceLifecycleConfig_606466;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_CreateNotebookInstanceLifecycleConfig_606466;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_606466(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_606467, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_606468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_606481 = ref object of OpenApiRestCall_605589
proc url_CreatePresignedDomainUrl_606483(protocol: Scheme; host: string;
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

proc validate_CreatePresignedDomainUrl_606482(path: JsonNode; query: JsonNode;
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
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_CreatePresignedDomainUrl_606481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_CreatePresignedDomainUrl_606481; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_606481(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_606482, base: "/",
    url: url_CreatePresignedDomainUrl_606483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_606496 = ref object of OpenApiRestCall_605589
proc url_CreatePresignedNotebookInstanceUrl_606498(protocol: Scheme; host: string;
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

proc validate_CreatePresignedNotebookInstanceUrl_606497(path: JsonNode;
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
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_CreatePresignedNotebookInstanceUrl_606496;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_CreatePresignedNotebookInstanceUrl_606496;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_606496(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_606497, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_606498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_606511 = ref object of OpenApiRestCall_605589
proc url_CreateProcessingJob_606513(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProcessingJob_606512(path: JsonNode; query: JsonNode;
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
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_CreateProcessingJob_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_CreateProcessingJob_606511; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var createProcessingJob* = Call_CreateProcessingJob_606511(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_606512, base: "/",
    url: url_CreateProcessingJob_606513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_606526 = ref object of OpenApiRestCall_605589
proc url_CreateTrainingJob_606528(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrainingJob_606527(path: JsonNode; query: JsonNode;
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
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_CreateTrainingJob_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_CreateTrainingJob_606526; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var createTrainingJob* = Call_CreateTrainingJob_606526(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_606527, base: "/",
    url: url_CreateTrainingJob_606528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_606541 = ref object of OpenApiRestCall_605589
proc url_CreateTransformJob_606543(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransformJob_606542(path: JsonNode; query: JsonNode;
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
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_CreateTransformJob_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_CreateTransformJob_606541; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var createTransformJob* = Call_CreateTransformJob_606541(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_606542, base: "/",
    url: url_CreateTransformJob_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_606556 = ref object of OpenApiRestCall_605589
proc url_CreateTrial_606558(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrial_606557(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true,
                                 default = newJString("SageMaker.CreateTrial"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_CreateTrial_606556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_CreateTrial_606556; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var createTrial* = Call_CreateTrial_606556(name: "createTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateTrial",
                                        validator: validate_CreateTrial_606557,
                                        base: "/", url: url_CreateTrial_606558,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_606571 = ref object of OpenApiRestCall_605589
proc url_CreateTrialComponent_606573(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrialComponent_606572(path: JsonNode; query: JsonNode;
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
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_CreateTrialComponent_606571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_CreateTrialComponent_606571; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p> <code>CreateTrialComponent</code> can only be invoked from within an Amazon SageMaker managed environment. This includes Amazon SageMaker training jobs, processing jobs, transform jobs, and Amazon SageMaker notebooks. A call to <code>CreateTrialComponent</code> from outside one of these environments results in an error.</p> </note>
  ##   body: JObject (required)
  var body_606585 = newJObject()
  if body != nil:
    body_606585 = body
  result = call_606584.call(nil, nil, nil, nil, body_606585)

var createTrialComponent* = Call_CreateTrialComponent_606571(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_606572, base: "/",
    url: url_CreateTrialComponent_606573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_606586 = ref object of OpenApiRestCall_605589
proc url_CreateUserProfile_606588(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserProfile_606587(path: JsonNode; query: JsonNode;
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
  var valid_606589 = header.getOrDefault("X-Amz-Target")
  valid_606589 = validateParameter(valid_606589, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_606589 != nil:
    section.add "X-Amz-Target", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_CreateUserProfile_606586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_CreateUserProfile_606586; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_606600 = newJObject()
  if body != nil:
    body_606600 = body
  result = call_606599.call(nil, nil, nil, nil, body_606600)

var createUserProfile* = Call_CreateUserProfile_606586(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_606587, base: "/",
    url: url_CreateUserProfile_606588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_606601 = ref object of OpenApiRestCall_605589
proc url_CreateWorkteam_606603(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkteam_606602(path: JsonNode; query: JsonNode;
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
  var valid_606604 = header.getOrDefault("X-Amz-Target")
  valid_606604 = validateParameter(valid_606604, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_606604 != nil:
    section.add "X-Amz-Target", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_CreateWorkteam_606601; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_CreateWorkteam_606601; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_606615 = newJObject()
  if body != nil:
    body_606615 = body
  result = call_606614.call(nil, nil, nil, nil, body_606615)

var createWorkteam* = Call_CreateWorkteam_606601(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_606602, base: "/", url: url_CreateWorkteam_606603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_606616 = ref object of OpenApiRestCall_605589
proc url_DeleteAlgorithm_606618(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlgorithm_606617(path: JsonNode; query: JsonNode;
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
  var valid_606619 = header.getOrDefault("X-Amz-Target")
  valid_606619 = validateParameter(valid_606619, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_606619 != nil:
    section.add "X-Amz-Target", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_DeleteAlgorithm_606616; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_DeleteAlgorithm_606616; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_606630 = newJObject()
  if body != nil:
    body_606630 = body
  result = call_606629.call(nil, nil, nil, nil, body_606630)

var deleteAlgorithm* = Call_DeleteAlgorithm_606616(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_606617, base: "/", url: url_DeleteAlgorithm_606618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_606631 = ref object of OpenApiRestCall_605589
proc url_DeleteApp_606633(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_606632(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606634 = header.getOrDefault("X-Amz-Target")
  valid_606634 = validateParameter(valid_606634, JString, required = true,
                                 default = newJString("SageMaker.DeleteApp"))
  if valid_606634 != nil:
    section.add "X-Amz-Target", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Signature")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Signature", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Content-Sha256", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Date")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Date", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Credential")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Credential", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Security-Token")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Security-Token", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Algorithm")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Algorithm", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-SignedHeaders", valid_606641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606643: Call_DeleteApp_606631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_606643.validator(path, query, header, formData, body)
  let scheme = call_606643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606643.url(scheme.get, call_606643.host, call_606643.base,
                         call_606643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606643, url, valid)

proc call*(call_606644: Call_DeleteApp_606631; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_606645 = newJObject()
  if body != nil:
    body_606645 = body
  result = call_606644.call(nil, nil, nil, nil, body_606645)

var deleteApp* = Call_DeleteApp_606631(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                    validator: validate_DeleteApp_606632,
                                    base: "/", url: url_DeleteApp_606633,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_606646 = ref object of OpenApiRestCall_605589
proc url_DeleteCodeRepository_606648(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCodeRepository_606647(path: JsonNode; query: JsonNode;
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
  var valid_606649 = header.getOrDefault("X-Amz-Target")
  valid_606649 = validateParameter(valid_606649, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_606649 != nil:
    section.add "X-Amz-Target", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Signature")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Signature", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Content-Sha256", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Date")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Date", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Credential")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Credential", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Security-Token")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Security-Token", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Algorithm")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Algorithm", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-SignedHeaders", valid_606656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606658: Call_DeleteCodeRepository_606646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_606658.validator(path, query, header, formData, body)
  let scheme = call_606658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606658.url(scheme.get, call_606658.host, call_606658.base,
                         call_606658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606658, url, valid)

proc call*(call_606659: Call_DeleteCodeRepository_606646; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_606660 = newJObject()
  if body != nil:
    body_606660 = body
  result = call_606659.call(nil, nil, nil, nil, body_606660)

var deleteCodeRepository* = Call_DeleteCodeRepository_606646(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_606647, base: "/",
    url: url_DeleteCodeRepository_606648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_606661 = ref object of OpenApiRestCall_605589
proc url_DeleteDomain_606663(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_606662(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606664 = header.getOrDefault("X-Amz-Target")
  valid_606664 = validateParameter(valid_606664, JString, required = true,
                                 default = newJString("SageMaker.DeleteDomain"))
  if valid_606664 != nil:
    section.add "X-Amz-Target", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Signature")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Signature", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Content-Sha256", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Date")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Date", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-Credential")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-Credential", valid_606668
  var valid_606669 = header.getOrDefault("X-Amz-Security-Token")
  valid_606669 = validateParameter(valid_606669, JString, required = false,
                                 default = nil)
  if valid_606669 != nil:
    section.add "X-Amz-Security-Token", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Algorithm")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Algorithm", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-SignedHeaders", valid_606671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606673: Call_DeleteDomain_606661; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_606673.validator(path, query, header, formData, body)
  let scheme = call_606673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606673.url(scheme.get, call_606673.host, call_606673.base,
                         call_606673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606673, url, valid)

proc call*(call_606674: Call_DeleteDomain_606661; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_606675 = newJObject()
  if body != nil:
    body_606675 = body
  result = call_606674.call(nil, nil, nil, nil, body_606675)

var deleteDomain* = Call_DeleteDomain_606661(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_606662, base: "/", url: url_DeleteDomain_606663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_606676 = ref object of OpenApiRestCall_605589
proc url_DeleteEndpoint_606678(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_606677(path: JsonNode; query: JsonNode;
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
  var valid_606679 = header.getOrDefault("X-Amz-Target")
  valid_606679 = validateParameter(valid_606679, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_606679 != nil:
    section.add "X-Amz-Target", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Signature")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Signature", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Content-Sha256", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Date")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Date", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Credential")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Credential", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-Security-Token")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-Security-Token", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Algorithm")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Algorithm", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-SignedHeaders", valid_606686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606688: Call_DeleteEndpoint_606676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_606688.validator(path, query, header, formData, body)
  let scheme = call_606688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606688.url(scheme.get, call_606688.host, call_606688.base,
                         call_606688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606688, url, valid)

proc call*(call_606689: Call_DeleteEndpoint_606676; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_606690 = newJObject()
  if body != nil:
    body_606690 = body
  result = call_606689.call(nil, nil, nil, nil, body_606690)

var deleteEndpoint* = Call_DeleteEndpoint_606676(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_606677, base: "/", url: url_DeleteEndpoint_606678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_606691 = ref object of OpenApiRestCall_605589
proc url_DeleteEndpointConfig_606693(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpointConfig_606692(path: JsonNode; query: JsonNode;
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
  var valid_606694 = header.getOrDefault("X-Amz-Target")
  valid_606694 = validateParameter(valid_606694, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_606694 != nil:
    section.add "X-Amz-Target", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606703: Call_DeleteEndpointConfig_606691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_606703.validator(path, query, header, formData, body)
  let scheme = call_606703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606703.url(scheme.get, call_606703.host, call_606703.base,
                         call_606703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606703, url, valid)

proc call*(call_606704: Call_DeleteEndpointConfig_606691; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_606705 = newJObject()
  if body != nil:
    body_606705 = body
  result = call_606704.call(nil, nil, nil, nil, body_606705)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_606691(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_606692, base: "/",
    url: url_DeleteEndpointConfig_606693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_606706 = ref object of OpenApiRestCall_605589
proc url_DeleteExperiment_606708(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteExperiment_606707(path: JsonNode; query: JsonNode;
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
  var valid_606709 = header.getOrDefault("X-Amz-Target")
  valid_606709 = validateParameter(valid_606709, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_606709 != nil:
    section.add "X-Amz-Target", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Signature")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Signature", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Content-Sha256", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Date")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Date", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Credential")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Credential", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Security-Token")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Security-Token", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Algorithm")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Algorithm", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-SignedHeaders", valid_606716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606718: Call_DeleteExperiment_606706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_606718.validator(path, query, header, formData, body)
  let scheme = call_606718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606718.url(scheme.get, call_606718.host, call_606718.base,
                         call_606718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606718, url, valid)

proc call*(call_606719: Call_DeleteExperiment_606706; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_606720 = newJObject()
  if body != nil:
    body_606720 = body
  result = call_606719.call(nil, nil, nil, nil, body_606720)

var deleteExperiment* = Call_DeleteExperiment_606706(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_606707, base: "/",
    url: url_DeleteExperiment_606708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_606721 = ref object of OpenApiRestCall_605589
proc url_DeleteFlowDefinition_606723(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowDefinition_606722(path: JsonNode; query: JsonNode;
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
  var valid_606724 = header.getOrDefault("X-Amz-Target")
  valid_606724 = validateParameter(valid_606724, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_606724 != nil:
    section.add "X-Amz-Target", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Signature")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Signature", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Content-Sha256", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Date")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Date", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Credential")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Credential", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Security-Token")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Security-Token", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Algorithm")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Algorithm", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-SignedHeaders", valid_606731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_DeleteFlowDefinition_606721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_DeleteFlowDefinition_606721; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_606735 = newJObject()
  if body != nil:
    body_606735 = body
  result = call_606734.call(nil, nil, nil, nil, body_606735)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_606721(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_606722, base: "/",
    url: url_DeleteFlowDefinition_606723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_606736 = ref object of OpenApiRestCall_605589
proc url_DeleteModel_606738(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModel_606737(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606739 = header.getOrDefault("X-Amz-Target")
  valid_606739 = validateParameter(valid_606739, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_606739 != nil:
    section.add "X-Amz-Target", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Signature")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Signature", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Content-Sha256", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Date")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Date", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Credential")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Credential", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Security-Token")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Security-Token", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Algorithm")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Algorithm", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-SignedHeaders", valid_606746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_DeleteModel_606736; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_DeleteModel_606736; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_606750 = newJObject()
  if body != nil:
    body_606750 = body
  result = call_606749.call(nil, nil, nil, nil, body_606750)

var deleteModel* = Call_DeleteModel_606736(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_606737,
                                        base: "/", url: url_DeleteModel_606738,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_606751 = ref object of OpenApiRestCall_605589
proc url_DeleteModelPackage_606753(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModelPackage_606752(path: JsonNode; query: JsonNode;
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
  var valid_606754 = header.getOrDefault("X-Amz-Target")
  valid_606754 = validateParameter(valid_606754, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_606754 != nil:
    section.add "X-Amz-Target", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Signature")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Signature", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Content-Sha256", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Date")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Date", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Credential")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Credential", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Security-Token")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Security-Token", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Algorithm")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Algorithm", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-SignedHeaders", valid_606761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606763: Call_DeleteModelPackage_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_606763.validator(path, query, header, formData, body)
  let scheme = call_606763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606763.url(scheme.get, call_606763.host, call_606763.base,
                         call_606763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606763, url, valid)

proc call*(call_606764: Call_DeleteModelPackage_606751; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_606765 = newJObject()
  if body != nil:
    body_606765 = body
  result = call_606764.call(nil, nil, nil, nil, body_606765)

var deleteModelPackage* = Call_DeleteModelPackage_606751(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_606752, base: "/",
    url: url_DeleteModelPackage_606753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_606766 = ref object of OpenApiRestCall_605589
proc url_DeleteMonitoringSchedule_606768(protocol: Scheme; host: string;
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

proc validate_DeleteMonitoringSchedule_606767(path: JsonNode; query: JsonNode;
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
  var valid_606769 = header.getOrDefault("X-Amz-Target")
  valid_606769 = validateParameter(valid_606769, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_606769 != nil:
    section.add "X-Amz-Target", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Signature")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Signature", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Content-Sha256", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Date")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Date", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Credential")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Credential", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Security-Token")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Security-Token", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Algorithm")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Algorithm", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-SignedHeaders", valid_606776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606778: Call_DeleteMonitoringSchedule_606766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_606778.validator(path, query, header, formData, body)
  let scheme = call_606778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606778.url(scheme.get, call_606778.host, call_606778.base,
                         call_606778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606778, url, valid)

proc call*(call_606779: Call_DeleteMonitoringSchedule_606766; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_606780 = newJObject()
  if body != nil:
    body_606780 = body
  result = call_606779.call(nil, nil, nil, nil, body_606780)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_606766(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_606767, base: "/",
    url: url_DeleteMonitoringSchedule_606768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_606781 = ref object of OpenApiRestCall_605589
proc url_DeleteNotebookInstance_606783(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstance_606782(path: JsonNode; query: JsonNode;
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
  var valid_606784 = header.getOrDefault("X-Amz-Target")
  valid_606784 = validateParameter(valid_606784, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_606784 != nil:
    section.add "X-Amz-Target", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Signature")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Signature", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Content-Sha256", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Date")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Date", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Credential")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Credential", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Security-Token")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Security-Token", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Algorithm")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Algorithm", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-SignedHeaders", valid_606791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606793: Call_DeleteNotebookInstance_606781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_606793.validator(path, query, header, formData, body)
  let scheme = call_606793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606793.url(scheme.get, call_606793.host, call_606793.base,
                         call_606793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606793, url, valid)

proc call*(call_606794: Call_DeleteNotebookInstance_606781; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_606795 = newJObject()
  if body != nil:
    body_606795 = body
  result = call_606794.call(nil, nil, nil, nil, body_606795)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_606781(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_606782, base: "/",
    url: url_DeleteNotebookInstance_606783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_606796 = ref object of OpenApiRestCall_605589
proc url_DeleteNotebookInstanceLifecycleConfig_606798(protocol: Scheme;
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

proc validate_DeleteNotebookInstanceLifecycleConfig_606797(path: JsonNode;
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
  var valid_606799 = header.getOrDefault("X-Amz-Target")
  valid_606799 = validateParameter(valid_606799, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_606799 != nil:
    section.add "X-Amz-Target", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Signature")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Signature", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Content-Sha256", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Date")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Date", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Credential")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Credential", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-Security-Token")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Security-Token", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Algorithm")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Algorithm", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-SignedHeaders", valid_606806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606808: Call_DeleteNotebookInstanceLifecycleConfig_606796;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_606808.validator(path, query, header, formData, body)
  let scheme = call_606808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606808.url(scheme.get, call_606808.host, call_606808.base,
                         call_606808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606808, url, valid)

proc call*(call_606809: Call_DeleteNotebookInstanceLifecycleConfig_606796;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_606810 = newJObject()
  if body != nil:
    body_606810 = body
  result = call_606809.call(nil, nil, nil, nil, body_606810)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_606796(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_606797, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_606798,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_606811 = ref object of OpenApiRestCall_605589
proc url_DeleteTags_606813(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_606812(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606814 = header.getOrDefault("X-Amz-Target")
  valid_606814 = validateParameter(valid_606814, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_606814 != nil:
    section.add "X-Amz-Target", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Signature")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Signature", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Content-Sha256", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Date")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Date", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Credential")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Credential", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Security-Token")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Security-Token", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Algorithm")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Algorithm", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-SignedHeaders", valid_606821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606823: Call_DeleteTags_606811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_606823.validator(path, query, header, formData, body)
  let scheme = call_606823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606823.url(scheme.get, call_606823.host, call_606823.base,
                         call_606823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606823, url, valid)

proc call*(call_606824: Call_DeleteTags_606811; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_606825 = newJObject()
  if body != nil:
    body_606825 = body
  result = call_606824.call(nil, nil, nil, nil, body_606825)

var deleteTags* = Call_DeleteTags_606811(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_606812,
                                      base: "/", url: url_DeleteTags_606813,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_606826 = ref object of OpenApiRestCall_605589
proc url_DeleteTrial_606828(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrial_606827(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606829 = header.getOrDefault("X-Amz-Target")
  valid_606829 = validateParameter(valid_606829, JString, required = true,
                                 default = newJString("SageMaker.DeleteTrial"))
  if valid_606829 != nil:
    section.add "X-Amz-Target", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606838: Call_DeleteTrial_606826; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_606838.validator(path, query, header, formData, body)
  let scheme = call_606838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606838.url(scheme.get, call_606838.host, call_606838.base,
                         call_606838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606838, url, valid)

proc call*(call_606839: Call_DeleteTrial_606826; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_606840 = newJObject()
  if body != nil:
    body_606840 = body
  result = call_606839.call(nil, nil, nil, nil, body_606840)

var deleteTrial* = Call_DeleteTrial_606826(name: "deleteTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTrial",
                                        validator: validate_DeleteTrial_606827,
                                        base: "/", url: url_DeleteTrial_606828,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_606841 = ref object of OpenApiRestCall_605589
proc url_DeleteTrialComponent_606843(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrialComponent_606842(path: JsonNode; query: JsonNode;
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
  var valid_606844 = header.getOrDefault("X-Amz-Target")
  valid_606844 = validateParameter(valid_606844, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_606844 != nil:
    section.add "X-Amz-Target", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Signature")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Signature", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Content-Sha256", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Date")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Date", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Credential")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Credential", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Security-Token")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Security-Token", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Algorithm")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Algorithm", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-SignedHeaders", valid_606851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606853: Call_DeleteTrialComponent_606841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_606853.validator(path, query, header, formData, body)
  let scheme = call_606853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606853.url(scheme.get, call_606853.host, call_606853.base,
                         call_606853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606853, url, valid)

proc call*(call_606854: Call_DeleteTrialComponent_606841; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_606855 = newJObject()
  if body != nil:
    body_606855 = body
  result = call_606854.call(nil, nil, nil, nil, body_606855)

var deleteTrialComponent* = Call_DeleteTrialComponent_606841(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_606842, base: "/",
    url: url_DeleteTrialComponent_606843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_606856 = ref object of OpenApiRestCall_605589
proc url_DeleteUserProfile_606858(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserProfile_606857(path: JsonNode; query: JsonNode;
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
  var valid_606859 = header.getOrDefault("X-Amz-Target")
  valid_606859 = validateParameter(valid_606859, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_606859 != nil:
    section.add "X-Amz-Target", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Signature")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Signature", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Content-Sha256", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Date")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Date", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Credential")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Credential", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Security-Token")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Security-Token", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Algorithm")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Algorithm", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-SignedHeaders", valid_606866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606868: Call_DeleteUserProfile_606856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_606868.validator(path, query, header, formData, body)
  let scheme = call_606868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606868.url(scheme.get, call_606868.host, call_606868.base,
                         call_606868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606868, url, valid)

proc call*(call_606869: Call_DeleteUserProfile_606856; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_606870 = newJObject()
  if body != nil:
    body_606870 = body
  result = call_606869.call(nil, nil, nil, nil, body_606870)

var deleteUserProfile* = Call_DeleteUserProfile_606856(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_606857, base: "/",
    url: url_DeleteUserProfile_606858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_606871 = ref object of OpenApiRestCall_605589
proc url_DeleteWorkteam_606873(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkteam_606872(path: JsonNode; query: JsonNode;
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
  var valid_606874 = header.getOrDefault("X-Amz-Target")
  valid_606874 = validateParameter(valid_606874, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_606874 != nil:
    section.add "X-Amz-Target", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Signature")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Signature", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Content-Sha256", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Date")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Date", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Credential")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Credential", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Security-Token")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Security-Token", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-Algorithm")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-Algorithm", valid_606880
  var valid_606881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-SignedHeaders", valid_606881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606883: Call_DeleteWorkteam_606871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_606883.validator(path, query, header, formData, body)
  let scheme = call_606883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606883.url(scheme.get, call_606883.host, call_606883.base,
                         call_606883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606883, url, valid)

proc call*(call_606884: Call_DeleteWorkteam_606871; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_606885 = newJObject()
  if body != nil:
    body_606885 = body
  result = call_606884.call(nil, nil, nil, nil, body_606885)

var deleteWorkteam* = Call_DeleteWorkteam_606871(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_606872, base: "/", url: url_DeleteWorkteam_606873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_606886 = ref object of OpenApiRestCall_605589
proc url_DescribeAlgorithm_606888(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAlgorithm_606887(path: JsonNode; query: JsonNode;
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
  var valid_606889 = header.getOrDefault("X-Amz-Target")
  valid_606889 = validateParameter(valid_606889, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_606889 != nil:
    section.add "X-Amz-Target", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Signature")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Signature", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Content-Sha256", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Date")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Date", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Credential")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Credential", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Security-Token")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Security-Token", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Algorithm")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Algorithm", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-SignedHeaders", valid_606896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606898: Call_DescribeAlgorithm_606886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_606898.validator(path, query, header, formData, body)
  let scheme = call_606898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606898.url(scheme.get, call_606898.host, call_606898.base,
                         call_606898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606898, url, valid)

proc call*(call_606899: Call_DescribeAlgorithm_606886; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_606900 = newJObject()
  if body != nil:
    body_606900 = body
  result = call_606899.call(nil, nil, nil, nil, body_606900)

var describeAlgorithm* = Call_DescribeAlgorithm_606886(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_606887, base: "/",
    url: url_DescribeAlgorithm_606888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_606901 = ref object of OpenApiRestCall_605589
proc url_DescribeApp_606903(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApp_606902(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606904 = header.getOrDefault("X-Amz-Target")
  valid_606904 = validateParameter(valid_606904, JString, required = true,
                                 default = newJString("SageMaker.DescribeApp"))
  if valid_606904 != nil:
    section.add "X-Amz-Target", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Signature")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Signature", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Content-Sha256", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Date")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Date", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Credential")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Credential", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Security-Token")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Security-Token", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Algorithm")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Algorithm", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-SignedHeaders", valid_606911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606913: Call_DescribeApp_606901; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the app.
  ## 
  let valid = call_606913.validator(path, query, header, formData, body)
  let scheme = call_606913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606913.url(scheme.get, call_606913.host, call_606913.base,
                         call_606913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606913, url, valid)

proc call*(call_606914: Call_DescribeApp_606901; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_606915 = newJObject()
  if body != nil:
    body_606915 = body
  result = call_606914.call(nil, nil, nil, nil, body_606915)

var describeApp* = Call_DescribeApp_606901(name: "describeApp",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DescribeApp",
                                        validator: validate_DescribeApp_606902,
                                        base: "/", url: url_DescribeApp_606903,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_606916 = ref object of OpenApiRestCall_605589
proc url_DescribeAutoMLJob_606918(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutoMLJob_606917(path: JsonNode; query: JsonNode;
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
  var valid_606919 = header.getOrDefault("X-Amz-Target")
  valid_606919 = validateParameter(valid_606919, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_606919 != nil:
    section.add "X-Amz-Target", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Signature")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Signature", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Content-Sha256", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Date")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Date", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Credential")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Credential", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Security-Token")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Security-Token", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Algorithm")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Algorithm", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-SignedHeaders", valid_606926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_DescribeAutoMLJob_606916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_DescribeAutoMLJob_606916; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_606930 = newJObject()
  if body != nil:
    body_606930 = body
  result = call_606929.call(nil, nil, nil, nil, body_606930)

var describeAutoMLJob* = Call_DescribeAutoMLJob_606916(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_606917, base: "/",
    url: url_DescribeAutoMLJob_606918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_606931 = ref object of OpenApiRestCall_605589
proc url_DescribeCodeRepository_606933(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCodeRepository_606932(path: JsonNode; query: JsonNode;
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
  var valid_606934 = header.getOrDefault("X-Amz-Target")
  valid_606934 = validateParameter(valid_606934, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_606934 != nil:
    section.add "X-Amz-Target", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Signature")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Signature", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Content-Sha256", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Date")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Date", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Credential")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Credential", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Security-Token")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Security-Token", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Algorithm")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Algorithm", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-SignedHeaders", valid_606941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606943: Call_DescribeCodeRepository_606931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_606943.validator(path, query, header, formData, body)
  let scheme = call_606943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606943.url(scheme.get, call_606943.host, call_606943.base,
                         call_606943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606943, url, valid)

proc call*(call_606944: Call_DescribeCodeRepository_606931; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_606945 = newJObject()
  if body != nil:
    body_606945 = body
  result = call_606944.call(nil, nil, nil, nil, body_606945)

var describeCodeRepository* = Call_DescribeCodeRepository_606931(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_606932, base: "/",
    url: url_DescribeCodeRepository_606933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_606946 = ref object of OpenApiRestCall_605589
proc url_DescribeCompilationJob_606948(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompilationJob_606947(path: JsonNode; query: JsonNode;
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
  var valid_606949 = header.getOrDefault("X-Amz-Target")
  valid_606949 = validateParameter(valid_606949, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_606949 != nil:
    section.add "X-Amz-Target", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-Signature")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-Signature", valid_606950
  var valid_606951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606951 = validateParameter(valid_606951, JString, required = false,
                                 default = nil)
  if valid_606951 != nil:
    section.add "X-Amz-Content-Sha256", valid_606951
  var valid_606952 = header.getOrDefault("X-Amz-Date")
  valid_606952 = validateParameter(valid_606952, JString, required = false,
                                 default = nil)
  if valid_606952 != nil:
    section.add "X-Amz-Date", valid_606952
  var valid_606953 = header.getOrDefault("X-Amz-Credential")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Credential", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Security-Token")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Security-Token", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Algorithm")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Algorithm", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-SignedHeaders", valid_606956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606958: Call_DescribeCompilationJob_606946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_606958.validator(path, query, header, formData, body)
  let scheme = call_606958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606958.url(scheme.get, call_606958.host, call_606958.base,
                         call_606958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606958, url, valid)

proc call*(call_606959: Call_DescribeCompilationJob_606946; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_606960 = newJObject()
  if body != nil:
    body_606960 = body
  result = call_606959.call(nil, nil, nil, nil, body_606960)

var describeCompilationJob* = Call_DescribeCompilationJob_606946(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_606947, base: "/",
    url: url_DescribeCompilationJob_606948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_606961 = ref object of OpenApiRestCall_605589
proc url_DescribeDomain_606963(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_606962(path: JsonNode; query: JsonNode;
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
  var valid_606964 = header.getOrDefault("X-Amz-Target")
  valid_606964 = validateParameter(valid_606964, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_606964 != nil:
    section.add "X-Amz-Target", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Signature")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Signature", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-Content-Sha256", valid_606966
  var valid_606967 = header.getOrDefault("X-Amz-Date")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "X-Amz-Date", valid_606967
  var valid_606968 = header.getOrDefault("X-Amz-Credential")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Credential", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-Security-Token")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Security-Token", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Algorithm")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Algorithm", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-SignedHeaders", valid_606971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606973: Call_DescribeDomain_606961; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_606973.validator(path, query, header, formData, body)
  let scheme = call_606973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606973.url(scheme.get, call_606973.host, call_606973.base,
                         call_606973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606973, url, valid)

proc call*(call_606974: Call_DescribeDomain_606961; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_606975 = newJObject()
  if body != nil:
    body_606975 = body
  result = call_606974.call(nil, nil, nil, nil, body_606975)

var describeDomain* = Call_DescribeDomain_606961(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_606962, base: "/", url: url_DescribeDomain_606963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_606976 = ref object of OpenApiRestCall_605589
proc url_DescribeEndpoint_606978(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_606977(path: JsonNode; query: JsonNode;
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
  var valid_606979 = header.getOrDefault("X-Amz-Target")
  valid_606979 = validateParameter(valid_606979, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_606979 != nil:
    section.add "X-Amz-Target", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Signature")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Signature", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Content-Sha256", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Date")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Date", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Credential")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Credential", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Security-Token")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Security-Token", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Algorithm")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Algorithm", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-SignedHeaders", valid_606986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606988: Call_DescribeEndpoint_606976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_606988.validator(path, query, header, formData, body)
  let scheme = call_606988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606988.url(scheme.get, call_606988.host, call_606988.base,
                         call_606988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606988, url, valid)

proc call*(call_606989: Call_DescribeEndpoint_606976; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_606990 = newJObject()
  if body != nil:
    body_606990 = body
  result = call_606989.call(nil, nil, nil, nil, body_606990)

var describeEndpoint* = Call_DescribeEndpoint_606976(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_606977, base: "/",
    url: url_DescribeEndpoint_606978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_606991 = ref object of OpenApiRestCall_605589
proc url_DescribeEndpointConfig_606993(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointConfig_606992(path: JsonNode; query: JsonNode;
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
  var valid_606994 = header.getOrDefault("X-Amz-Target")
  valid_606994 = validateParameter(valid_606994, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_606994 != nil:
    section.add "X-Amz-Target", valid_606994
  var valid_606995 = header.getOrDefault("X-Amz-Signature")
  valid_606995 = validateParameter(valid_606995, JString, required = false,
                                 default = nil)
  if valid_606995 != nil:
    section.add "X-Amz-Signature", valid_606995
  var valid_606996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Content-Sha256", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Date")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Date", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Credential")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Credential", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Security-Token")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Security-Token", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Algorithm")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Algorithm", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-SignedHeaders", valid_607001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607003: Call_DescribeEndpointConfig_606991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_607003.validator(path, query, header, formData, body)
  let scheme = call_607003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607003.url(scheme.get, call_607003.host, call_607003.base,
                         call_607003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607003, url, valid)

proc call*(call_607004: Call_DescribeEndpointConfig_606991; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_607005 = newJObject()
  if body != nil:
    body_607005 = body
  result = call_607004.call(nil, nil, nil, nil, body_607005)

var describeEndpointConfig* = Call_DescribeEndpointConfig_606991(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_606992, base: "/",
    url: url_DescribeEndpointConfig_606993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_607006 = ref object of OpenApiRestCall_605589
proc url_DescribeExperiment_607008(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExperiment_607007(path: JsonNode; query: JsonNode;
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
  var valid_607009 = header.getOrDefault("X-Amz-Target")
  valid_607009 = validateParameter(valid_607009, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_607009 != nil:
    section.add "X-Amz-Target", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-Signature")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-Signature", valid_607010
  var valid_607011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "X-Amz-Content-Sha256", valid_607011
  var valid_607012 = header.getOrDefault("X-Amz-Date")
  valid_607012 = validateParameter(valid_607012, JString, required = false,
                                 default = nil)
  if valid_607012 != nil:
    section.add "X-Amz-Date", valid_607012
  var valid_607013 = header.getOrDefault("X-Amz-Credential")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "X-Amz-Credential", valid_607013
  var valid_607014 = header.getOrDefault("X-Amz-Security-Token")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "X-Amz-Security-Token", valid_607014
  var valid_607015 = header.getOrDefault("X-Amz-Algorithm")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "X-Amz-Algorithm", valid_607015
  var valid_607016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "X-Amz-SignedHeaders", valid_607016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607018: Call_DescribeExperiment_607006; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_607018.validator(path, query, header, formData, body)
  let scheme = call_607018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607018.url(scheme.get, call_607018.host, call_607018.base,
                         call_607018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607018, url, valid)

proc call*(call_607019: Call_DescribeExperiment_607006; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_607020 = newJObject()
  if body != nil:
    body_607020 = body
  result = call_607019.call(nil, nil, nil, nil, body_607020)

var describeExperiment* = Call_DescribeExperiment_607006(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_607007, base: "/",
    url: url_DescribeExperiment_607008, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_607021 = ref object of OpenApiRestCall_605589
proc url_DescribeFlowDefinition_607023(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFlowDefinition_607022(path: JsonNode; query: JsonNode;
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
  var valid_607024 = header.getOrDefault("X-Amz-Target")
  valid_607024 = validateParameter(valid_607024, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_607024 != nil:
    section.add "X-Amz-Target", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Signature")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Signature", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Content-Sha256", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-Date")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-Date", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-Credential")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Credential", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Security-Token")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Security-Token", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Algorithm")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Algorithm", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-SignedHeaders", valid_607031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607033: Call_DescribeFlowDefinition_607021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_607033.validator(path, query, header, formData, body)
  let scheme = call_607033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607033.url(scheme.get, call_607033.host, call_607033.base,
                         call_607033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607033, url, valid)

proc call*(call_607034: Call_DescribeFlowDefinition_607021; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_607035 = newJObject()
  if body != nil:
    body_607035 = body
  result = call_607034.call(nil, nil, nil, nil, body_607035)

var describeFlowDefinition* = Call_DescribeFlowDefinition_607021(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_607022, base: "/",
    url: url_DescribeFlowDefinition_607023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_607036 = ref object of OpenApiRestCall_605589
proc url_DescribeHumanTaskUi_607038(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHumanTaskUi_607037(path: JsonNode; query: JsonNode;
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
  var valid_607039 = header.getOrDefault("X-Amz-Target")
  valid_607039 = validateParameter(valid_607039, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_607039 != nil:
    section.add "X-Amz-Target", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-Signature")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-Signature", valid_607040
  var valid_607041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "X-Amz-Content-Sha256", valid_607041
  var valid_607042 = header.getOrDefault("X-Amz-Date")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "X-Amz-Date", valid_607042
  var valid_607043 = header.getOrDefault("X-Amz-Credential")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Credential", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Security-Token")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Security-Token", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Algorithm")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Algorithm", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-SignedHeaders", valid_607046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607048: Call_DescribeHumanTaskUi_607036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_607048.validator(path, query, header, formData, body)
  let scheme = call_607048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607048.url(scheme.get, call_607048.host, call_607048.base,
                         call_607048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607048, url, valid)

proc call*(call_607049: Call_DescribeHumanTaskUi_607036; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_607050 = newJObject()
  if body != nil:
    body_607050 = body
  result = call_607049.call(nil, nil, nil, nil, body_607050)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_607036(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_607037, base: "/",
    url: url_DescribeHumanTaskUi_607038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_607051 = ref object of OpenApiRestCall_605589
proc url_DescribeHyperParameterTuningJob_607053(protocol: Scheme; host: string;
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

proc validate_DescribeHyperParameterTuningJob_607052(path: JsonNode;
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
  var valid_607054 = header.getOrDefault("X-Amz-Target")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_607054 != nil:
    section.add "X-Amz-Target", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607063: Call_DescribeHyperParameterTuningJob_607051;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_607063.validator(path, query, header, formData, body)
  let scheme = call_607063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607063.url(scheme.get, call_607063.host, call_607063.base,
                         call_607063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607063, url, valid)

proc call*(call_607064: Call_DescribeHyperParameterTuningJob_607051; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_607065 = newJObject()
  if body != nil:
    body_607065 = body
  result = call_607064.call(nil, nil, nil, nil, body_607065)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_607051(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_607052, base: "/",
    url: url_DescribeHyperParameterTuningJob_607053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_607066 = ref object of OpenApiRestCall_605589
proc url_DescribeLabelingJob_607068(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLabelingJob_607067(path: JsonNode; query: JsonNode;
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
  var valid_607069 = header.getOrDefault("X-Amz-Target")
  valid_607069 = validateParameter(valid_607069, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_607069 != nil:
    section.add "X-Amz-Target", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-Signature")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Signature", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Content-Sha256", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Date")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Date", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Credential")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Credential", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Security-Token")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Security-Token", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Algorithm")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Algorithm", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-SignedHeaders", valid_607076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607078: Call_DescribeLabelingJob_607066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_607078.validator(path, query, header, formData, body)
  let scheme = call_607078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607078.url(scheme.get, call_607078.host, call_607078.base,
                         call_607078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607078, url, valid)

proc call*(call_607079: Call_DescribeLabelingJob_607066; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_607080 = newJObject()
  if body != nil:
    body_607080 = body
  result = call_607079.call(nil, nil, nil, nil, body_607080)

var describeLabelingJob* = Call_DescribeLabelingJob_607066(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_607067, base: "/",
    url: url_DescribeLabelingJob_607068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_607081 = ref object of OpenApiRestCall_605589
proc url_DescribeModel_607083(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModel_607082(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607084 = header.getOrDefault("X-Amz-Target")
  valid_607084 = validateParameter(valid_607084, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_607084 != nil:
    section.add "X-Amz-Target", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Signature")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Signature", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Content-Sha256", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Date")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Date", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-Credential")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-Credential", valid_607088
  var valid_607089 = header.getOrDefault("X-Amz-Security-Token")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "X-Amz-Security-Token", valid_607089
  var valid_607090 = header.getOrDefault("X-Amz-Algorithm")
  valid_607090 = validateParameter(valid_607090, JString, required = false,
                                 default = nil)
  if valid_607090 != nil:
    section.add "X-Amz-Algorithm", valid_607090
  var valid_607091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607091 = validateParameter(valid_607091, JString, required = false,
                                 default = nil)
  if valid_607091 != nil:
    section.add "X-Amz-SignedHeaders", valid_607091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607093: Call_DescribeModel_607081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_607093.validator(path, query, header, formData, body)
  let scheme = call_607093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607093.url(scheme.get, call_607093.host, call_607093.base,
                         call_607093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607093, url, valid)

proc call*(call_607094: Call_DescribeModel_607081; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_607095 = newJObject()
  if body != nil:
    body_607095 = body
  result = call_607094.call(nil, nil, nil, nil, body_607095)

var describeModel* = Call_DescribeModel_607081(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_607082, base: "/", url: url_DescribeModel_607083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_607096 = ref object of OpenApiRestCall_605589
proc url_DescribeModelPackage_607098(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelPackage_607097(path: JsonNode; query: JsonNode;
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
  var valid_607099 = header.getOrDefault("X-Amz-Target")
  valid_607099 = validateParameter(valid_607099, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_607099 != nil:
    section.add "X-Amz-Target", valid_607099
  var valid_607100 = header.getOrDefault("X-Amz-Signature")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "X-Amz-Signature", valid_607100
  var valid_607101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Content-Sha256", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Date")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Date", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Credential")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Credential", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-Security-Token")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-Security-Token", valid_607104
  var valid_607105 = header.getOrDefault("X-Amz-Algorithm")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-Algorithm", valid_607105
  var valid_607106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-SignedHeaders", valid_607106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607108: Call_DescribeModelPackage_607096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_607108.validator(path, query, header, formData, body)
  let scheme = call_607108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607108.url(scheme.get, call_607108.host, call_607108.base,
                         call_607108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607108, url, valid)

proc call*(call_607109: Call_DescribeModelPackage_607096; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_607110 = newJObject()
  if body != nil:
    body_607110 = body
  result = call_607109.call(nil, nil, nil, nil, body_607110)

var describeModelPackage* = Call_DescribeModelPackage_607096(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_607097, base: "/",
    url: url_DescribeModelPackage_607098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_607111 = ref object of OpenApiRestCall_605589
proc url_DescribeMonitoringSchedule_607113(protocol: Scheme; host: string;
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

proc validate_DescribeMonitoringSchedule_607112(path: JsonNode; query: JsonNode;
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
  var valid_607114 = header.getOrDefault("X-Amz-Target")
  valid_607114 = validateParameter(valid_607114, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_607114 != nil:
    section.add "X-Amz-Target", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Signature")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Signature", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Content-Sha256", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Date")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Date", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Credential")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Credential", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-Security-Token")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-Security-Token", valid_607119
  var valid_607120 = header.getOrDefault("X-Amz-Algorithm")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "X-Amz-Algorithm", valid_607120
  var valid_607121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-SignedHeaders", valid_607121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607123: Call_DescribeMonitoringSchedule_607111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_607123.validator(path, query, header, formData, body)
  let scheme = call_607123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607123.url(scheme.get, call_607123.host, call_607123.base,
                         call_607123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607123, url, valid)

proc call*(call_607124: Call_DescribeMonitoringSchedule_607111; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_607125 = newJObject()
  if body != nil:
    body_607125 = body
  result = call_607124.call(nil, nil, nil, nil, body_607125)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_607111(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_607112, base: "/",
    url: url_DescribeMonitoringSchedule_607113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_607126 = ref object of OpenApiRestCall_605589
proc url_DescribeNotebookInstance_607128(protocol: Scheme; host: string;
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

proc validate_DescribeNotebookInstance_607127(path: JsonNode; query: JsonNode;
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
  var valid_607129 = header.getOrDefault("X-Amz-Target")
  valid_607129 = validateParameter(valid_607129, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_607129 != nil:
    section.add "X-Amz-Target", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Signature")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Signature", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Content-Sha256", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Date")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Date", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Credential")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Credential", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-Security-Token")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Security-Token", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-Algorithm")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-Algorithm", valid_607135
  var valid_607136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-SignedHeaders", valid_607136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607138: Call_DescribeNotebookInstance_607126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_607138.validator(path, query, header, formData, body)
  let scheme = call_607138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607138.url(scheme.get, call_607138.host, call_607138.base,
                         call_607138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607138, url, valid)

proc call*(call_607139: Call_DescribeNotebookInstance_607126; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_607140 = newJObject()
  if body != nil:
    body_607140 = body
  result = call_607139.call(nil, nil, nil, nil, body_607140)

var describeNotebookInstance* = Call_DescribeNotebookInstance_607126(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_607127, base: "/",
    url: url_DescribeNotebookInstance_607128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_607141 = ref object of OpenApiRestCall_605589
proc url_DescribeNotebookInstanceLifecycleConfig_607143(protocol: Scheme;
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

proc validate_DescribeNotebookInstanceLifecycleConfig_607142(path: JsonNode;
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
  var valid_607144 = header.getOrDefault("X-Amz-Target")
  valid_607144 = validateParameter(valid_607144, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_607144 != nil:
    section.add "X-Amz-Target", valid_607144
  var valid_607145 = header.getOrDefault("X-Amz-Signature")
  valid_607145 = validateParameter(valid_607145, JString, required = false,
                                 default = nil)
  if valid_607145 != nil:
    section.add "X-Amz-Signature", valid_607145
  var valid_607146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607146 = validateParameter(valid_607146, JString, required = false,
                                 default = nil)
  if valid_607146 != nil:
    section.add "X-Amz-Content-Sha256", valid_607146
  var valid_607147 = header.getOrDefault("X-Amz-Date")
  valid_607147 = validateParameter(valid_607147, JString, required = false,
                                 default = nil)
  if valid_607147 != nil:
    section.add "X-Amz-Date", valid_607147
  var valid_607148 = header.getOrDefault("X-Amz-Credential")
  valid_607148 = validateParameter(valid_607148, JString, required = false,
                                 default = nil)
  if valid_607148 != nil:
    section.add "X-Amz-Credential", valid_607148
  var valid_607149 = header.getOrDefault("X-Amz-Security-Token")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Security-Token", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Algorithm")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Algorithm", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-SignedHeaders", valid_607151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607153: Call_DescribeNotebookInstanceLifecycleConfig_607141;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_607153.validator(path, query, header, formData, body)
  let scheme = call_607153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607153.url(scheme.get, call_607153.host, call_607153.base,
                         call_607153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607153, url, valid)

proc call*(call_607154: Call_DescribeNotebookInstanceLifecycleConfig_607141;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_607155 = newJObject()
  if body != nil:
    body_607155 = body
  result = call_607154.call(nil, nil, nil, nil, body_607155)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_607141(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_607142, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_607143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_607156 = ref object of OpenApiRestCall_605589
proc url_DescribeProcessingJob_607158(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProcessingJob_607157(path: JsonNode; query: JsonNode;
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
  var valid_607159 = header.getOrDefault("X-Amz-Target")
  valid_607159 = validateParameter(valid_607159, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_607159 != nil:
    section.add "X-Amz-Target", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Signature")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Signature", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Content-Sha256", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Date")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Date", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-Credential")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-Credential", valid_607163
  var valid_607164 = header.getOrDefault("X-Amz-Security-Token")
  valid_607164 = validateParameter(valid_607164, JString, required = false,
                                 default = nil)
  if valid_607164 != nil:
    section.add "X-Amz-Security-Token", valid_607164
  var valid_607165 = header.getOrDefault("X-Amz-Algorithm")
  valid_607165 = validateParameter(valid_607165, JString, required = false,
                                 default = nil)
  if valid_607165 != nil:
    section.add "X-Amz-Algorithm", valid_607165
  var valid_607166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607166 = validateParameter(valid_607166, JString, required = false,
                                 default = nil)
  if valid_607166 != nil:
    section.add "X-Amz-SignedHeaders", valid_607166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607168: Call_DescribeProcessingJob_607156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_607168.validator(path, query, header, formData, body)
  let scheme = call_607168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607168.url(scheme.get, call_607168.host, call_607168.base,
                         call_607168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607168, url, valid)

proc call*(call_607169: Call_DescribeProcessingJob_607156; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_607170 = newJObject()
  if body != nil:
    body_607170 = body
  result = call_607169.call(nil, nil, nil, nil, body_607170)

var describeProcessingJob* = Call_DescribeProcessingJob_607156(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_607157, base: "/",
    url: url_DescribeProcessingJob_607158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_607171 = ref object of OpenApiRestCall_605589
proc url_DescribeSubscribedWorkteam_607173(protocol: Scheme; host: string;
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

proc validate_DescribeSubscribedWorkteam_607172(path: JsonNode; query: JsonNode;
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
  var valid_607174 = header.getOrDefault("X-Amz-Target")
  valid_607174 = validateParameter(valid_607174, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_607174 != nil:
    section.add "X-Amz-Target", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Signature")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Signature", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Content-Sha256", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Date")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Date", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-Credential")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-Credential", valid_607178
  var valid_607179 = header.getOrDefault("X-Amz-Security-Token")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "X-Amz-Security-Token", valid_607179
  var valid_607180 = header.getOrDefault("X-Amz-Algorithm")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "X-Amz-Algorithm", valid_607180
  var valid_607181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "X-Amz-SignedHeaders", valid_607181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607183: Call_DescribeSubscribedWorkteam_607171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_607183.validator(path, query, header, formData, body)
  let scheme = call_607183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607183.url(scheme.get, call_607183.host, call_607183.base,
                         call_607183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607183, url, valid)

proc call*(call_607184: Call_DescribeSubscribedWorkteam_607171; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_607185 = newJObject()
  if body != nil:
    body_607185 = body
  result = call_607184.call(nil, nil, nil, nil, body_607185)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_607171(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_607172, base: "/",
    url: url_DescribeSubscribedWorkteam_607173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_607186 = ref object of OpenApiRestCall_605589
proc url_DescribeTrainingJob_607188(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrainingJob_607187(path: JsonNode; query: JsonNode;
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
  var valid_607189 = header.getOrDefault("X-Amz-Target")
  valid_607189 = validateParameter(valid_607189, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_607189 != nil:
    section.add "X-Amz-Target", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Signature")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Signature", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Content-Sha256", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Date")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Date", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Credential")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Credential", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-Security-Token")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-Security-Token", valid_607194
  var valid_607195 = header.getOrDefault("X-Amz-Algorithm")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Algorithm", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-SignedHeaders", valid_607196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607198: Call_DescribeTrainingJob_607186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_607198.validator(path, query, header, formData, body)
  let scheme = call_607198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607198.url(scheme.get, call_607198.host, call_607198.base,
                         call_607198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607198, url, valid)

proc call*(call_607199: Call_DescribeTrainingJob_607186; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_607200 = newJObject()
  if body != nil:
    body_607200 = body
  result = call_607199.call(nil, nil, nil, nil, body_607200)

var describeTrainingJob* = Call_DescribeTrainingJob_607186(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_607187, base: "/",
    url: url_DescribeTrainingJob_607188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_607201 = ref object of OpenApiRestCall_605589
proc url_DescribeTransformJob_607203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTransformJob_607202(path: JsonNode; query: JsonNode;
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
  var valid_607204 = header.getOrDefault("X-Amz-Target")
  valid_607204 = validateParameter(valid_607204, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_607204 != nil:
    section.add "X-Amz-Target", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Signature")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Signature", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-Content-Sha256", valid_607206
  var valid_607207 = header.getOrDefault("X-Amz-Date")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "X-Amz-Date", valid_607207
  var valid_607208 = header.getOrDefault("X-Amz-Credential")
  valid_607208 = validateParameter(valid_607208, JString, required = false,
                                 default = nil)
  if valid_607208 != nil:
    section.add "X-Amz-Credential", valid_607208
  var valid_607209 = header.getOrDefault("X-Amz-Security-Token")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "X-Amz-Security-Token", valid_607209
  var valid_607210 = header.getOrDefault("X-Amz-Algorithm")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Algorithm", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-SignedHeaders", valid_607211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607213: Call_DescribeTransformJob_607201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_607213.validator(path, query, header, formData, body)
  let scheme = call_607213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607213.url(scheme.get, call_607213.host, call_607213.base,
                         call_607213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607213, url, valid)

proc call*(call_607214: Call_DescribeTransformJob_607201; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_607215 = newJObject()
  if body != nil:
    body_607215 = body
  result = call_607214.call(nil, nil, nil, nil, body_607215)

var describeTransformJob* = Call_DescribeTransformJob_607201(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_607202, base: "/",
    url: url_DescribeTransformJob_607203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_607216 = ref object of OpenApiRestCall_605589
proc url_DescribeTrial_607218(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrial_607217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607219 = header.getOrDefault("X-Amz-Target")
  valid_607219 = validateParameter(valid_607219, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_607219 != nil:
    section.add "X-Amz-Target", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Signature")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Signature", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-Content-Sha256", valid_607221
  var valid_607222 = header.getOrDefault("X-Amz-Date")
  valid_607222 = validateParameter(valid_607222, JString, required = false,
                                 default = nil)
  if valid_607222 != nil:
    section.add "X-Amz-Date", valid_607222
  var valid_607223 = header.getOrDefault("X-Amz-Credential")
  valid_607223 = validateParameter(valid_607223, JString, required = false,
                                 default = nil)
  if valid_607223 != nil:
    section.add "X-Amz-Credential", valid_607223
  var valid_607224 = header.getOrDefault("X-Amz-Security-Token")
  valid_607224 = validateParameter(valid_607224, JString, required = false,
                                 default = nil)
  if valid_607224 != nil:
    section.add "X-Amz-Security-Token", valid_607224
  var valid_607225 = header.getOrDefault("X-Amz-Algorithm")
  valid_607225 = validateParameter(valid_607225, JString, required = false,
                                 default = nil)
  if valid_607225 != nil:
    section.add "X-Amz-Algorithm", valid_607225
  var valid_607226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607226 = validateParameter(valid_607226, JString, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "X-Amz-SignedHeaders", valid_607226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607228: Call_DescribeTrial_607216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_607228.validator(path, query, header, formData, body)
  let scheme = call_607228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607228.url(scheme.get, call_607228.host, call_607228.base,
                         call_607228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607228, url, valid)

proc call*(call_607229: Call_DescribeTrial_607216; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_607230 = newJObject()
  if body != nil:
    body_607230 = body
  result = call_607229.call(nil, nil, nil, nil, body_607230)

var describeTrial* = Call_DescribeTrial_607216(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_607217, base: "/", url: url_DescribeTrial_607218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_607231 = ref object of OpenApiRestCall_605589
proc url_DescribeTrialComponent_607233(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrialComponent_607232(path: JsonNode; query: JsonNode;
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
  var valid_607234 = header.getOrDefault("X-Amz-Target")
  valid_607234 = validateParameter(valid_607234, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_607234 != nil:
    section.add "X-Amz-Target", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Signature")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Signature", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Content-Sha256", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Date")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Date", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-Credential")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-Credential", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Security-Token")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Security-Token", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-Algorithm")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-Algorithm", valid_607240
  var valid_607241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607241 = validateParameter(valid_607241, JString, required = false,
                                 default = nil)
  if valid_607241 != nil:
    section.add "X-Amz-SignedHeaders", valid_607241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607243: Call_DescribeTrialComponent_607231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_607243.validator(path, query, header, formData, body)
  let scheme = call_607243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607243.url(scheme.get, call_607243.host, call_607243.base,
                         call_607243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607243, url, valid)

proc call*(call_607244: Call_DescribeTrialComponent_607231; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_607245 = newJObject()
  if body != nil:
    body_607245 = body
  result = call_607244.call(nil, nil, nil, nil, body_607245)

var describeTrialComponent* = Call_DescribeTrialComponent_607231(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_607232, base: "/",
    url: url_DescribeTrialComponent_607233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_607246 = ref object of OpenApiRestCall_605589
proc url_DescribeUserProfile_607248(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserProfile_607247(path: JsonNode; query: JsonNode;
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
  var valid_607249 = header.getOrDefault("X-Amz-Target")
  valid_607249 = validateParameter(valid_607249, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_607249 != nil:
    section.add "X-Amz-Target", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Signature")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Signature", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Content-Sha256", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Date")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Date", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-Credential")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-Credential", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Security-Token")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Security-Token", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-Algorithm")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-Algorithm", valid_607255
  var valid_607256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607256 = validateParameter(valid_607256, JString, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "X-Amz-SignedHeaders", valid_607256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607258: Call_DescribeUserProfile_607246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_607258.validator(path, query, header, formData, body)
  let scheme = call_607258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607258.url(scheme.get, call_607258.host, call_607258.base,
                         call_607258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607258, url, valid)

proc call*(call_607259: Call_DescribeUserProfile_607246; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_607260 = newJObject()
  if body != nil:
    body_607260 = body
  result = call_607259.call(nil, nil, nil, nil, body_607260)

var describeUserProfile* = Call_DescribeUserProfile_607246(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_607247, base: "/",
    url: url_DescribeUserProfile_607248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_607261 = ref object of OpenApiRestCall_605589
proc url_DescribeWorkteam_607263(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkteam_607262(path: JsonNode; query: JsonNode;
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
  var valid_607264 = header.getOrDefault("X-Amz-Target")
  valid_607264 = validateParameter(valid_607264, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_607264 != nil:
    section.add "X-Amz-Target", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Signature")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Signature", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Content-Sha256", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Date")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Date", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Credential")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Credential", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Security-Token")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Security-Token", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Algorithm")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Algorithm", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-SignedHeaders", valid_607271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607273: Call_DescribeWorkteam_607261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_607273.validator(path, query, header, formData, body)
  let scheme = call_607273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607273.url(scheme.get, call_607273.host, call_607273.base,
                         call_607273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607273, url, valid)

proc call*(call_607274: Call_DescribeWorkteam_607261; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_607275 = newJObject()
  if body != nil:
    body_607275 = body
  result = call_607274.call(nil, nil, nil, nil, body_607275)

var describeWorkteam* = Call_DescribeWorkteam_607261(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_607262, base: "/",
    url: url_DescribeWorkteam_607263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_607276 = ref object of OpenApiRestCall_605589
proc url_DisassociateTrialComponent_607278(protocol: Scheme; host: string;
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

proc validate_DisassociateTrialComponent_607277(path: JsonNode; query: JsonNode;
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
  var valid_607279 = header.getOrDefault("X-Amz-Target")
  valid_607279 = validateParameter(valid_607279, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_607279 != nil:
    section.add "X-Amz-Target", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Signature")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Signature", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Content-Sha256", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Date")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Date", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Credential")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Credential", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Security-Token")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Security-Token", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Algorithm")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Algorithm", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-SignedHeaders", valid_607286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607288: Call_DisassociateTrialComponent_607276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ## 
  let valid = call_607288.validator(path, query, header, formData, body)
  let scheme = call_607288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607288.url(scheme.get, call_607288.host, call_607288.base,
                         call_607288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607288, url, valid)

proc call*(call_607289: Call_DisassociateTrialComponent_607276; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_607290 = newJObject()
  if body != nil:
    body_607290 = body
  result = call_607289.call(nil, nil, nil, nil, body_607290)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_607276(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_607277, base: "/",
    url: url_DisassociateTrialComponent_607278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_607291 = ref object of OpenApiRestCall_605589
proc url_GetSearchSuggestions_607293(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSearchSuggestions_607292(path: JsonNode; query: JsonNode;
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
  var valid_607294 = header.getOrDefault("X-Amz-Target")
  valid_607294 = validateParameter(valid_607294, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_607294 != nil:
    section.add "X-Amz-Target", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Signature")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Signature", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Content-Sha256", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Date")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Date", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Credential")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Credential", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Security-Token")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Security-Token", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Algorithm")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Algorithm", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-SignedHeaders", valid_607301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607303: Call_GetSearchSuggestions_607291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_607303.validator(path, query, header, formData, body)
  let scheme = call_607303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607303.url(scheme.get, call_607303.host, call_607303.base,
                         call_607303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607303, url, valid)

proc call*(call_607304: Call_GetSearchSuggestions_607291; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_607305 = newJObject()
  if body != nil:
    body_607305 = body
  result = call_607304.call(nil, nil, nil, nil, body_607305)

var getSearchSuggestions* = Call_GetSearchSuggestions_607291(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_607292, base: "/",
    url: url_GetSearchSuggestions_607293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_607306 = ref object of OpenApiRestCall_605589
proc url_ListAlgorithms_607308(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAlgorithms_607307(path: JsonNode; query: JsonNode;
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
  var valid_607309 = query.getOrDefault("MaxResults")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "MaxResults", valid_607309
  var valid_607310 = query.getOrDefault("NextToken")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "NextToken", valid_607310
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607311 = header.getOrDefault("X-Amz-Target")
  valid_607311 = validateParameter(valid_607311, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_607311 != nil:
    section.add "X-Amz-Target", valid_607311
  var valid_607312 = header.getOrDefault("X-Amz-Signature")
  valid_607312 = validateParameter(valid_607312, JString, required = false,
                                 default = nil)
  if valid_607312 != nil:
    section.add "X-Amz-Signature", valid_607312
  var valid_607313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607313 = validateParameter(valid_607313, JString, required = false,
                                 default = nil)
  if valid_607313 != nil:
    section.add "X-Amz-Content-Sha256", valid_607313
  var valid_607314 = header.getOrDefault("X-Amz-Date")
  valid_607314 = validateParameter(valid_607314, JString, required = false,
                                 default = nil)
  if valid_607314 != nil:
    section.add "X-Amz-Date", valid_607314
  var valid_607315 = header.getOrDefault("X-Amz-Credential")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-Credential", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-Security-Token")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Security-Token", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Algorithm")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Algorithm", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-SignedHeaders", valid_607318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607320: Call_ListAlgorithms_607306; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_607320.validator(path, query, header, formData, body)
  let scheme = call_607320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607320.url(scheme.get, call_607320.host, call_607320.base,
                         call_607320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607320, url, valid)

proc call*(call_607321: Call_ListAlgorithms_607306; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607322 = newJObject()
  var body_607323 = newJObject()
  add(query_607322, "MaxResults", newJString(MaxResults))
  add(query_607322, "NextToken", newJString(NextToken))
  if body != nil:
    body_607323 = body
  result = call_607321.call(nil, query_607322, nil, nil, body_607323)

var listAlgorithms* = Call_ListAlgorithms_607306(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_607307, base: "/", url: url_ListAlgorithms_607308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_607325 = ref object of OpenApiRestCall_605589
proc url_ListApps_607327(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListApps_607326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607328 = query.getOrDefault("MaxResults")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "MaxResults", valid_607328
  var valid_607329 = query.getOrDefault("NextToken")
  valid_607329 = validateParameter(valid_607329, JString, required = false,
                                 default = nil)
  if valid_607329 != nil:
    section.add "NextToken", valid_607329
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607330 = header.getOrDefault("X-Amz-Target")
  valid_607330 = validateParameter(valid_607330, JString, required = true,
                                 default = newJString("SageMaker.ListApps"))
  if valid_607330 != nil:
    section.add "X-Amz-Target", valid_607330
  var valid_607331 = header.getOrDefault("X-Amz-Signature")
  valid_607331 = validateParameter(valid_607331, JString, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "X-Amz-Signature", valid_607331
  var valid_607332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607332 = validateParameter(valid_607332, JString, required = false,
                                 default = nil)
  if valid_607332 != nil:
    section.add "X-Amz-Content-Sha256", valid_607332
  var valid_607333 = header.getOrDefault("X-Amz-Date")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Date", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Credential")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Credential", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Security-Token")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Security-Token", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Algorithm")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Algorithm", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-SignedHeaders", valid_607337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607339: Call_ListApps_607325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists apps.
  ## 
  let valid = call_607339.validator(path, query, header, formData, body)
  let scheme = call_607339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607339.url(scheme.get, call_607339.host, call_607339.base,
                         call_607339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607339, url, valid)

proc call*(call_607340: Call_ListApps_607325; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607341 = newJObject()
  var body_607342 = newJObject()
  add(query_607341, "MaxResults", newJString(MaxResults))
  add(query_607341, "NextToken", newJString(NextToken))
  if body != nil:
    body_607342 = body
  result = call_607340.call(nil, query_607341, nil, nil, body_607342)

var listApps* = Call_ListApps_607325(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListApps",
                                  validator: validate_ListApps_607326, base: "/",
                                  url: url_ListApps_607327,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_607343 = ref object of OpenApiRestCall_605589
proc url_ListAutoMLJobs_607345(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAutoMLJobs_607344(path: JsonNode; query: JsonNode;
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
  var valid_607346 = query.getOrDefault("MaxResults")
  valid_607346 = validateParameter(valid_607346, JString, required = false,
                                 default = nil)
  if valid_607346 != nil:
    section.add "MaxResults", valid_607346
  var valid_607347 = query.getOrDefault("NextToken")
  valid_607347 = validateParameter(valid_607347, JString, required = false,
                                 default = nil)
  if valid_607347 != nil:
    section.add "NextToken", valid_607347
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607348 = header.getOrDefault("X-Amz-Target")
  valid_607348 = validateParameter(valid_607348, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_607348 != nil:
    section.add "X-Amz-Target", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Signature")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Signature", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Content-Sha256", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Date")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Date", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Credential")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Credential", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Security-Token")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Security-Token", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Algorithm")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Algorithm", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-SignedHeaders", valid_607355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607357: Call_ListAutoMLJobs_607343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_607357.validator(path, query, header, formData, body)
  let scheme = call_607357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607357.url(scheme.get, call_607357.host, call_607357.base,
                         call_607357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607357, url, valid)

proc call*(call_607358: Call_ListAutoMLJobs_607343; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607359 = newJObject()
  var body_607360 = newJObject()
  add(query_607359, "MaxResults", newJString(MaxResults))
  add(query_607359, "NextToken", newJString(NextToken))
  if body != nil:
    body_607360 = body
  result = call_607358.call(nil, query_607359, nil, nil, body_607360)

var listAutoMLJobs* = Call_ListAutoMLJobs_607343(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_607344, base: "/", url: url_ListAutoMLJobs_607345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_607361 = ref object of OpenApiRestCall_605589
proc url_ListCandidatesForAutoMLJob_607363(protocol: Scheme; host: string;
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

proc validate_ListCandidatesForAutoMLJob_607362(path: JsonNode; query: JsonNode;
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
  var valid_607364 = query.getOrDefault("MaxResults")
  valid_607364 = validateParameter(valid_607364, JString, required = false,
                                 default = nil)
  if valid_607364 != nil:
    section.add "MaxResults", valid_607364
  var valid_607365 = query.getOrDefault("NextToken")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "NextToken", valid_607365
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607366 = header.getOrDefault("X-Amz-Target")
  valid_607366 = validateParameter(valid_607366, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_607366 != nil:
    section.add "X-Amz-Target", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Signature")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Signature", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Content-Sha256", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Date")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Date", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Credential")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Credential", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Security-Token")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Security-Token", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Algorithm")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Algorithm", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-SignedHeaders", valid_607373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607375: Call_ListCandidatesForAutoMLJob_607361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_607375.validator(path, query, header, formData, body)
  let scheme = call_607375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607375.url(scheme.get, call_607375.host, call_607375.base,
                         call_607375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607375, url, valid)

proc call*(call_607376: Call_ListCandidatesForAutoMLJob_607361; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607377 = newJObject()
  var body_607378 = newJObject()
  add(query_607377, "MaxResults", newJString(MaxResults))
  add(query_607377, "NextToken", newJString(NextToken))
  if body != nil:
    body_607378 = body
  result = call_607376.call(nil, query_607377, nil, nil, body_607378)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_607361(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_607362, base: "/",
    url: url_ListCandidatesForAutoMLJob_607363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_607379 = ref object of OpenApiRestCall_605589
proc url_ListCodeRepositories_607381(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCodeRepositories_607380(path: JsonNode; query: JsonNode;
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
  var valid_607382 = query.getOrDefault("MaxResults")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "MaxResults", valid_607382
  var valid_607383 = query.getOrDefault("NextToken")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "NextToken", valid_607383
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607384 = header.getOrDefault("X-Amz-Target")
  valid_607384 = validateParameter(valid_607384, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_607384 != nil:
    section.add "X-Amz-Target", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Signature")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Signature", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Content-Sha256", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Date")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Date", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Credential")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Credential", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-Security-Token")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Security-Token", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Algorithm")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Algorithm", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-SignedHeaders", valid_607391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607393: Call_ListCodeRepositories_607379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_607393.validator(path, query, header, formData, body)
  let scheme = call_607393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607393.url(scheme.get, call_607393.host, call_607393.base,
                         call_607393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607393, url, valid)

proc call*(call_607394: Call_ListCodeRepositories_607379; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607395 = newJObject()
  var body_607396 = newJObject()
  add(query_607395, "MaxResults", newJString(MaxResults))
  add(query_607395, "NextToken", newJString(NextToken))
  if body != nil:
    body_607396 = body
  result = call_607394.call(nil, query_607395, nil, nil, body_607396)

var listCodeRepositories* = Call_ListCodeRepositories_607379(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_607380, base: "/",
    url: url_ListCodeRepositories_607381, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_607397 = ref object of OpenApiRestCall_605589
proc url_ListCompilationJobs_607399(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompilationJobs_607398(path: JsonNode; query: JsonNode;
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
  var valid_607400 = query.getOrDefault("MaxResults")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "MaxResults", valid_607400
  var valid_607401 = query.getOrDefault("NextToken")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "NextToken", valid_607401
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607402 = header.getOrDefault("X-Amz-Target")
  valid_607402 = validateParameter(valid_607402, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_607402 != nil:
    section.add "X-Amz-Target", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Signature")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Signature", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Content-Sha256", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Date")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Date", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Credential")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Credential", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Security-Token")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Security-Token", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-Algorithm")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-Algorithm", valid_607408
  var valid_607409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-SignedHeaders", valid_607409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607411: Call_ListCompilationJobs_607397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_607411.validator(path, query, header, formData, body)
  let scheme = call_607411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607411.url(scheme.get, call_607411.host, call_607411.base,
                         call_607411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607411, url, valid)

proc call*(call_607412: Call_ListCompilationJobs_607397; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607413 = newJObject()
  var body_607414 = newJObject()
  add(query_607413, "MaxResults", newJString(MaxResults))
  add(query_607413, "NextToken", newJString(NextToken))
  if body != nil:
    body_607414 = body
  result = call_607412.call(nil, query_607413, nil, nil, body_607414)

var listCompilationJobs* = Call_ListCompilationJobs_607397(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_607398, base: "/",
    url: url_ListCompilationJobs_607399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_607415 = ref object of OpenApiRestCall_605589
proc url_ListDomains_607417(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_607416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607418 = query.getOrDefault("MaxResults")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "MaxResults", valid_607418
  var valid_607419 = query.getOrDefault("NextToken")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "NextToken", valid_607419
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607420 = header.getOrDefault("X-Amz-Target")
  valid_607420 = validateParameter(valid_607420, JString, required = true,
                                 default = newJString("SageMaker.ListDomains"))
  if valid_607420 != nil:
    section.add "X-Amz-Target", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Signature")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Signature", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Content-Sha256", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-Date")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-Date", valid_607423
  var valid_607424 = header.getOrDefault("X-Amz-Credential")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "X-Amz-Credential", valid_607424
  var valid_607425 = header.getOrDefault("X-Amz-Security-Token")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "X-Amz-Security-Token", valid_607425
  var valid_607426 = header.getOrDefault("X-Amz-Algorithm")
  valid_607426 = validateParameter(valid_607426, JString, required = false,
                                 default = nil)
  if valid_607426 != nil:
    section.add "X-Amz-Algorithm", valid_607426
  var valid_607427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607427 = validateParameter(valid_607427, JString, required = false,
                                 default = nil)
  if valid_607427 != nil:
    section.add "X-Amz-SignedHeaders", valid_607427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607429: Call_ListDomains_607415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_607429.validator(path, query, header, formData, body)
  let scheme = call_607429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607429.url(scheme.get, call_607429.host, call_607429.base,
                         call_607429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607429, url, valid)

proc call*(call_607430: Call_ListDomains_607415; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607431 = newJObject()
  var body_607432 = newJObject()
  add(query_607431, "MaxResults", newJString(MaxResults))
  add(query_607431, "NextToken", newJString(NextToken))
  if body != nil:
    body_607432 = body
  result = call_607430.call(nil, query_607431, nil, nil, body_607432)

var listDomains* = Call_ListDomains_607415(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListDomains",
                                        validator: validate_ListDomains_607416,
                                        base: "/", url: url_ListDomains_607417,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_607433 = ref object of OpenApiRestCall_605589
proc url_ListEndpointConfigs_607435(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpointConfigs_607434(path: JsonNode; query: JsonNode;
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
  var valid_607436 = query.getOrDefault("MaxResults")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "MaxResults", valid_607436
  var valid_607437 = query.getOrDefault("NextToken")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "NextToken", valid_607437
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607438 = header.getOrDefault("X-Amz-Target")
  valid_607438 = validateParameter(valid_607438, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_607438 != nil:
    section.add "X-Amz-Target", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Signature")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Signature", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Content-Sha256", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Date")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Date", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Credential")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Credential", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Security-Token")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Security-Token", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-Algorithm")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-Algorithm", valid_607444
  var valid_607445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607445 = validateParameter(valid_607445, JString, required = false,
                                 default = nil)
  if valid_607445 != nil:
    section.add "X-Amz-SignedHeaders", valid_607445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607447: Call_ListEndpointConfigs_607433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_607447.validator(path, query, header, formData, body)
  let scheme = call_607447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607447.url(scheme.get, call_607447.host, call_607447.base,
                         call_607447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607447, url, valid)

proc call*(call_607448: Call_ListEndpointConfigs_607433; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607449 = newJObject()
  var body_607450 = newJObject()
  add(query_607449, "MaxResults", newJString(MaxResults))
  add(query_607449, "NextToken", newJString(NextToken))
  if body != nil:
    body_607450 = body
  result = call_607448.call(nil, query_607449, nil, nil, body_607450)

var listEndpointConfigs* = Call_ListEndpointConfigs_607433(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_607434, base: "/",
    url: url_ListEndpointConfigs_607435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_607451 = ref object of OpenApiRestCall_605589
proc url_ListEndpoints_607453(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_607452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607454 = query.getOrDefault("MaxResults")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "MaxResults", valid_607454
  var valid_607455 = query.getOrDefault("NextToken")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "NextToken", valid_607455
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607456 = header.getOrDefault("X-Amz-Target")
  valid_607456 = validateParameter(valid_607456, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_607456 != nil:
    section.add "X-Amz-Target", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Signature")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Signature", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Content-Sha256", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-Date")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-Date", valid_607459
  var valid_607460 = header.getOrDefault("X-Amz-Credential")
  valid_607460 = validateParameter(valid_607460, JString, required = false,
                                 default = nil)
  if valid_607460 != nil:
    section.add "X-Amz-Credential", valid_607460
  var valid_607461 = header.getOrDefault("X-Amz-Security-Token")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "X-Amz-Security-Token", valid_607461
  var valid_607462 = header.getOrDefault("X-Amz-Algorithm")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "X-Amz-Algorithm", valid_607462
  var valid_607463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607463 = validateParameter(valid_607463, JString, required = false,
                                 default = nil)
  if valid_607463 != nil:
    section.add "X-Amz-SignedHeaders", valid_607463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607465: Call_ListEndpoints_607451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_607465.validator(path, query, header, formData, body)
  let scheme = call_607465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607465.url(scheme.get, call_607465.host, call_607465.base,
                         call_607465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607465, url, valid)

proc call*(call_607466: Call_ListEndpoints_607451; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607467 = newJObject()
  var body_607468 = newJObject()
  add(query_607467, "MaxResults", newJString(MaxResults))
  add(query_607467, "NextToken", newJString(NextToken))
  if body != nil:
    body_607468 = body
  result = call_607466.call(nil, query_607467, nil, nil, body_607468)

var listEndpoints* = Call_ListEndpoints_607451(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_607452, base: "/", url: url_ListEndpoints_607453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_607469 = ref object of OpenApiRestCall_605589
proc url_ListExperiments_607471(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExperiments_607470(path: JsonNode; query: JsonNode;
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
  var valid_607472 = query.getOrDefault("MaxResults")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "MaxResults", valid_607472
  var valid_607473 = query.getOrDefault("NextToken")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "NextToken", valid_607473
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607474 = header.getOrDefault("X-Amz-Target")
  valid_607474 = validateParameter(valid_607474, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_607474 != nil:
    section.add "X-Amz-Target", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Signature")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Signature", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Content-Sha256", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-Date")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Date", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Credential")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Credential", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Security-Token")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Security-Token", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-Algorithm")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-Algorithm", valid_607480
  var valid_607481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607481 = validateParameter(valid_607481, JString, required = false,
                                 default = nil)
  if valid_607481 != nil:
    section.add "X-Amz-SignedHeaders", valid_607481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607483: Call_ListExperiments_607469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_607483.validator(path, query, header, formData, body)
  let scheme = call_607483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607483.url(scheme.get, call_607483.host, call_607483.base,
                         call_607483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607483, url, valid)

proc call*(call_607484: Call_ListExperiments_607469; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607485 = newJObject()
  var body_607486 = newJObject()
  add(query_607485, "MaxResults", newJString(MaxResults))
  add(query_607485, "NextToken", newJString(NextToken))
  if body != nil:
    body_607486 = body
  result = call_607484.call(nil, query_607485, nil, nil, body_607486)

var listExperiments* = Call_ListExperiments_607469(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_607470, base: "/", url: url_ListExperiments_607471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_607487 = ref object of OpenApiRestCall_605589
proc url_ListFlowDefinitions_607489(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowDefinitions_607488(path: JsonNode; query: JsonNode;
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
  var valid_607490 = query.getOrDefault("MaxResults")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "MaxResults", valid_607490
  var valid_607491 = query.getOrDefault("NextToken")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "NextToken", valid_607491
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607492 = header.getOrDefault("X-Amz-Target")
  valid_607492 = validateParameter(valid_607492, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_607492 != nil:
    section.add "X-Amz-Target", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Signature")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Signature", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-Content-Sha256", valid_607494
  var valid_607495 = header.getOrDefault("X-Amz-Date")
  valid_607495 = validateParameter(valid_607495, JString, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "X-Amz-Date", valid_607495
  var valid_607496 = header.getOrDefault("X-Amz-Credential")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "X-Amz-Credential", valid_607496
  var valid_607497 = header.getOrDefault("X-Amz-Security-Token")
  valid_607497 = validateParameter(valid_607497, JString, required = false,
                                 default = nil)
  if valid_607497 != nil:
    section.add "X-Amz-Security-Token", valid_607497
  var valid_607498 = header.getOrDefault("X-Amz-Algorithm")
  valid_607498 = validateParameter(valid_607498, JString, required = false,
                                 default = nil)
  if valid_607498 != nil:
    section.add "X-Amz-Algorithm", valid_607498
  var valid_607499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607499 = validateParameter(valid_607499, JString, required = false,
                                 default = nil)
  if valid_607499 != nil:
    section.add "X-Amz-SignedHeaders", valid_607499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607501: Call_ListFlowDefinitions_607487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_607501.validator(path, query, header, formData, body)
  let scheme = call_607501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607501.url(scheme.get, call_607501.host, call_607501.base,
                         call_607501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607501, url, valid)

proc call*(call_607502: Call_ListFlowDefinitions_607487; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607503 = newJObject()
  var body_607504 = newJObject()
  add(query_607503, "MaxResults", newJString(MaxResults))
  add(query_607503, "NextToken", newJString(NextToken))
  if body != nil:
    body_607504 = body
  result = call_607502.call(nil, query_607503, nil, nil, body_607504)

var listFlowDefinitions* = Call_ListFlowDefinitions_607487(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_607488, base: "/",
    url: url_ListFlowDefinitions_607489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_607505 = ref object of OpenApiRestCall_605589
proc url_ListHumanTaskUis_607507(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanTaskUis_607506(path: JsonNode; query: JsonNode;
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
  var valid_607508 = query.getOrDefault("MaxResults")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "MaxResults", valid_607508
  var valid_607509 = query.getOrDefault("NextToken")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "NextToken", valid_607509
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607510 = header.getOrDefault("X-Amz-Target")
  valid_607510 = validateParameter(valid_607510, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_607510 != nil:
    section.add "X-Amz-Target", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Signature")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Signature", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Content-Sha256", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Date")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Date", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Credential")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Credential", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Security-Token")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Security-Token", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-Algorithm")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-Algorithm", valid_607516
  var valid_607517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607517 = validateParameter(valid_607517, JString, required = false,
                                 default = nil)
  if valid_607517 != nil:
    section.add "X-Amz-SignedHeaders", valid_607517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607519: Call_ListHumanTaskUis_607505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_607519.validator(path, query, header, formData, body)
  let scheme = call_607519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607519.url(scheme.get, call_607519.host, call_607519.base,
                         call_607519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607519, url, valid)

proc call*(call_607520: Call_ListHumanTaskUis_607505; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607521 = newJObject()
  var body_607522 = newJObject()
  add(query_607521, "MaxResults", newJString(MaxResults))
  add(query_607521, "NextToken", newJString(NextToken))
  if body != nil:
    body_607522 = body
  result = call_607520.call(nil, query_607521, nil, nil, body_607522)

var listHumanTaskUis* = Call_ListHumanTaskUis_607505(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_607506, base: "/",
    url: url_ListHumanTaskUis_607507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_607523 = ref object of OpenApiRestCall_605589
proc url_ListHyperParameterTuningJobs_607525(protocol: Scheme; host: string;
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

proc validate_ListHyperParameterTuningJobs_607524(path: JsonNode; query: JsonNode;
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
  var valid_607526 = query.getOrDefault("MaxResults")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "MaxResults", valid_607526
  var valid_607527 = query.getOrDefault("NextToken")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "NextToken", valid_607527
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607528 = header.getOrDefault("X-Amz-Target")
  valid_607528 = validateParameter(valid_607528, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_607528 != nil:
    section.add "X-Amz-Target", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Signature")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Signature", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Content-Sha256", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-Date")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-Date", valid_607531
  var valid_607532 = header.getOrDefault("X-Amz-Credential")
  valid_607532 = validateParameter(valid_607532, JString, required = false,
                                 default = nil)
  if valid_607532 != nil:
    section.add "X-Amz-Credential", valid_607532
  var valid_607533 = header.getOrDefault("X-Amz-Security-Token")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "X-Amz-Security-Token", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Algorithm")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Algorithm", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-SignedHeaders", valid_607535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607537: Call_ListHyperParameterTuningJobs_607523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_607537.validator(path, query, header, formData, body)
  let scheme = call_607537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607537.url(scheme.get, call_607537.host, call_607537.base,
                         call_607537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607537, url, valid)

proc call*(call_607538: Call_ListHyperParameterTuningJobs_607523; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607539 = newJObject()
  var body_607540 = newJObject()
  add(query_607539, "MaxResults", newJString(MaxResults))
  add(query_607539, "NextToken", newJString(NextToken))
  if body != nil:
    body_607540 = body
  result = call_607538.call(nil, query_607539, nil, nil, body_607540)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_607523(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_607524, base: "/",
    url: url_ListHyperParameterTuningJobs_607525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_607541 = ref object of OpenApiRestCall_605589
proc url_ListLabelingJobs_607543(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobs_607542(path: JsonNode; query: JsonNode;
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
  var valid_607544 = query.getOrDefault("MaxResults")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "MaxResults", valid_607544
  var valid_607545 = query.getOrDefault("NextToken")
  valid_607545 = validateParameter(valid_607545, JString, required = false,
                                 default = nil)
  if valid_607545 != nil:
    section.add "NextToken", valid_607545
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607546 = header.getOrDefault("X-Amz-Target")
  valid_607546 = validateParameter(valid_607546, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_607546 != nil:
    section.add "X-Amz-Target", valid_607546
  var valid_607547 = header.getOrDefault("X-Amz-Signature")
  valid_607547 = validateParameter(valid_607547, JString, required = false,
                                 default = nil)
  if valid_607547 != nil:
    section.add "X-Amz-Signature", valid_607547
  var valid_607548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Content-Sha256", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Date")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Date", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Credential")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Credential", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Security-Token")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Security-Token", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Algorithm")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Algorithm", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-SignedHeaders", valid_607553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607555: Call_ListLabelingJobs_607541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_607555.validator(path, query, header, formData, body)
  let scheme = call_607555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607555.url(scheme.get, call_607555.host, call_607555.base,
                         call_607555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607555, url, valid)

proc call*(call_607556: Call_ListLabelingJobs_607541; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607557 = newJObject()
  var body_607558 = newJObject()
  add(query_607557, "MaxResults", newJString(MaxResults))
  add(query_607557, "NextToken", newJString(NextToken))
  if body != nil:
    body_607558 = body
  result = call_607556.call(nil, query_607557, nil, nil, body_607558)

var listLabelingJobs* = Call_ListLabelingJobs_607541(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_607542, base: "/",
    url: url_ListLabelingJobs_607543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_607559 = ref object of OpenApiRestCall_605589
proc url_ListLabelingJobsForWorkteam_607561(protocol: Scheme; host: string;
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

proc validate_ListLabelingJobsForWorkteam_607560(path: JsonNode; query: JsonNode;
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
  var valid_607562 = query.getOrDefault("MaxResults")
  valid_607562 = validateParameter(valid_607562, JString, required = false,
                                 default = nil)
  if valid_607562 != nil:
    section.add "MaxResults", valid_607562
  var valid_607563 = query.getOrDefault("NextToken")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "NextToken", valid_607563
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607564 = header.getOrDefault("X-Amz-Target")
  valid_607564 = validateParameter(valid_607564, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_607564 != nil:
    section.add "X-Amz-Target", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Signature")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Signature", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Content-Sha256", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Date")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Date", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Credential")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Credential", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Security-Token")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Security-Token", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-Algorithm")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-Algorithm", valid_607570
  var valid_607571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "X-Amz-SignedHeaders", valid_607571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607573: Call_ListLabelingJobsForWorkteam_607559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_607573.validator(path, query, header, formData, body)
  let scheme = call_607573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607573.url(scheme.get, call_607573.host, call_607573.base,
                         call_607573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607573, url, valid)

proc call*(call_607574: Call_ListLabelingJobsForWorkteam_607559; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607575 = newJObject()
  var body_607576 = newJObject()
  add(query_607575, "MaxResults", newJString(MaxResults))
  add(query_607575, "NextToken", newJString(NextToken))
  if body != nil:
    body_607576 = body
  result = call_607574.call(nil, query_607575, nil, nil, body_607576)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_607559(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_607560, base: "/",
    url: url_ListLabelingJobsForWorkteam_607561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_607577 = ref object of OpenApiRestCall_605589
proc url_ListModelPackages_607579(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModelPackages_607578(path: JsonNode; query: JsonNode;
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
  var valid_607580 = query.getOrDefault("MaxResults")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "MaxResults", valid_607580
  var valid_607581 = query.getOrDefault("NextToken")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "NextToken", valid_607581
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607582 = header.getOrDefault("X-Amz-Target")
  valid_607582 = validateParameter(valid_607582, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_607582 != nil:
    section.add "X-Amz-Target", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-Signature")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-Signature", valid_607583
  var valid_607584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "X-Amz-Content-Sha256", valid_607584
  var valid_607585 = header.getOrDefault("X-Amz-Date")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "X-Amz-Date", valid_607585
  var valid_607586 = header.getOrDefault("X-Amz-Credential")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "X-Amz-Credential", valid_607586
  var valid_607587 = header.getOrDefault("X-Amz-Security-Token")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "X-Amz-Security-Token", valid_607587
  var valid_607588 = header.getOrDefault("X-Amz-Algorithm")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "X-Amz-Algorithm", valid_607588
  var valid_607589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "X-Amz-SignedHeaders", valid_607589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607591: Call_ListModelPackages_607577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_607591.validator(path, query, header, formData, body)
  let scheme = call_607591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607591.url(scheme.get, call_607591.host, call_607591.base,
                         call_607591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607591, url, valid)

proc call*(call_607592: Call_ListModelPackages_607577; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607593 = newJObject()
  var body_607594 = newJObject()
  add(query_607593, "MaxResults", newJString(MaxResults))
  add(query_607593, "NextToken", newJString(NextToken))
  if body != nil:
    body_607594 = body
  result = call_607592.call(nil, query_607593, nil, nil, body_607594)

var listModelPackages* = Call_ListModelPackages_607577(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_607578, base: "/",
    url: url_ListModelPackages_607579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_607595 = ref object of OpenApiRestCall_605589
proc url_ListModels_607597(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListModels_607596(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607598 = query.getOrDefault("MaxResults")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "MaxResults", valid_607598
  var valid_607599 = query.getOrDefault("NextToken")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "NextToken", valid_607599
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607600 = header.getOrDefault("X-Amz-Target")
  valid_607600 = validateParameter(valid_607600, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_607600 != nil:
    section.add "X-Amz-Target", valid_607600
  var valid_607601 = header.getOrDefault("X-Amz-Signature")
  valid_607601 = validateParameter(valid_607601, JString, required = false,
                                 default = nil)
  if valid_607601 != nil:
    section.add "X-Amz-Signature", valid_607601
  var valid_607602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Content-Sha256", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Date")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Date", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Credential")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Credential", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Security-Token")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Security-Token", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Algorithm")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Algorithm", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-SignedHeaders", valid_607607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607609: Call_ListModels_607595; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_607609.validator(path, query, header, formData, body)
  let scheme = call_607609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607609.url(scheme.get, call_607609.host, call_607609.base,
                         call_607609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607609, url, valid)

proc call*(call_607610: Call_ListModels_607595; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607611 = newJObject()
  var body_607612 = newJObject()
  add(query_607611, "MaxResults", newJString(MaxResults))
  add(query_607611, "NextToken", newJString(NextToken))
  if body != nil:
    body_607612 = body
  result = call_607610.call(nil, query_607611, nil, nil, body_607612)

var listModels* = Call_ListModels_607595(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_607596,
                                      base: "/", url: url_ListModels_607597,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_607613 = ref object of OpenApiRestCall_605589
proc url_ListMonitoringExecutions_607615(protocol: Scheme; host: string;
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

proc validate_ListMonitoringExecutions_607614(path: JsonNode; query: JsonNode;
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
  var valid_607616 = query.getOrDefault("MaxResults")
  valid_607616 = validateParameter(valid_607616, JString, required = false,
                                 default = nil)
  if valid_607616 != nil:
    section.add "MaxResults", valid_607616
  var valid_607617 = query.getOrDefault("NextToken")
  valid_607617 = validateParameter(valid_607617, JString, required = false,
                                 default = nil)
  if valid_607617 != nil:
    section.add "NextToken", valid_607617
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607618 = header.getOrDefault("X-Amz-Target")
  valid_607618 = validateParameter(valid_607618, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_607618 != nil:
    section.add "X-Amz-Target", valid_607618
  var valid_607619 = header.getOrDefault("X-Amz-Signature")
  valid_607619 = validateParameter(valid_607619, JString, required = false,
                                 default = nil)
  if valid_607619 != nil:
    section.add "X-Amz-Signature", valid_607619
  var valid_607620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607620 = validateParameter(valid_607620, JString, required = false,
                                 default = nil)
  if valid_607620 != nil:
    section.add "X-Amz-Content-Sha256", valid_607620
  var valid_607621 = header.getOrDefault("X-Amz-Date")
  valid_607621 = validateParameter(valid_607621, JString, required = false,
                                 default = nil)
  if valid_607621 != nil:
    section.add "X-Amz-Date", valid_607621
  var valid_607622 = header.getOrDefault("X-Amz-Credential")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "X-Amz-Credential", valid_607622
  var valid_607623 = header.getOrDefault("X-Amz-Security-Token")
  valid_607623 = validateParameter(valid_607623, JString, required = false,
                                 default = nil)
  if valid_607623 != nil:
    section.add "X-Amz-Security-Token", valid_607623
  var valid_607624 = header.getOrDefault("X-Amz-Algorithm")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Algorithm", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-SignedHeaders", valid_607625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607627: Call_ListMonitoringExecutions_607613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_607627.validator(path, query, header, formData, body)
  let scheme = call_607627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607627.url(scheme.get, call_607627.host, call_607627.base,
                         call_607627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607627, url, valid)

proc call*(call_607628: Call_ListMonitoringExecutions_607613; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607629 = newJObject()
  var body_607630 = newJObject()
  add(query_607629, "MaxResults", newJString(MaxResults))
  add(query_607629, "NextToken", newJString(NextToken))
  if body != nil:
    body_607630 = body
  result = call_607628.call(nil, query_607629, nil, nil, body_607630)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_607613(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_607614, base: "/",
    url: url_ListMonitoringExecutions_607615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_607631 = ref object of OpenApiRestCall_605589
proc url_ListMonitoringSchedules_607633(protocol: Scheme; host: string; base: string;
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

proc validate_ListMonitoringSchedules_607632(path: JsonNode; query: JsonNode;
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
  var valid_607634 = query.getOrDefault("MaxResults")
  valid_607634 = validateParameter(valid_607634, JString, required = false,
                                 default = nil)
  if valid_607634 != nil:
    section.add "MaxResults", valid_607634
  var valid_607635 = query.getOrDefault("NextToken")
  valid_607635 = validateParameter(valid_607635, JString, required = false,
                                 default = nil)
  if valid_607635 != nil:
    section.add "NextToken", valid_607635
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607636 = header.getOrDefault("X-Amz-Target")
  valid_607636 = validateParameter(valid_607636, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_607636 != nil:
    section.add "X-Amz-Target", valid_607636
  var valid_607637 = header.getOrDefault("X-Amz-Signature")
  valid_607637 = validateParameter(valid_607637, JString, required = false,
                                 default = nil)
  if valid_607637 != nil:
    section.add "X-Amz-Signature", valid_607637
  var valid_607638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607638 = validateParameter(valid_607638, JString, required = false,
                                 default = nil)
  if valid_607638 != nil:
    section.add "X-Amz-Content-Sha256", valid_607638
  var valid_607639 = header.getOrDefault("X-Amz-Date")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Date", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Credential")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Credential", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Security-Token")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Security-Token", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Algorithm")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Algorithm", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-SignedHeaders", valid_607643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607645: Call_ListMonitoringSchedules_607631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_607645.validator(path, query, header, formData, body)
  let scheme = call_607645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607645.url(scheme.get, call_607645.host, call_607645.base,
                         call_607645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607645, url, valid)

proc call*(call_607646: Call_ListMonitoringSchedules_607631; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607647 = newJObject()
  var body_607648 = newJObject()
  add(query_607647, "MaxResults", newJString(MaxResults))
  add(query_607647, "NextToken", newJString(NextToken))
  if body != nil:
    body_607648 = body
  result = call_607646.call(nil, query_607647, nil, nil, body_607648)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_607631(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_607632, base: "/",
    url: url_ListMonitoringSchedules_607633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_607649 = ref object of OpenApiRestCall_605589
proc url_ListNotebookInstanceLifecycleConfigs_607651(protocol: Scheme;
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

proc validate_ListNotebookInstanceLifecycleConfigs_607650(path: JsonNode;
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
  var valid_607652 = query.getOrDefault("MaxResults")
  valid_607652 = validateParameter(valid_607652, JString, required = false,
                                 default = nil)
  if valid_607652 != nil:
    section.add "MaxResults", valid_607652
  var valid_607653 = query.getOrDefault("NextToken")
  valid_607653 = validateParameter(valid_607653, JString, required = false,
                                 default = nil)
  if valid_607653 != nil:
    section.add "NextToken", valid_607653
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607654 = header.getOrDefault("X-Amz-Target")
  valid_607654 = validateParameter(valid_607654, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_607654 != nil:
    section.add "X-Amz-Target", valid_607654
  var valid_607655 = header.getOrDefault("X-Amz-Signature")
  valid_607655 = validateParameter(valid_607655, JString, required = false,
                                 default = nil)
  if valid_607655 != nil:
    section.add "X-Amz-Signature", valid_607655
  var valid_607656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "X-Amz-Content-Sha256", valid_607656
  var valid_607657 = header.getOrDefault("X-Amz-Date")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "X-Amz-Date", valid_607657
  var valid_607658 = header.getOrDefault("X-Amz-Credential")
  valid_607658 = validateParameter(valid_607658, JString, required = false,
                                 default = nil)
  if valid_607658 != nil:
    section.add "X-Amz-Credential", valid_607658
  var valid_607659 = header.getOrDefault("X-Amz-Security-Token")
  valid_607659 = validateParameter(valid_607659, JString, required = false,
                                 default = nil)
  if valid_607659 != nil:
    section.add "X-Amz-Security-Token", valid_607659
  var valid_607660 = header.getOrDefault("X-Amz-Algorithm")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Algorithm", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-SignedHeaders", valid_607661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607663: Call_ListNotebookInstanceLifecycleConfigs_607649;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_607663.validator(path, query, header, formData, body)
  let scheme = call_607663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607663.url(scheme.get, call_607663.host, call_607663.base,
                         call_607663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607663, url, valid)

proc call*(call_607664: Call_ListNotebookInstanceLifecycleConfigs_607649;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607665 = newJObject()
  var body_607666 = newJObject()
  add(query_607665, "MaxResults", newJString(MaxResults))
  add(query_607665, "NextToken", newJString(NextToken))
  if body != nil:
    body_607666 = body
  result = call_607664.call(nil, query_607665, nil, nil, body_607666)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_607649(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_607650, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_607651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_607667 = ref object of OpenApiRestCall_605589
proc url_ListNotebookInstances_607669(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstances_607668(path: JsonNode; query: JsonNode;
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
  var valid_607670 = query.getOrDefault("MaxResults")
  valid_607670 = validateParameter(valid_607670, JString, required = false,
                                 default = nil)
  if valid_607670 != nil:
    section.add "MaxResults", valid_607670
  var valid_607671 = query.getOrDefault("NextToken")
  valid_607671 = validateParameter(valid_607671, JString, required = false,
                                 default = nil)
  if valid_607671 != nil:
    section.add "NextToken", valid_607671
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607672 = header.getOrDefault("X-Amz-Target")
  valid_607672 = validateParameter(valid_607672, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_607672 != nil:
    section.add "X-Amz-Target", valid_607672
  var valid_607673 = header.getOrDefault("X-Amz-Signature")
  valid_607673 = validateParameter(valid_607673, JString, required = false,
                                 default = nil)
  if valid_607673 != nil:
    section.add "X-Amz-Signature", valid_607673
  var valid_607674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607674 = validateParameter(valid_607674, JString, required = false,
                                 default = nil)
  if valid_607674 != nil:
    section.add "X-Amz-Content-Sha256", valid_607674
  var valid_607675 = header.getOrDefault("X-Amz-Date")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Date", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Credential")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Credential", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-Security-Token")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-Security-Token", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-Algorithm")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-Algorithm", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-SignedHeaders", valid_607679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607681: Call_ListNotebookInstances_607667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_607681.validator(path, query, header, formData, body)
  let scheme = call_607681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607681.url(scheme.get, call_607681.host, call_607681.base,
                         call_607681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607681, url, valid)

proc call*(call_607682: Call_ListNotebookInstances_607667; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607683 = newJObject()
  var body_607684 = newJObject()
  add(query_607683, "MaxResults", newJString(MaxResults))
  add(query_607683, "NextToken", newJString(NextToken))
  if body != nil:
    body_607684 = body
  result = call_607682.call(nil, query_607683, nil, nil, body_607684)

var listNotebookInstances* = Call_ListNotebookInstances_607667(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_607668, base: "/",
    url: url_ListNotebookInstances_607669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_607685 = ref object of OpenApiRestCall_605589
proc url_ListProcessingJobs_607687(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProcessingJobs_607686(path: JsonNode; query: JsonNode;
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
  var valid_607688 = query.getOrDefault("MaxResults")
  valid_607688 = validateParameter(valid_607688, JString, required = false,
                                 default = nil)
  if valid_607688 != nil:
    section.add "MaxResults", valid_607688
  var valid_607689 = query.getOrDefault("NextToken")
  valid_607689 = validateParameter(valid_607689, JString, required = false,
                                 default = nil)
  if valid_607689 != nil:
    section.add "NextToken", valid_607689
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607690 = header.getOrDefault("X-Amz-Target")
  valid_607690 = validateParameter(valid_607690, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_607690 != nil:
    section.add "X-Amz-Target", valid_607690
  var valid_607691 = header.getOrDefault("X-Amz-Signature")
  valid_607691 = validateParameter(valid_607691, JString, required = false,
                                 default = nil)
  if valid_607691 != nil:
    section.add "X-Amz-Signature", valid_607691
  var valid_607692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607692 = validateParameter(valid_607692, JString, required = false,
                                 default = nil)
  if valid_607692 != nil:
    section.add "X-Amz-Content-Sha256", valid_607692
  var valid_607693 = header.getOrDefault("X-Amz-Date")
  valid_607693 = validateParameter(valid_607693, JString, required = false,
                                 default = nil)
  if valid_607693 != nil:
    section.add "X-Amz-Date", valid_607693
  var valid_607694 = header.getOrDefault("X-Amz-Credential")
  valid_607694 = validateParameter(valid_607694, JString, required = false,
                                 default = nil)
  if valid_607694 != nil:
    section.add "X-Amz-Credential", valid_607694
  var valid_607695 = header.getOrDefault("X-Amz-Security-Token")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "X-Amz-Security-Token", valid_607695
  var valid_607696 = header.getOrDefault("X-Amz-Algorithm")
  valid_607696 = validateParameter(valid_607696, JString, required = false,
                                 default = nil)
  if valid_607696 != nil:
    section.add "X-Amz-Algorithm", valid_607696
  var valid_607697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-SignedHeaders", valid_607697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607699: Call_ListProcessingJobs_607685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_607699.validator(path, query, header, formData, body)
  let scheme = call_607699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607699.url(scheme.get, call_607699.host, call_607699.base,
                         call_607699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607699, url, valid)

proc call*(call_607700: Call_ListProcessingJobs_607685; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607701 = newJObject()
  var body_607702 = newJObject()
  add(query_607701, "MaxResults", newJString(MaxResults))
  add(query_607701, "NextToken", newJString(NextToken))
  if body != nil:
    body_607702 = body
  result = call_607700.call(nil, query_607701, nil, nil, body_607702)

var listProcessingJobs* = Call_ListProcessingJobs_607685(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_607686, base: "/",
    url: url_ListProcessingJobs_607687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_607703 = ref object of OpenApiRestCall_605589
proc url_ListSubscribedWorkteams_607705(protocol: Scheme; host: string; base: string;
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

proc validate_ListSubscribedWorkteams_607704(path: JsonNode; query: JsonNode;
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
  var valid_607706 = query.getOrDefault("MaxResults")
  valid_607706 = validateParameter(valid_607706, JString, required = false,
                                 default = nil)
  if valid_607706 != nil:
    section.add "MaxResults", valid_607706
  var valid_607707 = query.getOrDefault("NextToken")
  valid_607707 = validateParameter(valid_607707, JString, required = false,
                                 default = nil)
  if valid_607707 != nil:
    section.add "NextToken", valid_607707
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607708 = header.getOrDefault("X-Amz-Target")
  valid_607708 = validateParameter(valid_607708, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_607708 != nil:
    section.add "X-Amz-Target", valid_607708
  var valid_607709 = header.getOrDefault("X-Amz-Signature")
  valid_607709 = validateParameter(valid_607709, JString, required = false,
                                 default = nil)
  if valid_607709 != nil:
    section.add "X-Amz-Signature", valid_607709
  var valid_607710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607710 = validateParameter(valid_607710, JString, required = false,
                                 default = nil)
  if valid_607710 != nil:
    section.add "X-Amz-Content-Sha256", valid_607710
  var valid_607711 = header.getOrDefault("X-Amz-Date")
  valid_607711 = validateParameter(valid_607711, JString, required = false,
                                 default = nil)
  if valid_607711 != nil:
    section.add "X-Amz-Date", valid_607711
  var valid_607712 = header.getOrDefault("X-Amz-Credential")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Credential", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Security-Token")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Security-Token", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Algorithm")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Algorithm", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-SignedHeaders", valid_607715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607717: Call_ListSubscribedWorkteams_607703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_607717.validator(path, query, header, formData, body)
  let scheme = call_607717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607717.url(scheme.get, call_607717.host, call_607717.base,
                         call_607717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607717, url, valid)

proc call*(call_607718: Call_ListSubscribedWorkteams_607703; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607719 = newJObject()
  var body_607720 = newJObject()
  add(query_607719, "MaxResults", newJString(MaxResults))
  add(query_607719, "NextToken", newJString(NextToken))
  if body != nil:
    body_607720 = body
  result = call_607718.call(nil, query_607719, nil, nil, body_607720)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_607703(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_607704, base: "/",
    url: url_ListSubscribedWorkteams_607705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_607721 = ref object of OpenApiRestCall_605589
proc url_ListTags_607723(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_607722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607724 = query.getOrDefault("MaxResults")
  valid_607724 = validateParameter(valid_607724, JString, required = false,
                                 default = nil)
  if valid_607724 != nil:
    section.add "MaxResults", valid_607724
  var valid_607725 = query.getOrDefault("NextToken")
  valid_607725 = validateParameter(valid_607725, JString, required = false,
                                 default = nil)
  if valid_607725 != nil:
    section.add "NextToken", valid_607725
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607726 = header.getOrDefault("X-Amz-Target")
  valid_607726 = validateParameter(valid_607726, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_607726 != nil:
    section.add "X-Amz-Target", valid_607726
  var valid_607727 = header.getOrDefault("X-Amz-Signature")
  valid_607727 = validateParameter(valid_607727, JString, required = false,
                                 default = nil)
  if valid_607727 != nil:
    section.add "X-Amz-Signature", valid_607727
  var valid_607728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607728 = validateParameter(valid_607728, JString, required = false,
                                 default = nil)
  if valid_607728 != nil:
    section.add "X-Amz-Content-Sha256", valid_607728
  var valid_607729 = header.getOrDefault("X-Amz-Date")
  valid_607729 = validateParameter(valid_607729, JString, required = false,
                                 default = nil)
  if valid_607729 != nil:
    section.add "X-Amz-Date", valid_607729
  var valid_607730 = header.getOrDefault("X-Amz-Credential")
  valid_607730 = validateParameter(valid_607730, JString, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "X-Amz-Credential", valid_607730
  var valid_607731 = header.getOrDefault("X-Amz-Security-Token")
  valid_607731 = validateParameter(valid_607731, JString, required = false,
                                 default = nil)
  if valid_607731 != nil:
    section.add "X-Amz-Security-Token", valid_607731
  var valid_607732 = header.getOrDefault("X-Amz-Algorithm")
  valid_607732 = validateParameter(valid_607732, JString, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "X-Amz-Algorithm", valid_607732
  var valid_607733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607733 = validateParameter(valid_607733, JString, required = false,
                                 default = nil)
  if valid_607733 != nil:
    section.add "X-Amz-SignedHeaders", valid_607733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607735: Call_ListTags_607721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_607735.validator(path, query, header, formData, body)
  let scheme = call_607735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607735.url(scheme.get, call_607735.host, call_607735.base,
                         call_607735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607735, url, valid)

proc call*(call_607736: Call_ListTags_607721; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607737 = newJObject()
  var body_607738 = newJObject()
  add(query_607737, "MaxResults", newJString(MaxResults))
  add(query_607737, "NextToken", newJString(NextToken))
  if body != nil:
    body_607738 = body
  result = call_607736.call(nil, query_607737, nil, nil, body_607738)

var listTags* = Call_ListTags_607721(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_607722, base: "/",
                                  url: url_ListTags_607723,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_607739 = ref object of OpenApiRestCall_605589
proc url_ListTrainingJobs_607741(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobs_607740(path: JsonNode; query: JsonNode;
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
  var valid_607742 = query.getOrDefault("MaxResults")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "MaxResults", valid_607742
  var valid_607743 = query.getOrDefault("NextToken")
  valid_607743 = validateParameter(valid_607743, JString, required = false,
                                 default = nil)
  if valid_607743 != nil:
    section.add "NextToken", valid_607743
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607744 = header.getOrDefault("X-Amz-Target")
  valid_607744 = validateParameter(valid_607744, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_607744 != nil:
    section.add "X-Amz-Target", valid_607744
  var valid_607745 = header.getOrDefault("X-Amz-Signature")
  valid_607745 = validateParameter(valid_607745, JString, required = false,
                                 default = nil)
  if valid_607745 != nil:
    section.add "X-Amz-Signature", valid_607745
  var valid_607746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607746 = validateParameter(valid_607746, JString, required = false,
                                 default = nil)
  if valid_607746 != nil:
    section.add "X-Amz-Content-Sha256", valid_607746
  var valid_607747 = header.getOrDefault("X-Amz-Date")
  valid_607747 = validateParameter(valid_607747, JString, required = false,
                                 default = nil)
  if valid_607747 != nil:
    section.add "X-Amz-Date", valid_607747
  var valid_607748 = header.getOrDefault("X-Amz-Credential")
  valid_607748 = validateParameter(valid_607748, JString, required = false,
                                 default = nil)
  if valid_607748 != nil:
    section.add "X-Amz-Credential", valid_607748
  var valid_607749 = header.getOrDefault("X-Amz-Security-Token")
  valid_607749 = validateParameter(valid_607749, JString, required = false,
                                 default = nil)
  if valid_607749 != nil:
    section.add "X-Amz-Security-Token", valid_607749
  var valid_607750 = header.getOrDefault("X-Amz-Algorithm")
  valid_607750 = validateParameter(valid_607750, JString, required = false,
                                 default = nil)
  if valid_607750 != nil:
    section.add "X-Amz-Algorithm", valid_607750
  var valid_607751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607751 = validateParameter(valid_607751, JString, required = false,
                                 default = nil)
  if valid_607751 != nil:
    section.add "X-Amz-SignedHeaders", valid_607751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607753: Call_ListTrainingJobs_607739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_607753.validator(path, query, header, formData, body)
  let scheme = call_607753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607753.url(scheme.get, call_607753.host, call_607753.base,
                         call_607753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607753, url, valid)

proc call*(call_607754: Call_ListTrainingJobs_607739; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607755 = newJObject()
  var body_607756 = newJObject()
  add(query_607755, "MaxResults", newJString(MaxResults))
  add(query_607755, "NextToken", newJString(NextToken))
  if body != nil:
    body_607756 = body
  result = call_607754.call(nil, query_607755, nil, nil, body_607756)

var listTrainingJobs* = Call_ListTrainingJobs_607739(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_607740, base: "/",
    url: url_ListTrainingJobs_607741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_607757 = ref object of OpenApiRestCall_605589
proc url_ListTrainingJobsForHyperParameterTuningJob_607759(protocol: Scheme;
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

proc validate_ListTrainingJobsForHyperParameterTuningJob_607758(path: JsonNode;
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
  var valid_607760 = query.getOrDefault("MaxResults")
  valid_607760 = validateParameter(valid_607760, JString, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "MaxResults", valid_607760
  var valid_607761 = query.getOrDefault("NextToken")
  valid_607761 = validateParameter(valid_607761, JString, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "NextToken", valid_607761
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607762 = header.getOrDefault("X-Amz-Target")
  valid_607762 = validateParameter(valid_607762, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_607762 != nil:
    section.add "X-Amz-Target", valid_607762
  var valid_607763 = header.getOrDefault("X-Amz-Signature")
  valid_607763 = validateParameter(valid_607763, JString, required = false,
                                 default = nil)
  if valid_607763 != nil:
    section.add "X-Amz-Signature", valid_607763
  var valid_607764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607764 = validateParameter(valid_607764, JString, required = false,
                                 default = nil)
  if valid_607764 != nil:
    section.add "X-Amz-Content-Sha256", valid_607764
  var valid_607765 = header.getOrDefault("X-Amz-Date")
  valid_607765 = validateParameter(valid_607765, JString, required = false,
                                 default = nil)
  if valid_607765 != nil:
    section.add "X-Amz-Date", valid_607765
  var valid_607766 = header.getOrDefault("X-Amz-Credential")
  valid_607766 = validateParameter(valid_607766, JString, required = false,
                                 default = nil)
  if valid_607766 != nil:
    section.add "X-Amz-Credential", valid_607766
  var valid_607767 = header.getOrDefault("X-Amz-Security-Token")
  valid_607767 = validateParameter(valid_607767, JString, required = false,
                                 default = nil)
  if valid_607767 != nil:
    section.add "X-Amz-Security-Token", valid_607767
  var valid_607768 = header.getOrDefault("X-Amz-Algorithm")
  valid_607768 = validateParameter(valid_607768, JString, required = false,
                                 default = nil)
  if valid_607768 != nil:
    section.add "X-Amz-Algorithm", valid_607768
  var valid_607769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607769 = validateParameter(valid_607769, JString, required = false,
                                 default = nil)
  if valid_607769 != nil:
    section.add "X-Amz-SignedHeaders", valid_607769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607771: Call_ListTrainingJobsForHyperParameterTuningJob_607757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_607771.validator(path, query, header, formData, body)
  let scheme = call_607771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607771.url(scheme.get, call_607771.host, call_607771.base,
                         call_607771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607771, url, valid)

proc call*(call_607772: Call_ListTrainingJobsForHyperParameterTuningJob_607757;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607773 = newJObject()
  var body_607774 = newJObject()
  add(query_607773, "MaxResults", newJString(MaxResults))
  add(query_607773, "NextToken", newJString(NextToken))
  if body != nil:
    body_607774 = body
  result = call_607772.call(nil, query_607773, nil, nil, body_607774)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_607757(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_607758,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_607759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_607775 = ref object of OpenApiRestCall_605589
proc url_ListTransformJobs_607777(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTransformJobs_607776(path: JsonNode; query: JsonNode;
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
  var valid_607778 = query.getOrDefault("MaxResults")
  valid_607778 = validateParameter(valid_607778, JString, required = false,
                                 default = nil)
  if valid_607778 != nil:
    section.add "MaxResults", valid_607778
  var valid_607779 = query.getOrDefault("NextToken")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "NextToken", valid_607779
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607780 = header.getOrDefault("X-Amz-Target")
  valid_607780 = validateParameter(valid_607780, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_607780 != nil:
    section.add "X-Amz-Target", valid_607780
  var valid_607781 = header.getOrDefault("X-Amz-Signature")
  valid_607781 = validateParameter(valid_607781, JString, required = false,
                                 default = nil)
  if valid_607781 != nil:
    section.add "X-Amz-Signature", valid_607781
  var valid_607782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607782 = validateParameter(valid_607782, JString, required = false,
                                 default = nil)
  if valid_607782 != nil:
    section.add "X-Amz-Content-Sha256", valid_607782
  var valid_607783 = header.getOrDefault("X-Amz-Date")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = nil)
  if valid_607783 != nil:
    section.add "X-Amz-Date", valid_607783
  var valid_607784 = header.getOrDefault("X-Amz-Credential")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "X-Amz-Credential", valid_607784
  var valid_607785 = header.getOrDefault("X-Amz-Security-Token")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "X-Amz-Security-Token", valid_607785
  var valid_607786 = header.getOrDefault("X-Amz-Algorithm")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Algorithm", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-SignedHeaders", valid_607787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607789: Call_ListTransformJobs_607775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_607789.validator(path, query, header, formData, body)
  let scheme = call_607789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607789.url(scheme.get, call_607789.host, call_607789.base,
                         call_607789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607789, url, valid)

proc call*(call_607790: Call_ListTransformJobs_607775; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607791 = newJObject()
  var body_607792 = newJObject()
  add(query_607791, "MaxResults", newJString(MaxResults))
  add(query_607791, "NextToken", newJString(NextToken))
  if body != nil:
    body_607792 = body
  result = call_607790.call(nil, query_607791, nil, nil, body_607792)

var listTransformJobs* = Call_ListTransformJobs_607775(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_607776, base: "/",
    url: url_ListTransformJobs_607777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_607793 = ref object of OpenApiRestCall_605589
proc url_ListTrialComponents_607795(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrialComponents_607794(path: JsonNode; query: JsonNode;
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
  var valid_607796 = query.getOrDefault("MaxResults")
  valid_607796 = validateParameter(valid_607796, JString, required = false,
                                 default = nil)
  if valid_607796 != nil:
    section.add "MaxResults", valid_607796
  var valid_607797 = query.getOrDefault("NextToken")
  valid_607797 = validateParameter(valid_607797, JString, required = false,
                                 default = nil)
  if valid_607797 != nil:
    section.add "NextToken", valid_607797
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607798 = header.getOrDefault("X-Amz-Target")
  valid_607798 = validateParameter(valid_607798, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_607798 != nil:
    section.add "X-Amz-Target", valid_607798
  var valid_607799 = header.getOrDefault("X-Amz-Signature")
  valid_607799 = validateParameter(valid_607799, JString, required = false,
                                 default = nil)
  if valid_607799 != nil:
    section.add "X-Amz-Signature", valid_607799
  var valid_607800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607800 = validateParameter(valid_607800, JString, required = false,
                                 default = nil)
  if valid_607800 != nil:
    section.add "X-Amz-Content-Sha256", valid_607800
  var valid_607801 = header.getOrDefault("X-Amz-Date")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Date", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Credential")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Credential", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Security-Token")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Security-Token", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Algorithm")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Algorithm", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-SignedHeaders", valid_607805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607807: Call_ListTrialComponents_607793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ## 
  let valid = call_607807.validator(path, query, header, formData, body)
  let scheme = call_607807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607807.url(scheme.get, call_607807.host, call_607807.base,
                         call_607807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607807, url, valid)

proc call*(call_607808: Call_ListTrialComponents_607793; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607809 = newJObject()
  var body_607810 = newJObject()
  add(query_607809, "MaxResults", newJString(MaxResults))
  add(query_607809, "NextToken", newJString(NextToken))
  if body != nil:
    body_607810 = body
  result = call_607808.call(nil, query_607809, nil, nil, body_607810)

var listTrialComponents* = Call_ListTrialComponents_607793(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_607794, base: "/",
    url: url_ListTrialComponents_607795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_607811 = ref object of OpenApiRestCall_605589
proc url_ListTrials_607813(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTrials_607812(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607814 = query.getOrDefault("MaxResults")
  valid_607814 = validateParameter(valid_607814, JString, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "MaxResults", valid_607814
  var valid_607815 = query.getOrDefault("NextToken")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "NextToken", valid_607815
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607816 = header.getOrDefault("X-Amz-Target")
  valid_607816 = validateParameter(valid_607816, JString, required = true,
                                 default = newJString("SageMaker.ListTrials"))
  if valid_607816 != nil:
    section.add "X-Amz-Target", valid_607816
  var valid_607817 = header.getOrDefault("X-Amz-Signature")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "X-Amz-Signature", valid_607817
  var valid_607818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "X-Amz-Content-Sha256", valid_607818
  var valid_607819 = header.getOrDefault("X-Amz-Date")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "X-Amz-Date", valid_607819
  var valid_607820 = header.getOrDefault("X-Amz-Credential")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "X-Amz-Credential", valid_607820
  var valid_607821 = header.getOrDefault("X-Amz-Security-Token")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "X-Amz-Security-Token", valid_607821
  var valid_607822 = header.getOrDefault("X-Amz-Algorithm")
  valid_607822 = validateParameter(valid_607822, JString, required = false,
                                 default = nil)
  if valid_607822 != nil:
    section.add "X-Amz-Algorithm", valid_607822
  var valid_607823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607823 = validateParameter(valid_607823, JString, required = false,
                                 default = nil)
  if valid_607823 != nil:
    section.add "X-Amz-SignedHeaders", valid_607823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607825: Call_ListTrials_607811; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_607825.validator(path, query, header, formData, body)
  let scheme = call_607825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607825.url(scheme.get, call_607825.host, call_607825.base,
                         call_607825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607825, url, valid)

proc call*(call_607826: Call_ListTrials_607811; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607827 = newJObject()
  var body_607828 = newJObject()
  add(query_607827, "MaxResults", newJString(MaxResults))
  add(query_607827, "NextToken", newJString(NextToken))
  if body != nil:
    body_607828 = body
  result = call_607826.call(nil, query_607827, nil, nil, body_607828)

var listTrials* = Call_ListTrials_607811(name: "listTrials",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                      validator: validate_ListTrials_607812,
                                      base: "/", url: url_ListTrials_607813,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_607829 = ref object of OpenApiRestCall_605589
proc url_ListUserProfiles_607831(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserProfiles_607830(path: JsonNode; query: JsonNode;
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
  var valid_607832 = query.getOrDefault("MaxResults")
  valid_607832 = validateParameter(valid_607832, JString, required = false,
                                 default = nil)
  if valid_607832 != nil:
    section.add "MaxResults", valid_607832
  var valid_607833 = query.getOrDefault("NextToken")
  valid_607833 = validateParameter(valid_607833, JString, required = false,
                                 default = nil)
  if valid_607833 != nil:
    section.add "NextToken", valid_607833
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607834 = header.getOrDefault("X-Amz-Target")
  valid_607834 = validateParameter(valid_607834, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_607834 != nil:
    section.add "X-Amz-Target", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Signature")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Signature", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Content-Sha256", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Date")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Date", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-Credential")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-Credential", valid_607838
  var valid_607839 = header.getOrDefault("X-Amz-Security-Token")
  valid_607839 = validateParameter(valid_607839, JString, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "X-Amz-Security-Token", valid_607839
  var valid_607840 = header.getOrDefault("X-Amz-Algorithm")
  valid_607840 = validateParameter(valid_607840, JString, required = false,
                                 default = nil)
  if valid_607840 != nil:
    section.add "X-Amz-Algorithm", valid_607840
  var valid_607841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607841 = validateParameter(valid_607841, JString, required = false,
                                 default = nil)
  if valid_607841 != nil:
    section.add "X-Amz-SignedHeaders", valid_607841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607843: Call_ListUserProfiles_607829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_607843.validator(path, query, header, formData, body)
  let scheme = call_607843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607843.url(scheme.get, call_607843.host, call_607843.base,
                         call_607843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607843, url, valid)

proc call*(call_607844: Call_ListUserProfiles_607829; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607845 = newJObject()
  var body_607846 = newJObject()
  add(query_607845, "MaxResults", newJString(MaxResults))
  add(query_607845, "NextToken", newJString(NextToken))
  if body != nil:
    body_607846 = body
  result = call_607844.call(nil, query_607845, nil, nil, body_607846)

var listUserProfiles* = Call_ListUserProfiles_607829(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_607830, base: "/",
    url: url_ListUserProfiles_607831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_607847 = ref object of OpenApiRestCall_605589
proc url_ListWorkteams_607849(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkteams_607848(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607850 = query.getOrDefault("MaxResults")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "MaxResults", valid_607850
  var valid_607851 = query.getOrDefault("NextToken")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "NextToken", valid_607851
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607852 = header.getOrDefault("X-Amz-Target")
  valid_607852 = validateParameter(valid_607852, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_607852 != nil:
    section.add "X-Amz-Target", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-Signature")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Signature", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Content-Sha256", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-Date")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-Date", valid_607855
  var valid_607856 = header.getOrDefault("X-Amz-Credential")
  valid_607856 = validateParameter(valid_607856, JString, required = false,
                                 default = nil)
  if valid_607856 != nil:
    section.add "X-Amz-Credential", valid_607856
  var valid_607857 = header.getOrDefault("X-Amz-Security-Token")
  valid_607857 = validateParameter(valid_607857, JString, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "X-Amz-Security-Token", valid_607857
  var valid_607858 = header.getOrDefault("X-Amz-Algorithm")
  valid_607858 = validateParameter(valid_607858, JString, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "X-Amz-Algorithm", valid_607858
  var valid_607859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607859 = validateParameter(valid_607859, JString, required = false,
                                 default = nil)
  if valid_607859 != nil:
    section.add "X-Amz-SignedHeaders", valid_607859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607861: Call_ListWorkteams_607847; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_607861.validator(path, query, header, formData, body)
  let scheme = call_607861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607861.url(scheme.get, call_607861.host, call_607861.base,
                         call_607861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607861, url, valid)

proc call*(call_607862: Call_ListWorkteams_607847; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607863 = newJObject()
  var body_607864 = newJObject()
  add(query_607863, "MaxResults", newJString(MaxResults))
  add(query_607863, "NextToken", newJString(NextToken))
  if body != nil:
    body_607864 = body
  result = call_607862.call(nil, query_607863, nil, nil, body_607864)

var listWorkteams* = Call_ListWorkteams_607847(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_607848, base: "/", url: url_ListWorkteams_607849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_607865 = ref object of OpenApiRestCall_605589
proc url_RenderUiTemplate_607867(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenderUiTemplate_607866(path: JsonNode; query: JsonNode;
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
  var valid_607868 = header.getOrDefault("X-Amz-Target")
  valid_607868 = validateParameter(valid_607868, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_607868 != nil:
    section.add "X-Amz-Target", valid_607868
  var valid_607869 = header.getOrDefault("X-Amz-Signature")
  valid_607869 = validateParameter(valid_607869, JString, required = false,
                                 default = nil)
  if valid_607869 != nil:
    section.add "X-Amz-Signature", valid_607869
  var valid_607870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607870 = validateParameter(valid_607870, JString, required = false,
                                 default = nil)
  if valid_607870 != nil:
    section.add "X-Amz-Content-Sha256", valid_607870
  var valid_607871 = header.getOrDefault("X-Amz-Date")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "X-Amz-Date", valid_607871
  var valid_607872 = header.getOrDefault("X-Amz-Credential")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Credential", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Security-Token")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Security-Token", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Algorithm")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Algorithm", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-SignedHeaders", valid_607875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607877: Call_RenderUiTemplate_607865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_607877.validator(path, query, header, formData, body)
  let scheme = call_607877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607877.url(scheme.get, call_607877.host, call_607877.base,
                         call_607877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607877, url, valid)

proc call*(call_607878: Call_RenderUiTemplate_607865; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_607879 = newJObject()
  if body != nil:
    body_607879 = body
  result = call_607878.call(nil, nil, nil, nil, body_607879)

var renderUiTemplate* = Call_RenderUiTemplate_607865(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_607866, base: "/",
    url: url_RenderUiTemplate_607867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_607880 = ref object of OpenApiRestCall_605589
proc url_Search_607882(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Search_607881(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607883 = query.getOrDefault("MaxResults")
  valid_607883 = validateParameter(valid_607883, JString, required = false,
                                 default = nil)
  if valid_607883 != nil:
    section.add "MaxResults", valid_607883
  var valid_607884 = query.getOrDefault("NextToken")
  valid_607884 = validateParameter(valid_607884, JString, required = false,
                                 default = nil)
  if valid_607884 != nil:
    section.add "NextToken", valid_607884
  result.add "query", section
  ## parameters in `header` object:
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
  var valid_607885 = header.getOrDefault("X-Amz-Target")
  valid_607885 = validateParameter(valid_607885, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_607885 != nil:
    section.add "X-Amz-Target", valid_607885
  var valid_607886 = header.getOrDefault("X-Amz-Signature")
  valid_607886 = validateParameter(valid_607886, JString, required = false,
                                 default = nil)
  if valid_607886 != nil:
    section.add "X-Amz-Signature", valid_607886
  var valid_607887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Content-Sha256", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-Date")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-Date", valid_607888
  var valid_607889 = header.getOrDefault("X-Amz-Credential")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "X-Amz-Credential", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Security-Token")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Security-Token", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Algorithm")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Algorithm", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-SignedHeaders", valid_607892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607894: Call_Search_607880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ## 
  let valid = call_607894.validator(path, query, header, formData, body)
  let scheme = call_607894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607894.url(scheme.get, call_607894.host, call_607894.base,
                         call_607894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607894, url, valid)

proc call*(call_607895: Call_Search_607880; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607896 = newJObject()
  var body_607897 = newJObject()
  add(query_607896, "MaxResults", newJString(MaxResults))
  add(query_607896, "NextToken", newJString(NextToken))
  if body != nil:
    body_607897 = body
  result = call_607895.call(nil, query_607896, nil, nil, body_607897)

var search* = Call_Search_607880(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_607881, base: "/",
                              url: url_Search_607882,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_607898 = ref object of OpenApiRestCall_605589
proc url_StartMonitoringSchedule_607900(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringSchedule_607899(path: JsonNode; query: JsonNode;
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
  var valid_607901 = header.getOrDefault("X-Amz-Target")
  valid_607901 = validateParameter(valid_607901, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_607901 != nil:
    section.add "X-Amz-Target", valid_607901
  var valid_607902 = header.getOrDefault("X-Amz-Signature")
  valid_607902 = validateParameter(valid_607902, JString, required = false,
                                 default = nil)
  if valid_607902 != nil:
    section.add "X-Amz-Signature", valid_607902
  var valid_607903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607903 = validateParameter(valid_607903, JString, required = false,
                                 default = nil)
  if valid_607903 != nil:
    section.add "X-Amz-Content-Sha256", valid_607903
  var valid_607904 = header.getOrDefault("X-Amz-Date")
  valid_607904 = validateParameter(valid_607904, JString, required = false,
                                 default = nil)
  if valid_607904 != nil:
    section.add "X-Amz-Date", valid_607904
  var valid_607905 = header.getOrDefault("X-Amz-Credential")
  valid_607905 = validateParameter(valid_607905, JString, required = false,
                                 default = nil)
  if valid_607905 != nil:
    section.add "X-Amz-Credential", valid_607905
  var valid_607906 = header.getOrDefault("X-Amz-Security-Token")
  valid_607906 = validateParameter(valid_607906, JString, required = false,
                                 default = nil)
  if valid_607906 != nil:
    section.add "X-Amz-Security-Token", valid_607906
  var valid_607907 = header.getOrDefault("X-Amz-Algorithm")
  valid_607907 = validateParameter(valid_607907, JString, required = false,
                                 default = nil)
  if valid_607907 != nil:
    section.add "X-Amz-Algorithm", valid_607907
  var valid_607908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607908 = validateParameter(valid_607908, JString, required = false,
                                 default = nil)
  if valid_607908 != nil:
    section.add "X-Amz-SignedHeaders", valid_607908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607910: Call_StartMonitoringSchedule_607898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_607910.validator(path, query, header, formData, body)
  let scheme = call_607910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607910.url(scheme.get, call_607910.host, call_607910.base,
                         call_607910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607910, url, valid)

proc call*(call_607911: Call_StartMonitoringSchedule_607898; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_607912 = newJObject()
  if body != nil:
    body_607912 = body
  result = call_607911.call(nil, nil, nil, nil, body_607912)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_607898(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_607899, base: "/",
    url: url_StartMonitoringSchedule_607900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_607913 = ref object of OpenApiRestCall_605589
proc url_StartNotebookInstance_607915(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartNotebookInstance_607914(path: JsonNode; query: JsonNode;
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
  var valid_607916 = header.getOrDefault("X-Amz-Target")
  valid_607916 = validateParameter(valid_607916, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_607916 != nil:
    section.add "X-Amz-Target", valid_607916
  var valid_607917 = header.getOrDefault("X-Amz-Signature")
  valid_607917 = validateParameter(valid_607917, JString, required = false,
                                 default = nil)
  if valid_607917 != nil:
    section.add "X-Amz-Signature", valid_607917
  var valid_607918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607918 = validateParameter(valid_607918, JString, required = false,
                                 default = nil)
  if valid_607918 != nil:
    section.add "X-Amz-Content-Sha256", valid_607918
  var valid_607919 = header.getOrDefault("X-Amz-Date")
  valid_607919 = validateParameter(valid_607919, JString, required = false,
                                 default = nil)
  if valid_607919 != nil:
    section.add "X-Amz-Date", valid_607919
  var valid_607920 = header.getOrDefault("X-Amz-Credential")
  valid_607920 = validateParameter(valid_607920, JString, required = false,
                                 default = nil)
  if valid_607920 != nil:
    section.add "X-Amz-Credential", valid_607920
  var valid_607921 = header.getOrDefault("X-Amz-Security-Token")
  valid_607921 = validateParameter(valid_607921, JString, required = false,
                                 default = nil)
  if valid_607921 != nil:
    section.add "X-Amz-Security-Token", valid_607921
  var valid_607922 = header.getOrDefault("X-Amz-Algorithm")
  valid_607922 = validateParameter(valid_607922, JString, required = false,
                                 default = nil)
  if valid_607922 != nil:
    section.add "X-Amz-Algorithm", valid_607922
  var valid_607923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607923 = validateParameter(valid_607923, JString, required = false,
                                 default = nil)
  if valid_607923 != nil:
    section.add "X-Amz-SignedHeaders", valid_607923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607925: Call_StartNotebookInstance_607913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_607925.validator(path, query, header, formData, body)
  let scheme = call_607925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607925.url(scheme.get, call_607925.host, call_607925.base,
                         call_607925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607925, url, valid)

proc call*(call_607926: Call_StartNotebookInstance_607913; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_607927 = newJObject()
  if body != nil:
    body_607927 = body
  result = call_607926.call(nil, nil, nil, nil, body_607927)

var startNotebookInstance* = Call_StartNotebookInstance_607913(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_607914, base: "/",
    url: url_StartNotebookInstance_607915, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_607928 = ref object of OpenApiRestCall_605589
proc url_StopAutoMLJob_607930(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutoMLJob_607929(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607931 = header.getOrDefault("X-Amz-Target")
  valid_607931 = validateParameter(valid_607931, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_607931 != nil:
    section.add "X-Amz-Target", valid_607931
  var valid_607932 = header.getOrDefault("X-Amz-Signature")
  valid_607932 = validateParameter(valid_607932, JString, required = false,
                                 default = nil)
  if valid_607932 != nil:
    section.add "X-Amz-Signature", valid_607932
  var valid_607933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607933 = validateParameter(valid_607933, JString, required = false,
                                 default = nil)
  if valid_607933 != nil:
    section.add "X-Amz-Content-Sha256", valid_607933
  var valid_607934 = header.getOrDefault("X-Amz-Date")
  valid_607934 = validateParameter(valid_607934, JString, required = false,
                                 default = nil)
  if valid_607934 != nil:
    section.add "X-Amz-Date", valid_607934
  var valid_607935 = header.getOrDefault("X-Amz-Credential")
  valid_607935 = validateParameter(valid_607935, JString, required = false,
                                 default = nil)
  if valid_607935 != nil:
    section.add "X-Amz-Credential", valid_607935
  var valid_607936 = header.getOrDefault("X-Amz-Security-Token")
  valid_607936 = validateParameter(valid_607936, JString, required = false,
                                 default = nil)
  if valid_607936 != nil:
    section.add "X-Amz-Security-Token", valid_607936
  var valid_607937 = header.getOrDefault("X-Amz-Algorithm")
  valid_607937 = validateParameter(valid_607937, JString, required = false,
                                 default = nil)
  if valid_607937 != nil:
    section.add "X-Amz-Algorithm", valid_607937
  var valid_607938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607938 = validateParameter(valid_607938, JString, required = false,
                                 default = nil)
  if valid_607938 != nil:
    section.add "X-Amz-SignedHeaders", valid_607938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607940: Call_StopAutoMLJob_607928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_607940.validator(path, query, header, formData, body)
  let scheme = call_607940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607940.url(scheme.get, call_607940.host, call_607940.base,
                         call_607940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607940, url, valid)

proc call*(call_607941: Call_StopAutoMLJob_607928; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_607942 = newJObject()
  if body != nil:
    body_607942 = body
  result = call_607941.call(nil, nil, nil, nil, body_607942)

var stopAutoMLJob* = Call_StopAutoMLJob_607928(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_607929, base: "/", url: url_StopAutoMLJob_607930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_607943 = ref object of OpenApiRestCall_605589
proc url_StopCompilationJob_607945(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCompilationJob_607944(path: JsonNode; query: JsonNode;
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
  var valid_607946 = header.getOrDefault("X-Amz-Target")
  valid_607946 = validateParameter(valid_607946, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_607946 != nil:
    section.add "X-Amz-Target", valid_607946
  var valid_607947 = header.getOrDefault("X-Amz-Signature")
  valid_607947 = validateParameter(valid_607947, JString, required = false,
                                 default = nil)
  if valid_607947 != nil:
    section.add "X-Amz-Signature", valid_607947
  var valid_607948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607948 = validateParameter(valid_607948, JString, required = false,
                                 default = nil)
  if valid_607948 != nil:
    section.add "X-Amz-Content-Sha256", valid_607948
  var valid_607949 = header.getOrDefault("X-Amz-Date")
  valid_607949 = validateParameter(valid_607949, JString, required = false,
                                 default = nil)
  if valid_607949 != nil:
    section.add "X-Amz-Date", valid_607949
  var valid_607950 = header.getOrDefault("X-Amz-Credential")
  valid_607950 = validateParameter(valid_607950, JString, required = false,
                                 default = nil)
  if valid_607950 != nil:
    section.add "X-Amz-Credential", valid_607950
  var valid_607951 = header.getOrDefault("X-Amz-Security-Token")
  valid_607951 = validateParameter(valid_607951, JString, required = false,
                                 default = nil)
  if valid_607951 != nil:
    section.add "X-Amz-Security-Token", valid_607951
  var valid_607952 = header.getOrDefault("X-Amz-Algorithm")
  valid_607952 = validateParameter(valid_607952, JString, required = false,
                                 default = nil)
  if valid_607952 != nil:
    section.add "X-Amz-Algorithm", valid_607952
  var valid_607953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607953 = validateParameter(valid_607953, JString, required = false,
                                 default = nil)
  if valid_607953 != nil:
    section.add "X-Amz-SignedHeaders", valid_607953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607955: Call_StopCompilationJob_607943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_607955.validator(path, query, header, formData, body)
  let scheme = call_607955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607955.url(scheme.get, call_607955.host, call_607955.base,
                         call_607955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607955, url, valid)

proc call*(call_607956: Call_StopCompilationJob_607943; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_607957 = newJObject()
  if body != nil:
    body_607957 = body
  result = call_607956.call(nil, nil, nil, nil, body_607957)

var stopCompilationJob* = Call_StopCompilationJob_607943(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_607944, base: "/",
    url: url_StopCompilationJob_607945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_607958 = ref object of OpenApiRestCall_605589
proc url_StopHyperParameterTuningJob_607960(protocol: Scheme; host: string;
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

proc validate_StopHyperParameterTuningJob_607959(path: JsonNode; query: JsonNode;
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
  var valid_607961 = header.getOrDefault("X-Amz-Target")
  valid_607961 = validateParameter(valid_607961, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_607961 != nil:
    section.add "X-Amz-Target", valid_607961
  var valid_607962 = header.getOrDefault("X-Amz-Signature")
  valid_607962 = validateParameter(valid_607962, JString, required = false,
                                 default = nil)
  if valid_607962 != nil:
    section.add "X-Amz-Signature", valid_607962
  var valid_607963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607963 = validateParameter(valid_607963, JString, required = false,
                                 default = nil)
  if valid_607963 != nil:
    section.add "X-Amz-Content-Sha256", valid_607963
  var valid_607964 = header.getOrDefault("X-Amz-Date")
  valid_607964 = validateParameter(valid_607964, JString, required = false,
                                 default = nil)
  if valid_607964 != nil:
    section.add "X-Amz-Date", valid_607964
  var valid_607965 = header.getOrDefault("X-Amz-Credential")
  valid_607965 = validateParameter(valid_607965, JString, required = false,
                                 default = nil)
  if valid_607965 != nil:
    section.add "X-Amz-Credential", valid_607965
  var valid_607966 = header.getOrDefault("X-Amz-Security-Token")
  valid_607966 = validateParameter(valid_607966, JString, required = false,
                                 default = nil)
  if valid_607966 != nil:
    section.add "X-Amz-Security-Token", valid_607966
  var valid_607967 = header.getOrDefault("X-Amz-Algorithm")
  valid_607967 = validateParameter(valid_607967, JString, required = false,
                                 default = nil)
  if valid_607967 != nil:
    section.add "X-Amz-Algorithm", valid_607967
  var valid_607968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607968 = validateParameter(valid_607968, JString, required = false,
                                 default = nil)
  if valid_607968 != nil:
    section.add "X-Amz-SignedHeaders", valid_607968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607970: Call_StopHyperParameterTuningJob_607958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_607970.validator(path, query, header, formData, body)
  let scheme = call_607970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607970.url(scheme.get, call_607970.host, call_607970.base,
                         call_607970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607970, url, valid)

proc call*(call_607971: Call_StopHyperParameterTuningJob_607958; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_607972 = newJObject()
  if body != nil:
    body_607972 = body
  result = call_607971.call(nil, nil, nil, nil, body_607972)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_607958(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_607959, base: "/",
    url: url_StopHyperParameterTuningJob_607960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_607973 = ref object of OpenApiRestCall_605589
proc url_StopLabelingJob_607975(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLabelingJob_607974(path: JsonNode; query: JsonNode;
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
  var valid_607976 = header.getOrDefault("X-Amz-Target")
  valid_607976 = validateParameter(valid_607976, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_607976 != nil:
    section.add "X-Amz-Target", valid_607976
  var valid_607977 = header.getOrDefault("X-Amz-Signature")
  valid_607977 = validateParameter(valid_607977, JString, required = false,
                                 default = nil)
  if valid_607977 != nil:
    section.add "X-Amz-Signature", valid_607977
  var valid_607978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607978 = validateParameter(valid_607978, JString, required = false,
                                 default = nil)
  if valid_607978 != nil:
    section.add "X-Amz-Content-Sha256", valid_607978
  var valid_607979 = header.getOrDefault("X-Amz-Date")
  valid_607979 = validateParameter(valid_607979, JString, required = false,
                                 default = nil)
  if valid_607979 != nil:
    section.add "X-Amz-Date", valid_607979
  var valid_607980 = header.getOrDefault("X-Amz-Credential")
  valid_607980 = validateParameter(valid_607980, JString, required = false,
                                 default = nil)
  if valid_607980 != nil:
    section.add "X-Amz-Credential", valid_607980
  var valid_607981 = header.getOrDefault("X-Amz-Security-Token")
  valid_607981 = validateParameter(valid_607981, JString, required = false,
                                 default = nil)
  if valid_607981 != nil:
    section.add "X-Amz-Security-Token", valid_607981
  var valid_607982 = header.getOrDefault("X-Amz-Algorithm")
  valid_607982 = validateParameter(valid_607982, JString, required = false,
                                 default = nil)
  if valid_607982 != nil:
    section.add "X-Amz-Algorithm", valid_607982
  var valid_607983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607983 = validateParameter(valid_607983, JString, required = false,
                                 default = nil)
  if valid_607983 != nil:
    section.add "X-Amz-SignedHeaders", valid_607983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607985: Call_StopLabelingJob_607973; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_607985.validator(path, query, header, formData, body)
  let scheme = call_607985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607985.url(scheme.get, call_607985.host, call_607985.base,
                         call_607985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607985, url, valid)

proc call*(call_607986: Call_StopLabelingJob_607973; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_607987 = newJObject()
  if body != nil:
    body_607987 = body
  result = call_607986.call(nil, nil, nil, nil, body_607987)

var stopLabelingJob* = Call_StopLabelingJob_607973(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_607974, base: "/", url: url_StopLabelingJob_607975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_607988 = ref object of OpenApiRestCall_605589
proc url_StopMonitoringSchedule_607990(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopMonitoringSchedule_607989(path: JsonNode; query: JsonNode;
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
  var valid_607991 = header.getOrDefault("X-Amz-Target")
  valid_607991 = validateParameter(valid_607991, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_607991 != nil:
    section.add "X-Amz-Target", valid_607991
  var valid_607992 = header.getOrDefault("X-Amz-Signature")
  valid_607992 = validateParameter(valid_607992, JString, required = false,
                                 default = nil)
  if valid_607992 != nil:
    section.add "X-Amz-Signature", valid_607992
  var valid_607993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607993 = validateParameter(valid_607993, JString, required = false,
                                 default = nil)
  if valid_607993 != nil:
    section.add "X-Amz-Content-Sha256", valid_607993
  var valid_607994 = header.getOrDefault("X-Amz-Date")
  valid_607994 = validateParameter(valid_607994, JString, required = false,
                                 default = nil)
  if valid_607994 != nil:
    section.add "X-Amz-Date", valid_607994
  var valid_607995 = header.getOrDefault("X-Amz-Credential")
  valid_607995 = validateParameter(valid_607995, JString, required = false,
                                 default = nil)
  if valid_607995 != nil:
    section.add "X-Amz-Credential", valid_607995
  var valid_607996 = header.getOrDefault("X-Amz-Security-Token")
  valid_607996 = validateParameter(valid_607996, JString, required = false,
                                 default = nil)
  if valid_607996 != nil:
    section.add "X-Amz-Security-Token", valid_607996
  var valid_607997 = header.getOrDefault("X-Amz-Algorithm")
  valid_607997 = validateParameter(valid_607997, JString, required = false,
                                 default = nil)
  if valid_607997 != nil:
    section.add "X-Amz-Algorithm", valid_607997
  var valid_607998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607998 = validateParameter(valid_607998, JString, required = false,
                                 default = nil)
  if valid_607998 != nil:
    section.add "X-Amz-SignedHeaders", valid_607998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608000: Call_StopMonitoringSchedule_607988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_608000.validator(path, query, header, formData, body)
  let scheme = call_608000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608000.url(scheme.get, call_608000.host, call_608000.base,
                         call_608000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608000, url, valid)

proc call*(call_608001: Call_StopMonitoringSchedule_607988; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_608002 = newJObject()
  if body != nil:
    body_608002 = body
  result = call_608001.call(nil, nil, nil, nil, body_608002)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_607988(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_607989, base: "/",
    url: url_StopMonitoringSchedule_607990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_608003 = ref object of OpenApiRestCall_605589
proc url_StopNotebookInstance_608005(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopNotebookInstance_608004(path: JsonNode; query: JsonNode;
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
  var valid_608006 = header.getOrDefault("X-Amz-Target")
  valid_608006 = validateParameter(valid_608006, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_608006 != nil:
    section.add "X-Amz-Target", valid_608006
  var valid_608007 = header.getOrDefault("X-Amz-Signature")
  valid_608007 = validateParameter(valid_608007, JString, required = false,
                                 default = nil)
  if valid_608007 != nil:
    section.add "X-Amz-Signature", valid_608007
  var valid_608008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608008 = validateParameter(valid_608008, JString, required = false,
                                 default = nil)
  if valid_608008 != nil:
    section.add "X-Amz-Content-Sha256", valid_608008
  var valid_608009 = header.getOrDefault("X-Amz-Date")
  valid_608009 = validateParameter(valid_608009, JString, required = false,
                                 default = nil)
  if valid_608009 != nil:
    section.add "X-Amz-Date", valid_608009
  var valid_608010 = header.getOrDefault("X-Amz-Credential")
  valid_608010 = validateParameter(valid_608010, JString, required = false,
                                 default = nil)
  if valid_608010 != nil:
    section.add "X-Amz-Credential", valid_608010
  var valid_608011 = header.getOrDefault("X-Amz-Security-Token")
  valid_608011 = validateParameter(valid_608011, JString, required = false,
                                 default = nil)
  if valid_608011 != nil:
    section.add "X-Amz-Security-Token", valid_608011
  var valid_608012 = header.getOrDefault("X-Amz-Algorithm")
  valid_608012 = validateParameter(valid_608012, JString, required = false,
                                 default = nil)
  if valid_608012 != nil:
    section.add "X-Amz-Algorithm", valid_608012
  var valid_608013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608013 = validateParameter(valid_608013, JString, required = false,
                                 default = nil)
  if valid_608013 != nil:
    section.add "X-Amz-SignedHeaders", valid_608013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608015: Call_StopNotebookInstance_608003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_608015.validator(path, query, header, formData, body)
  let scheme = call_608015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608015.url(scheme.get, call_608015.host, call_608015.base,
                         call_608015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608015, url, valid)

proc call*(call_608016: Call_StopNotebookInstance_608003; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_608017 = newJObject()
  if body != nil:
    body_608017 = body
  result = call_608016.call(nil, nil, nil, nil, body_608017)

var stopNotebookInstance* = Call_StopNotebookInstance_608003(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_608004, base: "/",
    url: url_StopNotebookInstance_608005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_608018 = ref object of OpenApiRestCall_605589
proc url_StopProcessingJob_608020(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopProcessingJob_608019(path: JsonNode; query: JsonNode;
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
  var valid_608021 = header.getOrDefault("X-Amz-Target")
  valid_608021 = validateParameter(valid_608021, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_608021 != nil:
    section.add "X-Amz-Target", valid_608021
  var valid_608022 = header.getOrDefault("X-Amz-Signature")
  valid_608022 = validateParameter(valid_608022, JString, required = false,
                                 default = nil)
  if valid_608022 != nil:
    section.add "X-Amz-Signature", valid_608022
  var valid_608023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608023 = validateParameter(valid_608023, JString, required = false,
                                 default = nil)
  if valid_608023 != nil:
    section.add "X-Amz-Content-Sha256", valid_608023
  var valid_608024 = header.getOrDefault("X-Amz-Date")
  valid_608024 = validateParameter(valid_608024, JString, required = false,
                                 default = nil)
  if valid_608024 != nil:
    section.add "X-Amz-Date", valid_608024
  var valid_608025 = header.getOrDefault("X-Amz-Credential")
  valid_608025 = validateParameter(valid_608025, JString, required = false,
                                 default = nil)
  if valid_608025 != nil:
    section.add "X-Amz-Credential", valid_608025
  var valid_608026 = header.getOrDefault("X-Amz-Security-Token")
  valid_608026 = validateParameter(valid_608026, JString, required = false,
                                 default = nil)
  if valid_608026 != nil:
    section.add "X-Amz-Security-Token", valid_608026
  var valid_608027 = header.getOrDefault("X-Amz-Algorithm")
  valid_608027 = validateParameter(valid_608027, JString, required = false,
                                 default = nil)
  if valid_608027 != nil:
    section.add "X-Amz-Algorithm", valid_608027
  var valid_608028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608028 = validateParameter(valid_608028, JString, required = false,
                                 default = nil)
  if valid_608028 != nil:
    section.add "X-Amz-SignedHeaders", valid_608028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608030: Call_StopProcessingJob_608018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_608030.validator(path, query, header, formData, body)
  let scheme = call_608030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608030.url(scheme.get, call_608030.host, call_608030.base,
                         call_608030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608030, url, valid)

proc call*(call_608031: Call_StopProcessingJob_608018; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_608032 = newJObject()
  if body != nil:
    body_608032 = body
  result = call_608031.call(nil, nil, nil, nil, body_608032)

var stopProcessingJob* = Call_StopProcessingJob_608018(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_608019, base: "/",
    url: url_StopProcessingJob_608020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_608033 = ref object of OpenApiRestCall_605589
proc url_StopTrainingJob_608035(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingJob_608034(path: JsonNode; query: JsonNode;
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
  var valid_608036 = header.getOrDefault("X-Amz-Target")
  valid_608036 = validateParameter(valid_608036, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_608036 != nil:
    section.add "X-Amz-Target", valid_608036
  var valid_608037 = header.getOrDefault("X-Amz-Signature")
  valid_608037 = validateParameter(valid_608037, JString, required = false,
                                 default = nil)
  if valid_608037 != nil:
    section.add "X-Amz-Signature", valid_608037
  var valid_608038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608038 = validateParameter(valid_608038, JString, required = false,
                                 default = nil)
  if valid_608038 != nil:
    section.add "X-Amz-Content-Sha256", valid_608038
  var valid_608039 = header.getOrDefault("X-Amz-Date")
  valid_608039 = validateParameter(valid_608039, JString, required = false,
                                 default = nil)
  if valid_608039 != nil:
    section.add "X-Amz-Date", valid_608039
  var valid_608040 = header.getOrDefault("X-Amz-Credential")
  valid_608040 = validateParameter(valid_608040, JString, required = false,
                                 default = nil)
  if valid_608040 != nil:
    section.add "X-Amz-Credential", valid_608040
  var valid_608041 = header.getOrDefault("X-Amz-Security-Token")
  valid_608041 = validateParameter(valid_608041, JString, required = false,
                                 default = nil)
  if valid_608041 != nil:
    section.add "X-Amz-Security-Token", valid_608041
  var valid_608042 = header.getOrDefault("X-Amz-Algorithm")
  valid_608042 = validateParameter(valid_608042, JString, required = false,
                                 default = nil)
  if valid_608042 != nil:
    section.add "X-Amz-Algorithm", valid_608042
  var valid_608043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608043 = validateParameter(valid_608043, JString, required = false,
                                 default = nil)
  if valid_608043 != nil:
    section.add "X-Amz-SignedHeaders", valid_608043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608045: Call_StopTrainingJob_608033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_608045.validator(path, query, header, formData, body)
  let scheme = call_608045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608045.url(scheme.get, call_608045.host, call_608045.base,
                         call_608045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608045, url, valid)

proc call*(call_608046: Call_StopTrainingJob_608033; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_608047 = newJObject()
  if body != nil:
    body_608047 = body
  result = call_608046.call(nil, nil, nil, nil, body_608047)

var stopTrainingJob* = Call_StopTrainingJob_608033(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_608034, base: "/", url: url_StopTrainingJob_608035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_608048 = ref object of OpenApiRestCall_605589
proc url_StopTransformJob_608050(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTransformJob_608049(path: JsonNode; query: JsonNode;
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
  var valid_608051 = header.getOrDefault("X-Amz-Target")
  valid_608051 = validateParameter(valid_608051, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_608051 != nil:
    section.add "X-Amz-Target", valid_608051
  var valid_608052 = header.getOrDefault("X-Amz-Signature")
  valid_608052 = validateParameter(valid_608052, JString, required = false,
                                 default = nil)
  if valid_608052 != nil:
    section.add "X-Amz-Signature", valid_608052
  var valid_608053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608053 = validateParameter(valid_608053, JString, required = false,
                                 default = nil)
  if valid_608053 != nil:
    section.add "X-Amz-Content-Sha256", valid_608053
  var valid_608054 = header.getOrDefault("X-Amz-Date")
  valid_608054 = validateParameter(valid_608054, JString, required = false,
                                 default = nil)
  if valid_608054 != nil:
    section.add "X-Amz-Date", valid_608054
  var valid_608055 = header.getOrDefault("X-Amz-Credential")
  valid_608055 = validateParameter(valid_608055, JString, required = false,
                                 default = nil)
  if valid_608055 != nil:
    section.add "X-Amz-Credential", valid_608055
  var valid_608056 = header.getOrDefault("X-Amz-Security-Token")
  valid_608056 = validateParameter(valid_608056, JString, required = false,
                                 default = nil)
  if valid_608056 != nil:
    section.add "X-Amz-Security-Token", valid_608056
  var valid_608057 = header.getOrDefault("X-Amz-Algorithm")
  valid_608057 = validateParameter(valid_608057, JString, required = false,
                                 default = nil)
  if valid_608057 != nil:
    section.add "X-Amz-Algorithm", valid_608057
  var valid_608058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608058 = validateParameter(valid_608058, JString, required = false,
                                 default = nil)
  if valid_608058 != nil:
    section.add "X-Amz-SignedHeaders", valid_608058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608060: Call_StopTransformJob_608048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_608060.validator(path, query, header, formData, body)
  let scheme = call_608060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608060.url(scheme.get, call_608060.host, call_608060.base,
                         call_608060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608060, url, valid)

proc call*(call_608061: Call_StopTransformJob_608048; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_608062 = newJObject()
  if body != nil:
    body_608062 = body
  result = call_608061.call(nil, nil, nil, nil, body_608062)

var stopTransformJob* = Call_StopTransformJob_608048(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_608049, base: "/",
    url: url_StopTransformJob_608050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_608063 = ref object of OpenApiRestCall_605589
proc url_UpdateCodeRepository_608065(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCodeRepository_608064(path: JsonNode; query: JsonNode;
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
  var valid_608066 = header.getOrDefault("X-Amz-Target")
  valid_608066 = validateParameter(valid_608066, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_608066 != nil:
    section.add "X-Amz-Target", valid_608066
  var valid_608067 = header.getOrDefault("X-Amz-Signature")
  valid_608067 = validateParameter(valid_608067, JString, required = false,
                                 default = nil)
  if valid_608067 != nil:
    section.add "X-Amz-Signature", valid_608067
  var valid_608068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608068 = validateParameter(valid_608068, JString, required = false,
                                 default = nil)
  if valid_608068 != nil:
    section.add "X-Amz-Content-Sha256", valid_608068
  var valid_608069 = header.getOrDefault("X-Amz-Date")
  valid_608069 = validateParameter(valid_608069, JString, required = false,
                                 default = nil)
  if valid_608069 != nil:
    section.add "X-Amz-Date", valid_608069
  var valid_608070 = header.getOrDefault("X-Amz-Credential")
  valid_608070 = validateParameter(valid_608070, JString, required = false,
                                 default = nil)
  if valid_608070 != nil:
    section.add "X-Amz-Credential", valid_608070
  var valid_608071 = header.getOrDefault("X-Amz-Security-Token")
  valid_608071 = validateParameter(valid_608071, JString, required = false,
                                 default = nil)
  if valid_608071 != nil:
    section.add "X-Amz-Security-Token", valid_608071
  var valid_608072 = header.getOrDefault("X-Amz-Algorithm")
  valid_608072 = validateParameter(valid_608072, JString, required = false,
                                 default = nil)
  if valid_608072 != nil:
    section.add "X-Amz-Algorithm", valid_608072
  var valid_608073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608073 = validateParameter(valid_608073, JString, required = false,
                                 default = nil)
  if valid_608073 != nil:
    section.add "X-Amz-SignedHeaders", valid_608073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608075: Call_UpdateCodeRepository_608063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_608075.validator(path, query, header, formData, body)
  let scheme = call_608075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608075.url(scheme.get, call_608075.host, call_608075.base,
                         call_608075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608075, url, valid)

proc call*(call_608076: Call_UpdateCodeRepository_608063; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_608077 = newJObject()
  if body != nil:
    body_608077 = body
  result = call_608076.call(nil, nil, nil, nil, body_608077)

var updateCodeRepository* = Call_UpdateCodeRepository_608063(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_608064, base: "/",
    url: url_UpdateCodeRepository_608065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_608078 = ref object of OpenApiRestCall_605589
proc url_UpdateDomain_608080(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomain_608079(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608081 = header.getOrDefault("X-Amz-Target")
  valid_608081 = validateParameter(valid_608081, JString, required = true,
                                 default = newJString("SageMaker.UpdateDomain"))
  if valid_608081 != nil:
    section.add "X-Amz-Target", valid_608081
  var valid_608082 = header.getOrDefault("X-Amz-Signature")
  valid_608082 = validateParameter(valid_608082, JString, required = false,
                                 default = nil)
  if valid_608082 != nil:
    section.add "X-Amz-Signature", valid_608082
  var valid_608083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608083 = validateParameter(valid_608083, JString, required = false,
                                 default = nil)
  if valid_608083 != nil:
    section.add "X-Amz-Content-Sha256", valid_608083
  var valid_608084 = header.getOrDefault("X-Amz-Date")
  valid_608084 = validateParameter(valid_608084, JString, required = false,
                                 default = nil)
  if valid_608084 != nil:
    section.add "X-Amz-Date", valid_608084
  var valid_608085 = header.getOrDefault("X-Amz-Credential")
  valid_608085 = validateParameter(valid_608085, JString, required = false,
                                 default = nil)
  if valid_608085 != nil:
    section.add "X-Amz-Credential", valid_608085
  var valid_608086 = header.getOrDefault("X-Amz-Security-Token")
  valid_608086 = validateParameter(valid_608086, JString, required = false,
                                 default = nil)
  if valid_608086 != nil:
    section.add "X-Amz-Security-Token", valid_608086
  var valid_608087 = header.getOrDefault("X-Amz-Algorithm")
  valid_608087 = validateParameter(valid_608087, JString, required = false,
                                 default = nil)
  if valid_608087 != nil:
    section.add "X-Amz-Algorithm", valid_608087
  var valid_608088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608088 = validateParameter(valid_608088, JString, required = false,
                                 default = nil)
  if valid_608088 != nil:
    section.add "X-Amz-SignedHeaders", valid_608088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608090: Call_UpdateDomain_608078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_608090.validator(path, query, header, formData, body)
  let scheme = call_608090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608090.url(scheme.get, call_608090.host, call_608090.base,
                         call_608090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608090, url, valid)

proc call*(call_608091: Call_UpdateDomain_608078; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_608092 = newJObject()
  if body != nil:
    body_608092 = body
  result = call_608091.call(nil, nil, nil, nil, body_608092)

var updateDomain* = Call_UpdateDomain_608078(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_608079, base: "/", url: url_UpdateDomain_608080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_608093 = ref object of OpenApiRestCall_605589
proc url_UpdateEndpoint_608095(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_608094(path: JsonNode; query: JsonNode;
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
  var valid_608096 = header.getOrDefault("X-Amz-Target")
  valid_608096 = validateParameter(valid_608096, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_608096 != nil:
    section.add "X-Amz-Target", valid_608096
  var valid_608097 = header.getOrDefault("X-Amz-Signature")
  valid_608097 = validateParameter(valid_608097, JString, required = false,
                                 default = nil)
  if valid_608097 != nil:
    section.add "X-Amz-Signature", valid_608097
  var valid_608098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608098 = validateParameter(valid_608098, JString, required = false,
                                 default = nil)
  if valid_608098 != nil:
    section.add "X-Amz-Content-Sha256", valid_608098
  var valid_608099 = header.getOrDefault("X-Amz-Date")
  valid_608099 = validateParameter(valid_608099, JString, required = false,
                                 default = nil)
  if valid_608099 != nil:
    section.add "X-Amz-Date", valid_608099
  var valid_608100 = header.getOrDefault("X-Amz-Credential")
  valid_608100 = validateParameter(valid_608100, JString, required = false,
                                 default = nil)
  if valid_608100 != nil:
    section.add "X-Amz-Credential", valid_608100
  var valid_608101 = header.getOrDefault("X-Amz-Security-Token")
  valid_608101 = validateParameter(valid_608101, JString, required = false,
                                 default = nil)
  if valid_608101 != nil:
    section.add "X-Amz-Security-Token", valid_608101
  var valid_608102 = header.getOrDefault("X-Amz-Algorithm")
  valid_608102 = validateParameter(valid_608102, JString, required = false,
                                 default = nil)
  if valid_608102 != nil:
    section.add "X-Amz-Algorithm", valid_608102
  var valid_608103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608103 = validateParameter(valid_608103, JString, required = false,
                                 default = nil)
  if valid_608103 != nil:
    section.add "X-Amz-SignedHeaders", valid_608103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608105: Call_UpdateEndpoint_608093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_608105.validator(path, query, header, formData, body)
  let scheme = call_608105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608105.url(scheme.get, call_608105.host, call_608105.base,
                         call_608105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608105, url, valid)

proc call*(call_608106: Call_UpdateEndpoint_608093; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_608107 = newJObject()
  if body != nil:
    body_608107 = body
  result = call_608106.call(nil, nil, nil, nil, body_608107)

var updateEndpoint* = Call_UpdateEndpoint_608093(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_608094, base: "/", url: url_UpdateEndpoint_608095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_608108 = ref object of OpenApiRestCall_605589
proc url_UpdateEndpointWeightsAndCapacities_608110(protocol: Scheme; host: string;
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

proc validate_UpdateEndpointWeightsAndCapacities_608109(path: JsonNode;
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
  var valid_608111 = header.getOrDefault("X-Amz-Target")
  valid_608111 = validateParameter(valid_608111, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_608111 != nil:
    section.add "X-Amz-Target", valid_608111
  var valid_608112 = header.getOrDefault("X-Amz-Signature")
  valid_608112 = validateParameter(valid_608112, JString, required = false,
                                 default = nil)
  if valid_608112 != nil:
    section.add "X-Amz-Signature", valid_608112
  var valid_608113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608113 = validateParameter(valid_608113, JString, required = false,
                                 default = nil)
  if valid_608113 != nil:
    section.add "X-Amz-Content-Sha256", valid_608113
  var valid_608114 = header.getOrDefault("X-Amz-Date")
  valid_608114 = validateParameter(valid_608114, JString, required = false,
                                 default = nil)
  if valid_608114 != nil:
    section.add "X-Amz-Date", valid_608114
  var valid_608115 = header.getOrDefault("X-Amz-Credential")
  valid_608115 = validateParameter(valid_608115, JString, required = false,
                                 default = nil)
  if valid_608115 != nil:
    section.add "X-Amz-Credential", valid_608115
  var valid_608116 = header.getOrDefault("X-Amz-Security-Token")
  valid_608116 = validateParameter(valid_608116, JString, required = false,
                                 default = nil)
  if valid_608116 != nil:
    section.add "X-Amz-Security-Token", valid_608116
  var valid_608117 = header.getOrDefault("X-Amz-Algorithm")
  valid_608117 = validateParameter(valid_608117, JString, required = false,
                                 default = nil)
  if valid_608117 != nil:
    section.add "X-Amz-Algorithm", valid_608117
  var valid_608118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608118 = validateParameter(valid_608118, JString, required = false,
                                 default = nil)
  if valid_608118 != nil:
    section.add "X-Amz-SignedHeaders", valid_608118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608120: Call_UpdateEndpointWeightsAndCapacities_608108;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_608120.validator(path, query, header, formData, body)
  let scheme = call_608120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608120.url(scheme.get, call_608120.host, call_608120.base,
                         call_608120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608120, url, valid)

proc call*(call_608121: Call_UpdateEndpointWeightsAndCapacities_608108;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_608122 = newJObject()
  if body != nil:
    body_608122 = body
  result = call_608121.call(nil, nil, nil, nil, body_608122)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_608108(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_608109, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_608110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_608123 = ref object of OpenApiRestCall_605589
proc url_UpdateExperiment_608125(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateExperiment_608124(path: JsonNode; query: JsonNode;
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
  var valid_608126 = header.getOrDefault("X-Amz-Target")
  valid_608126 = validateParameter(valid_608126, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_608126 != nil:
    section.add "X-Amz-Target", valid_608126
  var valid_608127 = header.getOrDefault("X-Amz-Signature")
  valid_608127 = validateParameter(valid_608127, JString, required = false,
                                 default = nil)
  if valid_608127 != nil:
    section.add "X-Amz-Signature", valid_608127
  var valid_608128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608128 = validateParameter(valid_608128, JString, required = false,
                                 default = nil)
  if valid_608128 != nil:
    section.add "X-Amz-Content-Sha256", valid_608128
  var valid_608129 = header.getOrDefault("X-Amz-Date")
  valid_608129 = validateParameter(valid_608129, JString, required = false,
                                 default = nil)
  if valid_608129 != nil:
    section.add "X-Amz-Date", valid_608129
  var valid_608130 = header.getOrDefault("X-Amz-Credential")
  valid_608130 = validateParameter(valid_608130, JString, required = false,
                                 default = nil)
  if valid_608130 != nil:
    section.add "X-Amz-Credential", valid_608130
  var valid_608131 = header.getOrDefault("X-Amz-Security-Token")
  valid_608131 = validateParameter(valid_608131, JString, required = false,
                                 default = nil)
  if valid_608131 != nil:
    section.add "X-Amz-Security-Token", valid_608131
  var valid_608132 = header.getOrDefault("X-Amz-Algorithm")
  valid_608132 = validateParameter(valid_608132, JString, required = false,
                                 default = nil)
  if valid_608132 != nil:
    section.add "X-Amz-Algorithm", valid_608132
  var valid_608133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608133 = validateParameter(valid_608133, JString, required = false,
                                 default = nil)
  if valid_608133 != nil:
    section.add "X-Amz-SignedHeaders", valid_608133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608135: Call_UpdateExperiment_608123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_608135.validator(path, query, header, formData, body)
  let scheme = call_608135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608135.url(scheme.get, call_608135.host, call_608135.base,
                         call_608135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608135, url, valid)

proc call*(call_608136: Call_UpdateExperiment_608123; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_608137 = newJObject()
  if body != nil:
    body_608137 = body
  result = call_608136.call(nil, nil, nil, nil, body_608137)

var updateExperiment* = Call_UpdateExperiment_608123(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_608124, base: "/",
    url: url_UpdateExperiment_608125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_608138 = ref object of OpenApiRestCall_605589
proc url_UpdateMonitoringSchedule_608140(protocol: Scheme; host: string;
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

proc validate_UpdateMonitoringSchedule_608139(path: JsonNode; query: JsonNode;
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
  var valid_608141 = header.getOrDefault("X-Amz-Target")
  valid_608141 = validateParameter(valid_608141, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_608141 != nil:
    section.add "X-Amz-Target", valid_608141
  var valid_608142 = header.getOrDefault("X-Amz-Signature")
  valid_608142 = validateParameter(valid_608142, JString, required = false,
                                 default = nil)
  if valid_608142 != nil:
    section.add "X-Amz-Signature", valid_608142
  var valid_608143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608143 = validateParameter(valid_608143, JString, required = false,
                                 default = nil)
  if valid_608143 != nil:
    section.add "X-Amz-Content-Sha256", valid_608143
  var valid_608144 = header.getOrDefault("X-Amz-Date")
  valid_608144 = validateParameter(valid_608144, JString, required = false,
                                 default = nil)
  if valid_608144 != nil:
    section.add "X-Amz-Date", valid_608144
  var valid_608145 = header.getOrDefault("X-Amz-Credential")
  valid_608145 = validateParameter(valid_608145, JString, required = false,
                                 default = nil)
  if valid_608145 != nil:
    section.add "X-Amz-Credential", valid_608145
  var valid_608146 = header.getOrDefault("X-Amz-Security-Token")
  valid_608146 = validateParameter(valid_608146, JString, required = false,
                                 default = nil)
  if valid_608146 != nil:
    section.add "X-Amz-Security-Token", valid_608146
  var valid_608147 = header.getOrDefault("X-Amz-Algorithm")
  valid_608147 = validateParameter(valid_608147, JString, required = false,
                                 default = nil)
  if valid_608147 != nil:
    section.add "X-Amz-Algorithm", valid_608147
  var valid_608148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608148 = validateParameter(valid_608148, JString, required = false,
                                 default = nil)
  if valid_608148 != nil:
    section.add "X-Amz-SignedHeaders", valid_608148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608150: Call_UpdateMonitoringSchedule_608138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_608150.validator(path, query, header, formData, body)
  let scheme = call_608150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608150.url(scheme.get, call_608150.host, call_608150.base,
                         call_608150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608150, url, valid)

proc call*(call_608151: Call_UpdateMonitoringSchedule_608138; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_608152 = newJObject()
  if body != nil:
    body_608152 = body
  result = call_608151.call(nil, nil, nil, nil, body_608152)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_608138(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_608139, base: "/",
    url: url_UpdateMonitoringSchedule_608140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_608153 = ref object of OpenApiRestCall_605589
proc url_UpdateNotebookInstance_608155(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstance_608154(path: JsonNode; query: JsonNode;
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
  var valid_608156 = header.getOrDefault("X-Amz-Target")
  valid_608156 = validateParameter(valid_608156, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_608156 != nil:
    section.add "X-Amz-Target", valid_608156
  var valid_608157 = header.getOrDefault("X-Amz-Signature")
  valid_608157 = validateParameter(valid_608157, JString, required = false,
                                 default = nil)
  if valid_608157 != nil:
    section.add "X-Amz-Signature", valid_608157
  var valid_608158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608158 = validateParameter(valid_608158, JString, required = false,
                                 default = nil)
  if valid_608158 != nil:
    section.add "X-Amz-Content-Sha256", valid_608158
  var valid_608159 = header.getOrDefault("X-Amz-Date")
  valid_608159 = validateParameter(valid_608159, JString, required = false,
                                 default = nil)
  if valid_608159 != nil:
    section.add "X-Amz-Date", valid_608159
  var valid_608160 = header.getOrDefault("X-Amz-Credential")
  valid_608160 = validateParameter(valid_608160, JString, required = false,
                                 default = nil)
  if valid_608160 != nil:
    section.add "X-Amz-Credential", valid_608160
  var valid_608161 = header.getOrDefault("X-Amz-Security-Token")
  valid_608161 = validateParameter(valid_608161, JString, required = false,
                                 default = nil)
  if valid_608161 != nil:
    section.add "X-Amz-Security-Token", valid_608161
  var valid_608162 = header.getOrDefault("X-Amz-Algorithm")
  valid_608162 = validateParameter(valid_608162, JString, required = false,
                                 default = nil)
  if valid_608162 != nil:
    section.add "X-Amz-Algorithm", valid_608162
  var valid_608163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608163 = validateParameter(valid_608163, JString, required = false,
                                 default = nil)
  if valid_608163 != nil:
    section.add "X-Amz-SignedHeaders", valid_608163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608165: Call_UpdateNotebookInstance_608153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_608165.validator(path, query, header, formData, body)
  let scheme = call_608165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608165.url(scheme.get, call_608165.host, call_608165.base,
                         call_608165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608165, url, valid)

proc call*(call_608166: Call_UpdateNotebookInstance_608153; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_608167 = newJObject()
  if body != nil:
    body_608167 = body
  result = call_608166.call(nil, nil, nil, nil, body_608167)

var updateNotebookInstance* = Call_UpdateNotebookInstance_608153(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_608154, base: "/",
    url: url_UpdateNotebookInstance_608155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_608168 = ref object of OpenApiRestCall_605589
proc url_UpdateNotebookInstanceLifecycleConfig_608170(protocol: Scheme;
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

proc validate_UpdateNotebookInstanceLifecycleConfig_608169(path: JsonNode;
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
  var valid_608171 = header.getOrDefault("X-Amz-Target")
  valid_608171 = validateParameter(valid_608171, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_608171 != nil:
    section.add "X-Amz-Target", valid_608171
  var valid_608172 = header.getOrDefault("X-Amz-Signature")
  valid_608172 = validateParameter(valid_608172, JString, required = false,
                                 default = nil)
  if valid_608172 != nil:
    section.add "X-Amz-Signature", valid_608172
  var valid_608173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608173 = validateParameter(valid_608173, JString, required = false,
                                 default = nil)
  if valid_608173 != nil:
    section.add "X-Amz-Content-Sha256", valid_608173
  var valid_608174 = header.getOrDefault("X-Amz-Date")
  valid_608174 = validateParameter(valid_608174, JString, required = false,
                                 default = nil)
  if valid_608174 != nil:
    section.add "X-Amz-Date", valid_608174
  var valid_608175 = header.getOrDefault("X-Amz-Credential")
  valid_608175 = validateParameter(valid_608175, JString, required = false,
                                 default = nil)
  if valid_608175 != nil:
    section.add "X-Amz-Credential", valid_608175
  var valid_608176 = header.getOrDefault("X-Amz-Security-Token")
  valid_608176 = validateParameter(valid_608176, JString, required = false,
                                 default = nil)
  if valid_608176 != nil:
    section.add "X-Amz-Security-Token", valid_608176
  var valid_608177 = header.getOrDefault("X-Amz-Algorithm")
  valid_608177 = validateParameter(valid_608177, JString, required = false,
                                 default = nil)
  if valid_608177 != nil:
    section.add "X-Amz-Algorithm", valid_608177
  var valid_608178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608178 = validateParameter(valid_608178, JString, required = false,
                                 default = nil)
  if valid_608178 != nil:
    section.add "X-Amz-SignedHeaders", valid_608178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608180: Call_UpdateNotebookInstanceLifecycleConfig_608168;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_608180.validator(path, query, header, formData, body)
  let scheme = call_608180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608180.url(scheme.get, call_608180.host, call_608180.base,
                         call_608180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608180, url, valid)

proc call*(call_608181: Call_UpdateNotebookInstanceLifecycleConfig_608168;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_608182 = newJObject()
  if body != nil:
    body_608182 = body
  result = call_608181.call(nil, nil, nil, nil, body_608182)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_608168(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_608169, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_608170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_608183 = ref object of OpenApiRestCall_605589
proc url_UpdateTrial_608185(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrial_608184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_608186 = header.getOrDefault("X-Amz-Target")
  valid_608186 = validateParameter(valid_608186, JString, required = true,
                                 default = newJString("SageMaker.UpdateTrial"))
  if valid_608186 != nil:
    section.add "X-Amz-Target", valid_608186
  var valid_608187 = header.getOrDefault("X-Amz-Signature")
  valid_608187 = validateParameter(valid_608187, JString, required = false,
                                 default = nil)
  if valid_608187 != nil:
    section.add "X-Amz-Signature", valid_608187
  var valid_608188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608188 = validateParameter(valid_608188, JString, required = false,
                                 default = nil)
  if valid_608188 != nil:
    section.add "X-Amz-Content-Sha256", valid_608188
  var valid_608189 = header.getOrDefault("X-Amz-Date")
  valid_608189 = validateParameter(valid_608189, JString, required = false,
                                 default = nil)
  if valid_608189 != nil:
    section.add "X-Amz-Date", valid_608189
  var valid_608190 = header.getOrDefault("X-Amz-Credential")
  valid_608190 = validateParameter(valid_608190, JString, required = false,
                                 default = nil)
  if valid_608190 != nil:
    section.add "X-Amz-Credential", valid_608190
  var valid_608191 = header.getOrDefault("X-Amz-Security-Token")
  valid_608191 = validateParameter(valid_608191, JString, required = false,
                                 default = nil)
  if valid_608191 != nil:
    section.add "X-Amz-Security-Token", valid_608191
  var valid_608192 = header.getOrDefault("X-Amz-Algorithm")
  valid_608192 = validateParameter(valid_608192, JString, required = false,
                                 default = nil)
  if valid_608192 != nil:
    section.add "X-Amz-Algorithm", valid_608192
  var valid_608193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608193 = validateParameter(valid_608193, JString, required = false,
                                 default = nil)
  if valid_608193 != nil:
    section.add "X-Amz-SignedHeaders", valid_608193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608195: Call_UpdateTrial_608183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_608195.validator(path, query, header, formData, body)
  let scheme = call_608195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608195.url(scheme.get, call_608195.host, call_608195.base,
                         call_608195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608195, url, valid)

proc call*(call_608196: Call_UpdateTrial_608183; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_608197 = newJObject()
  if body != nil:
    body_608197 = body
  result = call_608196.call(nil, nil, nil, nil, body_608197)

var updateTrial* = Call_UpdateTrial_608183(name: "updateTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.UpdateTrial",
                                        validator: validate_UpdateTrial_608184,
                                        base: "/", url: url_UpdateTrial_608185,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_608198 = ref object of OpenApiRestCall_605589
proc url_UpdateTrialComponent_608200(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrialComponent_608199(path: JsonNode; query: JsonNode;
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
  var valid_608201 = header.getOrDefault("X-Amz-Target")
  valid_608201 = validateParameter(valid_608201, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_608201 != nil:
    section.add "X-Amz-Target", valid_608201
  var valid_608202 = header.getOrDefault("X-Amz-Signature")
  valid_608202 = validateParameter(valid_608202, JString, required = false,
                                 default = nil)
  if valid_608202 != nil:
    section.add "X-Amz-Signature", valid_608202
  var valid_608203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608203 = validateParameter(valid_608203, JString, required = false,
                                 default = nil)
  if valid_608203 != nil:
    section.add "X-Amz-Content-Sha256", valid_608203
  var valid_608204 = header.getOrDefault("X-Amz-Date")
  valid_608204 = validateParameter(valid_608204, JString, required = false,
                                 default = nil)
  if valid_608204 != nil:
    section.add "X-Amz-Date", valid_608204
  var valid_608205 = header.getOrDefault("X-Amz-Credential")
  valid_608205 = validateParameter(valid_608205, JString, required = false,
                                 default = nil)
  if valid_608205 != nil:
    section.add "X-Amz-Credential", valid_608205
  var valid_608206 = header.getOrDefault("X-Amz-Security-Token")
  valid_608206 = validateParameter(valid_608206, JString, required = false,
                                 default = nil)
  if valid_608206 != nil:
    section.add "X-Amz-Security-Token", valid_608206
  var valid_608207 = header.getOrDefault("X-Amz-Algorithm")
  valid_608207 = validateParameter(valid_608207, JString, required = false,
                                 default = nil)
  if valid_608207 != nil:
    section.add "X-Amz-Algorithm", valid_608207
  var valid_608208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608208 = validateParameter(valid_608208, JString, required = false,
                                 default = nil)
  if valid_608208 != nil:
    section.add "X-Amz-SignedHeaders", valid_608208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608210: Call_UpdateTrialComponent_608198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_608210.validator(path, query, header, formData, body)
  let scheme = call_608210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608210.url(scheme.get, call_608210.host, call_608210.base,
                         call_608210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608210, url, valid)

proc call*(call_608211: Call_UpdateTrialComponent_608198; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_608212 = newJObject()
  if body != nil:
    body_608212 = body
  result = call_608211.call(nil, nil, nil, nil, body_608212)

var updateTrialComponent* = Call_UpdateTrialComponent_608198(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_608199, base: "/",
    url: url_UpdateTrialComponent_608200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_608213 = ref object of OpenApiRestCall_605589
proc url_UpdateUserProfile_608215(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserProfile_608214(path: JsonNode; query: JsonNode;
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
  var valid_608216 = header.getOrDefault("X-Amz-Target")
  valid_608216 = validateParameter(valid_608216, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_608216 != nil:
    section.add "X-Amz-Target", valid_608216
  var valid_608217 = header.getOrDefault("X-Amz-Signature")
  valid_608217 = validateParameter(valid_608217, JString, required = false,
                                 default = nil)
  if valid_608217 != nil:
    section.add "X-Amz-Signature", valid_608217
  var valid_608218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608218 = validateParameter(valid_608218, JString, required = false,
                                 default = nil)
  if valid_608218 != nil:
    section.add "X-Amz-Content-Sha256", valid_608218
  var valid_608219 = header.getOrDefault("X-Amz-Date")
  valid_608219 = validateParameter(valid_608219, JString, required = false,
                                 default = nil)
  if valid_608219 != nil:
    section.add "X-Amz-Date", valid_608219
  var valid_608220 = header.getOrDefault("X-Amz-Credential")
  valid_608220 = validateParameter(valid_608220, JString, required = false,
                                 default = nil)
  if valid_608220 != nil:
    section.add "X-Amz-Credential", valid_608220
  var valid_608221 = header.getOrDefault("X-Amz-Security-Token")
  valid_608221 = validateParameter(valid_608221, JString, required = false,
                                 default = nil)
  if valid_608221 != nil:
    section.add "X-Amz-Security-Token", valid_608221
  var valid_608222 = header.getOrDefault("X-Amz-Algorithm")
  valid_608222 = validateParameter(valid_608222, JString, required = false,
                                 default = nil)
  if valid_608222 != nil:
    section.add "X-Amz-Algorithm", valid_608222
  var valid_608223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608223 = validateParameter(valid_608223, JString, required = false,
                                 default = nil)
  if valid_608223 != nil:
    section.add "X-Amz-SignedHeaders", valid_608223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608225: Call_UpdateUserProfile_608213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_608225.validator(path, query, header, formData, body)
  let scheme = call_608225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608225.url(scheme.get, call_608225.host, call_608225.base,
                         call_608225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608225, url, valid)

proc call*(call_608226: Call_UpdateUserProfile_608213; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_608227 = newJObject()
  if body != nil:
    body_608227 = body
  result = call_608226.call(nil, nil, nil, nil, body_608227)

var updateUserProfile* = Call_UpdateUserProfile_608213(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_608214, base: "/",
    url: url_UpdateUserProfile_608215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_608228 = ref object of OpenApiRestCall_605589
proc url_UpdateWorkteam_608230(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkteam_608229(path: JsonNode; query: JsonNode;
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
  var valid_608231 = header.getOrDefault("X-Amz-Target")
  valid_608231 = validateParameter(valid_608231, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_608231 != nil:
    section.add "X-Amz-Target", valid_608231
  var valid_608232 = header.getOrDefault("X-Amz-Signature")
  valid_608232 = validateParameter(valid_608232, JString, required = false,
                                 default = nil)
  if valid_608232 != nil:
    section.add "X-Amz-Signature", valid_608232
  var valid_608233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_608233 = validateParameter(valid_608233, JString, required = false,
                                 default = nil)
  if valid_608233 != nil:
    section.add "X-Amz-Content-Sha256", valid_608233
  var valid_608234 = header.getOrDefault("X-Amz-Date")
  valid_608234 = validateParameter(valid_608234, JString, required = false,
                                 default = nil)
  if valid_608234 != nil:
    section.add "X-Amz-Date", valid_608234
  var valid_608235 = header.getOrDefault("X-Amz-Credential")
  valid_608235 = validateParameter(valid_608235, JString, required = false,
                                 default = nil)
  if valid_608235 != nil:
    section.add "X-Amz-Credential", valid_608235
  var valid_608236 = header.getOrDefault("X-Amz-Security-Token")
  valid_608236 = validateParameter(valid_608236, JString, required = false,
                                 default = nil)
  if valid_608236 != nil:
    section.add "X-Amz-Security-Token", valid_608236
  var valid_608237 = header.getOrDefault("X-Amz-Algorithm")
  valid_608237 = validateParameter(valid_608237, JString, required = false,
                                 default = nil)
  if valid_608237 != nil:
    section.add "X-Amz-Algorithm", valid_608237
  var valid_608238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_608238 = validateParameter(valid_608238, JString, required = false,
                                 default = nil)
  if valid_608238 != nil:
    section.add "X-Amz-SignedHeaders", valid_608238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_608240: Call_UpdateWorkteam_608228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_608240.validator(path, query, header, formData, body)
  let scheme = call_608240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_608240.url(scheme.get, call_608240.host, call_608240.base,
                         call_608240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_608240, url, valid)

proc call*(call_608241: Call_UpdateWorkteam_608228; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_608242 = newJObject()
  if body != nil:
    body_608242 = body
  result = call_608241.call(nil, nil, nil, nil, body_608242)

var updateWorkteam* = Call_UpdateWorkteam_608228(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_608229, base: "/", url: url_UpdateWorkteam_608230,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
