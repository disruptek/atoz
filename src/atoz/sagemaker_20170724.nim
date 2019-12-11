
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_AddTags_597727 = ref object of OpenApiRestCall_597389
proc url_AddTags_597729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_597728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597854 = header.getOrDefault("X-Amz-Target")
  valid_597854 = validateParameter(valid_597854, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
  if valid_597854 != nil:
    section.add "X-Amz-Target", valid_597854
  var valid_597855 = header.getOrDefault("X-Amz-Signature")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = nil)
  if valid_597855 != nil:
    section.add "X-Amz-Signature", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Content-Sha256", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Date")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Date", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Credential")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Credential", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Security-Token")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Security-Token", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Algorithm")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Algorithm", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-SignedHeaders", valid_597861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597885: Call_AddTags_597727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_597885.validator(path, query, header, formData, body)
  let scheme = call_597885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597885.url(scheme.get, call_597885.host, call_597885.base,
                         call_597885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597885, url, valid)

proc call*(call_597956: Call_AddTags_597727; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_597957 = newJObject()
  if body != nil:
    body_597957 = body
  result = call_597956.call(nil, nil, nil, nil, body_597957)

var addTags* = Call_AddTags_597727(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_597728, base: "/",
                                url: url_AddTags_597729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_AssociateTrialComponent_597996 = ref object of OpenApiRestCall_597389
proc url_AssociateTrialComponent_597998(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateTrialComponent_597997(path: JsonNode; query: JsonNode;
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
  var valid_597999 = header.getOrDefault("X-Amz-Target")
  valid_597999 = validateParameter(valid_597999, JString, required = true, default = newJString(
      "SageMaker.AssociateTrialComponent"))
  if valid_597999 != nil:
    section.add "X-Amz-Target", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Signature")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Signature", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Content-Sha256", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Date")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Date", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Credential")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Credential", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Security-Token")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Security-Token", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Algorithm")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Algorithm", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-SignedHeaders", valid_598006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598008: Call_AssociateTrialComponent_597996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_598008.validator(path, query, header, formData, body)
  let scheme = call_598008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598008.url(scheme.get, call_598008.host, call_598008.base,
                         call_598008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598008, url, valid)

proc call*(call_598009: Call_AssociateTrialComponent_597996; body: JsonNode): Recallable =
  ## associateTrialComponent
  ## Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_598010 = newJObject()
  if body != nil:
    body_598010 = body
  result = call_598009.call(nil, nil, nil, nil, body_598010)

var associateTrialComponent* = Call_AssociateTrialComponent_597996(
    name: "associateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.AssociateTrialComponent",
    validator: validate_AssociateTrialComponent_597997, base: "/",
    url: url_AssociateTrialComponent_597998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_598011 = ref object of OpenApiRestCall_597389
proc url_CreateAlgorithm_598013(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAlgorithm_598012(path: JsonNode; query: JsonNode;
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
  var valid_598014 = header.getOrDefault("X-Amz-Target")
  valid_598014 = validateParameter(valid_598014, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_598014 != nil:
    section.add "X-Amz-Target", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Signature")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Signature", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Content-Sha256", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Date")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Date", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Credential")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Credential", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Security-Token")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Security-Token", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Algorithm")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Algorithm", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-SignedHeaders", valid_598021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598023: Call_CreateAlgorithm_598011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_598023.validator(path, query, header, formData, body)
  let scheme = call_598023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598023.url(scheme.get, call_598023.host, call_598023.base,
                         call_598023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598023, url, valid)

proc call*(call_598024: Call_CreateAlgorithm_598011; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_598025 = newJObject()
  if body != nil:
    body_598025 = body
  result = call_598024.call(nil, nil, nil, nil, body_598025)

var createAlgorithm* = Call_CreateAlgorithm_598011(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_598012, base: "/", url: url_CreateAlgorithm_598013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApp_598026 = ref object of OpenApiRestCall_597389
proc url_CreateApp_598028(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateApp_598027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598029 = header.getOrDefault("X-Amz-Target")
  valid_598029 = validateParameter(valid_598029, JString, required = true,
                                 default = newJString("SageMaker.CreateApp"))
  if valid_598029 != nil:
    section.add "X-Amz-Target", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Signature")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Signature", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Content-Sha256", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Date")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Date", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Credential")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Credential", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Security-Token")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Security-Token", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Algorithm")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Algorithm", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-SignedHeaders", valid_598036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598038: Call_CreateApp_598026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ## 
  let valid = call_598038.validator(path, query, header, formData, body)
  let scheme = call_598038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598038.url(scheme.get, call_598038.host, call_598038.base,
                         call_598038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598038, url, valid)

proc call*(call_598039: Call_CreateApp_598026; body: JsonNode): Recallable =
  ## createApp
  ## Creates a running App for the specified UserProfile. Supported Apps are JupyterServer and KernelGateway. This operation is automatically invoked by Amazon SageMaker Amazon SageMaker Studio (Studio) upon access to the associated Studio Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously. Apps will automatically terminate and be deleted when stopped from within Studio, or when the DeleteApp API is manually called. UserProfiles are limited to 5 concurrently running Apps at a time.
  ##   body: JObject (required)
  var body_598040 = newJObject()
  if body != nil:
    body_598040 = body
  result = call_598039.call(nil, nil, nil, nil, body_598040)

var createApp* = Call_CreateApp_598026(name: "createApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateApp",
                                    validator: validate_CreateApp_598027,
                                    base: "/", url: url_CreateApp_598028,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAutoMLJob_598041 = ref object of OpenApiRestCall_597389
proc url_CreateAutoMLJob_598043(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAutoMLJob_598042(path: JsonNode; query: JsonNode;
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
  var valid_598044 = header.getOrDefault("X-Amz-Target")
  valid_598044 = validateParameter(valid_598044, JString, required = true, default = newJString(
      "SageMaker.CreateAutoMLJob"))
  if valid_598044 != nil:
    section.add "X-Amz-Target", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Signature")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Signature", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Content-Sha256", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Date")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Date", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Credential")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Credential", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Security-Token")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Security-Token", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Algorithm")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Algorithm", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-SignedHeaders", valid_598051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598053: Call_CreateAutoMLJob_598041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an AutoPilot job.
  ## 
  let valid = call_598053.validator(path, query, header, formData, body)
  let scheme = call_598053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598053.url(scheme.get, call_598053.host, call_598053.base,
                         call_598053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598053, url, valid)

proc call*(call_598054: Call_CreateAutoMLJob_598041; body: JsonNode): Recallable =
  ## createAutoMLJob
  ## Creates an AutoPilot job.
  ##   body: JObject (required)
  var body_598055 = newJObject()
  if body != nil:
    body_598055 = body
  result = call_598054.call(nil, nil, nil, nil, body_598055)

var createAutoMLJob* = Call_CreateAutoMLJob_598041(name: "createAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAutoMLJob",
    validator: validate_CreateAutoMLJob_598042, base: "/", url: url_CreateAutoMLJob_598043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_598056 = ref object of OpenApiRestCall_597389
proc url_CreateCodeRepository_598058(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCodeRepository_598057(path: JsonNode; query: JsonNode;
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
  var valid_598059 = header.getOrDefault("X-Amz-Target")
  valid_598059 = validateParameter(valid_598059, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_598059 != nil:
    section.add "X-Amz-Target", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Signature")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Signature", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Content-Sha256", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Date")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Date", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Credential")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Credential", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Security-Token")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Security-Token", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Algorithm")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Algorithm", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-SignedHeaders", valid_598066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598068: Call_CreateCodeRepository_598056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_598068.validator(path, query, header, formData, body)
  let scheme = call_598068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598068.url(scheme.get, call_598068.host, call_598068.base,
                         call_598068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598068, url, valid)

proc call*(call_598069: Call_CreateCodeRepository_598056; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_598070 = newJObject()
  if body != nil:
    body_598070 = body
  result = call_598069.call(nil, nil, nil, nil, body_598070)

var createCodeRepository* = Call_CreateCodeRepository_598056(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_598057, base: "/",
    url: url_CreateCodeRepository_598058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_598071 = ref object of OpenApiRestCall_597389
proc url_CreateCompilationJob_598073(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCompilationJob_598072(path: JsonNode; query: JsonNode;
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
  var valid_598074 = header.getOrDefault("X-Amz-Target")
  valid_598074 = validateParameter(valid_598074, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_598074 != nil:
    section.add "X-Amz-Target", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Signature")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Signature", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Content-Sha256", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Date")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Date", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Credential")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Credential", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Security-Token")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Security-Token", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Algorithm")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Algorithm", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-SignedHeaders", valid_598081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598083: Call_CreateCompilationJob_598071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_598083.validator(path, query, header, formData, body)
  let scheme = call_598083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598083.url(scheme.get, call_598083.host, call_598083.base,
                         call_598083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598083, url, valid)

proc call*(call_598084: Call_CreateCompilationJob_598071; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_598085 = newJObject()
  if body != nil:
    body_598085 = body
  result = call_598084.call(nil, nil, nil, nil, body_598085)

var createCompilationJob* = Call_CreateCompilationJob_598071(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_598072, base: "/",
    url: url_CreateCompilationJob_598073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDomain_598086 = ref object of OpenApiRestCall_597389
proc url_CreateDomain_598088(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDomain_598087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598089 = header.getOrDefault("X-Amz-Target")
  valid_598089 = validateParameter(valid_598089, JString, required = true,
                                 default = newJString("SageMaker.CreateDomain"))
  if valid_598089 != nil:
    section.add "X-Amz-Target", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Signature")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Signature", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Content-Sha256", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Date")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Date", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Credential")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Credential", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Security-Token")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Security-Token", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Algorithm")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Algorithm", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-SignedHeaders", valid_598096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598098: Call_CreateDomain_598086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ## 
  let valid = call_598098.validator(path, query, header, formData, body)
  let scheme = call_598098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598098.url(scheme.get, call_598098.host, call_598098.base,
                         call_598098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598098, url, valid)

proc call*(call_598099: Call_CreateDomain_598086; body: JsonNode): Recallable =
  ## createDomain
  ## Creates a Domain for Amazon SageMaker Amazon SageMaker Studio (Studio), which can be accessed by end-users in a web browser. A Domain has an associated directory, list of authorized users, and a variety of security, application, policies, and Amazon Virtual Private Cloud configurations. An AWS account is limited to one Domain, per region. Users within a domain can share notebook files and other artifacts with each other. When a Domain is created, an Amazon Elastic File System (EFS) is also created for use by all of the users within the Domain. Each user receives a private home directory within the EFS for notebooks, Git repositories, and data files. 
  ##   body: JObject (required)
  var body_598100 = newJObject()
  if body != nil:
    body_598100 = body
  result = call_598099.call(nil, nil, nil, nil, body_598100)

var createDomain* = Call_CreateDomain_598086(name: "createDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateDomain",
    validator: validate_CreateDomain_598087, base: "/", url: url_CreateDomain_598088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_598101 = ref object of OpenApiRestCall_597389
proc url_CreateEndpoint_598103(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpoint_598102(path: JsonNode; query: JsonNode;
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
  var valid_598104 = header.getOrDefault("X-Amz-Target")
  valid_598104 = validateParameter(valid_598104, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_598104 != nil:
    section.add "X-Amz-Target", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_CreateEndpoint_598101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_CreateEndpoint_598101; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS in an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var createEndpoint* = Call_CreateEndpoint_598101(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_598102, base: "/", url: url_CreateEndpoint_598103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_598116 = ref object of OpenApiRestCall_597389
proc url_CreateEndpointConfig_598118(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEndpointConfig_598117(path: JsonNode; query: JsonNode;
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
  var valid_598119 = header.getOrDefault("X-Amz-Target")
  valid_598119 = validateParameter(valid_598119, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_598119 != nil:
    section.add "X-Amz-Target", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Signature")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Signature", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Content-Sha256", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Date")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Date", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Credential")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Credential", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Security-Token")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Security-Token", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Algorithm")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Algorithm", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-SignedHeaders", valid_598126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598128: Call_CreateEndpointConfig_598116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_598128.validator(path, query, header, formData, body)
  let scheme = call_598128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598128.url(scheme.get, call_598128.host, call_598128.base,
                         call_598128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598128, url, valid)

proc call*(call_598129: Call_CreateEndpointConfig_598116; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_598130 = newJObject()
  if body != nil:
    body_598130 = body
  result = call_598129.call(nil, nil, nil, nil, body_598130)

var createEndpointConfig* = Call_CreateEndpointConfig_598116(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_598117, base: "/",
    url: url_CreateEndpointConfig_598118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateExperiment_598131 = ref object of OpenApiRestCall_597389
proc url_CreateExperiment_598133(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateExperiment_598132(path: JsonNode; query: JsonNode;
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
  var valid_598134 = header.getOrDefault("X-Amz-Target")
  valid_598134 = validateParameter(valid_598134, JString, required = true, default = newJString(
      "SageMaker.CreateExperiment"))
  if valid_598134 != nil:
    section.add "X-Amz-Target", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Signature")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Signature", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Content-Sha256", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Date")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Date", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Credential")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Credential", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Security-Token")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Security-Token", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Algorithm")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Algorithm", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-SignedHeaders", valid_598141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598143: Call_CreateExperiment_598131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ## 
  let valid = call_598143.validator(path, query, header, formData, body)
  let scheme = call_598143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598143.url(scheme.get, call_598143.host, call_598143.base,
                         call_598143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598143, url, valid)

proc call*(call_598144: Call_CreateExperiment_598131; body: JsonNode): Recallable =
  ## createExperiment
  ## <p>Creates an Amazon SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a>Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a>UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a>ListExperiments</a> API. To view an experiment's properties, call the <a>DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a>ListTrials</a> API. To create a trial call the <a>CreateTrial</a> API.</p>
  ##   body: JObject (required)
  var body_598145 = newJObject()
  if body != nil:
    body_598145 = body
  result = call_598144.call(nil, nil, nil, nil, body_598145)

var createExperiment* = Call_CreateExperiment_598131(name: "createExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateExperiment",
    validator: validate_CreateExperiment_598132, base: "/",
    url: url_CreateExperiment_598133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlowDefinition_598146 = ref object of OpenApiRestCall_597389
proc url_CreateFlowDefinition_598148(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlowDefinition_598147(path: JsonNode; query: JsonNode;
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
  var valid_598149 = header.getOrDefault("X-Amz-Target")
  valid_598149 = validateParameter(valid_598149, JString, required = true, default = newJString(
      "SageMaker.CreateFlowDefinition"))
  if valid_598149 != nil:
    section.add "X-Amz-Target", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Signature")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Signature", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Content-Sha256", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-Date")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Date", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Credential")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Credential", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Security-Token")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Security-Token", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-Algorithm")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Algorithm", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-SignedHeaders", valid_598156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598158: Call_CreateFlowDefinition_598146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a flow definition.
  ## 
  let valid = call_598158.validator(path, query, header, formData, body)
  let scheme = call_598158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598158.url(scheme.get, call_598158.host, call_598158.base,
                         call_598158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598158, url, valid)

proc call*(call_598159: Call_CreateFlowDefinition_598146; body: JsonNode): Recallable =
  ## createFlowDefinition
  ## Creates a flow definition.
  ##   body: JObject (required)
  var body_598160 = newJObject()
  if body != nil:
    body_598160 = body
  result = call_598159.call(nil, nil, nil, nil, body_598160)

var createFlowDefinition* = Call_CreateFlowDefinition_598146(
    name: "createFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateFlowDefinition",
    validator: validate_CreateFlowDefinition_598147, base: "/",
    url: url_CreateFlowDefinition_598148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHumanTaskUi_598161 = ref object of OpenApiRestCall_597389
proc url_CreateHumanTaskUi_598163(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHumanTaskUi_598162(path: JsonNode; query: JsonNode;
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
  var valid_598164 = header.getOrDefault("X-Amz-Target")
  valid_598164 = validateParameter(valid_598164, JString, required = true, default = newJString(
      "SageMaker.CreateHumanTaskUi"))
  if valid_598164 != nil:
    section.add "X-Amz-Target", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Signature")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Signature", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-Content-Sha256", valid_598166
  var valid_598167 = header.getOrDefault("X-Amz-Date")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Date", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Credential")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Credential", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-Security-Token")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Security-Token", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-Algorithm")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-Algorithm", valid_598170
  var valid_598171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-SignedHeaders", valid_598171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598173: Call_CreateHumanTaskUi_598161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ## 
  let valid = call_598173.validator(path, query, header, formData, body)
  let scheme = call_598173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598173.url(scheme.get, call_598173.host, call_598173.base,
                         call_598173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598173, url, valid)

proc call*(call_598174: Call_CreateHumanTaskUi_598161; body: JsonNode): Recallable =
  ## createHumanTaskUi
  ## Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
  ##   body: JObject (required)
  var body_598175 = newJObject()
  if body != nil:
    body_598175 = body
  result = call_598174.call(nil, nil, nil, nil, body_598175)

var createHumanTaskUi* = Call_CreateHumanTaskUi_598161(name: "createHumanTaskUi",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHumanTaskUi",
    validator: validate_CreateHumanTaskUi_598162, base: "/",
    url: url_CreateHumanTaskUi_598163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_598176 = ref object of OpenApiRestCall_597389
proc url_CreateHyperParameterTuningJob_598178(protocol: Scheme; host: string;
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

proc validate_CreateHyperParameterTuningJob_598177(path: JsonNode; query: JsonNode;
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
  var valid_598179 = header.getOrDefault("X-Amz-Target")
  valid_598179 = validateParameter(valid_598179, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_598179 != nil:
    section.add "X-Amz-Target", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Signature")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Signature", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Content-Sha256", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Date")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Date", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Credential")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Credential", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Security-Token")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Security-Token", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-Algorithm")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-Algorithm", valid_598185
  var valid_598186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "X-Amz-SignedHeaders", valid_598186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598188: Call_CreateHyperParameterTuningJob_598176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_598188.validator(path, query, header, formData, body)
  let scheme = call_598188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598188.url(scheme.get, call_598188.host, call_598188.base,
                         call_598188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598188, url, valid)

proc call*(call_598189: Call_CreateHyperParameterTuningJob_598176; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_598190 = newJObject()
  if body != nil:
    body_598190 = body
  result = call_598189.call(nil, nil, nil, nil, body_598190)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_598176(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_598177, base: "/",
    url: url_CreateHyperParameterTuningJob_598178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_598191 = ref object of OpenApiRestCall_597389
proc url_CreateLabelingJob_598193(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLabelingJob_598192(path: JsonNode; query: JsonNode;
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
  var valid_598194 = header.getOrDefault("X-Amz-Target")
  valid_598194 = validateParameter(valid_598194, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_598194 != nil:
    section.add "X-Amz-Target", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Signature")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Signature", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Content-Sha256", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Date")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Date", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Credential")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Credential", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Security-Token")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Security-Token", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Algorithm")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Algorithm", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-SignedHeaders", valid_598201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598203: Call_CreateLabelingJob_598191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_598203.validator(path, query, header, formData, body)
  let scheme = call_598203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598203.url(scheme.get, call_598203.host, call_598203.base,
                         call_598203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598203, url, valid)

proc call*(call_598204: Call_CreateLabelingJob_598191; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_598205 = newJObject()
  if body != nil:
    body_598205 = body
  result = call_598204.call(nil, nil, nil, nil, body_598205)

var createLabelingJob* = Call_CreateLabelingJob_598191(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_598192, base: "/",
    url: url_CreateLabelingJob_598193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_598206 = ref object of OpenApiRestCall_597389
proc url_CreateModel_598208(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModel_598207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598209 = header.getOrDefault("X-Amz-Target")
  valid_598209 = validateParameter(valid_598209, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_598209 != nil:
    section.add "X-Amz-Target", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Signature")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Signature", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Content-Sha256", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Date")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Date", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Credential")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Credential", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Security-Token")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Security-Token", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Algorithm")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Algorithm", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-SignedHeaders", valid_598216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598218: Call_CreateModel_598206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_598218.validator(path, query, header, formData, body)
  let scheme = call_598218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598218.url(scheme.get, call_598218.host, call_598218.base,
                         call_598218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598218, url, valid)

proc call*(call_598219: Call_CreateModel_598206; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_598220 = newJObject()
  if body != nil:
    body_598220 = body
  result = call_598219.call(nil, nil, nil, nil, body_598220)

var createModel* = Call_CreateModel_598206(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_598207,
                                        base: "/", url: url_CreateModel_598208,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_598221 = ref object of OpenApiRestCall_597389
proc url_CreateModelPackage_598223(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateModelPackage_598222(path: JsonNode; query: JsonNode;
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
  var valid_598224 = header.getOrDefault("X-Amz-Target")
  valid_598224 = validateParameter(valid_598224, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_598224 != nil:
    section.add "X-Amz-Target", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Signature")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Signature", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Content-Sha256", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Date")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Date", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Credential")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Credential", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Security-Token")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Security-Token", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Algorithm")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Algorithm", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-SignedHeaders", valid_598231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598233: Call_CreateModelPackage_598221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_598233.validator(path, query, header, formData, body)
  let scheme = call_598233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598233.url(scheme.get, call_598233.host, call_598233.base,
                         call_598233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598233, url, valid)

proc call*(call_598234: Call_CreateModelPackage_598221; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_598235 = newJObject()
  if body != nil:
    body_598235 = body
  result = call_598234.call(nil, nil, nil, nil, body_598235)

var createModelPackage* = Call_CreateModelPackage_598221(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_598222, base: "/",
    url: url_CreateModelPackage_598223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMonitoringSchedule_598236 = ref object of OpenApiRestCall_597389
proc url_CreateMonitoringSchedule_598238(protocol: Scheme; host: string;
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

proc validate_CreateMonitoringSchedule_598237(path: JsonNode; query: JsonNode;
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
  var valid_598239 = header.getOrDefault("X-Amz-Target")
  valid_598239 = validateParameter(valid_598239, JString, required = true, default = newJString(
      "SageMaker.CreateMonitoringSchedule"))
  if valid_598239 != nil:
    section.add "X-Amz-Target", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Signature")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Signature", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Content-Sha256", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Date")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Date", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Credential")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Credential", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Security-Token")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Security-Token", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Algorithm")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Algorithm", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-SignedHeaders", valid_598246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598248: Call_CreateMonitoringSchedule_598236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ## 
  let valid = call_598248.validator(path, query, header, formData, body)
  let scheme = call_598248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598248.url(scheme.get, call_598248.host, call_598248.base,
                         call_598248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598248, url, valid)

proc call*(call_598249: Call_CreateMonitoringSchedule_598236; body: JsonNode): Recallable =
  ## createMonitoringSchedule
  ## Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endoint.
  ##   body: JObject (required)
  var body_598250 = newJObject()
  if body != nil:
    body_598250 = body
  result = call_598249.call(nil, nil, nil, nil, body_598250)

var createMonitoringSchedule* = Call_CreateMonitoringSchedule_598236(
    name: "createMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule",
    validator: validate_CreateMonitoringSchedule_598237, base: "/",
    url: url_CreateMonitoringSchedule_598238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_598251 = ref object of OpenApiRestCall_597389
proc url_CreateNotebookInstance_598253(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateNotebookInstance_598252(path: JsonNode; query: JsonNode;
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
  var valid_598254 = header.getOrDefault("X-Amz-Target")
  valid_598254 = validateParameter(valid_598254, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_598254 != nil:
    section.add "X-Amz-Target", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Signature")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Signature", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-Content-Sha256", valid_598256
  var valid_598257 = header.getOrDefault("X-Amz-Date")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Date", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Credential")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Credential", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-Security-Token")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Security-Token", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Algorithm")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Algorithm", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-SignedHeaders", valid_598261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598263: Call_CreateNotebookInstance_598251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_598263.validator(path, query, header, formData, body)
  let scheme = call_598263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598263.url(scheme.get, call_598263.host, call_598263.base,
                         call_598263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598263, url, valid)

proc call*(call_598264: Call_CreateNotebookInstance_598251; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_598265 = newJObject()
  if body != nil:
    body_598265 = body
  result = call_598264.call(nil, nil, nil, nil, body_598265)

var createNotebookInstance* = Call_CreateNotebookInstance_598251(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_598252, base: "/",
    url: url_CreateNotebookInstance_598253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_598266 = ref object of OpenApiRestCall_597389
proc url_CreateNotebookInstanceLifecycleConfig_598268(protocol: Scheme;
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

proc validate_CreateNotebookInstanceLifecycleConfig_598267(path: JsonNode;
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
  var valid_598269 = header.getOrDefault("X-Amz-Target")
  valid_598269 = validateParameter(valid_598269, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_598269 != nil:
    section.add "X-Amz-Target", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Signature")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Signature", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Content-Sha256", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Date")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Date", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-Credential")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-Credential", valid_598273
  var valid_598274 = header.getOrDefault("X-Amz-Security-Token")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "X-Amz-Security-Token", valid_598274
  var valid_598275 = header.getOrDefault("X-Amz-Algorithm")
  valid_598275 = validateParameter(valid_598275, JString, required = false,
                                 default = nil)
  if valid_598275 != nil:
    section.add "X-Amz-Algorithm", valid_598275
  var valid_598276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "X-Amz-SignedHeaders", valid_598276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598278: Call_CreateNotebookInstanceLifecycleConfig_598266;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_598278.validator(path, query, header, formData, body)
  let scheme = call_598278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598278.url(scheme.get, call_598278.host, call_598278.base,
                         call_598278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598278, url, valid)

proc call*(call_598279: Call_CreateNotebookInstanceLifecycleConfig_598266;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_598280 = newJObject()
  if body != nil:
    body_598280 = body
  result = call_598279.call(nil, nil, nil, nil, body_598280)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_598266(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_598267, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_598268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedDomainUrl_598281 = ref object of OpenApiRestCall_597389
proc url_CreatePresignedDomainUrl_598283(protocol: Scheme; host: string;
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

proc validate_CreatePresignedDomainUrl_598282(path: JsonNode; query: JsonNode;
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
  var valid_598284 = header.getOrDefault("X-Amz-Target")
  valid_598284 = validateParameter(valid_598284, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedDomainUrl"))
  if valid_598284 != nil:
    section.add "X-Amz-Target", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Signature")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Signature", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-Content-Sha256", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Date")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Date", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-Credential")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Credential", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-Security-Token")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-Security-Token", valid_598289
  var valid_598290 = header.getOrDefault("X-Amz-Algorithm")
  valid_598290 = validateParameter(valid_598290, JString, required = false,
                                 default = nil)
  if valid_598290 != nil:
    section.add "X-Amz-Algorithm", valid_598290
  var valid_598291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598291 = validateParameter(valid_598291, JString, required = false,
                                 default = nil)
  if valid_598291 != nil:
    section.add "X-Amz-SignedHeaders", valid_598291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598293: Call_CreatePresignedDomainUrl_598281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ## 
  let valid = call_598293.validator(path, query, header, formData, body)
  let scheme = call_598293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598293.url(scheme.get, call_598293.host, call_598293.base,
                         call_598293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598293, url, valid)

proc call*(call_598294: Call_CreatePresignedDomainUrl_598281; body: JsonNode): Recallable =
  ## createPresignedDomainUrl
  ## Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Amazon SageMaker Studio (Studio), and granted access to all of the Apps and files associated with that Amazon Elastic File System (EFS). This operation can only be called when AuthMode equals IAM. 
  ##   body: JObject (required)
  var body_598295 = newJObject()
  if body != nil:
    body_598295 = body
  result = call_598294.call(nil, nil, nil, nil, body_598295)

var createPresignedDomainUrl* = Call_CreatePresignedDomainUrl_598281(
    name: "createPresignedDomainUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl",
    validator: validate_CreatePresignedDomainUrl_598282, base: "/",
    url: url_CreatePresignedDomainUrl_598283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_598296 = ref object of OpenApiRestCall_597389
proc url_CreatePresignedNotebookInstanceUrl_598298(protocol: Scheme; host: string;
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

proc validate_CreatePresignedNotebookInstanceUrl_598297(path: JsonNode;
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
  var valid_598299 = header.getOrDefault("X-Amz-Target")
  valid_598299 = validateParameter(valid_598299, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_598299 != nil:
    section.add "X-Amz-Target", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Signature")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Signature", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Content-Sha256", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Date")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Date", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Credential")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Credential", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-Security-Token")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Security-Token", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-Algorithm")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-Algorithm", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-SignedHeaders", valid_598306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598308: Call_CreatePresignedNotebookInstanceUrl_598296;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_598308.validator(path, query, header, formData, body)
  let scheme = call_598308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598308.url(scheme.get, call_598308.host, call_598308.base,
                         call_598308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598308, url, valid)

proc call*(call_598309: Call_CreatePresignedNotebookInstanceUrl_598296;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_598310 = newJObject()
  if body != nil:
    body_598310 = body
  result = call_598309.call(nil, nil, nil, nil, body_598310)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_598296(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_598297, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_598298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProcessingJob_598311 = ref object of OpenApiRestCall_597389
proc url_CreateProcessingJob_598313(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProcessingJob_598312(path: JsonNode; query: JsonNode;
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
  var valid_598314 = header.getOrDefault("X-Amz-Target")
  valid_598314 = validateParameter(valid_598314, JString, required = true, default = newJString(
      "SageMaker.CreateProcessingJob"))
  if valid_598314 != nil:
    section.add "X-Amz-Target", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Signature")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Signature", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Content-Sha256", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Date")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Date", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Credential")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Credential", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Security-Token")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Security-Token", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-Algorithm")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-Algorithm", valid_598320
  var valid_598321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "X-Amz-SignedHeaders", valid_598321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598323: Call_CreateProcessingJob_598311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a processing job.
  ## 
  let valid = call_598323.validator(path, query, header, formData, body)
  let scheme = call_598323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598323.url(scheme.get, call_598323.host, call_598323.base,
                         call_598323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598323, url, valid)

proc call*(call_598324: Call_CreateProcessingJob_598311; body: JsonNode): Recallable =
  ## createProcessingJob
  ## Creates a processing job.
  ##   body: JObject (required)
  var body_598325 = newJObject()
  if body != nil:
    body_598325 = body
  result = call_598324.call(nil, nil, nil, nil, body_598325)

var createProcessingJob* = Call_CreateProcessingJob_598311(
    name: "createProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateProcessingJob",
    validator: validate_CreateProcessingJob_598312, base: "/",
    url: url_CreateProcessingJob_598313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_598326 = ref object of OpenApiRestCall_597389
proc url_CreateTrainingJob_598328(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrainingJob_598327(path: JsonNode; query: JsonNode;
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
  var valid_598329 = header.getOrDefault("X-Amz-Target")
  valid_598329 = validateParameter(valid_598329, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_598329 != nil:
    section.add "X-Amz-Target", valid_598329
  var valid_598330 = header.getOrDefault("X-Amz-Signature")
  valid_598330 = validateParameter(valid_598330, JString, required = false,
                                 default = nil)
  if valid_598330 != nil:
    section.add "X-Amz-Signature", valid_598330
  var valid_598331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "X-Amz-Content-Sha256", valid_598331
  var valid_598332 = header.getOrDefault("X-Amz-Date")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Date", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Credential")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Credential", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Security-Token")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Security-Token", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Algorithm")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Algorithm", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-SignedHeaders", valid_598336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598338: Call_CreateTrainingJob_598326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_598338.validator(path, query, header, formData, body)
  let scheme = call_598338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598338.url(scheme.get, call_598338.host, call_598338.base,
                         call_598338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598338, url, valid)

proc call*(call_598339: Call_CreateTrainingJob_598326; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_598340 = newJObject()
  if body != nil:
    body_598340 = body
  result = call_598339.call(nil, nil, nil, nil, body_598340)

var createTrainingJob* = Call_CreateTrainingJob_598326(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_598327, base: "/",
    url: url_CreateTrainingJob_598328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_598341 = ref object of OpenApiRestCall_597389
proc url_CreateTransformJob_598343(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTransformJob_598342(path: JsonNode; query: JsonNode;
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
  var valid_598344 = header.getOrDefault("X-Amz-Target")
  valid_598344 = validateParameter(valid_598344, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_598344 != nil:
    section.add "X-Amz-Target", valid_598344
  var valid_598345 = header.getOrDefault("X-Amz-Signature")
  valid_598345 = validateParameter(valid_598345, JString, required = false,
                                 default = nil)
  if valid_598345 != nil:
    section.add "X-Amz-Signature", valid_598345
  var valid_598346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598346 = validateParameter(valid_598346, JString, required = false,
                                 default = nil)
  if valid_598346 != nil:
    section.add "X-Amz-Content-Sha256", valid_598346
  var valid_598347 = header.getOrDefault("X-Amz-Date")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Date", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Credential")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Credential", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Security-Token")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Security-Token", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Algorithm")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Algorithm", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-SignedHeaders", valid_598351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598353: Call_CreateTransformJob_598341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ## 
  let valid = call_598353.validator(path, query, header, formData, body)
  let scheme = call_598353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598353.url(scheme.get, call_598353.host, call_598353.base,
                         call_598353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598353, url, valid)

proc call*(call_598354: Call_CreateTransformJob_598341; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
  ##   body: JObject (required)
  var body_598355 = newJObject()
  if body != nil:
    body_598355 = body
  result = call_598354.call(nil, nil, nil, nil, body_598355)

var createTransformJob* = Call_CreateTransformJob_598341(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_598342, base: "/",
    url: url_CreateTransformJob_598343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrial_598356 = ref object of OpenApiRestCall_597389
proc url_CreateTrial_598358(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrial_598357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598359 = header.getOrDefault("X-Amz-Target")
  valid_598359 = validateParameter(valid_598359, JString, required = true,
                                 default = newJString("SageMaker.CreateTrial"))
  if valid_598359 != nil:
    section.add "X-Amz-Target", valid_598359
  var valid_598360 = header.getOrDefault("X-Amz-Signature")
  valid_598360 = validateParameter(valid_598360, JString, required = false,
                                 default = nil)
  if valid_598360 != nil:
    section.add "X-Amz-Signature", valid_598360
  var valid_598361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598361 = validateParameter(valid_598361, JString, required = false,
                                 default = nil)
  if valid_598361 != nil:
    section.add "X-Amz-Content-Sha256", valid_598361
  var valid_598362 = header.getOrDefault("X-Amz-Date")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "X-Amz-Date", valid_598362
  var valid_598363 = header.getOrDefault("X-Amz-Credential")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "X-Amz-Credential", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-Security-Token")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-Security-Token", valid_598364
  var valid_598365 = header.getOrDefault("X-Amz-Algorithm")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Algorithm", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-SignedHeaders", valid_598366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598368: Call_CreateTrial_598356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ## 
  let valid = call_598368.validator(path, query, header, formData, body)
  let scheme = call_598368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598368.url(scheme.get, call_598368.host, call_598368.base,
                         call_598368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598368, url, valid)

proc call*(call_598369: Call_CreateTrial_598356; body: JsonNode): Recallable =
  ## createTrial
  ## <p>Creates an Amazon SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single Amazon SageMaker <i>experiment</i>.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a>Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a>ListTrials</a> API. To view a trial's properties, call the <a>DescribeTrial</a> API. To create a trial component, call the <a>CreateTrialComponent</a> API.</p>
  ##   body: JObject (required)
  var body_598370 = newJObject()
  if body != nil:
    body_598370 = body
  result = call_598369.call(nil, nil, nil, nil, body_598370)

var createTrial* = Call_CreateTrial_598356(name: "createTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateTrial",
                                        validator: validate_CreateTrial_598357,
                                        base: "/", url: url_CreateTrial_598358,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrialComponent_598371 = ref object of OpenApiRestCall_597389
proc url_CreateTrialComponent_598373(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrialComponent_598372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p>You can create a trial component through a direct call to the <code>CreateTrialComponent</code> API. However, you can't specify the <code>Source</code> property of the component in the request, therefore, the component isn't associated with an Amazon SageMaker job. You must use Amazon SageMaker Studio, the Amazon SageMaker Python SDK, or the AWS SDK for Python (Boto) to create the component with a valid <code>Source</code> property.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_598374 = header.getOrDefault("X-Amz-Target")
  valid_598374 = validateParameter(valid_598374, JString, required = true, default = newJString(
      "SageMaker.CreateTrialComponent"))
  if valid_598374 != nil:
    section.add "X-Amz-Target", valid_598374
  var valid_598375 = header.getOrDefault("X-Amz-Signature")
  valid_598375 = validateParameter(valid_598375, JString, required = false,
                                 default = nil)
  if valid_598375 != nil:
    section.add "X-Amz-Signature", valid_598375
  var valid_598376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598376 = validateParameter(valid_598376, JString, required = false,
                                 default = nil)
  if valid_598376 != nil:
    section.add "X-Amz-Content-Sha256", valid_598376
  var valid_598377 = header.getOrDefault("X-Amz-Date")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "X-Amz-Date", valid_598377
  var valid_598378 = header.getOrDefault("X-Amz-Credential")
  valid_598378 = validateParameter(valid_598378, JString, required = false,
                                 default = nil)
  if valid_598378 != nil:
    section.add "X-Amz-Credential", valid_598378
  var valid_598379 = header.getOrDefault("X-Amz-Security-Token")
  valid_598379 = validateParameter(valid_598379, JString, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "X-Amz-Security-Token", valid_598379
  var valid_598380 = header.getOrDefault("X-Amz-Algorithm")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "X-Amz-Algorithm", valid_598380
  var valid_598381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "X-Amz-SignedHeaders", valid_598381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598383: Call_CreateTrialComponent_598371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p>You can create a trial component through a direct call to the <code>CreateTrialComponent</code> API. However, you can't specify the <code>Source</code> property of the component in the request, therefore, the component isn't associated with an Amazon SageMaker job. You must use Amazon SageMaker Studio, the Amazon SageMaker Python SDK, or the AWS SDK for Python (Boto) to create the component with a valid <code>Source</code> property.</p> </note>
  ## 
  let valid = call_598383.validator(path, query, header, formData, body)
  let scheme = call_598383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598383.url(scheme.get, call_598383.host, call_598383.base,
                         call_598383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598383, url, valid)

proc call*(call_598384: Call_CreateTrialComponent_598371; body: JsonNode): Recallable =
  ## createTrialComponent
  ## <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use Amazon SageMaker Studio or the Amazon SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the AWS SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a>Search</a> API to search for the tags.</p> <note> <p>You can create a trial component through a direct call to the <code>CreateTrialComponent</code> API. However, you can't specify the <code>Source</code> property of the component in the request, therefore, the component isn't associated with an Amazon SageMaker job. You must use Amazon SageMaker Studio, the Amazon SageMaker Python SDK, or the AWS SDK for Python (Boto) to create the component with a valid <code>Source</code> property.</p> </note>
  ##   body: JObject (required)
  var body_598385 = newJObject()
  if body != nil:
    body_598385 = body
  result = call_598384.call(nil, nil, nil, nil, body_598385)

var createTrialComponent* = Call_CreateTrialComponent_598371(
    name: "createTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrialComponent",
    validator: validate_CreateTrialComponent_598372, base: "/",
    url: url_CreateTrialComponent_598373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserProfile_598386 = ref object of OpenApiRestCall_597389
proc url_CreateUserProfile_598388(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUserProfile_598387(path: JsonNode; query: JsonNode;
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
  var valid_598389 = header.getOrDefault("X-Amz-Target")
  valid_598389 = validateParameter(valid_598389, JString, required = true, default = newJString(
      "SageMaker.CreateUserProfile"))
  if valid_598389 != nil:
    section.add "X-Amz-Target", valid_598389
  var valid_598390 = header.getOrDefault("X-Amz-Signature")
  valid_598390 = validateParameter(valid_598390, JString, required = false,
                                 default = nil)
  if valid_598390 != nil:
    section.add "X-Amz-Signature", valid_598390
  var valid_598391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598391 = validateParameter(valid_598391, JString, required = false,
                                 default = nil)
  if valid_598391 != nil:
    section.add "X-Amz-Content-Sha256", valid_598391
  var valid_598392 = header.getOrDefault("X-Amz-Date")
  valid_598392 = validateParameter(valid_598392, JString, required = false,
                                 default = nil)
  if valid_598392 != nil:
    section.add "X-Amz-Date", valid_598392
  var valid_598393 = header.getOrDefault("X-Amz-Credential")
  valid_598393 = validateParameter(valid_598393, JString, required = false,
                                 default = nil)
  if valid_598393 != nil:
    section.add "X-Amz-Credential", valid_598393
  var valid_598394 = header.getOrDefault("X-Amz-Security-Token")
  valid_598394 = validateParameter(valid_598394, JString, required = false,
                                 default = nil)
  if valid_598394 != nil:
    section.add "X-Amz-Security-Token", valid_598394
  var valid_598395 = header.getOrDefault("X-Amz-Algorithm")
  valid_598395 = validateParameter(valid_598395, JString, required = false,
                                 default = nil)
  if valid_598395 != nil:
    section.add "X-Amz-Algorithm", valid_598395
  var valid_598396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598396 = validateParameter(valid_598396, JString, required = false,
                                 default = nil)
  if valid_598396 != nil:
    section.add "X-Amz-SignedHeaders", valid_598396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598398: Call_CreateUserProfile_598386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ## 
  let valid = call_598398.validator(path, query, header, formData, body)
  let scheme = call_598398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598398.url(scheme.get, call_598398.host, call_598398.base,
                         call_598398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598398, url, valid)

proc call*(call_598399: Call_CreateUserProfile_598386; body: JsonNode): Recallable =
  ## createUserProfile
  ## Creates a new user profile. A user profile represents a single user within a Domain, and is the main way to reference a "person" for the purposes of sharing, reporting and other user-oriented features. This entity is created during on-boarding. If an administrator invites a person by email or imports them from SSO, a new UserProfile is automatically created. This entity is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
  ##   body: JObject (required)
  var body_598400 = newJObject()
  if body != nil:
    body_598400 = body
  result = call_598399.call(nil, nil, nil, nil, body_598400)

var createUserProfile* = Call_CreateUserProfile_598386(name: "createUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateUserProfile",
    validator: validate_CreateUserProfile_598387, base: "/",
    url: url_CreateUserProfile_598388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_598401 = ref object of OpenApiRestCall_597389
proc url_CreateWorkteam_598403(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWorkteam_598402(path: JsonNode; query: JsonNode;
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
  var valid_598404 = header.getOrDefault("X-Amz-Target")
  valid_598404 = validateParameter(valid_598404, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_598404 != nil:
    section.add "X-Amz-Target", valid_598404
  var valid_598405 = header.getOrDefault("X-Amz-Signature")
  valid_598405 = validateParameter(valid_598405, JString, required = false,
                                 default = nil)
  if valid_598405 != nil:
    section.add "X-Amz-Signature", valid_598405
  var valid_598406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598406 = validateParameter(valid_598406, JString, required = false,
                                 default = nil)
  if valid_598406 != nil:
    section.add "X-Amz-Content-Sha256", valid_598406
  var valid_598407 = header.getOrDefault("X-Amz-Date")
  valid_598407 = validateParameter(valid_598407, JString, required = false,
                                 default = nil)
  if valid_598407 != nil:
    section.add "X-Amz-Date", valid_598407
  var valid_598408 = header.getOrDefault("X-Amz-Credential")
  valid_598408 = validateParameter(valid_598408, JString, required = false,
                                 default = nil)
  if valid_598408 != nil:
    section.add "X-Amz-Credential", valid_598408
  var valid_598409 = header.getOrDefault("X-Amz-Security-Token")
  valid_598409 = validateParameter(valid_598409, JString, required = false,
                                 default = nil)
  if valid_598409 != nil:
    section.add "X-Amz-Security-Token", valid_598409
  var valid_598410 = header.getOrDefault("X-Amz-Algorithm")
  valid_598410 = validateParameter(valid_598410, JString, required = false,
                                 default = nil)
  if valid_598410 != nil:
    section.add "X-Amz-Algorithm", valid_598410
  var valid_598411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-SignedHeaders", valid_598411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598413: Call_CreateWorkteam_598401; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_598413.validator(path, query, header, formData, body)
  let scheme = call_598413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598413.url(scheme.get, call_598413.host, call_598413.base,
                         call_598413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598413, url, valid)

proc call*(call_598414: Call_CreateWorkteam_598401; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_598415 = newJObject()
  if body != nil:
    body_598415 = body
  result = call_598414.call(nil, nil, nil, nil, body_598415)

var createWorkteam* = Call_CreateWorkteam_598401(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_598402, base: "/", url: url_CreateWorkteam_598403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_598416 = ref object of OpenApiRestCall_597389
proc url_DeleteAlgorithm_598418(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAlgorithm_598417(path: JsonNode; query: JsonNode;
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
  var valid_598419 = header.getOrDefault("X-Amz-Target")
  valid_598419 = validateParameter(valid_598419, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_598419 != nil:
    section.add "X-Amz-Target", valid_598419
  var valid_598420 = header.getOrDefault("X-Amz-Signature")
  valid_598420 = validateParameter(valid_598420, JString, required = false,
                                 default = nil)
  if valid_598420 != nil:
    section.add "X-Amz-Signature", valid_598420
  var valid_598421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598421 = validateParameter(valid_598421, JString, required = false,
                                 default = nil)
  if valid_598421 != nil:
    section.add "X-Amz-Content-Sha256", valid_598421
  var valid_598422 = header.getOrDefault("X-Amz-Date")
  valid_598422 = validateParameter(valid_598422, JString, required = false,
                                 default = nil)
  if valid_598422 != nil:
    section.add "X-Amz-Date", valid_598422
  var valid_598423 = header.getOrDefault("X-Amz-Credential")
  valid_598423 = validateParameter(valid_598423, JString, required = false,
                                 default = nil)
  if valid_598423 != nil:
    section.add "X-Amz-Credential", valid_598423
  var valid_598424 = header.getOrDefault("X-Amz-Security-Token")
  valid_598424 = validateParameter(valid_598424, JString, required = false,
                                 default = nil)
  if valid_598424 != nil:
    section.add "X-Amz-Security-Token", valid_598424
  var valid_598425 = header.getOrDefault("X-Amz-Algorithm")
  valid_598425 = validateParameter(valid_598425, JString, required = false,
                                 default = nil)
  if valid_598425 != nil:
    section.add "X-Amz-Algorithm", valid_598425
  var valid_598426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598426 = validateParameter(valid_598426, JString, required = false,
                                 default = nil)
  if valid_598426 != nil:
    section.add "X-Amz-SignedHeaders", valid_598426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598428: Call_DeleteAlgorithm_598416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_598428.validator(path, query, header, formData, body)
  let scheme = call_598428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598428.url(scheme.get, call_598428.host, call_598428.base,
                         call_598428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598428, url, valid)

proc call*(call_598429: Call_DeleteAlgorithm_598416; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_598430 = newJObject()
  if body != nil:
    body_598430 = body
  result = call_598429.call(nil, nil, nil, nil, body_598430)

var deleteAlgorithm* = Call_DeleteAlgorithm_598416(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_598417, base: "/", url: url_DeleteAlgorithm_598418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApp_598431 = ref object of OpenApiRestCall_597389
proc url_DeleteApp_598433(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteApp_598432(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598434 = header.getOrDefault("X-Amz-Target")
  valid_598434 = validateParameter(valid_598434, JString, required = true,
                                 default = newJString("SageMaker.DeleteApp"))
  if valid_598434 != nil:
    section.add "X-Amz-Target", valid_598434
  var valid_598435 = header.getOrDefault("X-Amz-Signature")
  valid_598435 = validateParameter(valid_598435, JString, required = false,
                                 default = nil)
  if valid_598435 != nil:
    section.add "X-Amz-Signature", valid_598435
  var valid_598436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598436 = validateParameter(valid_598436, JString, required = false,
                                 default = nil)
  if valid_598436 != nil:
    section.add "X-Amz-Content-Sha256", valid_598436
  var valid_598437 = header.getOrDefault("X-Amz-Date")
  valid_598437 = validateParameter(valid_598437, JString, required = false,
                                 default = nil)
  if valid_598437 != nil:
    section.add "X-Amz-Date", valid_598437
  var valid_598438 = header.getOrDefault("X-Amz-Credential")
  valid_598438 = validateParameter(valid_598438, JString, required = false,
                                 default = nil)
  if valid_598438 != nil:
    section.add "X-Amz-Credential", valid_598438
  var valid_598439 = header.getOrDefault("X-Amz-Security-Token")
  valid_598439 = validateParameter(valid_598439, JString, required = false,
                                 default = nil)
  if valid_598439 != nil:
    section.add "X-Amz-Security-Token", valid_598439
  var valid_598440 = header.getOrDefault("X-Amz-Algorithm")
  valid_598440 = validateParameter(valid_598440, JString, required = false,
                                 default = nil)
  if valid_598440 != nil:
    section.add "X-Amz-Algorithm", valid_598440
  var valid_598441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598441 = validateParameter(valid_598441, JString, required = false,
                                 default = nil)
  if valid_598441 != nil:
    section.add "X-Amz-SignedHeaders", valid_598441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598443: Call_DeleteApp_598431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to stop and delete an app.
  ## 
  let valid = call_598443.validator(path, query, header, formData, body)
  let scheme = call_598443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598443.url(scheme.get, call_598443.host, call_598443.base,
                         call_598443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598443, url, valid)

proc call*(call_598444: Call_DeleteApp_598431; body: JsonNode): Recallable =
  ## deleteApp
  ## Used to stop and delete an app.
  ##   body: JObject (required)
  var body_598445 = newJObject()
  if body != nil:
    body_598445 = body
  result = call_598444.call(nil, nil, nil, nil, body_598445)

var deleteApp* = Call_DeleteApp_598431(name: "deleteApp", meth: HttpMethod.HttpPost,
                                    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteApp",
                                    validator: validate_DeleteApp_598432,
                                    base: "/", url: url_DeleteApp_598433,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_598446 = ref object of OpenApiRestCall_597389
proc url_DeleteCodeRepository_598448(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCodeRepository_598447(path: JsonNode; query: JsonNode;
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
  var valid_598449 = header.getOrDefault("X-Amz-Target")
  valid_598449 = validateParameter(valid_598449, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_598449 != nil:
    section.add "X-Amz-Target", valid_598449
  var valid_598450 = header.getOrDefault("X-Amz-Signature")
  valid_598450 = validateParameter(valid_598450, JString, required = false,
                                 default = nil)
  if valid_598450 != nil:
    section.add "X-Amz-Signature", valid_598450
  var valid_598451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598451 = validateParameter(valid_598451, JString, required = false,
                                 default = nil)
  if valid_598451 != nil:
    section.add "X-Amz-Content-Sha256", valid_598451
  var valid_598452 = header.getOrDefault("X-Amz-Date")
  valid_598452 = validateParameter(valid_598452, JString, required = false,
                                 default = nil)
  if valid_598452 != nil:
    section.add "X-Amz-Date", valid_598452
  var valid_598453 = header.getOrDefault("X-Amz-Credential")
  valid_598453 = validateParameter(valid_598453, JString, required = false,
                                 default = nil)
  if valid_598453 != nil:
    section.add "X-Amz-Credential", valid_598453
  var valid_598454 = header.getOrDefault("X-Amz-Security-Token")
  valid_598454 = validateParameter(valid_598454, JString, required = false,
                                 default = nil)
  if valid_598454 != nil:
    section.add "X-Amz-Security-Token", valid_598454
  var valid_598455 = header.getOrDefault("X-Amz-Algorithm")
  valid_598455 = validateParameter(valid_598455, JString, required = false,
                                 default = nil)
  if valid_598455 != nil:
    section.add "X-Amz-Algorithm", valid_598455
  var valid_598456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598456 = validateParameter(valid_598456, JString, required = false,
                                 default = nil)
  if valid_598456 != nil:
    section.add "X-Amz-SignedHeaders", valid_598456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598458: Call_DeleteCodeRepository_598446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_598458.validator(path, query, header, formData, body)
  let scheme = call_598458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598458.url(scheme.get, call_598458.host, call_598458.base,
                         call_598458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598458, url, valid)

proc call*(call_598459: Call_DeleteCodeRepository_598446; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_598460 = newJObject()
  if body != nil:
    body_598460 = body
  result = call_598459.call(nil, nil, nil, nil, body_598460)

var deleteCodeRepository* = Call_DeleteCodeRepository_598446(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_598447, base: "/",
    url: url_DeleteCodeRepository_598448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDomain_598461 = ref object of OpenApiRestCall_597389
proc url_DeleteDomain_598463(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDomain_598462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598464 = header.getOrDefault("X-Amz-Target")
  valid_598464 = validateParameter(valid_598464, JString, required = true,
                                 default = newJString("SageMaker.DeleteDomain"))
  if valid_598464 != nil:
    section.add "X-Amz-Target", valid_598464
  var valid_598465 = header.getOrDefault("X-Amz-Signature")
  valid_598465 = validateParameter(valid_598465, JString, required = false,
                                 default = nil)
  if valid_598465 != nil:
    section.add "X-Amz-Signature", valid_598465
  var valid_598466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598466 = validateParameter(valid_598466, JString, required = false,
                                 default = nil)
  if valid_598466 != nil:
    section.add "X-Amz-Content-Sha256", valid_598466
  var valid_598467 = header.getOrDefault("X-Amz-Date")
  valid_598467 = validateParameter(valid_598467, JString, required = false,
                                 default = nil)
  if valid_598467 != nil:
    section.add "X-Amz-Date", valid_598467
  var valid_598468 = header.getOrDefault("X-Amz-Credential")
  valid_598468 = validateParameter(valid_598468, JString, required = false,
                                 default = nil)
  if valid_598468 != nil:
    section.add "X-Amz-Credential", valid_598468
  var valid_598469 = header.getOrDefault("X-Amz-Security-Token")
  valid_598469 = validateParameter(valid_598469, JString, required = false,
                                 default = nil)
  if valid_598469 != nil:
    section.add "X-Amz-Security-Token", valid_598469
  var valid_598470 = header.getOrDefault("X-Amz-Algorithm")
  valid_598470 = validateParameter(valid_598470, JString, required = false,
                                 default = nil)
  if valid_598470 != nil:
    section.add "X-Amz-Algorithm", valid_598470
  var valid_598471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598471 = validateParameter(valid_598471, JString, required = false,
                                 default = nil)
  if valid_598471 != nil:
    section.add "X-Amz-SignedHeaders", valid_598471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598473: Call_DeleteDomain_598461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ## 
  let valid = call_598473.validator(path, query, header, formData, body)
  let scheme = call_598473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598473.url(scheme.get, call_598473.host, call_598473.base,
                         call_598473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598473, url, valid)

proc call*(call_598474: Call_DeleteDomain_598461; body: JsonNode): Recallable =
  ## deleteDomain
  ## Used to delete a domain. If you on-boarded with IAM mode, you will need to delete your domain to on-board again using SSO. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
  ##   body: JObject (required)
  var body_598475 = newJObject()
  if body != nil:
    body_598475 = body
  result = call_598474.call(nil, nil, nil, nil, body_598475)

var deleteDomain* = Call_DeleteDomain_598461(name: "deleteDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteDomain",
    validator: validate_DeleteDomain_598462, base: "/", url: url_DeleteDomain_598463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_598476 = ref object of OpenApiRestCall_597389
proc url_DeleteEndpoint_598478(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpoint_598477(path: JsonNode; query: JsonNode;
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
  var valid_598479 = header.getOrDefault("X-Amz-Target")
  valid_598479 = validateParameter(valid_598479, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_598479 != nil:
    section.add "X-Amz-Target", valid_598479
  var valid_598480 = header.getOrDefault("X-Amz-Signature")
  valid_598480 = validateParameter(valid_598480, JString, required = false,
                                 default = nil)
  if valid_598480 != nil:
    section.add "X-Amz-Signature", valid_598480
  var valid_598481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598481 = validateParameter(valid_598481, JString, required = false,
                                 default = nil)
  if valid_598481 != nil:
    section.add "X-Amz-Content-Sha256", valid_598481
  var valid_598482 = header.getOrDefault("X-Amz-Date")
  valid_598482 = validateParameter(valid_598482, JString, required = false,
                                 default = nil)
  if valid_598482 != nil:
    section.add "X-Amz-Date", valid_598482
  var valid_598483 = header.getOrDefault("X-Amz-Credential")
  valid_598483 = validateParameter(valid_598483, JString, required = false,
                                 default = nil)
  if valid_598483 != nil:
    section.add "X-Amz-Credential", valid_598483
  var valid_598484 = header.getOrDefault("X-Amz-Security-Token")
  valid_598484 = validateParameter(valid_598484, JString, required = false,
                                 default = nil)
  if valid_598484 != nil:
    section.add "X-Amz-Security-Token", valid_598484
  var valid_598485 = header.getOrDefault("X-Amz-Algorithm")
  valid_598485 = validateParameter(valid_598485, JString, required = false,
                                 default = nil)
  if valid_598485 != nil:
    section.add "X-Amz-Algorithm", valid_598485
  var valid_598486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598486 = validateParameter(valid_598486, JString, required = false,
                                 default = nil)
  if valid_598486 != nil:
    section.add "X-Amz-SignedHeaders", valid_598486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598488: Call_DeleteEndpoint_598476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_598488.validator(path, query, header, formData, body)
  let scheme = call_598488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598488.url(scheme.get, call_598488.host, call_598488.base,
                         call_598488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598488, url, valid)

proc call*(call_598489: Call_DeleteEndpoint_598476; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_598490 = newJObject()
  if body != nil:
    body_598490 = body
  result = call_598489.call(nil, nil, nil, nil, body_598490)

var deleteEndpoint* = Call_DeleteEndpoint_598476(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_598477, base: "/", url: url_DeleteEndpoint_598478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_598491 = ref object of OpenApiRestCall_597389
proc url_DeleteEndpointConfig_598493(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEndpointConfig_598492(path: JsonNode; query: JsonNode;
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
  var valid_598494 = header.getOrDefault("X-Amz-Target")
  valid_598494 = validateParameter(valid_598494, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_598494 != nil:
    section.add "X-Amz-Target", valid_598494
  var valid_598495 = header.getOrDefault("X-Amz-Signature")
  valid_598495 = validateParameter(valid_598495, JString, required = false,
                                 default = nil)
  if valid_598495 != nil:
    section.add "X-Amz-Signature", valid_598495
  var valid_598496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598496 = validateParameter(valid_598496, JString, required = false,
                                 default = nil)
  if valid_598496 != nil:
    section.add "X-Amz-Content-Sha256", valid_598496
  var valid_598497 = header.getOrDefault("X-Amz-Date")
  valid_598497 = validateParameter(valid_598497, JString, required = false,
                                 default = nil)
  if valid_598497 != nil:
    section.add "X-Amz-Date", valid_598497
  var valid_598498 = header.getOrDefault("X-Amz-Credential")
  valid_598498 = validateParameter(valid_598498, JString, required = false,
                                 default = nil)
  if valid_598498 != nil:
    section.add "X-Amz-Credential", valid_598498
  var valid_598499 = header.getOrDefault("X-Amz-Security-Token")
  valid_598499 = validateParameter(valid_598499, JString, required = false,
                                 default = nil)
  if valid_598499 != nil:
    section.add "X-Amz-Security-Token", valid_598499
  var valid_598500 = header.getOrDefault("X-Amz-Algorithm")
  valid_598500 = validateParameter(valid_598500, JString, required = false,
                                 default = nil)
  if valid_598500 != nil:
    section.add "X-Amz-Algorithm", valid_598500
  var valid_598501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598501 = validateParameter(valid_598501, JString, required = false,
                                 default = nil)
  if valid_598501 != nil:
    section.add "X-Amz-SignedHeaders", valid_598501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598503: Call_DeleteEndpointConfig_598491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_598503.validator(path, query, header, formData, body)
  let scheme = call_598503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598503.url(scheme.get, call_598503.host, call_598503.base,
                         call_598503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598503, url, valid)

proc call*(call_598504: Call_DeleteEndpointConfig_598491; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_598505 = newJObject()
  if body != nil:
    body_598505 = body
  result = call_598504.call(nil, nil, nil, nil, body_598505)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_598491(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_598492, base: "/",
    url: url_DeleteEndpointConfig_598493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteExperiment_598506 = ref object of OpenApiRestCall_597389
proc url_DeleteExperiment_598508(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteExperiment_598507(path: JsonNode; query: JsonNode;
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
  var valid_598509 = header.getOrDefault("X-Amz-Target")
  valid_598509 = validateParameter(valid_598509, JString, required = true, default = newJString(
      "SageMaker.DeleteExperiment"))
  if valid_598509 != nil:
    section.add "X-Amz-Target", valid_598509
  var valid_598510 = header.getOrDefault("X-Amz-Signature")
  valid_598510 = validateParameter(valid_598510, JString, required = false,
                                 default = nil)
  if valid_598510 != nil:
    section.add "X-Amz-Signature", valid_598510
  var valid_598511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598511 = validateParameter(valid_598511, JString, required = false,
                                 default = nil)
  if valid_598511 != nil:
    section.add "X-Amz-Content-Sha256", valid_598511
  var valid_598512 = header.getOrDefault("X-Amz-Date")
  valid_598512 = validateParameter(valid_598512, JString, required = false,
                                 default = nil)
  if valid_598512 != nil:
    section.add "X-Amz-Date", valid_598512
  var valid_598513 = header.getOrDefault("X-Amz-Credential")
  valid_598513 = validateParameter(valid_598513, JString, required = false,
                                 default = nil)
  if valid_598513 != nil:
    section.add "X-Amz-Credential", valid_598513
  var valid_598514 = header.getOrDefault("X-Amz-Security-Token")
  valid_598514 = validateParameter(valid_598514, JString, required = false,
                                 default = nil)
  if valid_598514 != nil:
    section.add "X-Amz-Security-Token", valid_598514
  var valid_598515 = header.getOrDefault("X-Amz-Algorithm")
  valid_598515 = validateParameter(valid_598515, JString, required = false,
                                 default = nil)
  if valid_598515 != nil:
    section.add "X-Amz-Algorithm", valid_598515
  var valid_598516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598516 = validateParameter(valid_598516, JString, required = false,
                                 default = nil)
  if valid_598516 != nil:
    section.add "X-Amz-SignedHeaders", valid_598516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598518: Call_DeleteExperiment_598506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ## 
  let valid = call_598518.validator(path, query, header, formData, body)
  let scheme = call_598518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598518.url(scheme.get, call_598518.host, call_598518.base,
                         call_598518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598518, url, valid)

proc call*(call_598519: Call_DeleteExperiment_598506; body: JsonNode): Recallable =
  ## deleteExperiment
  ## Deletes an Amazon SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a>ListTrials</a> API to get a list of the trials associated with the experiment.
  ##   body: JObject (required)
  var body_598520 = newJObject()
  if body != nil:
    body_598520 = body
  result = call_598519.call(nil, nil, nil, nil, body_598520)

var deleteExperiment* = Call_DeleteExperiment_598506(name: "deleteExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteExperiment",
    validator: validate_DeleteExperiment_598507, base: "/",
    url: url_DeleteExperiment_598508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlowDefinition_598521 = ref object of OpenApiRestCall_597389
proc url_DeleteFlowDefinition_598523(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFlowDefinition_598522(path: JsonNode; query: JsonNode;
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
  var valid_598524 = header.getOrDefault("X-Amz-Target")
  valid_598524 = validateParameter(valid_598524, JString, required = true, default = newJString(
      "SageMaker.DeleteFlowDefinition"))
  if valid_598524 != nil:
    section.add "X-Amz-Target", valid_598524
  var valid_598525 = header.getOrDefault("X-Amz-Signature")
  valid_598525 = validateParameter(valid_598525, JString, required = false,
                                 default = nil)
  if valid_598525 != nil:
    section.add "X-Amz-Signature", valid_598525
  var valid_598526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598526 = validateParameter(valid_598526, JString, required = false,
                                 default = nil)
  if valid_598526 != nil:
    section.add "X-Amz-Content-Sha256", valid_598526
  var valid_598527 = header.getOrDefault("X-Amz-Date")
  valid_598527 = validateParameter(valid_598527, JString, required = false,
                                 default = nil)
  if valid_598527 != nil:
    section.add "X-Amz-Date", valid_598527
  var valid_598528 = header.getOrDefault("X-Amz-Credential")
  valid_598528 = validateParameter(valid_598528, JString, required = false,
                                 default = nil)
  if valid_598528 != nil:
    section.add "X-Amz-Credential", valid_598528
  var valid_598529 = header.getOrDefault("X-Amz-Security-Token")
  valid_598529 = validateParameter(valid_598529, JString, required = false,
                                 default = nil)
  if valid_598529 != nil:
    section.add "X-Amz-Security-Token", valid_598529
  var valid_598530 = header.getOrDefault("X-Amz-Algorithm")
  valid_598530 = validateParameter(valid_598530, JString, required = false,
                                 default = nil)
  if valid_598530 != nil:
    section.add "X-Amz-Algorithm", valid_598530
  var valid_598531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598531 = validateParameter(valid_598531, JString, required = false,
                                 default = nil)
  if valid_598531 != nil:
    section.add "X-Amz-SignedHeaders", valid_598531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598533: Call_DeleteFlowDefinition_598521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified flow definition.
  ## 
  let valid = call_598533.validator(path, query, header, formData, body)
  let scheme = call_598533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598533.url(scheme.get, call_598533.host, call_598533.base,
                         call_598533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598533, url, valid)

proc call*(call_598534: Call_DeleteFlowDefinition_598521; body: JsonNode): Recallable =
  ## deleteFlowDefinition
  ## Deletes the specified flow definition.
  ##   body: JObject (required)
  var body_598535 = newJObject()
  if body != nil:
    body_598535 = body
  result = call_598534.call(nil, nil, nil, nil, body_598535)

var deleteFlowDefinition* = Call_DeleteFlowDefinition_598521(
    name: "deleteFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteFlowDefinition",
    validator: validate_DeleteFlowDefinition_598522, base: "/",
    url: url_DeleteFlowDefinition_598523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_598536 = ref object of OpenApiRestCall_597389
proc url_DeleteModel_598538(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModel_598537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598539 = header.getOrDefault("X-Amz-Target")
  valid_598539 = validateParameter(valid_598539, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_598539 != nil:
    section.add "X-Amz-Target", valid_598539
  var valid_598540 = header.getOrDefault("X-Amz-Signature")
  valid_598540 = validateParameter(valid_598540, JString, required = false,
                                 default = nil)
  if valid_598540 != nil:
    section.add "X-Amz-Signature", valid_598540
  var valid_598541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598541 = validateParameter(valid_598541, JString, required = false,
                                 default = nil)
  if valid_598541 != nil:
    section.add "X-Amz-Content-Sha256", valid_598541
  var valid_598542 = header.getOrDefault("X-Amz-Date")
  valid_598542 = validateParameter(valid_598542, JString, required = false,
                                 default = nil)
  if valid_598542 != nil:
    section.add "X-Amz-Date", valid_598542
  var valid_598543 = header.getOrDefault("X-Amz-Credential")
  valid_598543 = validateParameter(valid_598543, JString, required = false,
                                 default = nil)
  if valid_598543 != nil:
    section.add "X-Amz-Credential", valid_598543
  var valid_598544 = header.getOrDefault("X-Amz-Security-Token")
  valid_598544 = validateParameter(valid_598544, JString, required = false,
                                 default = nil)
  if valid_598544 != nil:
    section.add "X-Amz-Security-Token", valid_598544
  var valid_598545 = header.getOrDefault("X-Amz-Algorithm")
  valid_598545 = validateParameter(valid_598545, JString, required = false,
                                 default = nil)
  if valid_598545 != nil:
    section.add "X-Amz-Algorithm", valid_598545
  var valid_598546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598546 = validateParameter(valid_598546, JString, required = false,
                                 default = nil)
  if valid_598546 != nil:
    section.add "X-Amz-SignedHeaders", valid_598546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598548: Call_DeleteModel_598536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_598548.validator(path, query, header, formData, body)
  let scheme = call_598548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598548.url(scheme.get, call_598548.host, call_598548.base,
                         call_598548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598548, url, valid)

proc call*(call_598549: Call_DeleteModel_598536; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_598550 = newJObject()
  if body != nil:
    body_598550 = body
  result = call_598549.call(nil, nil, nil, nil, body_598550)

var deleteModel* = Call_DeleteModel_598536(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_598537,
                                        base: "/", url: url_DeleteModel_598538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_598551 = ref object of OpenApiRestCall_597389
proc url_DeleteModelPackage_598553(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteModelPackage_598552(path: JsonNode; query: JsonNode;
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
  var valid_598554 = header.getOrDefault("X-Amz-Target")
  valid_598554 = validateParameter(valid_598554, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_598554 != nil:
    section.add "X-Amz-Target", valid_598554
  var valid_598555 = header.getOrDefault("X-Amz-Signature")
  valid_598555 = validateParameter(valid_598555, JString, required = false,
                                 default = nil)
  if valid_598555 != nil:
    section.add "X-Amz-Signature", valid_598555
  var valid_598556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598556 = validateParameter(valid_598556, JString, required = false,
                                 default = nil)
  if valid_598556 != nil:
    section.add "X-Amz-Content-Sha256", valid_598556
  var valid_598557 = header.getOrDefault("X-Amz-Date")
  valid_598557 = validateParameter(valid_598557, JString, required = false,
                                 default = nil)
  if valid_598557 != nil:
    section.add "X-Amz-Date", valid_598557
  var valid_598558 = header.getOrDefault("X-Amz-Credential")
  valid_598558 = validateParameter(valid_598558, JString, required = false,
                                 default = nil)
  if valid_598558 != nil:
    section.add "X-Amz-Credential", valid_598558
  var valid_598559 = header.getOrDefault("X-Amz-Security-Token")
  valid_598559 = validateParameter(valid_598559, JString, required = false,
                                 default = nil)
  if valid_598559 != nil:
    section.add "X-Amz-Security-Token", valid_598559
  var valid_598560 = header.getOrDefault("X-Amz-Algorithm")
  valid_598560 = validateParameter(valid_598560, JString, required = false,
                                 default = nil)
  if valid_598560 != nil:
    section.add "X-Amz-Algorithm", valid_598560
  var valid_598561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598561 = validateParameter(valid_598561, JString, required = false,
                                 default = nil)
  if valid_598561 != nil:
    section.add "X-Amz-SignedHeaders", valid_598561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598563: Call_DeleteModelPackage_598551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_598563.validator(path, query, header, formData, body)
  let scheme = call_598563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598563.url(scheme.get, call_598563.host, call_598563.base,
                         call_598563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598563, url, valid)

proc call*(call_598564: Call_DeleteModelPackage_598551; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_598565 = newJObject()
  if body != nil:
    body_598565 = body
  result = call_598564.call(nil, nil, nil, nil, body_598565)

var deleteModelPackage* = Call_DeleteModelPackage_598551(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_598552, base: "/",
    url: url_DeleteModelPackage_598553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMonitoringSchedule_598566 = ref object of OpenApiRestCall_597389
proc url_DeleteMonitoringSchedule_598568(protocol: Scheme; host: string;
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

proc validate_DeleteMonitoringSchedule_598567(path: JsonNode; query: JsonNode;
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
  var valid_598569 = header.getOrDefault("X-Amz-Target")
  valid_598569 = validateParameter(valid_598569, JString, required = true, default = newJString(
      "SageMaker.DeleteMonitoringSchedule"))
  if valid_598569 != nil:
    section.add "X-Amz-Target", valid_598569
  var valid_598570 = header.getOrDefault("X-Amz-Signature")
  valid_598570 = validateParameter(valid_598570, JString, required = false,
                                 default = nil)
  if valid_598570 != nil:
    section.add "X-Amz-Signature", valid_598570
  var valid_598571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598571 = validateParameter(valid_598571, JString, required = false,
                                 default = nil)
  if valid_598571 != nil:
    section.add "X-Amz-Content-Sha256", valid_598571
  var valid_598572 = header.getOrDefault("X-Amz-Date")
  valid_598572 = validateParameter(valid_598572, JString, required = false,
                                 default = nil)
  if valid_598572 != nil:
    section.add "X-Amz-Date", valid_598572
  var valid_598573 = header.getOrDefault("X-Amz-Credential")
  valid_598573 = validateParameter(valid_598573, JString, required = false,
                                 default = nil)
  if valid_598573 != nil:
    section.add "X-Amz-Credential", valid_598573
  var valid_598574 = header.getOrDefault("X-Amz-Security-Token")
  valid_598574 = validateParameter(valid_598574, JString, required = false,
                                 default = nil)
  if valid_598574 != nil:
    section.add "X-Amz-Security-Token", valid_598574
  var valid_598575 = header.getOrDefault("X-Amz-Algorithm")
  valid_598575 = validateParameter(valid_598575, JString, required = false,
                                 default = nil)
  if valid_598575 != nil:
    section.add "X-Amz-Algorithm", valid_598575
  var valid_598576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598576 = validateParameter(valid_598576, JString, required = false,
                                 default = nil)
  if valid_598576 != nil:
    section.add "X-Amz-SignedHeaders", valid_598576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598578: Call_DeleteMonitoringSchedule_598566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ## 
  let valid = call_598578.validator(path, query, header, formData, body)
  let scheme = call_598578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598578.url(scheme.get, call_598578.host, call_598578.base,
                         call_598578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598578, url, valid)

proc call*(call_598579: Call_DeleteMonitoringSchedule_598566; body: JsonNode): Recallable =
  ## deleteMonitoringSchedule
  ## Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
  ##   body: JObject (required)
  var body_598580 = newJObject()
  if body != nil:
    body_598580 = body
  result = call_598579.call(nil, nil, nil, nil, body_598580)

var deleteMonitoringSchedule* = Call_DeleteMonitoringSchedule_598566(
    name: "deleteMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule",
    validator: validate_DeleteMonitoringSchedule_598567, base: "/",
    url: url_DeleteMonitoringSchedule_598568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_598581 = ref object of OpenApiRestCall_597389
proc url_DeleteNotebookInstance_598583(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteNotebookInstance_598582(path: JsonNode; query: JsonNode;
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
  var valid_598584 = header.getOrDefault("X-Amz-Target")
  valid_598584 = validateParameter(valid_598584, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_598584 != nil:
    section.add "X-Amz-Target", valid_598584
  var valid_598585 = header.getOrDefault("X-Amz-Signature")
  valid_598585 = validateParameter(valid_598585, JString, required = false,
                                 default = nil)
  if valid_598585 != nil:
    section.add "X-Amz-Signature", valid_598585
  var valid_598586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598586 = validateParameter(valid_598586, JString, required = false,
                                 default = nil)
  if valid_598586 != nil:
    section.add "X-Amz-Content-Sha256", valid_598586
  var valid_598587 = header.getOrDefault("X-Amz-Date")
  valid_598587 = validateParameter(valid_598587, JString, required = false,
                                 default = nil)
  if valid_598587 != nil:
    section.add "X-Amz-Date", valid_598587
  var valid_598588 = header.getOrDefault("X-Amz-Credential")
  valid_598588 = validateParameter(valid_598588, JString, required = false,
                                 default = nil)
  if valid_598588 != nil:
    section.add "X-Amz-Credential", valid_598588
  var valid_598589 = header.getOrDefault("X-Amz-Security-Token")
  valid_598589 = validateParameter(valid_598589, JString, required = false,
                                 default = nil)
  if valid_598589 != nil:
    section.add "X-Amz-Security-Token", valid_598589
  var valid_598590 = header.getOrDefault("X-Amz-Algorithm")
  valid_598590 = validateParameter(valid_598590, JString, required = false,
                                 default = nil)
  if valid_598590 != nil:
    section.add "X-Amz-Algorithm", valid_598590
  var valid_598591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598591 = validateParameter(valid_598591, JString, required = false,
                                 default = nil)
  if valid_598591 != nil:
    section.add "X-Amz-SignedHeaders", valid_598591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598593: Call_DeleteNotebookInstance_598581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_598593.validator(path, query, header, formData, body)
  let scheme = call_598593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598593.url(scheme.get, call_598593.host, call_598593.base,
                         call_598593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598593, url, valid)

proc call*(call_598594: Call_DeleteNotebookInstance_598581; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_598595 = newJObject()
  if body != nil:
    body_598595 = body
  result = call_598594.call(nil, nil, nil, nil, body_598595)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_598581(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_598582, base: "/",
    url: url_DeleteNotebookInstance_598583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_598596 = ref object of OpenApiRestCall_597389
proc url_DeleteNotebookInstanceLifecycleConfig_598598(protocol: Scheme;
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

proc validate_DeleteNotebookInstanceLifecycleConfig_598597(path: JsonNode;
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
  var valid_598599 = header.getOrDefault("X-Amz-Target")
  valid_598599 = validateParameter(valid_598599, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_598599 != nil:
    section.add "X-Amz-Target", valid_598599
  var valid_598600 = header.getOrDefault("X-Amz-Signature")
  valid_598600 = validateParameter(valid_598600, JString, required = false,
                                 default = nil)
  if valid_598600 != nil:
    section.add "X-Amz-Signature", valid_598600
  var valid_598601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598601 = validateParameter(valid_598601, JString, required = false,
                                 default = nil)
  if valid_598601 != nil:
    section.add "X-Amz-Content-Sha256", valid_598601
  var valid_598602 = header.getOrDefault("X-Amz-Date")
  valid_598602 = validateParameter(valid_598602, JString, required = false,
                                 default = nil)
  if valid_598602 != nil:
    section.add "X-Amz-Date", valid_598602
  var valid_598603 = header.getOrDefault("X-Amz-Credential")
  valid_598603 = validateParameter(valid_598603, JString, required = false,
                                 default = nil)
  if valid_598603 != nil:
    section.add "X-Amz-Credential", valid_598603
  var valid_598604 = header.getOrDefault("X-Amz-Security-Token")
  valid_598604 = validateParameter(valid_598604, JString, required = false,
                                 default = nil)
  if valid_598604 != nil:
    section.add "X-Amz-Security-Token", valid_598604
  var valid_598605 = header.getOrDefault("X-Amz-Algorithm")
  valid_598605 = validateParameter(valid_598605, JString, required = false,
                                 default = nil)
  if valid_598605 != nil:
    section.add "X-Amz-Algorithm", valid_598605
  var valid_598606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598606 = validateParameter(valid_598606, JString, required = false,
                                 default = nil)
  if valid_598606 != nil:
    section.add "X-Amz-SignedHeaders", valid_598606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598608: Call_DeleteNotebookInstanceLifecycleConfig_598596;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_598608.validator(path, query, header, formData, body)
  let scheme = call_598608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598608.url(scheme.get, call_598608.host, call_598608.base,
                         call_598608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598608, url, valid)

proc call*(call_598609: Call_DeleteNotebookInstanceLifecycleConfig_598596;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_598610 = newJObject()
  if body != nil:
    body_598610 = body
  result = call_598609.call(nil, nil, nil, nil, body_598610)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_598596(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_598597, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_598598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_598611 = ref object of OpenApiRestCall_597389
proc url_DeleteTags_598613(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_598612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598614 = header.getOrDefault("X-Amz-Target")
  valid_598614 = validateParameter(valid_598614, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_598614 != nil:
    section.add "X-Amz-Target", valid_598614
  var valid_598615 = header.getOrDefault("X-Amz-Signature")
  valid_598615 = validateParameter(valid_598615, JString, required = false,
                                 default = nil)
  if valid_598615 != nil:
    section.add "X-Amz-Signature", valid_598615
  var valid_598616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598616 = validateParameter(valid_598616, JString, required = false,
                                 default = nil)
  if valid_598616 != nil:
    section.add "X-Amz-Content-Sha256", valid_598616
  var valid_598617 = header.getOrDefault("X-Amz-Date")
  valid_598617 = validateParameter(valid_598617, JString, required = false,
                                 default = nil)
  if valid_598617 != nil:
    section.add "X-Amz-Date", valid_598617
  var valid_598618 = header.getOrDefault("X-Amz-Credential")
  valid_598618 = validateParameter(valid_598618, JString, required = false,
                                 default = nil)
  if valid_598618 != nil:
    section.add "X-Amz-Credential", valid_598618
  var valid_598619 = header.getOrDefault("X-Amz-Security-Token")
  valid_598619 = validateParameter(valid_598619, JString, required = false,
                                 default = nil)
  if valid_598619 != nil:
    section.add "X-Amz-Security-Token", valid_598619
  var valid_598620 = header.getOrDefault("X-Amz-Algorithm")
  valid_598620 = validateParameter(valid_598620, JString, required = false,
                                 default = nil)
  if valid_598620 != nil:
    section.add "X-Amz-Algorithm", valid_598620
  var valid_598621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598621 = validateParameter(valid_598621, JString, required = false,
                                 default = nil)
  if valid_598621 != nil:
    section.add "X-Amz-SignedHeaders", valid_598621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598623: Call_DeleteTags_598611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_598623.validator(path, query, header, formData, body)
  let scheme = call_598623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598623.url(scheme.get, call_598623.host, call_598623.base,
                         call_598623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598623, url, valid)

proc call*(call_598624: Call_DeleteTags_598611; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_598625 = newJObject()
  if body != nil:
    body_598625 = body
  result = call_598624.call(nil, nil, nil, nil, body_598625)

var deleteTags* = Call_DeleteTags_598611(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_598612,
                                      base: "/", url: url_DeleteTags_598613,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrial_598626 = ref object of OpenApiRestCall_597389
proc url_DeleteTrial_598628(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrial_598627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598629 = header.getOrDefault("X-Amz-Target")
  valid_598629 = validateParameter(valid_598629, JString, required = true,
                                 default = newJString("SageMaker.DeleteTrial"))
  if valid_598629 != nil:
    section.add "X-Amz-Target", valid_598629
  var valid_598630 = header.getOrDefault("X-Amz-Signature")
  valid_598630 = validateParameter(valid_598630, JString, required = false,
                                 default = nil)
  if valid_598630 != nil:
    section.add "X-Amz-Signature", valid_598630
  var valid_598631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598631 = validateParameter(valid_598631, JString, required = false,
                                 default = nil)
  if valid_598631 != nil:
    section.add "X-Amz-Content-Sha256", valid_598631
  var valid_598632 = header.getOrDefault("X-Amz-Date")
  valid_598632 = validateParameter(valid_598632, JString, required = false,
                                 default = nil)
  if valid_598632 != nil:
    section.add "X-Amz-Date", valid_598632
  var valid_598633 = header.getOrDefault("X-Amz-Credential")
  valid_598633 = validateParameter(valid_598633, JString, required = false,
                                 default = nil)
  if valid_598633 != nil:
    section.add "X-Amz-Credential", valid_598633
  var valid_598634 = header.getOrDefault("X-Amz-Security-Token")
  valid_598634 = validateParameter(valid_598634, JString, required = false,
                                 default = nil)
  if valid_598634 != nil:
    section.add "X-Amz-Security-Token", valid_598634
  var valid_598635 = header.getOrDefault("X-Amz-Algorithm")
  valid_598635 = validateParameter(valid_598635, JString, required = false,
                                 default = nil)
  if valid_598635 != nil:
    section.add "X-Amz-Algorithm", valid_598635
  var valid_598636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598636 = validateParameter(valid_598636, JString, required = false,
                                 default = nil)
  if valid_598636 != nil:
    section.add "X-Amz-SignedHeaders", valid_598636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598638: Call_DeleteTrial_598626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ## 
  let valid = call_598638.validator(path, query, header, formData, body)
  let scheme = call_598638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598638.url(scheme.get, call_598638.host, call_598638.base,
                         call_598638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598638, url, valid)

proc call*(call_598639: Call_DeleteTrial_598626; body: JsonNode): Recallable =
  ## deleteTrial
  ## Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a>DescribeTrialComponent</a> API to get the list of trial components.
  ##   body: JObject (required)
  var body_598640 = newJObject()
  if body != nil:
    body_598640 = body
  result = call_598639.call(nil, nil, nil, nil, body_598640)

var deleteTrial* = Call_DeleteTrial_598626(name: "deleteTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTrial",
                                        validator: validate_DeleteTrial_598627,
                                        base: "/", url: url_DeleteTrial_598628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrialComponent_598641 = ref object of OpenApiRestCall_597389
proc url_DeleteTrialComponent_598643(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrialComponent_598642(path: JsonNode; query: JsonNode;
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
  var valid_598644 = header.getOrDefault("X-Amz-Target")
  valid_598644 = validateParameter(valid_598644, JString, required = true, default = newJString(
      "SageMaker.DeleteTrialComponent"))
  if valid_598644 != nil:
    section.add "X-Amz-Target", valid_598644
  var valid_598645 = header.getOrDefault("X-Amz-Signature")
  valid_598645 = validateParameter(valid_598645, JString, required = false,
                                 default = nil)
  if valid_598645 != nil:
    section.add "X-Amz-Signature", valid_598645
  var valid_598646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598646 = validateParameter(valid_598646, JString, required = false,
                                 default = nil)
  if valid_598646 != nil:
    section.add "X-Amz-Content-Sha256", valid_598646
  var valid_598647 = header.getOrDefault("X-Amz-Date")
  valid_598647 = validateParameter(valid_598647, JString, required = false,
                                 default = nil)
  if valid_598647 != nil:
    section.add "X-Amz-Date", valid_598647
  var valid_598648 = header.getOrDefault("X-Amz-Credential")
  valid_598648 = validateParameter(valid_598648, JString, required = false,
                                 default = nil)
  if valid_598648 != nil:
    section.add "X-Amz-Credential", valid_598648
  var valid_598649 = header.getOrDefault("X-Amz-Security-Token")
  valid_598649 = validateParameter(valid_598649, JString, required = false,
                                 default = nil)
  if valid_598649 != nil:
    section.add "X-Amz-Security-Token", valid_598649
  var valid_598650 = header.getOrDefault("X-Amz-Algorithm")
  valid_598650 = validateParameter(valid_598650, JString, required = false,
                                 default = nil)
  if valid_598650 != nil:
    section.add "X-Amz-Algorithm", valid_598650
  var valid_598651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598651 = validateParameter(valid_598651, JString, required = false,
                                 default = nil)
  if valid_598651 != nil:
    section.add "X-Amz-SignedHeaders", valid_598651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598653: Call_DeleteTrialComponent_598641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ## 
  let valid = call_598653.validator(path, query, header, formData, body)
  let scheme = call_598653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598653.url(scheme.get, call_598653.host, call_598653.base,
                         call_598653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598653, url, valid)

proc call*(call_598654: Call_DeleteTrialComponent_598641; body: JsonNode): Recallable =
  ## deleteTrialComponent
  ## Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a>DisassociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_598655 = newJObject()
  if body != nil:
    body_598655 = body
  result = call_598654.call(nil, nil, nil, nil, body_598655)

var deleteTrialComponent* = Call_DeleteTrialComponent_598641(
    name: "deleteTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteTrialComponent",
    validator: validate_DeleteTrialComponent_598642, base: "/",
    url: url_DeleteTrialComponent_598643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserProfile_598656 = ref object of OpenApiRestCall_597389
proc url_DeleteUserProfile_598658(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteUserProfile_598657(path: JsonNode; query: JsonNode;
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
  var valid_598659 = header.getOrDefault("X-Amz-Target")
  valid_598659 = validateParameter(valid_598659, JString, required = true, default = newJString(
      "SageMaker.DeleteUserProfile"))
  if valid_598659 != nil:
    section.add "X-Amz-Target", valid_598659
  var valid_598660 = header.getOrDefault("X-Amz-Signature")
  valid_598660 = validateParameter(valid_598660, JString, required = false,
                                 default = nil)
  if valid_598660 != nil:
    section.add "X-Amz-Signature", valid_598660
  var valid_598661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598661 = validateParameter(valid_598661, JString, required = false,
                                 default = nil)
  if valid_598661 != nil:
    section.add "X-Amz-Content-Sha256", valid_598661
  var valid_598662 = header.getOrDefault("X-Amz-Date")
  valid_598662 = validateParameter(valid_598662, JString, required = false,
                                 default = nil)
  if valid_598662 != nil:
    section.add "X-Amz-Date", valid_598662
  var valid_598663 = header.getOrDefault("X-Amz-Credential")
  valid_598663 = validateParameter(valid_598663, JString, required = false,
                                 default = nil)
  if valid_598663 != nil:
    section.add "X-Amz-Credential", valid_598663
  var valid_598664 = header.getOrDefault("X-Amz-Security-Token")
  valid_598664 = validateParameter(valid_598664, JString, required = false,
                                 default = nil)
  if valid_598664 != nil:
    section.add "X-Amz-Security-Token", valid_598664
  var valid_598665 = header.getOrDefault("X-Amz-Algorithm")
  valid_598665 = validateParameter(valid_598665, JString, required = false,
                                 default = nil)
  if valid_598665 != nil:
    section.add "X-Amz-Algorithm", valid_598665
  var valid_598666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598666 = validateParameter(valid_598666, JString, required = false,
                                 default = nil)
  if valid_598666 != nil:
    section.add "X-Amz-SignedHeaders", valid_598666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598668: Call_DeleteUserProfile_598656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user profile.
  ## 
  let valid = call_598668.validator(path, query, header, formData, body)
  let scheme = call_598668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598668.url(scheme.get, call_598668.host, call_598668.base,
                         call_598668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598668, url, valid)

proc call*(call_598669: Call_DeleteUserProfile_598656; body: JsonNode): Recallable =
  ## deleteUserProfile
  ## Deletes a user profile.
  ##   body: JObject (required)
  var body_598670 = newJObject()
  if body != nil:
    body_598670 = body
  result = call_598669.call(nil, nil, nil, nil, body_598670)

var deleteUserProfile* = Call_DeleteUserProfile_598656(name: "deleteUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteUserProfile",
    validator: validate_DeleteUserProfile_598657, base: "/",
    url: url_DeleteUserProfile_598658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_598671 = ref object of OpenApiRestCall_597389
proc url_DeleteWorkteam_598673(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWorkteam_598672(path: JsonNode; query: JsonNode;
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
  var valid_598674 = header.getOrDefault("X-Amz-Target")
  valid_598674 = validateParameter(valid_598674, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_598674 != nil:
    section.add "X-Amz-Target", valid_598674
  var valid_598675 = header.getOrDefault("X-Amz-Signature")
  valid_598675 = validateParameter(valid_598675, JString, required = false,
                                 default = nil)
  if valid_598675 != nil:
    section.add "X-Amz-Signature", valid_598675
  var valid_598676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598676 = validateParameter(valid_598676, JString, required = false,
                                 default = nil)
  if valid_598676 != nil:
    section.add "X-Amz-Content-Sha256", valid_598676
  var valid_598677 = header.getOrDefault("X-Amz-Date")
  valid_598677 = validateParameter(valid_598677, JString, required = false,
                                 default = nil)
  if valid_598677 != nil:
    section.add "X-Amz-Date", valid_598677
  var valid_598678 = header.getOrDefault("X-Amz-Credential")
  valid_598678 = validateParameter(valid_598678, JString, required = false,
                                 default = nil)
  if valid_598678 != nil:
    section.add "X-Amz-Credential", valid_598678
  var valid_598679 = header.getOrDefault("X-Amz-Security-Token")
  valid_598679 = validateParameter(valid_598679, JString, required = false,
                                 default = nil)
  if valid_598679 != nil:
    section.add "X-Amz-Security-Token", valid_598679
  var valid_598680 = header.getOrDefault("X-Amz-Algorithm")
  valid_598680 = validateParameter(valid_598680, JString, required = false,
                                 default = nil)
  if valid_598680 != nil:
    section.add "X-Amz-Algorithm", valid_598680
  var valid_598681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598681 = validateParameter(valid_598681, JString, required = false,
                                 default = nil)
  if valid_598681 != nil:
    section.add "X-Amz-SignedHeaders", valid_598681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598683: Call_DeleteWorkteam_598671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_598683.validator(path, query, header, formData, body)
  let scheme = call_598683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598683.url(scheme.get, call_598683.host, call_598683.base,
                         call_598683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598683, url, valid)

proc call*(call_598684: Call_DeleteWorkteam_598671; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_598685 = newJObject()
  if body != nil:
    body_598685 = body
  result = call_598684.call(nil, nil, nil, nil, body_598685)

var deleteWorkteam* = Call_DeleteWorkteam_598671(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_598672, base: "/", url: url_DeleteWorkteam_598673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_598686 = ref object of OpenApiRestCall_597389
proc url_DescribeAlgorithm_598688(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAlgorithm_598687(path: JsonNode; query: JsonNode;
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
  var valid_598689 = header.getOrDefault("X-Amz-Target")
  valid_598689 = validateParameter(valid_598689, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_598689 != nil:
    section.add "X-Amz-Target", valid_598689
  var valid_598690 = header.getOrDefault("X-Amz-Signature")
  valid_598690 = validateParameter(valid_598690, JString, required = false,
                                 default = nil)
  if valid_598690 != nil:
    section.add "X-Amz-Signature", valid_598690
  var valid_598691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598691 = validateParameter(valid_598691, JString, required = false,
                                 default = nil)
  if valid_598691 != nil:
    section.add "X-Amz-Content-Sha256", valid_598691
  var valid_598692 = header.getOrDefault("X-Amz-Date")
  valid_598692 = validateParameter(valid_598692, JString, required = false,
                                 default = nil)
  if valid_598692 != nil:
    section.add "X-Amz-Date", valid_598692
  var valid_598693 = header.getOrDefault("X-Amz-Credential")
  valid_598693 = validateParameter(valid_598693, JString, required = false,
                                 default = nil)
  if valid_598693 != nil:
    section.add "X-Amz-Credential", valid_598693
  var valid_598694 = header.getOrDefault("X-Amz-Security-Token")
  valid_598694 = validateParameter(valid_598694, JString, required = false,
                                 default = nil)
  if valid_598694 != nil:
    section.add "X-Amz-Security-Token", valid_598694
  var valid_598695 = header.getOrDefault("X-Amz-Algorithm")
  valid_598695 = validateParameter(valid_598695, JString, required = false,
                                 default = nil)
  if valid_598695 != nil:
    section.add "X-Amz-Algorithm", valid_598695
  var valid_598696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598696 = validateParameter(valid_598696, JString, required = false,
                                 default = nil)
  if valid_598696 != nil:
    section.add "X-Amz-SignedHeaders", valid_598696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598698: Call_DescribeAlgorithm_598686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_598698.validator(path, query, header, formData, body)
  let scheme = call_598698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598698.url(scheme.get, call_598698.host, call_598698.base,
                         call_598698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598698, url, valid)

proc call*(call_598699: Call_DescribeAlgorithm_598686; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_598700 = newJObject()
  if body != nil:
    body_598700 = body
  result = call_598699.call(nil, nil, nil, nil, body_598700)

var describeAlgorithm* = Call_DescribeAlgorithm_598686(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_598687, base: "/",
    url: url_DescribeAlgorithm_598688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApp_598701 = ref object of OpenApiRestCall_597389
proc url_DescribeApp_598703(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApp_598702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598704 = header.getOrDefault("X-Amz-Target")
  valid_598704 = validateParameter(valid_598704, JString, required = true,
                                 default = newJString("SageMaker.DescribeApp"))
  if valid_598704 != nil:
    section.add "X-Amz-Target", valid_598704
  var valid_598705 = header.getOrDefault("X-Amz-Signature")
  valid_598705 = validateParameter(valid_598705, JString, required = false,
                                 default = nil)
  if valid_598705 != nil:
    section.add "X-Amz-Signature", valid_598705
  var valid_598706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598706 = validateParameter(valid_598706, JString, required = false,
                                 default = nil)
  if valid_598706 != nil:
    section.add "X-Amz-Content-Sha256", valid_598706
  var valid_598707 = header.getOrDefault("X-Amz-Date")
  valid_598707 = validateParameter(valid_598707, JString, required = false,
                                 default = nil)
  if valid_598707 != nil:
    section.add "X-Amz-Date", valid_598707
  var valid_598708 = header.getOrDefault("X-Amz-Credential")
  valid_598708 = validateParameter(valid_598708, JString, required = false,
                                 default = nil)
  if valid_598708 != nil:
    section.add "X-Amz-Credential", valid_598708
  var valid_598709 = header.getOrDefault("X-Amz-Security-Token")
  valid_598709 = validateParameter(valid_598709, JString, required = false,
                                 default = nil)
  if valid_598709 != nil:
    section.add "X-Amz-Security-Token", valid_598709
  var valid_598710 = header.getOrDefault("X-Amz-Algorithm")
  valid_598710 = validateParameter(valid_598710, JString, required = false,
                                 default = nil)
  if valid_598710 != nil:
    section.add "X-Amz-Algorithm", valid_598710
  var valid_598711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598711 = validateParameter(valid_598711, JString, required = false,
                                 default = nil)
  if valid_598711 != nil:
    section.add "X-Amz-SignedHeaders", valid_598711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598713: Call_DescribeApp_598701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the app.
  ## 
  let valid = call_598713.validator(path, query, header, formData, body)
  let scheme = call_598713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598713.url(scheme.get, call_598713.host, call_598713.base,
                         call_598713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598713, url, valid)

proc call*(call_598714: Call_DescribeApp_598701; body: JsonNode): Recallable =
  ## describeApp
  ## Describes the app.
  ##   body: JObject (required)
  var body_598715 = newJObject()
  if body != nil:
    body_598715 = body
  result = call_598714.call(nil, nil, nil, nil, body_598715)

var describeApp* = Call_DescribeApp_598701(name: "describeApp",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DescribeApp",
                                        validator: validate_DescribeApp_598702,
                                        base: "/", url: url_DescribeApp_598703,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutoMLJob_598716 = ref object of OpenApiRestCall_597389
proc url_DescribeAutoMLJob_598718(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutoMLJob_598717(path: JsonNode; query: JsonNode;
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
  var valid_598719 = header.getOrDefault("X-Amz-Target")
  valid_598719 = validateParameter(valid_598719, JString, required = true, default = newJString(
      "SageMaker.DescribeAutoMLJob"))
  if valid_598719 != nil:
    section.add "X-Amz-Target", valid_598719
  var valid_598720 = header.getOrDefault("X-Amz-Signature")
  valid_598720 = validateParameter(valid_598720, JString, required = false,
                                 default = nil)
  if valid_598720 != nil:
    section.add "X-Amz-Signature", valid_598720
  var valid_598721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598721 = validateParameter(valid_598721, JString, required = false,
                                 default = nil)
  if valid_598721 != nil:
    section.add "X-Amz-Content-Sha256", valid_598721
  var valid_598722 = header.getOrDefault("X-Amz-Date")
  valid_598722 = validateParameter(valid_598722, JString, required = false,
                                 default = nil)
  if valid_598722 != nil:
    section.add "X-Amz-Date", valid_598722
  var valid_598723 = header.getOrDefault("X-Amz-Credential")
  valid_598723 = validateParameter(valid_598723, JString, required = false,
                                 default = nil)
  if valid_598723 != nil:
    section.add "X-Amz-Credential", valid_598723
  var valid_598724 = header.getOrDefault("X-Amz-Security-Token")
  valid_598724 = validateParameter(valid_598724, JString, required = false,
                                 default = nil)
  if valid_598724 != nil:
    section.add "X-Amz-Security-Token", valid_598724
  var valid_598725 = header.getOrDefault("X-Amz-Algorithm")
  valid_598725 = validateParameter(valid_598725, JString, required = false,
                                 default = nil)
  if valid_598725 != nil:
    section.add "X-Amz-Algorithm", valid_598725
  var valid_598726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598726 = validateParameter(valid_598726, JString, required = false,
                                 default = nil)
  if valid_598726 != nil:
    section.add "X-Amz-SignedHeaders", valid_598726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598728: Call_DescribeAutoMLJob_598716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about an Amazon SageMaker job.
  ## 
  let valid = call_598728.validator(path, query, header, formData, body)
  let scheme = call_598728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598728.url(scheme.get, call_598728.host, call_598728.base,
                         call_598728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598728, url, valid)

proc call*(call_598729: Call_DescribeAutoMLJob_598716; body: JsonNode): Recallable =
  ## describeAutoMLJob
  ## Returns information about an Amazon SageMaker job.
  ##   body: JObject (required)
  var body_598730 = newJObject()
  if body != nil:
    body_598730 = body
  result = call_598729.call(nil, nil, nil, nil, body_598730)

var describeAutoMLJob* = Call_DescribeAutoMLJob_598716(name: "describeAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAutoMLJob",
    validator: validate_DescribeAutoMLJob_598717, base: "/",
    url: url_DescribeAutoMLJob_598718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_598731 = ref object of OpenApiRestCall_597389
proc url_DescribeCodeRepository_598733(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCodeRepository_598732(path: JsonNode; query: JsonNode;
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
  var valid_598734 = header.getOrDefault("X-Amz-Target")
  valid_598734 = validateParameter(valid_598734, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_598734 != nil:
    section.add "X-Amz-Target", valid_598734
  var valid_598735 = header.getOrDefault("X-Amz-Signature")
  valid_598735 = validateParameter(valid_598735, JString, required = false,
                                 default = nil)
  if valid_598735 != nil:
    section.add "X-Amz-Signature", valid_598735
  var valid_598736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598736 = validateParameter(valid_598736, JString, required = false,
                                 default = nil)
  if valid_598736 != nil:
    section.add "X-Amz-Content-Sha256", valid_598736
  var valid_598737 = header.getOrDefault("X-Amz-Date")
  valid_598737 = validateParameter(valid_598737, JString, required = false,
                                 default = nil)
  if valid_598737 != nil:
    section.add "X-Amz-Date", valid_598737
  var valid_598738 = header.getOrDefault("X-Amz-Credential")
  valid_598738 = validateParameter(valid_598738, JString, required = false,
                                 default = nil)
  if valid_598738 != nil:
    section.add "X-Amz-Credential", valid_598738
  var valid_598739 = header.getOrDefault("X-Amz-Security-Token")
  valid_598739 = validateParameter(valid_598739, JString, required = false,
                                 default = nil)
  if valid_598739 != nil:
    section.add "X-Amz-Security-Token", valid_598739
  var valid_598740 = header.getOrDefault("X-Amz-Algorithm")
  valid_598740 = validateParameter(valid_598740, JString, required = false,
                                 default = nil)
  if valid_598740 != nil:
    section.add "X-Amz-Algorithm", valid_598740
  var valid_598741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598741 = validateParameter(valid_598741, JString, required = false,
                                 default = nil)
  if valid_598741 != nil:
    section.add "X-Amz-SignedHeaders", valid_598741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598743: Call_DescribeCodeRepository_598731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_598743.validator(path, query, header, formData, body)
  let scheme = call_598743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598743.url(scheme.get, call_598743.host, call_598743.base,
                         call_598743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598743, url, valid)

proc call*(call_598744: Call_DescribeCodeRepository_598731; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_598745 = newJObject()
  if body != nil:
    body_598745 = body
  result = call_598744.call(nil, nil, nil, nil, body_598745)

var describeCodeRepository* = Call_DescribeCodeRepository_598731(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_598732, base: "/",
    url: url_DescribeCodeRepository_598733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_598746 = ref object of OpenApiRestCall_597389
proc url_DescribeCompilationJob_598748(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeCompilationJob_598747(path: JsonNode; query: JsonNode;
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
  var valid_598749 = header.getOrDefault("X-Amz-Target")
  valid_598749 = validateParameter(valid_598749, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_598749 != nil:
    section.add "X-Amz-Target", valid_598749
  var valid_598750 = header.getOrDefault("X-Amz-Signature")
  valid_598750 = validateParameter(valid_598750, JString, required = false,
                                 default = nil)
  if valid_598750 != nil:
    section.add "X-Amz-Signature", valid_598750
  var valid_598751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598751 = validateParameter(valid_598751, JString, required = false,
                                 default = nil)
  if valid_598751 != nil:
    section.add "X-Amz-Content-Sha256", valid_598751
  var valid_598752 = header.getOrDefault("X-Amz-Date")
  valid_598752 = validateParameter(valid_598752, JString, required = false,
                                 default = nil)
  if valid_598752 != nil:
    section.add "X-Amz-Date", valid_598752
  var valid_598753 = header.getOrDefault("X-Amz-Credential")
  valid_598753 = validateParameter(valid_598753, JString, required = false,
                                 default = nil)
  if valid_598753 != nil:
    section.add "X-Amz-Credential", valid_598753
  var valid_598754 = header.getOrDefault("X-Amz-Security-Token")
  valid_598754 = validateParameter(valid_598754, JString, required = false,
                                 default = nil)
  if valid_598754 != nil:
    section.add "X-Amz-Security-Token", valid_598754
  var valid_598755 = header.getOrDefault("X-Amz-Algorithm")
  valid_598755 = validateParameter(valid_598755, JString, required = false,
                                 default = nil)
  if valid_598755 != nil:
    section.add "X-Amz-Algorithm", valid_598755
  var valid_598756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598756 = validateParameter(valid_598756, JString, required = false,
                                 default = nil)
  if valid_598756 != nil:
    section.add "X-Amz-SignedHeaders", valid_598756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598758: Call_DescribeCompilationJob_598746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_598758.validator(path, query, header, formData, body)
  let scheme = call_598758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598758.url(scheme.get, call_598758.host, call_598758.base,
                         call_598758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598758, url, valid)

proc call*(call_598759: Call_DescribeCompilationJob_598746; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_598760 = newJObject()
  if body != nil:
    body_598760 = body
  result = call_598759.call(nil, nil, nil, nil, body_598760)

var describeCompilationJob* = Call_DescribeCompilationJob_598746(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_598747, base: "/",
    url: url_DescribeCompilationJob_598748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomain_598761 = ref object of OpenApiRestCall_597389
proc url_DescribeDomain_598763(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDomain_598762(path: JsonNode; query: JsonNode;
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
  var valid_598764 = header.getOrDefault("X-Amz-Target")
  valid_598764 = validateParameter(valid_598764, JString, required = true, default = newJString(
      "SageMaker.DescribeDomain"))
  if valid_598764 != nil:
    section.add "X-Amz-Target", valid_598764
  var valid_598765 = header.getOrDefault("X-Amz-Signature")
  valid_598765 = validateParameter(valid_598765, JString, required = false,
                                 default = nil)
  if valid_598765 != nil:
    section.add "X-Amz-Signature", valid_598765
  var valid_598766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598766 = validateParameter(valid_598766, JString, required = false,
                                 default = nil)
  if valid_598766 != nil:
    section.add "X-Amz-Content-Sha256", valid_598766
  var valid_598767 = header.getOrDefault("X-Amz-Date")
  valid_598767 = validateParameter(valid_598767, JString, required = false,
                                 default = nil)
  if valid_598767 != nil:
    section.add "X-Amz-Date", valid_598767
  var valid_598768 = header.getOrDefault("X-Amz-Credential")
  valid_598768 = validateParameter(valid_598768, JString, required = false,
                                 default = nil)
  if valid_598768 != nil:
    section.add "X-Amz-Credential", valid_598768
  var valid_598769 = header.getOrDefault("X-Amz-Security-Token")
  valid_598769 = validateParameter(valid_598769, JString, required = false,
                                 default = nil)
  if valid_598769 != nil:
    section.add "X-Amz-Security-Token", valid_598769
  var valid_598770 = header.getOrDefault("X-Amz-Algorithm")
  valid_598770 = validateParameter(valid_598770, JString, required = false,
                                 default = nil)
  if valid_598770 != nil:
    section.add "X-Amz-Algorithm", valid_598770
  var valid_598771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598771 = validateParameter(valid_598771, JString, required = false,
                                 default = nil)
  if valid_598771 != nil:
    section.add "X-Amz-SignedHeaders", valid_598771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598773: Call_DescribeDomain_598761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## The desciption of the domain.
  ## 
  let valid = call_598773.validator(path, query, header, formData, body)
  let scheme = call_598773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598773.url(scheme.get, call_598773.host, call_598773.base,
                         call_598773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598773, url, valid)

proc call*(call_598774: Call_DescribeDomain_598761; body: JsonNode): Recallable =
  ## describeDomain
  ## The desciption of the domain.
  ##   body: JObject (required)
  var body_598775 = newJObject()
  if body != nil:
    body_598775 = body
  result = call_598774.call(nil, nil, nil, nil, body_598775)

var describeDomain* = Call_DescribeDomain_598761(name: "describeDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeDomain",
    validator: validate_DescribeDomain_598762, base: "/", url: url_DescribeDomain_598763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_598776 = ref object of OpenApiRestCall_597389
proc url_DescribeEndpoint_598778(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpoint_598777(path: JsonNode; query: JsonNode;
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
  var valid_598779 = header.getOrDefault("X-Amz-Target")
  valid_598779 = validateParameter(valid_598779, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_598779 != nil:
    section.add "X-Amz-Target", valid_598779
  var valid_598780 = header.getOrDefault("X-Amz-Signature")
  valid_598780 = validateParameter(valid_598780, JString, required = false,
                                 default = nil)
  if valid_598780 != nil:
    section.add "X-Amz-Signature", valid_598780
  var valid_598781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598781 = validateParameter(valid_598781, JString, required = false,
                                 default = nil)
  if valid_598781 != nil:
    section.add "X-Amz-Content-Sha256", valid_598781
  var valid_598782 = header.getOrDefault("X-Amz-Date")
  valid_598782 = validateParameter(valid_598782, JString, required = false,
                                 default = nil)
  if valid_598782 != nil:
    section.add "X-Amz-Date", valid_598782
  var valid_598783 = header.getOrDefault("X-Amz-Credential")
  valid_598783 = validateParameter(valid_598783, JString, required = false,
                                 default = nil)
  if valid_598783 != nil:
    section.add "X-Amz-Credential", valid_598783
  var valid_598784 = header.getOrDefault("X-Amz-Security-Token")
  valid_598784 = validateParameter(valid_598784, JString, required = false,
                                 default = nil)
  if valid_598784 != nil:
    section.add "X-Amz-Security-Token", valid_598784
  var valid_598785 = header.getOrDefault("X-Amz-Algorithm")
  valid_598785 = validateParameter(valid_598785, JString, required = false,
                                 default = nil)
  if valid_598785 != nil:
    section.add "X-Amz-Algorithm", valid_598785
  var valid_598786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598786 = validateParameter(valid_598786, JString, required = false,
                                 default = nil)
  if valid_598786 != nil:
    section.add "X-Amz-SignedHeaders", valid_598786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598788: Call_DescribeEndpoint_598776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_598788.validator(path, query, header, formData, body)
  let scheme = call_598788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598788.url(scheme.get, call_598788.host, call_598788.base,
                         call_598788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598788, url, valid)

proc call*(call_598789: Call_DescribeEndpoint_598776; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_598790 = newJObject()
  if body != nil:
    body_598790 = body
  result = call_598789.call(nil, nil, nil, nil, body_598790)

var describeEndpoint* = Call_DescribeEndpoint_598776(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_598777, base: "/",
    url: url_DescribeEndpoint_598778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_598791 = ref object of OpenApiRestCall_597389
proc url_DescribeEndpointConfig_598793(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEndpointConfig_598792(path: JsonNode; query: JsonNode;
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
  var valid_598794 = header.getOrDefault("X-Amz-Target")
  valid_598794 = validateParameter(valid_598794, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_598794 != nil:
    section.add "X-Amz-Target", valid_598794
  var valid_598795 = header.getOrDefault("X-Amz-Signature")
  valid_598795 = validateParameter(valid_598795, JString, required = false,
                                 default = nil)
  if valid_598795 != nil:
    section.add "X-Amz-Signature", valid_598795
  var valid_598796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598796 = validateParameter(valid_598796, JString, required = false,
                                 default = nil)
  if valid_598796 != nil:
    section.add "X-Amz-Content-Sha256", valid_598796
  var valid_598797 = header.getOrDefault("X-Amz-Date")
  valid_598797 = validateParameter(valid_598797, JString, required = false,
                                 default = nil)
  if valid_598797 != nil:
    section.add "X-Amz-Date", valid_598797
  var valid_598798 = header.getOrDefault("X-Amz-Credential")
  valid_598798 = validateParameter(valid_598798, JString, required = false,
                                 default = nil)
  if valid_598798 != nil:
    section.add "X-Amz-Credential", valid_598798
  var valid_598799 = header.getOrDefault("X-Amz-Security-Token")
  valid_598799 = validateParameter(valid_598799, JString, required = false,
                                 default = nil)
  if valid_598799 != nil:
    section.add "X-Amz-Security-Token", valid_598799
  var valid_598800 = header.getOrDefault("X-Amz-Algorithm")
  valid_598800 = validateParameter(valid_598800, JString, required = false,
                                 default = nil)
  if valid_598800 != nil:
    section.add "X-Amz-Algorithm", valid_598800
  var valid_598801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598801 = validateParameter(valid_598801, JString, required = false,
                                 default = nil)
  if valid_598801 != nil:
    section.add "X-Amz-SignedHeaders", valid_598801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598803: Call_DescribeEndpointConfig_598791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_598803.validator(path, query, header, formData, body)
  let scheme = call_598803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598803.url(scheme.get, call_598803.host, call_598803.base,
                         call_598803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598803, url, valid)

proc call*(call_598804: Call_DescribeEndpointConfig_598791; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_598805 = newJObject()
  if body != nil:
    body_598805 = body
  result = call_598804.call(nil, nil, nil, nil, body_598805)

var describeEndpointConfig* = Call_DescribeEndpointConfig_598791(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_598792, base: "/",
    url: url_DescribeEndpointConfig_598793, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExperiment_598806 = ref object of OpenApiRestCall_597389
proc url_DescribeExperiment_598808(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExperiment_598807(path: JsonNode; query: JsonNode;
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
  var valid_598809 = header.getOrDefault("X-Amz-Target")
  valid_598809 = validateParameter(valid_598809, JString, required = true, default = newJString(
      "SageMaker.DescribeExperiment"))
  if valid_598809 != nil:
    section.add "X-Amz-Target", valid_598809
  var valid_598810 = header.getOrDefault("X-Amz-Signature")
  valid_598810 = validateParameter(valid_598810, JString, required = false,
                                 default = nil)
  if valid_598810 != nil:
    section.add "X-Amz-Signature", valid_598810
  var valid_598811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598811 = validateParameter(valid_598811, JString, required = false,
                                 default = nil)
  if valid_598811 != nil:
    section.add "X-Amz-Content-Sha256", valid_598811
  var valid_598812 = header.getOrDefault("X-Amz-Date")
  valid_598812 = validateParameter(valid_598812, JString, required = false,
                                 default = nil)
  if valid_598812 != nil:
    section.add "X-Amz-Date", valid_598812
  var valid_598813 = header.getOrDefault("X-Amz-Credential")
  valid_598813 = validateParameter(valid_598813, JString, required = false,
                                 default = nil)
  if valid_598813 != nil:
    section.add "X-Amz-Credential", valid_598813
  var valid_598814 = header.getOrDefault("X-Amz-Security-Token")
  valid_598814 = validateParameter(valid_598814, JString, required = false,
                                 default = nil)
  if valid_598814 != nil:
    section.add "X-Amz-Security-Token", valid_598814
  var valid_598815 = header.getOrDefault("X-Amz-Algorithm")
  valid_598815 = validateParameter(valid_598815, JString, required = false,
                                 default = nil)
  if valid_598815 != nil:
    section.add "X-Amz-Algorithm", valid_598815
  var valid_598816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598816 = validateParameter(valid_598816, JString, required = false,
                                 default = nil)
  if valid_598816 != nil:
    section.add "X-Amz-SignedHeaders", valid_598816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598818: Call_DescribeExperiment_598806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of an experiment's properties.
  ## 
  let valid = call_598818.validator(path, query, header, formData, body)
  let scheme = call_598818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598818.url(scheme.get, call_598818.host, call_598818.base,
                         call_598818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598818, url, valid)

proc call*(call_598819: Call_DescribeExperiment_598806; body: JsonNode): Recallable =
  ## describeExperiment
  ## Provides a list of an experiment's properties.
  ##   body: JObject (required)
  var body_598820 = newJObject()
  if body != nil:
    body_598820 = body
  result = call_598819.call(nil, nil, nil, nil, body_598820)

var describeExperiment* = Call_DescribeExperiment_598806(
    name: "describeExperiment", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeExperiment",
    validator: validate_DescribeExperiment_598807, base: "/",
    url: url_DescribeExperiment_598808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlowDefinition_598821 = ref object of OpenApiRestCall_597389
proc url_DescribeFlowDefinition_598823(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFlowDefinition_598822(path: JsonNode; query: JsonNode;
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
  var valid_598824 = header.getOrDefault("X-Amz-Target")
  valid_598824 = validateParameter(valid_598824, JString, required = true, default = newJString(
      "SageMaker.DescribeFlowDefinition"))
  if valid_598824 != nil:
    section.add "X-Amz-Target", valid_598824
  var valid_598825 = header.getOrDefault("X-Amz-Signature")
  valid_598825 = validateParameter(valid_598825, JString, required = false,
                                 default = nil)
  if valid_598825 != nil:
    section.add "X-Amz-Signature", valid_598825
  var valid_598826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598826 = validateParameter(valid_598826, JString, required = false,
                                 default = nil)
  if valid_598826 != nil:
    section.add "X-Amz-Content-Sha256", valid_598826
  var valid_598827 = header.getOrDefault("X-Amz-Date")
  valid_598827 = validateParameter(valid_598827, JString, required = false,
                                 default = nil)
  if valid_598827 != nil:
    section.add "X-Amz-Date", valid_598827
  var valid_598828 = header.getOrDefault("X-Amz-Credential")
  valid_598828 = validateParameter(valid_598828, JString, required = false,
                                 default = nil)
  if valid_598828 != nil:
    section.add "X-Amz-Credential", valid_598828
  var valid_598829 = header.getOrDefault("X-Amz-Security-Token")
  valid_598829 = validateParameter(valid_598829, JString, required = false,
                                 default = nil)
  if valid_598829 != nil:
    section.add "X-Amz-Security-Token", valid_598829
  var valid_598830 = header.getOrDefault("X-Amz-Algorithm")
  valid_598830 = validateParameter(valid_598830, JString, required = false,
                                 default = nil)
  if valid_598830 != nil:
    section.add "X-Amz-Algorithm", valid_598830
  var valid_598831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598831 = validateParameter(valid_598831, JString, required = false,
                                 default = nil)
  if valid_598831 != nil:
    section.add "X-Amz-SignedHeaders", valid_598831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598833: Call_DescribeFlowDefinition_598821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified flow definition.
  ## 
  let valid = call_598833.validator(path, query, header, formData, body)
  let scheme = call_598833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598833.url(scheme.get, call_598833.host, call_598833.base,
                         call_598833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598833, url, valid)

proc call*(call_598834: Call_DescribeFlowDefinition_598821; body: JsonNode): Recallable =
  ## describeFlowDefinition
  ## Returns information about the specified flow definition.
  ##   body: JObject (required)
  var body_598835 = newJObject()
  if body != nil:
    body_598835 = body
  result = call_598834.call(nil, nil, nil, nil, body_598835)

var describeFlowDefinition* = Call_DescribeFlowDefinition_598821(
    name: "describeFlowDefinition", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeFlowDefinition",
    validator: validate_DescribeFlowDefinition_598822, base: "/",
    url: url_DescribeFlowDefinition_598823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHumanTaskUi_598836 = ref object of OpenApiRestCall_597389
proc url_DescribeHumanTaskUi_598838(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHumanTaskUi_598837(path: JsonNode; query: JsonNode;
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
  var valid_598839 = header.getOrDefault("X-Amz-Target")
  valid_598839 = validateParameter(valid_598839, JString, required = true, default = newJString(
      "SageMaker.DescribeHumanTaskUi"))
  if valid_598839 != nil:
    section.add "X-Amz-Target", valid_598839
  var valid_598840 = header.getOrDefault("X-Amz-Signature")
  valid_598840 = validateParameter(valid_598840, JString, required = false,
                                 default = nil)
  if valid_598840 != nil:
    section.add "X-Amz-Signature", valid_598840
  var valid_598841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598841 = validateParameter(valid_598841, JString, required = false,
                                 default = nil)
  if valid_598841 != nil:
    section.add "X-Amz-Content-Sha256", valid_598841
  var valid_598842 = header.getOrDefault("X-Amz-Date")
  valid_598842 = validateParameter(valid_598842, JString, required = false,
                                 default = nil)
  if valid_598842 != nil:
    section.add "X-Amz-Date", valid_598842
  var valid_598843 = header.getOrDefault("X-Amz-Credential")
  valid_598843 = validateParameter(valid_598843, JString, required = false,
                                 default = nil)
  if valid_598843 != nil:
    section.add "X-Amz-Credential", valid_598843
  var valid_598844 = header.getOrDefault("X-Amz-Security-Token")
  valid_598844 = validateParameter(valid_598844, JString, required = false,
                                 default = nil)
  if valid_598844 != nil:
    section.add "X-Amz-Security-Token", valid_598844
  var valid_598845 = header.getOrDefault("X-Amz-Algorithm")
  valid_598845 = validateParameter(valid_598845, JString, required = false,
                                 default = nil)
  if valid_598845 != nil:
    section.add "X-Amz-Algorithm", valid_598845
  var valid_598846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598846 = validateParameter(valid_598846, JString, required = false,
                                 default = nil)
  if valid_598846 != nil:
    section.add "X-Amz-SignedHeaders", valid_598846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598848: Call_DescribeHumanTaskUi_598836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the requested human task user interface.
  ## 
  let valid = call_598848.validator(path, query, header, formData, body)
  let scheme = call_598848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598848.url(scheme.get, call_598848.host, call_598848.base,
                         call_598848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598848, url, valid)

proc call*(call_598849: Call_DescribeHumanTaskUi_598836; body: JsonNode): Recallable =
  ## describeHumanTaskUi
  ## Returns information about the requested human task user interface.
  ##   body: JObject (required)
  var body_598850 = newJObject()
  if body != nil:
    body_598850 = body
  result = call_598849.call(nil, nil, nil, nil, body_598850)

var describeHumanTaskUi* = Call_DescribeHumanTaskUi_598836(
    name: "describeHumanTaskUi", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi",
    validator: validate_DescribeHumanTaskUi_598837, base: "/",
    url: url_DescribeHumanTaskUi_598838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_598851 = ref object of OpenApiRestCall_597389
proc url_DescribeHyperParameterTuningJob_598853(protocol: Scheme; host: string;
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

proc validate_DescribeHyperParameterTuningJob_598852(path: JsonNode;
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
  var valid_598854 = header.getOrDefault("X-Amz-Target")
  valid_598854 = validateParameter(valid_598854, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_598854 != nil:
    section.add "X-Amz-Target", valid_598854
  var valid_598855 = header.getOrDefault("X-Amz-Signature")
  valid_598855 = validateParameter(valid_598855, JString, required = false,
                                 default = nil)
  if valid_598855 != nil:
    section.add "X-Amz-Signature", valid_598855
  var valid_598856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598856 = validateParameter(valid_598856, JString, required = false,
                                 default = nil)
  if valid_598856 != nil:
    section.add "X-Amz-Content-Sha256", valid_598856
  var valid_598857 = header.getOrDefault("X-Amz-Date")
  valid_598857 = validateParameter(valid_598857, JString, required = false,
                                 default = nil)
  if valid_598857 != nil:
    section.add "X-Amz-Date", valid_598857
  var valid_598858 = header.getOrDefault("X-Amz-Credential")
  valid_598858 = validateParameter(valid_598858, JString, required = false,
                                 default = nil)
  if valid_598858 != nil:
    section.add "X-Amz-Credential", valid_598858
  var valid_598859 = header.getOrDefault("X-Amz-Security-Token")
  valid_598859 = validateParameter(valid_598859, JString, required = false,
                                 default = nil)
  if valid_598859 != nil:
    section.add "X-Amz-Security-Token", valid_598859
  var valid_598860 = header.getOrDefault("X-Amz-Algorithm")
  valid_598860 = validateParameter(valid_598860, JString, required = false,
                                 default = nil)
  if valid_598860 != nil:
    section.add "X-Amz-Algorithm", valid_598860
  var valid_598861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598861 = validateParameter(valid_598861, JString, required = false,
                                 default = nil)
  if valid_598861 != nil:
    section.add "X-Amz-SignedHeaders", valid_598861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598863: Call_DescribeHyperParameterTuningJob_598851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_598863.validator(path, query, header, formData, body)
  let scheme = call_598863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598863.url(scheme.get, call_598863.host, call_598863.base,
                         call_598863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598863, url, valid)

proc call*(call_598864: Call_DescribeHyperParameterTuningJob_598851; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_598865 = newJObject()
  if body != nil:
    body_598865 = body
  result = call_598864.call(nil, nil, nil, nil, body_598865)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_598851(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_598852, base: "/",
    url: url_DescribeHyperParameterTuningJob_598853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_598866 = ref object of OpenApiRestCall_597389
proc url_DescribeLabelingJob_598868(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLabelingJob_598867(path: JsonNode; query: JsonNode;
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
  var valid_598869 = header.getOrDefault("X-Amz-Target")
  valid_598869 = validateParameter(valid_598869, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_598869 != nil:
    section.add "X-Amz-Target", valid_598869
  var valid_598870 = header.getOrDefault("X-Amz-Signature")
  valid_598870 = validateParameter(valid_598870, JString, required = false,
                                 default = nil)
  if valid_598870 != nil:
    section.add "X-Amz-Signature", valid_598870
  var valid_598871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598871 = validateParameter(valid_598871, JString, required = false,
                                 default = nil)
  if valid_598871 != nil:
    section.add "X-Amz-Content-Sha256", valid_598871
  var valid_598872 = header.getOrDefault("X-Amz-Date")
  valid_598872 = validateParameter(valid_598872, JString, required = false,
                                 default = nil)
  if valid_598872 != nil:
    section.add "X-Amz-Date", valid_598872
  var valid_598873 = header.getOrDefault("X-Amz-Credential")
  valid_598873 = validateParameter(valid_598873, JString, required = false,
                                 default = nil)
  if valid_598873 != nil:
    section.add "X-Amz-Credential", valid_598873
  var valid_598874 = header.getOrDefault("X-Amz-Security-Token")
  valid_598874 = validateParameter(valid_598874, JString, required = false,
                                 default = nil)
  if valid_598874 != nil:
    section.add "X-Amz-Security-Token", valid_598874
  var valid_598875 = header.getOrDefault("X-Amz-Algorithm")
  valid_598875 = validateParameter(valid_598875, JString, required = false,
                                 default = nil)
  if valid_598875 != nil:
    section.add "X-Amz-Algorithm", valid_598875
  var valid_598876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598876 = validateParameter(valid_598876, JString, required = false,
                                 default = nil)
  if valid_598876 != nil:
    section.add "X-Amz-SignedHeaders", valid_598876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598878: Call_DescribeLabelingJob_598866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_598878.validator(path, query, header, formData, body)
  let scheme = call_598878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598878.url(scheme.get, call_598878.host, call_598878.base,
                         call_598878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598878, url, valid)

proc call*(call_598879: Call_DescribeLabelingJob_598866; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_598880 = newJObject()
  if body != nil:
    body_598880 = body
  result = call_598879.call(nil, nil, nil, nil, body_598880)

var describeLabelingJob* = Call_DescribeLabelingJob_598866(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_598867, base: "/",
    url: url_DescribeLabelingJob_598868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_598881 = ref object of OpenApiRestCall_597389
proc url_DescribeModel_598883(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModel_598882(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598884 = header.getOrDefault("X-Amz-Target")
  valid_598884 = validateParameter(valid_598884, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_598884 != nil:
    section.add "X-Amz-Target", valid_598884
  var valid_598885 = header.getOrDefault("X-Amz-Signature")
  valid_598885 = validateParameter(valid_598885, JString, required = false,
                                 default = nil)
  if valid_598885 != nil:
    section.add "X-Amz-Signature", valid_598885
  var valid_598886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598886 = validateParameter(valid_598886, JString, required = false,
                                 default = nil)
  if valid_598886 != nil:
    section.add "X-Amz-Content-Sha256", valid_598886
  var valid_598887 = header.getOrDefault("X-Amz-Date")
  valid_598887 = validateParameter(valid_598887, JString, required = false,
                                 default = nil)
  if valid_598887 != nil:
    section.add "X-Amz-Date", valid_598887
  var valid_598888 = header.getOrDefault("X-Amz-Credential")
  valid_598888 = validateParameter(valid_598888, JString, required = false,
                                 default = nil)
  if valid_598888 != nil:
    section.add "X-Amz-Credential", valid_598888
  var valid_598889 = header.getOrDefault("X-Amz-Security-Token")
  valid_598889 = validateParameter(valid_598889, JString, required = false,
                                 default = nil)
  if valid_598889 != nil:
    section.add "X-Amz-Security-Token", valid_598889
  var valid_598890 = header.getOrDefault("X-Amz-Algorithm")
  valid_598890 = validateParameter(valid_598890, JString, required = false,
                                 default = nil)
  if valid_598890 != nil:
    section.add "X-Amz-Algorithm", valid_598890
  var valid_598891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598891 = validateParameter(valid_598891, JString, required = false,
                                 default = nil)
  if valid_598891 != nil:
    section.add "X-Amz-SignedHeaders", valid_598891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598893: Call_DescribeModel_598881; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_598893.validator(path, query, header, formData, body)
  let scheme = call_598893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598893.url(scheme.get, call_598893.host, call_598893.base,
                         call_598893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598893, url, valid)

proc call*(call_598894: Call_DescribeModel_598881; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_598895 = newJObject()
  if body != nil:
    body_598895 = body
  result = call_598894.call(nil, nil, nil, nil, body_598895)

var describeModel* = Call_DescribeModel_598881(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_598882, base: "/", url: url_DescribeModel_598883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_598896 = ref object of OpenApiRestCall_597389
proc url_DescribeModelPackage_598898(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeModelPackage_598897(path: JsonNode; query: JsonNode;
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
  var valid_598899 = header.getOrDefault("X-Amz-Target")
  valid_598899 = validateParameter(valid_598899, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_598899 != nil:
    section.add "X-Amz-Target", valid_598899
  var valid_598900 = header.getOrDefault("X-Amz-Signature")
  valid_598900 = validateParameter(valid_598900, JString, required = false,
                                 default = nil)
  if valid_598900 != nil:
    section.add "X-Amz-Signature", valid_598900
  var valid_598901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598901 = validateParameter(valid_598901, JString, required = false,
                                 default = nil)
  if valid_598901 != nil:
    section.add "X-Amz-Content-Sha256", valid_598901
  var valid_598902 = header.getOrDefault("X-Amz-Date")
  valid_598902 = validateParameter(valid_598902, JString, required = false,
                                 default = nil)
  if valid_598902 != nil:
    section.add "X-Amz-Date", valid_598902
  var valid_598903 = header.getOrDefault("X-Amz-Credential")
  valid_598903 = validateParameter(valid_598903, JString, required = false,
                                 default = nil)
  if valid_598903 != nil:
    section.add "X-Amz-Credential", valid_598903
  var valid_598904 = header.getOrDefault("X-Amz-Security-Token")
  valid_598904 = validateParameter(valid_598904, JString, required = false,
                                 default = nil)
  if valid_598904 != nil:
    section.add "X-Amz-Security-Token", valid_598904
  var valid_598905 = header.getOrDefault("X-Amz-Algorithm")
  valid_598905 = validateParameter(valid_598905, JString, required = false,
                                 default = nil)
  if valid_598905 != nil:
    section.add "X-Amz-Algorithm", valid_598905
  var valid_598906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598906 = validateParameter(valid_598906, JString, required = false,
                                 default = nil)
  if valid_598906 != nil:
    section.add "X-Amz-SignedHeaders", valid_598906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598908: Call_DescribeModelPackage_598896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_598908.validator(path, query, header, formData, body)
  let scheme = call_598908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598908.url(scheme.get, call_598908.host, call_598908.base,
                         call_598908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598908, url, valid)

proc call*(call_598909: Call_DescribeModelPackage_598896; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_598910 = newJObject()
  if body != nil:
    body_598910 = body
  result = call_598909.call(nil, nil, nil, nil, body_598910)

var describeModelPackage* = Call_DescribeModelPackage_598896(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_598897, base: "/",
    url: url_DescribeModelPackage_598898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMonitoringSchedule_598911 = ref object of OpenApiRestCall_597389
proc url_DescribeMonitoringSchedule_598913(protocol: Scheme; host: string;
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

proc validate_DescribeMonitoringSchedule_598912(path: JsonNode; query: JsonNode;
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
  var valid_598914 = header.getOrDefault("X-Amz-Target")
  valid_598914 = validateParameter(valid_598914, JString, required = true, default = newJString(
      "SageMaker.DescribeMonitoringSchedule"))
  if valid_598914 != nil:
    section.add "X-Amz-Target", valid_598914
  var valid_598915 = header.getOrDefault("X-Amz-Signature")
  valid_598915 = validateParameter(valid_598915, JString, required = false,
                                 default = nil)
  if valid_598915 != nil:
    section.add "X-Amz-Signature", valid_598915
  var valid_598916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598916 = validateParameter(valid_598916, JString, required = false,
                                 default = nil)
  if valid_598916 != nil:
    section.add "X-Amz-Content-Sha256", valid_598916
  var valid_598917 = header.getOrDefault("X-Amz-Date")
  valid_598917 = validateParameter(valid_598917, JString, required = false,
                                 default = nil)
  if valid_598917 != nil:
    section.add "X-Amz-Date", valid_598917
  var valid_598918 = header.getOrDefault("X-Amz-Credential")
  valid_598918 = validateParameter(valid_598918, JString, required = false,
                                 default = nil)
  if valid_598918 != nil:
    section.add "X-Amz-Credential", valid_598918
  var valid_598919 = header.getOrDefault("X-Amz-Security-Token")
  valid_598919 = validateParameter(valid_598919, JString, required = false,
                                 default = nil)
  if valid_598919 != nil:
    section.add "X-Amz-Security-Token", valid_598919
  var valid_598920 = header.getOrDefault("X-Amz-Algorithm")
  valid_598920 = validateParameter(valid_598920, JString, required = false,
                                 default = nil)
  if valid_598920 != nil:
    section.add "X-Amz-Algorithm", valid_598920
  var valid_598921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598921 = validateParameter(valid_598921, JString, required = false,
                                 default = nil)
  if valid_598921 != nil:
    section.add "X-Amz-SignedHeaders", valid_598921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598923: Call_DescribeMonitoringSchedule_598911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the schedule for a monitoring job.
  ## 
  let valid = call_598923.validator(path, query, header, formData, body)
  let scheme = call_598923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598923.url(scheme.get, call_598923.host, call_598923.base,
                         call_598923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598923, url, valid)

proc call*(call_598924: Call_DescribeMonitoringSchedule_598911; body: JsonNode): Recallable =
  ## describeMonitoringSchedule
  ## Describes the schedule for a monitoring job.
  ##   body: JObject (required)
  var body_598925 = newJObject()
  if body != nil:
    body_598925 = body
  result = call_598924.call(nil, nil, nil, nil, body_598925)

var describeMonitoringSchedule* = Call_DescribeMonitoringSchedule_598911(
    name: "describeMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule",
    validator: validate_DescribeMonitoringSchedule_598912, base: "/",
    url: url_DescribeMonitoringSchedule_598913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_598926 = ref object of OpenApiRestCall_597389
proc url_DescribeNotebookInstance_598928(protocol: Scheme; host: string;
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

proc validate_DescribeNotebookInstance_598927(path: JsonNode; query: JsonNode;
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
  var valid_598929 = header.getOrDefault("X-Amz-Target")
  valid_598929 = validateParameter(valid_598929, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_598929 != nil:
    section.add "X-Amz-Target", valid_598929
  var valid_598930 = header.getOrDefault("X-Amz-Signature")
  valid_598930 = validateParameter(valid_598930, JString, required = false,
                                 default = nil)
  if valid_598930 != nil:
    section.add "X-Amz-Signature", valid_598930
  var valid_598931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598931 = validateParameter(valid_598931, JString, required = false,
                                 default = nil)
  if valid_598931 != nil:
    section.add "X-Amz-Content-Sha256", valid_598931
  var valid_598932 = header.getOrDefault("X-Amz-Date")
  valid_598932 = validateParameter(valid_598932, JString, required = false,
                                 default = nil)
  if valid_598932 != nil:
    section.add "X-Amz-Date", valid_598932
  var valid_598933 = header.getOrDefault("X-Amz-Credential")
  valid_598933 = validateParameter(valid_598933, JString, required = false,
                                 default = nil)
  if valid_598933 != nil:
    section.add "X-Amz-Credential", valid_598933
  var valid_598934 = header.getOrDefault("X-Amz-Security-Token")
  valid_598934 = validateParameter(valid_598934, JString, required = false,
                                 default = nil)
  if valid_598934 != nil:
    section.add "X-Amz-Security-Token", valid_598934
  var valid_598935 = header.getOrDefault("X-Amz-Algorithm")
  valid_598935 = validateParameter(valid_598935, JString, required = false,
                                 default = nil)
  if valid_598935 != nil:
    section.add "X-Amz-Algorithm", valid_598935
  var valid_598936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598936 = validateParameter(valid_598936, JString, required = false,
                                 default = nil)
  if valid_598936 != nil:
    section.add "X-Amz-SignedHeaders", valid_598936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598938: Call_DescribeNotebookInstance_598926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_598938.validator(path, query, header, formData, body)
  let scheme = call_598938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598938.url(scheme.get, call_598938.host, call_598938.base,
                         call_598938.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598938, url, valid)

proc call*(call_598939: Call_DescribeNotebookInstance_598926; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_598940 = newJObject()
  if body != nil:
    body_598940 = body
  result = call_598939.call(nil, nil, nil, nil, body_598940)

var describeNotebookInstance* = Call_DescribeNotebookInstance_598926(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_598927, base: "/",
    url: url_DescribeNotebookInstance_598928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_598941 = ref object of OpenApiRestCall_597389
proc url_DescribeNotebookInstanceLifecycleConfig_598943(protocol: Scheme;
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

proc validate_DescribeNotebookInstanceLifecycleConfig_598942(path: JsonNode;
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
  var valid_598944 = header.getOrDefault("X-Amz-Target")
  valid_598944 = validateParameter(valid_598944, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_598944 != nil:
    section.add "X-Amz-Target", valid_598944
  var valid_598945 = header.getOrDefault("X-Amz-Signature")
  valid_598945 = validateParameter(valid_598945, JString, required = false,
                                 default = nil)
  if valid_598945 != nil:
    section.add "X-Amz-Signature", valid_598945
  var valid_598946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598946 = validateParameter(valid_598946, JString, required = false,
                                 default = nil)
  if valid_598946 != nil:
    section.add "X-Amz-Content-Sha256", valid_598946
  var valid_598947 = header.getOrDefault("X-Amz-Date")
  valid_598947 = validateParameter(valid_598947, JString, required = false,
                                 default = nil)
  if valid_598947 != nil:
    section.add "X-Amz-Date", valid_598947
  var valid_598948 = header.getOrDefault("X-Amz-Credential")
  valid_598948 = validateParameter(valid_598948, JString, required = false,
                                 default = nil)
  if valid_598948 != nil:
    section.add "X-Amz-Credential", valid_598948
  var valid_598949 = header.getOrDefault("X-Amz-Security-Token")
  valid_598949 = validateParameter(valid_598949, JString, required = false,
                                 default = nil)
  if valid_598949 != nil:
    section.add "X-Amz-Security-Token", valid_598949
  var valid_598950 = header.getOrDefault("X-Amz-Algorithm")
  valid_598950 = validateParameter(valid_598950, JString, required = false,
                                 default = nil)
  if valid_598950 != nil:
    section.add "X-Amz-Algorithm", valid_598950
  var valid_598951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598951 = validateParameter(valid_598951, JString, required = false,
                                 default = nil)
  if valid_598951 != nil:
    section.add "X-Amz-SignedHeaders", valid_598951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598953: Call_DescribeNotebookInstanceLifecycleConfig_598941;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_598953.validator(path, query, header, formData, body)
  let scheme = call_598953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598953.url(scheme.get, call_598953.host, call_598953.base,
                         call_598953.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598953, url, valid)

proc call*(call_598954: Call_DescribeNotebookInstanceLifecycleConfig_598941;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_598955 = newJObject()
  if body != nil:
    body_598955 = body
  result = call_598954.call(nil, nil, nil, nil, body_598955)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_598941(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_598942, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_598943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProcessingJob_598956 = ref object of OpenApiRestCall_597389
proc url_DescribeProcessingJob_598958(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProcessingJob_598957(path: JsonNode; query: JsonNode;
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
  var valid_598959 = header.getOrDefault("X-Amz-Target")
  valid_598959 = validateParameter(valid_598959, JString, required = true, default = newJString(
      "SageMaker.DescribeProcessingJob"))
  if valid_598959 != nil:
    section.add "X-Amz-Target", valid_598959
  var valid_598960 = header.getOrDefault("X-Amz-Signature")
  valid_598960 = validateParameter(valid_598960, JString, required = false,
                                 default = nil)
  if valid_598960 != nil:
    section.add "X-Amz-Signature", valid_598960
  var valid_598961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598961 = validateParameter(valid_598961, JString, required = false,
                                 default = nil)
  if valid_598961 != nil:
    section.add "X-Amz-Content-Sha256", valid_598961
  var valid_598962 = header.getOrDefault("X-Amz-Date")
  valid_598962 = validateParameter(valid_598962, JString, required = false,
                                 default = nil)
  if valid_598962 != nil:
    section.add "X-Amz-Date", valid_598962
  var valid_598963 = header.getOrDefault("X-Amz-Credential")
  valid_598963 = validateParameter(valid_598963, JString, required = false,
                                 default = nil)
  if valid_598963 != nil:
    section.add "X-Amz-Credential", valid_598963
  var valid_598964 = header.getOrDefault("X-Amz-Security-Token")
  valid_598964 = validateParameter(valid_598964, JString, required = false,
                                 default = nil)
  if valid_598964 != nil:
    section.add "X-Amz-Security-Token", valid_598964
  var valid_598965 = header.getOrDefault("X-Amz-Algorithm")
  valid_598965 = validateParameter(valid_598965, JString, required = false,
                                 default = nil)
  if valid_598965 != nil:
    section.add "X-Amz-Algorithm", valid_598965
  var valid_598966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598966 = validateParameter(valid_598966, JString, required = false,
                                 default = nil)
  if valid_598966 != nil:
    section.add "X-Amz-SignedHeaders", valid_598966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598968: Call_DescribeProcessingJob_598956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of a processing job.
  ## 
  let valid = call_598968.validator(path, query, header, formData, body)
  let scheme = call_598968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598968.url(scheme.get, call_598968.host, call_598968.base,
                         call_598968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598968, url, valid)

proc call*(call_598969: Call_DescribeProcessingJob_598956; body: JsonNode): Recallable =
  ## describeProcessingJob
  ## Returns a description of a processing job.
  ##   body: JObject (required)
  var body_598970 = newJObject()
  if body != nil:
    body_598970 = body
  result = call_598969.call(nil, nil, nil, nil, body_598970)

var describeProcessingJob* = Call_DescribeProcessingJob_598956(
    name: "describeProcessingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeProcessingJob",
    validator: validate_DescribeProcessingJob_598957, base: "/",
    url: url_DescribeProcessingJob_598958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_598971 = ref object of OpenApiRestCall_597389
proc url_DescribeSubscribedWorkteam_598973(protocol: Scheme; host: string;
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

proc validate_DescribeSubscribedWorkteam_598972(path: JsonNode; query: JsonNode;
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
  var valid_598974 = header.getOrDefault("X-Amz-Target")
  valid_598974 = validateParameter(valid_598974, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_598974 != nil:
    section.add "X-Amz-Target", valid_598974
  var valid_598975 = header.getOrDefault("X-Amz-Signature")
  valid_598975 = validateParameter(valid_598975, JString, required = false,
                                 default = nil)
  if valid_598975 != nil:
    section.add "X-Amz-Signature", valid_598975
  var valid_598976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598976 = validateParameter(valid_598976, JString, required = false,
                                 default = nil)
  if valid_598976 != nil:
    section.add "X-Amz-Content-Sha256", valid_598976
  var valid_598977 = header.getOrDefault("X-Amz-Date")
  valid_598977 = validateParameter(valid_598977, JString, required = false,
                                 default = nil)
  if valid_598977 != nil:
    section.add "X-Amz-Date", valid_598977
  var valid_598978 = header.getOrDefault("X-Amz-Credential")
  valid_598978 = validateParameter(valid_598978, JString, required = false,
                                 default = nil)
  if valid_598978 != nil:
    section.add "X-Amz-Credential", valid_598978
  var valid_598979 = header.getOrDefault("X-Amz-Security-Token")
  valid_598979 = validateParameter(valid_598979, JString, required = false,
                                 default = nil)
  if valid_598979 != nil:
    section.add "X-Amz-Security-Token", valid_598979
  var valid_598980 = header.getOrDefault("X-Amz-Algorithm")
  valid_598980 = validateParameter(valid_598980, JString, required = false,
                                 default = nil)
  if valid_598980 != nil:
    section.add "X-Amz-Algorithm", valid_598980
  var valid_598981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598981 = validateParameter(valid_598981, JString, required = false,
                                 default = nil)
  if valid_598981 != nil:
    section.add "X-Amz-SignedHeaders", valid_598981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598983: Call_DescribeSubscribedWorkteam_598971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_598983.validator(path, query, header, formData, body)
  let scheme = call_598983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598983.url(scheme.get, call_598983.host, call_598983.base,
                         call_598983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598983, url, valid)

proc call*(call_598984: Call_DescribeSubscribedWorkteam_598971; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_598985 = newJObject()
  if body != nil:
    body_598985 = body
  result = call_598984.call(nil, nil, nil, nil, body_598985)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_598971(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_598972, base: "/",
    url: url_DescribeSubscribedWorkteam_598973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_598986 = ref object of OpenApiRestCall_597389
proc url_DescribeTrainingJob_598988(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrainingJob_598987(path: JsonNode; query: JsonNode;
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
  var valid_598989 = header.getOrDefault("X-Amz-Target")
  valid_598989 = validateParameter(valid_598989, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_598989 != nil:
    section.add "X-Amz-Target", valid_598989
  var valid_598990 = header.getOrDefault("X-Amz-Signature")
  valid_598990 = validateParameter(valid_598990, JString, required = false,
                                 default = nil)
  if valid_598990 != nil:
    section.add "X-Amz-Signature", valid_598990
  var valid_598991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598991 = validateParameter(valid_598991, JString, required = false,
                                 default = nil)
  if valid_598991 != nil:
    section.add "X-Amz-Content-Sha256", valid_598991
  var valid_598992 = header.getOrDefault("X-Amz-Date")
  valid_598992 = validateParameter(valid_598992, JString, required = false,
                                 default = nil)
  if valid_598992 != nil:
    section.add "X-Amz-Date", valid_598992
  var valid_598993 = header.getOrDefault("X-Amz-Credential")
  valid_598993 = validateParameter(valid_598993, JString, required = false,
                                 default = nil)
  if valid_598993 != nil:
    section.add "X-Amz-Credential", valid_598993
  var valid_598994 = header.getOrDefault("X-Amz-Security-Token")
  valid_598994 = validateParameter(valid_598994, JString, required = false,
                                 default = nil)
  if valid_598994 != nil:
    section.add "X-Amz-Security-Token", valid_598994
  var valid_598995 = header.getOrDefault("X-Amz-Algorithm")
  valid_598995 = validateParameter(valid_598995, JString, required = false,
                                 default = nil)
  if valid_598995 != nil:
    section.add "X-Amz-Algorithm", valid_598995
  var valid_598996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598996 = validateParameter(valid_598996, JString, required = false,
                                 default = nil)
  if valid_598996 != nil:
    section.add "X-Amz-SignedHeaders", valid_598996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598998: Call_DescribeTrainingJob_598986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_598998.validator(path, query, header, formData, body)
  let scheme = call_598998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598998.url(scheme.get, call_598998.host, call_598998.base,
                         call_598998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598998, url, valid)

proc call*(call_598999: Call_DescribeTrainingJob_598986; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_599000 = newJObject()
  if body != nil:
    body_599000 = body
  result = call_598999.call(nil, nil, nil, nil, body_599000)

var describeTrainingJob* = Call_DescribeTrainingJob_598986(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_598987, base: "/",
    url: url_DescribeTrainingJob_598988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_599001 = ref object of OpenApiRestCall_597389
proc url_DescribeTransformJob_599003(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTransformJob_599002(path: JsonNode; query: JsonNode;
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
  var valid_599004 = header.getOrDefault("X-Amz-Target")
  valid_599004 = validateParameter(valid_599004, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_599004 != nil:
    section.add "X-Amz-Target", valid_599004
  var valid_599005 = header.getOrDefault("X-Amz-Signature")
  valid_599005 = validateParameter(valid_599005, JString, required = false,
                                 default = nil)
  if valid_599005 != nil:
    section.add "X-Amz-Signature", valid_599005
  var valid_599006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599006 = validateParameter(valid_599006, JString, required = false,
                                 default = nil)
  if valid_599006 != nil:
    section.add "X-Amz-Content-Sha256", valid_599006
  var valid_599007 = header.getOrDefault("X-Amz-Date")
  valid_599007 = validateParameter(valid_599007, JString, required = false,
                                 default = nil)
  if valid_599007 != nil:
    section.add "X-Amz-Date", valid_599007
  var valid_599008 = header.getOrDefault("X-Amz-Credential")
  valid_599008 = validateParameter(valid_599008, JString, required = false,
                                 default = nil)
  if valid_599008 != nil:
    section.add "X-Amz-Credential", valid_599008
  var valid_599009 = header.getOrDefault("X-Amz-Security-Token")
  valid_599009 = validateParameter(valid_599009, JString, required = false,
                                 default = nil)
  if valid_599009 != nil:
    section.add "X-Amz-Security-Token", valid_599009
  var valid_599010 = header.getOrDefault("X-Amz-Algorithm")
  valid_599010 = validateParameter(valid_599010, JString, required = false,
                                 default = nil)
  if valid_599010 != nil:
    section.add "X-Amz-Algorithm", valid_599010
  var valid_599011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599011 = validateParameter(valid_599011, JString, required = false,
                                 default = nil)
  if valid_599011 != nil:
    section.add "X-Amz-SignedHeaders", valid_599011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599013: Call_DescribeTransformJob_599001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_599013.validator(path, query, header, formData, body)
  let scheme = call_599013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599013.url(scheme.get, call_599013.host, call_599013.base,
                         call_599013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599013, url, valid)

proc call*(call_599014: Call_DescribeTransformJob_599001; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_599015 = newJObject()
  if body != nil:
    body_599015 = body
  result = call_599014.call(nil, nil, nil, nil, body_599015)

var describeTransformJob* = Call_DescribeTransformJob_599001(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_599002, base: "/",
    url: url_DescribeTransformJob_599003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrial_599016 = ref object of OpenApiRestCall_597389
proc url_DescribeTrial_599018(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrial_599017(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599019 = header.getOrDefault("X-Amz-Target")
  valid_599019 = validateParameter(valid_599019, JString, required = true, default = newJString(
      "SageMaker.DescribeTrial"))
  if valid_599019 != nil:
    section.add "X-Amz-Target", valid_599019
  var valid_599020 = header.getOrDefault("X-Amz-Signature")
  valid_599020 = validateParameter(valid_599020, JString, required = false,
                                 default = nil)
  if valid_599020 != nil:
    section.add "X-Amz-Signature", valid_599020
  var valid_599021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599021 = validateParameter(valid_599021, JString, required = false,
                                 default = nil)
  if valid_599021 != nil:
    section.add "X-Amz-Content-Sha256", valid_599021
  var valid_599022 = header.getOrDefault("X-Amz-Date")
  valid_599022 = validateParameter(valid_599022, JString, required = false,
                                 default = nil)
  if valid_599022 != nil:
    section.add "X-Amz-Date", valid_599022
  var valid_599023 = header.getOrDefault("X-Amz-Credential")
  valid_599023 = validateParameter(valid_599023, JString, required = false,
                                 default = nil)
  if valid_599023 != nil:
    section.add "X-Amz-Credential", valid_599023
  var valid_599024 = header.getOrDefault("X-Amz-Security-Token")
  valid_599024 = validateParameter(valid_599024, JString, required = false,
                                 default = nil)
  if valid_599024 != nil:
    section.add "X-Amz-Security-Token", valid_599024
  var valid_599025 = header.getOrDefault("X-Amz-Algorithm")
  valid_599025 = validateParameter(valid_599025, JString, required = false,
                                 default = nil)
  if valid_599025 != nil:
    section.add "X-Amz-Algorithm", valid_599025
  var valid_599026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599026 = validateParameter(valid_599026, JString, required = false,
                                 default = nil)
  if valid_599026 != nil:
    section.add "X-Amz-SignedHeaders", valid_599026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599028: Call_DescribeTrial_599016; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trial's properties.
  ## 
  let valid = call_599028.validator(path, query, header, formData, body)
  let scheme = call_599028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599028.url(scheme.get, call_599028.host, call_599028.base,
                         call_599028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599028, url, valid)

proc call*(call_599029: Call_DescribeTrial_599016; body: JsonNode): Recallable =
  ## describeTrial
  ## Provides a list of a trial's properties.
  ##   body: JObject (required)
  var body_599030 = newJObject()
  if body != nil:
    body_599030 = body
  result = call_599029.call(nil, nil, nil, nil, body_599030)

var describeTrial* = Call_DescribeTrial_599016(name: "describeTrial",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrial",
    validator: validate_DescribeTrial_599017, base: "/", url: url_DescribeTrial_599018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrialComponent_599031 = ref object of OpenApiRestCall_597389
proc url_DescribeTrialComponent_599033(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrialComponent_599032(path: JsonNode; query: JsonNode;
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
  var valid_599034 = header.getOrDefault("X-Amz-Target")
  valid_599034 = validateParameter(valid_599034, JString, required = true, default = newJString(
      "SageMaker.DescribeTrialComponent"))
  if valid_599034 != nil:
    section.add "X-Amz-Target", valid_599034
  var valid_599035 = header.getOrDefault("X-Amz-Signature")
  valid_599035 = validateParameter(valid_599035, JString, required = false,
                                 default = nil)
  if valid_599035 != nil:
    section.add "X-Amz-Signature", valid_599035
  var valid_599036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599036 = validateParameter(valid_599036, JString, required = false,
                                 default = nil)
  if valid_599036 != nil:
    section.add "X-Amz-Content-Sha256", valid_599036
  var valid_599037 = header.getOrDefault("X-Amz-Date")
  valid_599037 = validateParameter(valid_599037, JString, required = false,
                                 default = nil)
  if valid_599037 != nil:
    section.add "X-Amz-Date", valid_599037
  var valid_599038 = header.getOrDefault("X-Amz-Credential")
  valid_599038 = validateParameter(valid_599038, JString, required = false,
                                 default = nil)
  if valid_599038 != nil:
    section.add "X-Amz-Credential", valid_599038
  var valid_599039 = header.getOrDefault("X-Amz-Security-Token")
  valid_599039 = validateParameter(valid_599039, JString, required = false,
                                 default = nil)
  if valid_599039 != nil:
    section.add "X-Amz-Security-Token", valid_599039
  var valid_599040 = header.getOrDefault("X-Amz-Algorithm")
  valid_599040 = validateParameter(valid_599040, JString, required = false,
                                 default = nil)
  if valid_599040 != nil:
    section.add "X-Amz-Algorithm", valid_599040
  var valid_599041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599041 = validateParameter(valid_599041, JString, required = false,
                                 default = nil)
  if valid_599041 != nil:
    section.add "X-Amz-SignedHeaders", valid_599041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599043: Call_DescribeTrialComponent_599031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of a trials component's properties.
  ## 
  let valid = call_599043.validator(path, query, header, formData, body)
  let scheme = call_599043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599043.url(scheme.get, call_599043.host, call_599043.base,
                         call_599043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599043, url, valid)

proc call*(call_599044: Call_DescribeTrialComponent_599031; body: JsonNode): Recallable =
  ## describeTrialComponent
  ## Provides a list of a trials component's properties.
  ##   body: JObject (required)
  var body_599045 = newJObject()
  if body != nil:
    body_599045 = body
  result = call_599044.call(nil, nil, nil, nil, body_599045)

var describeTrialComponent* = Call_DescribeTrialComponent_599031(
    name: "describeTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrialComponent",
    validator: validate_DescribeTrialComponent_599032, base: "/",
    url: url_DescribeTrialComponent_599033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUserProfile_599046 = ref object of OpenApiRestCall_597389
proc url_DescribeUserProfile_599048(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeUserProfile_599047(path: JsonNode; query: JsonNode;
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
  var valid_599049 = header.getOrDefault("X-Amz-Target")
  valid_599049 = validateParameter(valid_599049, JString, required = true, default = newJString(
      "SageMaker.DescribeUserProfile"))
  if valid_599049 != nil:
    section.add "X-Amz-Target", valid_599049
  var valid_599050 = header.getOrDefault("X-Amz-Signature")
  valid_599050 = validateParameter(valid_599050, JString, required = false,
                                 default = nil)
  if valid_599050 != nil:
    section.add "X-Amz-Signature", valid_599050
  var valid_599051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599051 = validateParameter(valid_599051, JString, required = false,
                                 default = nil)
  if valid_599051 != nil:
    section.add "X-Amz-Content-Sha256", valid_599051
  var valid_599052 = header.getOrDefault("X-Amz-Date")
  valid_599052 = validateParameter(valid_599052, JString, required = false,
                                 default = nil)
  if valid_599052 != nil:
    section.add "X-Amz-Date", valid_599052
  var valid_599053 = header.getOrDefault("X-Amz-Credential")
  valid_599053 = validateParameter(valid_599053, JString, required = false,
                                 default = nil)
  if valid_599053 != nil:
    section.add "X-Amz-Credential", valid_599053
  var valid_599054 = header.getOrDefault("X-Amz-Security-Token")
  valid_599054 = validateParameter(valid_599054, JString, required = false,
                                 default = nil)
  if valid_599054 != nil:
    section.add "X-Amz-Security-Token", valid_599054
  var valid_599055 = header.getOrDefault("X-Amz-Algorithm")
  valid_599055 = validateParameter(valid_599055, JString, required = false,
                                 default = nil)
  if valid_599055 != nil:
    section.add "X-Amz-Algorithm", valid_599055
  var valid_599056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599056 = validateParameter(valid_599056, JString, required = false,
                                 default = nil)
  if valid_599056 != nil:
    section.add "X-Amz-SignedHeaders", valid_599056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599058: Call_DescribeUserProfile_599046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the user profile.
  ## 
  let valid = call_599058.validator(path, query, header, formData, body)
  let scheme = call_599058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599058.url(scheme.get, call_599058.host, call_599058.base,
                         call_599058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599058, url, valid)

proc call*(call_599059: Call_DescribeUserProfile_599046; body: JsonNode): Recallable =
  ## describeUserProfile
  ## Describes the user profile.
  ##   body: JObject (required)
  var body_599060 = newJObject()
  if body != nil:
    body_599060 = body
  result = call_599059.call(nil, nil, nil, nil, body_599060)

var describeUserProfile* = Call_DescribeUserProfile_599046(
    name: "describeUserProfile", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeUserProfile",
    validator: validate_DescribeUserProfile_599047, base: "/",
    url: url_DescribeUserProfile_599048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_599061 = ref object of OpenApiRestCall_597389
proc url_DescribeWorkteam_599063(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeWorkteam_599062(path: JsonNode; query: JsonNode;
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
  var valid_599064 = header.getOrDefault("X-Amz-Target")
  valid_599064 = validateParameter(valid_599064, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_599064 != nil:
    section.add "X-Amz-Target", valid_599064
  var valid_599065 = header.getOrDefault("X-Amz-Signature")
  valid_599065 = validateParameter(valid_599065, JString, required = false,
                                 default = nil)
  if valid_599065 != nil:
    section.add "X-Amz-Signature", valid_599065
  var valid_599066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599066 = validateParameter(valid_599066, JString, required = false,
                                 default = nil)
  if valid_599066 != nil:
    section.add "X-Amz-Content-Sha256", valid_599066
  var valid_599067 = header.getOrDefault("X-Amz-Date")
  valid_599067 = validateParameter(valid_599067, JString, required = false,
                                 default = nil)
  if valid_599067 != nil:
    section.add "X-Amz-Date", valid_599067
  var valid_599068 = header.getOrDefault("X-Amz-Credential")
  valid_599068 = validateParameter(valid_599068, JString, required = false,
                                 default = nil)
  if valid_599068 != nil:
    section.add "X-Amz-Credential", valid_599068
  var valid_599069 = header.getOrDefault("X-Amz-Security-Token")
  valid_599069 = validateParameter(valid_599069, JString, required = false,
                                 default = nil)
  if valid_599069 != nil:
    section.add "X-Amz-Security-Token", valid_599069
  var valid_599070 = header.getOrDefault("X-Amz-Algorithm")
  valid_599070 = validateParameter(valid_599070, JString, required = false,
                                 default = nil)
  if valid_599070 != nil:
    section.add "X-Amz-Algorithm", valid_599070
  var valid_599071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599071 = validateParameter(valid_599071, JString, required = false,
                                 default = nil)
  if valid_599071 != nil:
    section.add "X-Amz-SignedHeaders", valid_599071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599073: Call_DescribeWorkteam_599061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_599073.validator(path, query, header, formData, body)
  let scheme = call_599073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599073.url(scheme.get, call_599073.host, call_599073.base,
                         call_599073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599073, url, valid)

proc call*(call_599074: Call_DescribeWorkteam_599061; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_599075 = newJObject()
  if body != nil:
    body_599075 = body
  result = call_599074.call(nil, nil, nil, nil, body_599075)

var describeWorkteam* = Call_DescribeWorkteam_599061(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_599062, base: "/",
    url: url_DescribeWorkteam_599063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateTrialComponent_599076 = ref object of OpenApiRestCall_597389
proc url_DisassociateTrialComponent_599078(protocol: Scheme; host: string;
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

proc validate_DisassociateTrialComponent_599077(path: JsonNode; query: JsonNode;
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
  var valid_599079 = header.getOrDefault("X-Amz-Target")
  valid_599079 = validateParameter(valid_599079, JString, required = true, default = newJString(
      "SageMaker.DisassociateTrialComponent"))
  if valid_599079 != nil:
    section.add "X-Amz-Target", valid_599079
  var valid_599080 = header.getOrDefault("X-Amz-Signature")
  valid_599080 = validateParameter(valid_599080, JString, required = false,
                                 default = nil)
  if valid_599080 != nil:
    section.add "X-Amz-Signature", valid_599080
  var valid_599081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599081 = validateParameter(valid_599081, JString, required = false,
                                 default = nil)
  if valid_599081 != nil:
    section.add "X-Amz-Content-Sha256", valid_599081
  var valid_599082 = header.getOrDefault("X-Amz-Date")
  valid_599082 = validateParameter(valid_599082, JString, required = false,
                                 default = nil)
  if valid_599082 != nil:
    section.add "X-Amz-Date", valid_599082
  var valid_599083 = header.getOrDefault("X-Amz-Credential")
  valid_599083 = validateParameter(valid_599083, JString, required = false,
                                 default = nil)
  if valid_599083 != nil:
    section.add "X-Amz-Credential", valid_599083
  var valid_599084 = header.getOrDefault("X-Amz-Security-Token")
  valid_599084 = validateParameter(valid_599084, JString, required = false,
                                 default = nil)
  if valid_599084 != nil:
    section.add "X-Amz-Security-Token", valid_599084
  var valid_599085 = header.getOrDefault("X-Amz-Algorithm")
  valid_599085 = validateParameter(valid_599085, JString, required = false,
                                 default = nil)
  if valid_599085 != nil:
    section.add "X-Amz-Algorithm", valid_599085
  var valid_599086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599086 = validateParameter(valid_599086, JString, required = false,
                                 default = nil)
  if valid_599086 != nil:
    section.add "X-Amz-SignedHeaders", valid_599086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599088: Call_DisassociateTrialComponent_599076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ## 
  let valid = call_599088.validator(path, query, header, formData, body)
  let scheme = call_599088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599088.url(scheme.get, call_599088.host, call_599088.base,
                         call_599088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599088, url, valid)

proc call*(call_599089: Call_DisassociateTrialComponent_599076; body: JsonNode): Recallable =
  ## disassociateTrialComponent
  ## Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a>AssociateTrialComponent</a> API.
  ##   body: JObject (required)
  var body_599090 = newJObject()
  if body != nil:
    body_599090 = body
  result = call_599089.call(nil, nil, nil, nil, body_599090)

var disassociateTrialComponent* = Call_DisassociateTrialComponent_599076(
    name: "disassociateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DisassociateTrialComponent",
    validator: validate_DisassociateTrialComponent_599077, base: "/",
    url: url_DisassociateTrialComponent_599078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_599091 = ref object of OpenApiRestCall_597389
proc url_GetSearchSuggestions_599093(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSearchSuggestions_599092(path: JsonNode; query: JsonNode;
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
  var valid_599094 = header.getOrDefault("X-Amz-Target")
  valid_599094 = validateParameter(valid_599094, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_599094 != nil:
    section.add "X-Amz-Target", valid_599094
  var valid_599095 = header.getOrDefault("X-Amz-Signature")
  valid_599095 = validateParameter(valid_599095, JString, required = false,
                                 default = nil)
  if valid_599095 != nil:
    section.add "X-Amz-Signature", valid_599095
  var valid_599096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599096 = validateParameter(valid_599096, JString, required = false,
                                 default = nil)
  if valid_599096 != nil:
    section.add "X-Amz-Content-Sha256", valid_599096
  var valid_599097 = header.getOrDefault("X-Amz-Date")
  valid_599097 = validateParameter(valid_599097, JString, required = false,
                                 default = nil)
  if valid_599097 != nil:
    section.add "X-Amz-Date", valid_599097
  var valid_599098 = header.getOrDefault("X-Amz-Credential")
  valid_599098 = validateParameter(valid_599098, JString, required = false,
                                 default = nil)
  if valid_599098 != nil:
    section.add "X-Amz-Credential", valid_599098
  var valid_599099 = header.getOrDefault("X-Amz-Security-Token")
  valid_599099 = validateParameter(valid_599099, JString, required = false,
                                 default = nil)
  if valid_599099 != nil:
    section.add "X-Amz-Security-Token", valid_599099
  var valid_599100 = header.getOrDefault("X-Amz-Algorithm")
  valid_599100 = validateParameter(valid_599100, JString, required = false,
                                 default = nil)
  if valid_599100 != nil:
    section.add "X-Amz-Algorithm", valid_599100
  var valid_599101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599101 = validateParameter(valid_599101, JString, required = false,
                                 default = nil)
  if valid_599101 != nil:
    section.add "X-Amz-SignedHeaders", valid_599101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599103: Call_GetSearchSuggestions_599091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_599103.validator(path, query, header, formData, body)
  let scheme = call_599103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599103.url(scheme.get, call_599103.host, call_599103.base,
                         call_599103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599103, url, valid)

proc call*(call_599104: Call_GetSearchSuggestions_599091; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_599105 = newJObject()
  if body != nil:
    body_599105 = body
  result = call_599104.call(nil, nil, nil, nil, body_599105)

var getSearchSuggestions* = Call_GetSearchSuggestions_599091(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_599092, base: "/",
    url: url_GetSearchSuggestions_599093, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_599106 = ref object of OpenApiRestCall_597389
proc url_ListAlgorithms_599108(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAlgorithms_599107(path: JsonNode; query: JsonNode;
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
  var valid_599109 = query.getOrDefault("MaxResults")
  valid_599109 = validateParameter(valid_599109, JString, required = false,
                                 default = nil)
  if valid_599109 != nil:
    section.add "MaxResults", valid_599109
  var valid_599110 = query.getOrDefault("NextToken")
  valid_599110 = validateParameter(valid_599110, JString, required = false,
                                 default = nil)
  if valid_599110 != nil:
    section.add "NextToken", valid_599110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599111 = header.getOrDefault("X-Amz-Target")
  valid_599111 = validateParameter(valid_599111, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_599111 != nil:
    section.add "X-Amz-Target", valid_599111
  var valid_599112 = header.getOrDefault("X-Amz-Signature")
  valid_599112 = validateParameter(valid_599112, JString, required = false,
                                 default = nil)
  if valid_599112 != nil:
    section.add "X-Amz-Signature", valid_599112
  var valid_599113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599113 = validateParameter(valid_599113, JString, required = false,
                                 default = nil)
  if valid_599113 != nil:
    section.add "X-Amz-Content-Sha256", valid_599113
  var valid_599114 = header.getOrDefault("X-Amz-Date")
  valid_599114 = validateParameter(valid_599114, JString, required = false,
                                 default = nil)
  if valid_599114 != nil:
    section.add "X-Amz-Date", valid_599114
  var valid_599115 = header.getOrDefault("X-Amz-Credential")
  valid_599115 = validateParameter(valid_599115, JString, required = false,
                                 default = nil)
  if valid_599115 != nil:
    section.add "X-Amz-Credential", valid_599115
  var valid_599116 = header.getOrDefault("X-Amz-Security-Token")
  valid_599116 = validateParameter(valid_599116, JString, required = false,
                                 default = nil)
  if valid_599116 != nil:
    section.add "X-Amz-Security-Token", valid_599116
  var valid_599117 = header.getOrDefault("X-Amz-Algorithm")
  valid_599117 = validateParameter(valid_599117, JString, required = false,
                                 default = nil)
  if valid_599117 != nil:
    section.add "X-Amz-Algorithm", valid_599117
  var valid_599118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599118 = validateParameter(valid_599118, JString, required = false,
                                 default = nil)
  if valid_599118 != nil:
    section.add "X-Amz-SignedHeaders", valid_599118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599120: Call_ListAlgorithms_599106; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_599120.validator(path, query, header, formData, body)
  let scheme = call_599120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599120.url(scheme.get, call_599120.host, call_599120.base,
                         call_599120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599120, url, valid)

proc call*(call_599121: Call_ListAlgorithms_599106; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599122 = newJObject()
  var body_599123 = newJObject()
  add(query_599122, "MaxResults", newJString(MaxResults))
  add(query_599122, "NextToken", newJString(NextToken))
  if body != nil:
    body_599123 = body
  result = call_599121.call(nil, query_599122, nil, nil, body_599123)

var listAlgorithms* = Call_ListAlgorithms_599106(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_599107, base: "/", url: url_ListAlgorithms_599108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApps_599125 = ref object of OpenApiRestCall_597389
proc url_ListApps_599127(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListApps_599126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599128 = query.getOrDefault("MaxResults")
  valid_599128 = validateParameter(valid_599128, JString, required = false,
                                 default = nil)
  if valid_599128 != nil:
    section.add "MaxResults", valid_599128
  var valid_599129 = query.getOrDefault("NextToken")
  valid_599129 = validateParameter(valid_599129, JString, required = false,
                                 default = nil)
  if valid_599129 != nil:
    section.add "NextToken", valid_599129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599130 = header.getOrDefault("X-Amz-Target")
  valid_599130 = validateParameter(valid_599130, JString, required = true,
                                 default = newJString("SageMaker.ListApps"))
  if valid_599130 != nil:
    section.add "X-Amz-Target", valid_599130
  var valid_599131 = header.getOrDefault("X-Amz-Signature")
  valid_599131 = validateParameter(valid_599131, JString, required = false,
                                 default = nil)
  if valid_599131 != nil:
    section.add "X-Amz-Signature", valid_599131
  var valid_599132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599132 = validateParameter(valid_599132, JString, required = false,
                                 default = nil)
  if valid_599132 != nil:
    section.add "X-Amz-Content-Sha256", valid_599132
  var valid_599133 = header.getOrDefault("X-Amz-Date")
  valid_599133 = validateParameter(valid_599133, JString, required = false,
                                 default = nil)
  if valid_599133 != nil:
    section.add "X-Amz-Date", valid_599133
  var valid_599134 = header.getOrDefault("X-Amz-Credential")
  valid_599134 = validateParameter(valid_599134, JString, required = false,
                                 default = nil)
  if valid_599134 != nil:
    section.add "X-Amz-Credential", valid_599134
  var valid_599135 = header.getOrDefault("X-Amz-Security-Token")
  valid_599135 = validateParameter(valid_599135, JString, required = false,
                                 default = nil)
  if valid_599135 != nil:
    section.add "X-Amz-Security-Token", valid_599135
  var valid_599136 = header.getOrDefault("X-Amz-Algorithm")
  valid_599136 = validateParameter(valid_599136, JString, required = false,
                                 default = nil)
  if valid_599136 != nil:
    section.add "X-Amz-Algorithm", valid_599136
  var valid_599137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599137 = validateParameter(valid_599137, JString, required = false,
                                 default = nil)
  if valid_599137 != nil:
    section.add "X-Amz-SignedHeaders", valid_599137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599139: Call_ListApps_599125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists apps.
  ## 
  let valid = call_599139.validator(path, query, header, formData, body)
  let scheme = call_599139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599139.url(scheme.get, call_599139.host, call_599139.base,
                         call_599139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599139, url, valid)

proc call*(call_599140: Call_ListApps_599125; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApps
  ## Lists apps.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599141 = newJObject()
  var body_599142 = newJObject()
  add(query_599141, "MaxResults", newJString(MaxResults))
  add(query_599141, "NextToken", newJString(NextToken))
  if body != nil:
    body_599142 = body
  result = call_599140.call(nil, query_599141, nil, nil, body_599142)

var listApps* = Call_ListApps_599125(name: "listApps", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListApps",
                                  validator: validate_ListApps_599126, base: "/",
                                  url: url_ListApps_599127,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAutoMLJobs_599143 = ref object of OpenApiRestCall_597389
proc url_ListAutoMLJobs_599145(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAutoMLJobs_599144(path: JsonNode; query: JsonNode;
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
  var valid_599146 = query.getOrDefault("MaxResults")
  valid_599146 = validateParameter(valid_599146, JString, required = false,
                                 default = nil)
  if valid_599146 != nil:
    section.add "MaxResults", valid_599146
  var valid_599147 = query.getOrDefault("NextToken")
  valid_599147 = validateParameter(valid_599147, JString, required = false,
                                 default = nil)
  if valid_599147 != nil:
    section.add "NextToken", valid_599147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599148 = header.getOrDefault("X-Amz-Target")
  valid_599148 = validateParameter(valid_599148, JString, required = true, default = newJString(
      "SageMaker.ListAutoMLJobs"))
  if valid_599148 != nil:
    section.add "X-Amz-Target", valid_599148
  var valid_599149 = header.getOrDefault("X-Amz-Signature")
  valid_599149 = validateParameter(valid_599149, JString, required = false,
                                 default = nil)
  if valid_599149 != nil:
    section.add "X-Amz-Signature", valid_599149
  var valid_599150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599150 = validateParameter(valid_599150, JString, required = false,
                                 default = nil)
  if valid_599150 != nil:
    section.add "X-Amz-Content-Sha256", valid_599150
  var valid_599151 = header.getOrDefault("X-Amz-Date")
  valid_599151 = validateParameter(valid_599151, JString, required = false,
                                 default = nil)
  if valid_599151 != nil:
    section.add "X-Amz-Date", valid_599151
  var valid_599152 = header.getOrDefault("X-Amz-Credential")
  valid_599152 = validateParameter(valid_599152, JString, required = false,
                                 default = nil)
  if valid_599152 != nil:
    section.add "X-Amz-Credential", valid_599152
  var valid_599153 = header.getOrDefault("X-Amz-Security-Token")
  valid_599153 = validateParameter(valid_599153, JString, required = false,
                                 default = nil)
  if valid_599153 != nil:
    section.add "X-Amz-Security-Token", valid_599153
  var valid_599154 = header.getOrDefault("X-Amz-Algorithm")
  valid_599154 = validateParameter(valid_599154, JString, required = false,
                                 default = nil)
  if valid_599154 != nil:
    section.add "X-Amz-Algorithm", valid_599154
  var valid_599155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599155 = validateParameter(valid_599155, JString, required = false,
                                 default = nil)
  if valid_599155 != nil:
    section.add "X-Amz-SignedHeaders", valid_599155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599157: Call_ListAutoMLJobs_599143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Request a list of jobs.
  ## 
  let valid = call_599157.validator(path, query, header, formData, body)
  let scheme = call_599157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599157.url(scheme.get, call_599157.host, call_599157.base,
                         call_599157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599157, url, valid)

proc call*(call_599158: Call_ListAutoMLJobs_599143; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAutoMLJobs
  ## Request a list of jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599159 = newJObject()
  var body_599160 = newJObject()
  add(query_599159, "MaxResults", newJString(MaxResults))
  add(query_599159, "NextToken", newJString(NextToken))
  if body != nil:
    body_599160 = body
  result = call_599158.call(nil, query_599159, nil, nil, body_599160)

var listAutoMLJobs* = Call_ListAutoMLJobs_599143(name: "listAutoMLJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAutoMLJobs",
    validator: validate_ListAutoMLJobs_599144, base: "/", url: url_ListAutoMLJobs_599145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCandidatesForAutoMLJob_599161 = ref object of OpenApiRestCall_597389
proc url_ListCandidatesForAutoMLJob_599163(protocol: Scheme; host: string;
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

proc validate_ListCandidatesForAutoMLJob_599162(path: JsonNode; query: JsonNode;
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
  var valid_599164 = query.getOrDefault("MaxResults")
  valid_599164 = validateParameter(valid_599164, JString, required = false,
                                 default = nil)
  if valid_599164 != nil:
    section.add "MaxResults", valid_599164
  var valid_599165 = query.getOrDefault("NextToken")
  valid_599165 = validateParameter(valid_599165, JString, required = false,
                                 default = nil)
  if valid_599165 != nil:
    section.add "NextToken", valid_599165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599166 = header.getOrDefault("X-Amz-Target")
  valid_599166 = validateParameter(valid_599166, JString, required = true, default = newJString(
      "SageMaker.ListCandidatesForAutoMLJob"))
  if valid_599166 != nil:
    section.add "X-Amz-Target", valid_599166
  var valid_599167 = header.getOrDefault("X-Amz-Signature")
  valid_599167 = validateParameter(valid_599167, JString, required = false,
                                 default = nil)
  if valid_599167 != nil:
    section.add "X-Amz-Signature", valid_599167
  var valid_599168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599168 = validateParameter(valid_599168, JString, required = false,
                                 default = nil)
  if valid_599168 != nil:
    section.add "X-Amz-Content-Sha256", valid_599168
  var valid_599169 = header.getOrDefault("X-Amz-Date")
  valid_599169 = validateParameter(valid_599169, JString, required = false,
                                 default = nil)
  if valid_599169 != nil:
    section.add "X-Amz-Date", valid_599169
  var valid_599170 = header.getOrDefault("X-Amz-Credential")
  valid_599170 = validateParameter(valid_599170, JString, required = false,
                                 default = nil)
  if valid_599170 != nil:
    section.add "X-Amz-Credential", valid_599170
  var valid_599171 = header.getOrDefault("X-Amz-Security-Token")
  valid_599171 = validateParameter(valid_599171, JString, required = false,
                                 default = nil)
  if valid_599171 != nil:
    section.add "X-Amz-Security-Token", valid_599171
  var valid_599172 = header.getOrDefault("X-Amz-Algorithm")
  valid_599172 = validateParameter(valid_599172, JString, required = false,
                                 default = nil)
  if valid_599172 != nil:
    section.add "X-Amz-Algorithm", valid_599172
  var valid_599173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599173 = validateParameter(valid_599173, JString, required = false,
                                 default = nil)
  if valid_599173 != nil:
    section.add "X-Amz-SignedHeaders", valid_599173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599175: Call_ListCandidatesForAutoMLJob_599161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Candidates created for the job.
  ## 
  let valid = call_599175.validator(path, query, header, formData, body)
  let scheme = call_599175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599175.url(scheme.get, call_599175.host, call_599175.base,
                         call_599175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599175, url, valid)

proc call*(call_599176: Call_ListCandidatesForAutoMLJob_599161; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCandidatesForAutoMLJob
  ## List the Candidates created for the job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599177 = newJObject()
  var body_599178 = newJObject()
  add(query_599177, "MaxResults", newJString(MaxResults))
  add(query_599177, "NextToken", newJString(NextToken))
  if body != nil:
    body_599178 = body
  result = call_599176.call(nil, query_599177, nil, nil, body_599178)

var listCandidatesForAutoMLJob* = Call_ListCandidatesForAutoMLJob_599161(
    name: "listCandidatesForAutoMLJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob",
    validator: validate_ListCandidatesForAutoMLJob_599162, base: "/",
    url: url_ListCandidatesForAutoMLJob_599163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_599179 = ref object of OpenApiRestCall_597389
proc url_ListCodeRepositories_599181(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCodeRepositories_599180(path: JsonNode; query: JsonNode;
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
  var valid_599182 = query.getOrDefault("MaxResults")
  valid_599182 = validateParameter(valid_599182, JString, required = false,
                                 default = nil)
  if valid_599182 != nil:
    section.add "MaxResults", valid_599182
  var valid_599183 = query.getOrDefault("NextToken")
  valid_599183 = validateParameter(valid_599183, JString, required = false,
                                 default = nil)
  if valid_599183 != nil:
    section.add "NextToken", valid_599183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599184 = header.getOrDefault("X-Amz-Target")
  valid_599184 = validateParameter(valid_599184, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_599184 != nil:
    section.add "X-Amz-Target", valid_599184
  var valid_599185 = header.getOrDefault("X-Amz-Signature")
  valid_599185 = validateParameter(valid_599185, JString, required = false,
                                 default = nil)
  if valid_599185 != nil:
    section.add "X-Amz-Signature", valid_599185
  var valid_599186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599186 = validateParameter(valid_599186, JString, required = false,
                                 default = nil)
  if valid_599186 != nil:
    section.add "X-Amz-Content-Sha256", valid_599186
  var valid_599187 = header.getOrDefault("X-Amz-Date")
  valid_599187 = validateParameter(valid_599187, JString, required = false,
                                 default = nil)
  if valid_599187 != nil:
    section.add "X-Amz-Date", valid_599187
  var valid_599188 = header.getOrDefault("X-Amz-Credential")
  valid_599188 = validateParameter(valid_599188, JString, required = false,
                                 default = nil)
  if valid_599188 != nil:
    section.add "X-Amz-Credential", valid_599188
  var valid_599189 = header.getOrDefault("X-Amz-Security-Token")
  valid_599189 = validateParameter(valid_599189, JString, required = false,
                                 default = nil)
  if valid_599189 != nil:
    section.add "X-Amz-Security-Token", valid_599189
  var valid_599190 = header.getOrDefault("X-Amz-Algorithm")
  valid_599190 = validateParameter(valid_599190, JString, required = false,
                                 default = nil)
  if valid_599190 != nil:
    section.add "X-Amz-Algorithm", valid_599190
  var valid_599191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599191 = validateParameter(valid_599191, JString, required = false,
                                 default = nil)
  if valid_599191 != nil:
    section.add "X-Amz-SignedHeaders", valid_599191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599193: Call_ListCodeRepositories_599179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_599193.validator(path, query, header, formData, body)
  let scheme = call_599193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599193.url(scheme.get, call_599193.host, call_599193.base,
                         call_599193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599193, url, valid)

proc call*(call_599194: Call_ListCodeRepositories_599179; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599195 = newJObject()
  var body_599196 = newJObject()
  add(query_599195, "MaxResults", newJString(MaxResults))
  add(query_599195, "NextToken", newJString(NextToken))
  if body != nil:
    body_599196 = body
  result = call_599194.call(nil, query_599195, nil, nil, body_599196)

var listCodeRepositories* = Call_ListCodeRepositories_599179(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_599180, base: "/",
    url: url_ListCodeRepositories_599181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_599197 = ref object of OpenApiRestCall_597389
proc url_ListCompilationJobs_599199(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCompilationJobs_599198(path: JsonNode; query: JsonNode;
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
  var valid_599200 = query.getOrDefault("MaxResults")
  valid_599200 = validateParameter(valid_599200, JString, required = false,
                                 default = nil)
  if valid_599200 != nil:
    section.add "MaxResults", valid_599200
  var valid_599201 = query.getOrDefault("NextToken")
  valid_599201 = validateParameter(valid_599201, JString, required = false,
                                 default = nil)
  if valid_599201 != nil:
    section.add "NextToken", valid_599201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599202 = header.getOrDefault("X-Amz-Target")
  valid_599202 = validateParameter(valid_599202, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_599202 != nil:
    section.add "X-Amz-Target", valid_599202
  var valid_599203 = header.getOrDefault("X-Amz-Signature")
  valid_599203 = validateParameter(valid_599203, JString, required = false,
                                 default = nil)
  if valid_599203 != nil:
    section.add "X-Amz-Signature", valid_599203
  var valid_599204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599204 = validateParameter(valid_599204, JString, required = false,
                                 default = nil)
  if valid_599204 != nil:
    section.add "X-Amz-Content-Sha256", valid_599204
  var valid_599205 = header.getOrDefault("X-Amz-Date")
  valid_599205 = validateParameter(valid_599205, JString, required = false,
                                 default = nil)
  if valid_599205 != nil:
    section.add "X-Amz-Date", valid_599205
  var valid_599206 = header.getOrDefault("X-Amz-Credential")
  valid_599206 = validateParameter(valid_599206, JString, required = false,
                                 default = nil)
  if valid_599206 != nil:
    section.add "X-Amz-Credential", valid_599206
  var valid_599207 = header.getOrDefault("X-Amz-Security-Token")
  valid_599207 = validateParameter(valid_599207, JString, required = false,
                                 default = nil)
  if valid_599207 != nil:
    section.add "X-Amz-Security-Token", valid_599207
  var valid_599208 = header.getOrDefault("X-Amz-Algorithm")
  valid_599208 = validateParameter(valid_599208, JString, required = false,
                                 default = nil)
  if valid_599208 != nil:
    section.add "X-Amz-Algorithm", valid_599208
  var valid_599209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599209 = validateParameter(valid_599209, JString, required = false,
                                 default = nil)
  if valid_599209 != nil:
    section.add "X-Amz-SignedHeaders", valid_599209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599211: Call_ListCompilationJobs_599197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_599211.validator(path, query, header, formData, body)
  let scheme = call_599211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599211.url(scheme.get, call_599211.host, call_599211.base,
                         call_599211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599211, url, valid)

proc call*(call_599212: Call_ListCompilationJobs_599197; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599213 = newJObject()
  var body_599214 = newJObject()
  add(query_599213, "MaxResults", newJString(MaxResults))
  add(query_599213, "NextToken", newJString(NextToken))
  if body != nil:
    body_599214 = body
  result = call_599212.call(nil, query_599213, nil, nil, body_599214)

var listCompilationJobs* = Call_ListCompilationJobs_599197(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_599198, base: "/",
    url: url_ListCompilationJobs_599199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomains_599215 = ref object of OpenApiRestCall_597389
proc url_ListDomains_599217(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomains_599216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599218 = query.getOrDefault("MaxResults")
  valid_599218 = validateParameter(valid_599218, JString, required = false,
                                 default = nil)
  if valid_599218 != nil:
    section.add "MaxResults", valid_599218
  var valid_599219 = query.getOrDefault("NextToken")
  valid_599219 = validateParameter(valid_599219, JString, required = false,
                                 default = nil)
  if valid_599219 != nil:
    section.add "NextToken", valid_599219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599220 = header.getOrDefault("X-Amz-Target")
  valid_599220 = validateParameter(valid_599220, JString, required = true,
                                 default = newJString("SageMaker.ListDomains"))
  if valid_599220 != nil:
    section.add "X-Amz-Target", valid_599220
  var valid_599221 = header.getOrDefault("X-Amz-Signature")
  valid_599221 = validateParameter(valid_599221, JString, required = false,
                                 default = nil)
  if valid_599221 != nil:
    section.add "X-Amz-Signature", valid_599221
  var valid_599222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599222 = validateParameter(valid_599222, JString, required = false,
                                 default = nil)
  if valid_599222 != nil:
    section.add "X-Amz-Content-Sha256", valid_599222
  var valid_599223 = header.getOrDefault("X-Amz-Date")
  valid_599223 = validateParameter(valid_599223, JString, required = false,
                                 default = nil)
  if valid_599223 != nil:
    section.add "X-Amz-Date", valid_599223
  var valid_599224 = header.getOrDefault("X-Amz-Credential")
  valid_599224 = validateParameter(valid_599224, JString, required = false,
                                 default = nil)
  if valid_599224 != nil:
    section.add "X-Amz-Credential", valid_599224
  var valid_599225 = header.getOrDefault("X-Amz-Security-Token")
  valid_599225 = validateParameter(valid_599225, JString, required = false,
                                 default = nil)
  if valid_599225 != nil:
    section.add "X-Amz-Security-Token", valid_599225
  var valid_599226 = header.getOrDefault("X-Amz-Algorithm")
  valid_599226 = validateParameter(valid_599226, JString, required = false,
                                 default = nil)
  if valid_599226 != nil:
    section.add "X-Amz-Algorithm", valid_599226
  var valid_599227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599227 = validateParameter(valid_599227, JString, required = false,
                                 default = nil)
  if valid_599227 != nil:
    section.add "X-Amz-SignedHeaders", valid_599227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599229: Call_ListDomains_599215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the domains.
  ## 
  let valid = call_599229.validator(path, query, header, formData, body)
  let scheme = call_599229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599229.url(scheme.get, call_599229.host, call_599229.base,
                         call_599229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599229, url, valid)

proc call*(call_599230: Call_ListDomains_599215; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDomains
  ## Lists the domains.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599231 = newJObject()
  var body_599232 = newJObject()
  add(query_599231, "MaxResults", newJString(MaxResults))
  add(query_599231, "NextToken", newJString(NextToken))
  if body != nil:
    body_599232 = body
  result = call_599230.call(nil, query_599231, nil, nil, body_599232)

var listDomains* = Call_ListDomains_599215(name: "listDomains",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListDomains",
                                        validator: validate_ListDomains_599216,
                                        base: "/", url: url_ListDomains_599217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_599233 = ref object of OpenApiRestCall_597389
proc url_ListEndpointConfigs_599235(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpointConfigs_599234(path: JsonNode; query: JsonNode;
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
  var valid_599236 = query.getOrDefault("MaxResults")
  valid_599236 = validateParameter(valid_599236, JString, required = false,
                                 default = nil)
  if valid_599236 != nil:
    section.add "MaxResults", valid_599236
  var valid_599237 = query.getOrDefault("NextToken")
  valid_599237 = validateParameter(valid_599237, JString, required = false,
                                 default = nil)
  if valid_599237 != nil:
    section.add "NextToken", valid_599237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599238 = header.getOrDefault("X-Amz-Target")
  valid_599238 = validateParameter(valid_599238, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_599238 != nil:
    section.add "X-Amz-Target", valid_599238
  var valid_599239 = header.getOrDefault("X-Amz-Signature")
  valid_599239 = validateParameter(valid_599239, JString, required = false,
                                 default = nil)
  if valid_599239 != nil:
    section.add "X-Amz-Signature", valid_599239
  var valid_599240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599240 = validateParameter(valid_599240, JString, required = false,
                                 default = nil)
  if valid_599240 != nil:
    section.add "X-Amz-Content-Sha256", valid_599240
  var valid_599241 = header.getOrDefault("X-Amz-Date")
  valid_599241 = validateParameter(valid_599241, JString, required = false,
                                 default = nil)
  if valid_599241 != nil:
    section.add "X-Amz-Date", valid_599241
  var valid_599242 = header.getOrDefault("X-Amz-Credential")
  valid_599242 = validateParameter(valid_599242, JString, required = false,
                                 default = nil)
  if valid_599242 != nil:
    section.add "X-Amz-Credential", valid_599242
  var valid_599243 = header.getOrDefault("X-Amz-Security-Token")
  valid_599243 = validateParameter(valid_599243, JString, required = false,
                                 default = nil)
  if valid_599243 != nil:
    section.add "X-Amz-Security-Token", valid_599243
  var valid_599244 = header.getOrDefault("X-Amz-Algorithm")
  valid_599244 = validateParameter(valid_599244, JString, required = false,
                                 default = nil)
  if valid_599244 != nil:
    section.add "X-Amz-Algorithm", valid_599244
  var valid_599245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599245 = validateParameter(valid_599245, JString, required = false,
                                 default = nil)
  if valid_599245 != nil:
    section.add "X-Amz-SignedHeaders", valid_599245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599247: Call_ListEndpointConfigs_599233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_599247.validator(path, query, header, formData, body)
  let scheme = call_599247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599247.url(scheme.get, call_599247.host, call_599247.base,
                         call_599247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599247, url, valid)

proc call*(call_599248: Call_ListEndpointConfigs_599233; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599249 = newJObject()
  var body_599250 = newJObject()
  add(query_599249, "MaxResults", newJString(MaxResults))
  add(query_599249, "NextToken", newJString(NextToken))
  if body != nil:
    body_599250 = body
  result = call_599248.call(nil, query_599249, nil, nil, body_599250)

var listEndpointConfigs* = Call_ListEndpointConfigs_599233(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_599234, base: "/",
    url: url_ListEndpointConfigs_599235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_599251 = ref object of OpenApiRestCall_597389
proc url_ListEndpoints_599253(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEndpoints_599252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599254 = query.getOrDefault("MaxResults")
  valid_599254 = validateParameter(valid_599254, JString, required = false,
                                 default = nil)
  if valid_599254 != nil:
    section.add "MaxResults", valid_599254
  var valid_599255 = query.getOrDefault("NextToken")
  valid_599255 = validateParameter(valid_599255, JString, required = false,
                                 default = nil)
  if valid_599255 != nil:
    section.add "NextToken", valid_599255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599256 = header.getOrDefault("X-Amz-Target")
  valid_599256 = validateParameter(valid_599256, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_599256 != nil:
    section.add "X-Amz-Target", valid_599256
  var valid_599257 = header.getOrDefault("X-Amz-Signature")
  valid_599257 = validateParameter(valid_599257, JString, required = false,
                                 default = nil)
  if valid_599257 != nil:
    section.add "X-Amz-Signature", valid_599257
  var valid_599258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599258 = validateParameter(valid_599258, JString, required = false,
                                 default = nil)
  if valid_599258 != nil:
    section.add "X-Amz-Content-Sha256", valid_599258
  var valid_599259 = header.getOrDefault("X-Amz-Date")
  valid_599259 = validateParameter(valid_599259, JString, required = false,
                                 default = nil)
  if valid_599259 != nil:
    section.add "X-Amz-Date", valid_599259
  var valid_599260 = header.getOrDefault("X-Amz-Credential")
  valid_599260 = validateParameter(valid_599260, JString, required = false,
                                 default = nil)
  if valid_599260 != nil:
    section.add "X-Amz-Credential", valid_599260
  var valid_599261 = header.getOrDefault("X-Amz-Security-Token")
  valid_599261 = validateParameter(valid_599261, JString, required = false,
                                 default = nil)
  if valid_599261 != nil:
    section.add "X-Amz-Security-Token", valid_599261
  var valid_599262 = header.getOrDefault("X-Amz-Algorithm")
  valid_599262 = validateParameter(valid_599262, JString, required = false,
                                 default = nil)
  if valid_599262 != nil:
    section.add "X-Amz-Algorithm", valid_599262
  var valid_599263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599263 = validateParameter(valid_599263, JString, required = false,
                                 default = nil)
  if valid_599263 != nil:
    section.add "X-Amz-SignedHeaders", valid_599263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599265: Call_ListEndpoints_599251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_599265.validator(path, query, header, formData, body)
  let scheme = call_599265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599265.url(scheme.get, call_599265.host, call_599265.base,
                         call_599265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599265, url, valid)

proc call*(call_599266: Call_ListEndpoints_599251; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599267 = newJObject()
  var body_599268 = newJObject()
  add(query_599267, "MaxResults", newJString(MaxResults))
  add(query_599267, "NextToken", newJString(NextToken))
  if body != nil:
    body_599268 = body
  result = call_599266.call(nil, query_599267, nil, nil, body_599268)

var listEndpoints* = Call_ListEndpoints_599251(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_599252, base: "/", url: url_ListEndpoints_599253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListExperiments_599269 = ref object of OpenApiRestCall_597389
proc url_ListExperiments_599271(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListExperiments_599270(path: JsonNode; query: JsonNode;
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
  var valid_599272 = query.getOrDefault("MaxResults")
  valid_599272 = validateParameter(valid_599272, JString, required = false,
                                 default = nil)
  if valid_599272 != nil:
    section.add "MaxResults", valid_599272
  var valid_599273 = query.getOrDefault("NextToken")
  valid_599273 = validateParameter(valid_599273, JString, required = false,
                                 default = nil)
  if valid_599273 != nil:
    section.add "NextToken", valid_599273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599274 = header.getOrDefault("X-Amz-Target")
  valid_599274 = validateParameter(valid_599274, JString, required = true, default = newJString(
      "SageMaker.ListExperiments"))
  if valid_599274 != nil:
    section.add "X-Amz-Target", valid_599274
  var valid_599275 = header.getOrDefault("X-Amz-Signature")
  valid_599275 = validateParameter(valid_599275, JString, required = false,
                                 default = nil)
  if valid_599275 != nil:
    section.add "X-Amz-Signature", valid_599275
  var valid_599276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599276 = validateParameter(valid_599276, JString, required = false,
                                 default = nil)
  if valid_599276 != nil:
    section.add "X-Amz-Content-Sha256", valid_599276
  var valid_599277 = header.getOrDefault("X-Amz-Date")
  valid_599277 = validateParameter(valid_599277, JString, required = false,
                                 default = nil)
  if valid_599277 != nil:
    section.add "X-Amz-Date", valid_599277
  var valid_599278 = header.getOrDefault("X-Amz-Credential")
  valid_599278 = validateParameter(valid_599278, JString, required = false,
                                 default = nil)
  if valid_599278 != nil:
    section.add "X-Amz-Credential", valid_599278
  var valid_599279 = header.getOrDefault("X-Amz-Security-Token")
  valid_599279 = validateParameter(valid_599279, JString, required = false,
                                 default = nil)
  if valid_599279 != nil:
    section.add "X-Amz-Security-Token", valid_599279
  var valid_599280 = header.getOrDefault("X-Amz-Algorithm")
  valid_599280 = validateParameter(valid_599280, JString, required = false,
                                 default = nil)
  if valid_599280 != nil:
    section.add "X-Amz-Algorithm", valid_599280
  var valid_599281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599281 = validateParameter(valid_599281, JString, required = false,
                                 default = nil)
  if valid_599281 != nil:
    section.add "X-Amz-SignedHeaders", valid_599281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599283: Call_ListExperiments_599269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ## 
  let valid = call_599283.validator(path, query, header, formData, body)
  let scheme = call_599283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599283.url(scheme.get, call_599283.host, call_599283.base,
                         call_599283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599283, url, valid)

proc call*(call_599284: Call_ListExperiments_599269; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listExperiments
  ## Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599285 = newJObject()
  var body_599286 = newJObject()
  add(query_599285, "MaxResults", newJString(MaxResults))
  add(query_599285, "NextToken", newJString(NextToken))
  if body != nil:
    body_599286 = body
  result = call_599284.call(nil, query_599285, nil, nil, body_599286)

var listExperiments* = Call_ListExperiments_599269(name: "listExperiments",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListExperiments",
    validator: validate_ListExperiments_599270, base: "/", url: url_ListExperiments_599271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlowDefinitions_599287 = ref object of OpenApiRestCall_597389
proc url_ListFlowDefinitions_599289(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlowDefinitions_599288(path: JsonNode; query: JsonNode;
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
  var valid_599290 = query.getOrDefault("MaxResults")
  valid_599290 = validateParameter(valid_599290, JString, required = false,
                                 default = nil)
  if valid_599290 != nil:
    section.add "MaxResults", valid_599290
  var valid_599291 = query.getOrDefault("NextToken")
  valid_599291 = validateParameter(valid_599291, JString, required = false,
                                 default = nil)
  if valid_599291 != nil:
    section.add "NextToken", valid_599291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599292 = header.getOrDefault("X-Amz-Target")
  valid_599292 = validateParameter(valid_599292, JString, required = true, default = newJString(
      "SageMaker.ListFlowDefinitions"))
  if valid_599292 != nil:
    section.add "X-Amz-Target", valid_599292
  var valid_599293 = header.getOrDefault("X-Amz-Signature")
  valid_599293 = validateParameter(valid_599293, JString, required = false,
                                 default = nil)
  if valid_599293 != nil:
    section.add "X-Amz-Signature", valid_599293
  var valid_599294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599294 = validateParameter(valid_599294, JString, required = false,
                                 default = nil)
  if valid_599294 != nil:
    section.add "X-Amz-Content-Sha256", valid_599294
  var valid_599295 = header.getOrDefault("X-Amz-Date")
  valid_599295 = validateParameter(valid_599295, JString, required = false,
                                 default = nil)
  if valid_599295 != nil:
    section.add "X-Amz-Date", valid_599295
  var valid_599296 = header.getOrDefault("X-Amz-Credential")
  valid_599296 = validateParameter(valid_599296, JString, required = false,
                                 default = nil)
  if valid_599296 != nil:
    section.add "X-Amz-Credential", valid_599296
  var valid_599297 = header.getOrDefault("X-Amz-Security-Token")
  valid_599297 = validateParameter(valid_599297, JString, required = false,
                                 default = nil)
  if valid_599297 != nil:
    section.add "X-Amz-Security-Token", valid_599297
  var valid_599298 = header.getOrDefault("X-Amz-Algorithm")
  valid_599298 = validateParameter(valid_599298, JString, required = false,
                                 default = nil)
  if valid_599298 != nil:
    section.add "X-Amz-Algorithm", valid_599298
  var valid_599299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599299 = validateParameter(valid_599299, JString, required = false,
                                 default = nil)
  if valid_599299 != nil:
    section.add "X-Amz-SignedHeaders", valid_599299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599301: Call_ListFlowDefinitions_599287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the flow definitions in your account.
  ## 
  let valid = call_599301.validator(path, query, header, formData, body)
  let scheme = call_599301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599301.url(scheme.get, call_599301.host, call_599301.base,
                         call_599301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599301, url, valid)

proc call*(call_599302: Call_ListFlowDefinitions_599287; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFlowDefinitions
  ## Returns information about the flow definitions in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599303 = newJObject()
  var body_599304 = newJObject()
  add(query_599303, "MaxResults", newJString(MaxResults))
  add(query_599303, "NextToken", newJString(NextToken))
  if body != nil:
    body_599304 = body
  result = call_599302.call(nil, query_599303, nil, nil, body_599304)

var listFlowDefinitions* = Call_ListFlowDefinitions_599287(
    name: "listFlowDefinitions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListFlowDefinitions",
    validator: validate_ListFlowDefinitions_599288, base: "/",
    url: url_ListFlowDefinitions_599289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanTaskUis_599305 = ref object of OpenApiRestCall_597389
proc url_ListHumanTaskUis_599307(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanTaskUis_599306(path: JsonNode; query: JsonNode;
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
  var valid_599308 = query.getOrDefault("MaxResults")
  valid_599308 = validateParameter(valid_599308, JString, required = false,
                                 default = nil)
  if valid_599308 != nil:
    section.add "MaxResults", valid_599308
  var valid_599309 = query.getOrDefault("NextToken")
  valid_599309 = validateParameter(valid_599309, JString, required = false,
                                 default = nil)
  if valid_599309 != nil:
    section.add "NextToken", valid_599309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599310 = header.getOrDefault("X-Amz-Target")
  valid_599310 = validateParameter(valid_599310, JString, required = true, default = newJString(
      "SageMaker.ListHumanTaskUis"))
  if valid_599310 != nil:
    section.add "X-Amz-Target", valid_599310
  var valid_599311 = header.getOrDefault("X-Amz-Signature")
  valid_599311 = validateParameter(valid_599311, JString, required = false,
                                 default = nil)
  if valid_599311 != nil:
    section.add "X-Amz-Signature", valid_599311
  var valid_599312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599312 = validateParameter(valid_599312, JString, required = false,
                                 default = nil)
  if valid_599312 != nil:
    section.add "X-Amz-Content-Sha256", valid_599312
  var valid_599313 = header.getOrDefault("X-Amz-Date")
  valid_599313 = validateParameter(valid_599313, JString, required = false,
                                 default = nil)
  if valid_599313 != nil:
    section.add "X-Amz-Date", valid_599313
  var valid_599314 = header.getOrDefault("X-Amz-Credential")
  valid_599314 = validateParameter(valid_599314, JString, required = false,
                                 default = nil)
  if valid_599314 != nil:
    section.add "X-Amz-Credential", valid_599314
  var valid_599315 = header.getOrDefault("X-Amz-Security-Token")
  valid_599315 = validateParameter(valid_599315, JString, required = false,
                                 default = nil)
  if valid_599315 != nil:
    section.add "X-Amz-Security-Token", valid_599315
  var valid_599316 = header.getOrDefault("X-Amz-Algorithm")
  valid_599316 = validateParameter(valid_599316, JString, required = false,
                                 default = nil)
  if valid_599316 != nil:
    section.add "X-Amz-Algorithm", valid_599316
  var valid_599317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599317 = validateParameter(valid_599317, JString, required = false,
                                 default = nil)
  if valid_599317 != nil:
    section.add "X-Amz-SignedHeaders", valid_599317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599319: Call_ListHumanTaskUis_599305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the human task user interfaces in your account.
  ## 
  let valid = call_599319.validator(path, query, header, formData, body)
  let scheme = call_599319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599319.url(scheme.get, call_599319.host, call_599319.base,
                         call_599319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599319, url, valid)

proc call*(call_599320: Call_ListHumanTaskUis_599305; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHumanTaskUis
  ## Returns information about the human task user interfaces in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599321 = newJObject()
  var body_599322 = newJObject()
  add(query_599321, "MaxResults", newJString(MaxResults))
  add(query_599321, "NextToken", newJString(NextToken))
  if body != nil:
    body_599322 = body
  result = call_599320.call(nil, query_599321, nil, nil, body_599322)

var listHumanTaskUis* = Call_ListHumanTaskUis_599305(name: "listHumanTaskUis",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHumanTaskUis",
    validator: validate_ListHumanTaskUis_599306, base: "/",
    url: url_ListHumanTaskUis_599307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_599323 = ref object of OpenApiRestCall_597389
proc url_ListHyperParameterTuningJobs_599325(protocol: Scheme; host: string;
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

proc validate_ListHyperParameterTuningJobs_599324(path: JsonNode; query: JsonNode;
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
  var valid_599326 = query.getOrDefault("MaxResults")
  valid_599326 = validateParameter(valid_599326, JString, required = false,
                                 default = nil)
  if valid_599326 != nil:
    section.add "MaxResults", valid_599326
  var valid_599327 = query.getOrDefault("NextToken")
  valid_599327 = validateParameter(valid_599327, JString, required = false,
                                 default = nil)
  if valid_599327 != nil:
    section.add "NextToken", valid_599327
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599328 = header.getOrDefault("X-Amz-Target")
  valid_599328 = validateParameter(valid_599328, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_599328 != nil:
    section.add "X-Amz-Target", valid_599328
  var valid_599329 = header.getOrDefault("X-Amz-Signature")
  valid_599329 = validateParameter(valid_599329, JString, required = false,
                                 default = nil)
  if valid_599329 != nil:
    section.add "X-Amz-Signature", valid_599329
  var valid_599330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599330 = validateParameter(valid_599330, JString, required = false,
                                 default = nil)
  if valid_599330 != nil:
    section.add "X-Amz-Content-Sha256", valid_599330
  var valid_599331 = header.getOrDefault("X-Amz-Date")
  valid_599331 = validateParameter(valid_599331, JString, required = false,
                                 default = nil)
  if valid_599331 != nil:
    section.add "X-Amz-Date", valid_599331
  var valid_599332 = header.getOrDefault("X-Amz-Credential")
  valid_599332 = validateParameter(valid_599332, JString, required = false,
                                 default = nil)
  if valid_599332 != nil:
    section.add "X-Amz-Credential", valid_599332
  var valid_599333 = header.getOrDefault("X-Amz-Security-Token")
  valid_599333 = validateParameter(valid_599333, JString, required = false,
                                 default = nil)
  if valid_599333 != nil:
    section.add "X-Amz-Security-Token", valid_599333
  var valid_599334 = header.getOrDefault("X-Amz-Algorithm")
  valid_599334 = validateParameter(valid_599334, JString, required = false,
                                 default = nil)
  if valid_599334 != nil:
    section.add "X-Amz-Algorithm", valid_599334
  var valid_599335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599335 = validateParameter(valid_599335, JString, required = false,
                                 default = nil)
  if valid_599335 != nil:
    section.add "X-Amz-SignedHeaders", valid_599335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599337: Call_ListHyperParameterTuningJobs_599323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_599337.validator(path, query, header, formData, body)
  let scheme = call_599337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599337.url(scheme.get, call_599337.host, call_599337.base,
                         call_599337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599337, url, valid)

proc call*(call_599338: Call_ListHyperParameterTuningJobs_599323; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599339 = newJObject()
  var body_599340 = newJObject()
  add(query_599339, "MaxResults", newJString(MaxResults))
  add(query_599339, "NextToken", newJString(NextToken))
  if body != nil:
    body_599340 = body
  result = call_599338.call(nil, query_599339, nil, nil, body_599340)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_599323(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_599324, base: "/",
    url: url_ListHyperParameterTuningJobs_599325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_599341 = ref object of OpenApiRestCall_597389
proc url_ListLabelingJobs_599343(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLabelingJobs_599342(path: JsonNode; query: JsonNode;
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
  var valid_599344 = query.getOrDefault("MaxResults")
  valid_599344 = validateParameter(valid_599344, JString, required = false,
                                 default = nil)
  if valid_599344 != nil:
    section.add "MaxResults", valid_599344
  var valid_599345 = query.getOrDefault("NextToken")
  valid_599345 = validateParameter(valid_599345, JString, required = false,
                                 default = nil)
  if valid_599345 != nil:
    section.add "NextToken", valid_599345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599346 = header.getOrDefault("X-Amz-Target")
  valid_599346 = validateParameter(valid_599346, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_599346 != nil:
    section.add "X-Amz-Target", valid_599346
  var valid_599347 = header.getOrDefault("X-Amz-Signature")
  valid_599347 = validateParameter(valid_599347, JString, required = false,
                                 default = nil)
  if valid_599347 != nil:
    section.add "X-Amz-Signature", valid_599347
  var valid_599348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599348 = validateParameter(valid_599348, JString, required = false,
                                 default = nil)
  if valid_599348 != nil:
    section.add "X-Amz-Content-Sha256", valid_599348
  var valid_599349 = header.getOrDefault("X-Amz-Date")
  valid_599349 = validateParameter(valid_599349, JString, required = false,
                                 default = nil)
  if valid_599349 != nil:
    section.add "X-Amz-Date", valid_599349
  var valid_599350 = header.getOrDefault("X-Amz-Credential")
  valid_599350 = validateParameter(valid_599350, JString, required = false,
                                 default = nil)
  if valid_599350 != nil:
    section.add "X-Amz-Credential", valid_599350
  var valid_599351 = header.getOrDefault("X-Amz-Security-Token")
  valid_599351 = validateParameter(valid_599351, JString, required = false,
                                 default = nil)
  if valid_599351 != nil:
    section.add "X-Amz-Security-Token", valid_599351
  var valid_599352 = header.getOrDefault("X-Amz-Algorithm")
  valid_599352 = validateParameter(valid_599352, JString, required = false,
                                 default = nil)
  if valid_599352 != nil:
    section.add "X-Amz-Algorithm", valid_599352
  var valid_599353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599353 = validateParameter(valid_599353, JString, required = false,
                                 default = nil)
  if valid_599353 != nil:
    section.add "X-Amz-SignedHeaders", valid_599353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599355: Call_ListLabelingJobs_599341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_599355.validator(path, query, header, formData, body)
  let scheme = call_599355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599355.url(scheme.get, call_599355.host, call_599355.base,
                         call_599355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599355, url, valid)

proc call*(call_599356: Call_ListLabelingJobs_599341; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599357 = newJObject()
  var body_599358 = newJObject()
  add(query_599357, "MaxResults", newJString(MaxResults))
  add(query_599357, "NextToken", newJString(NextToken))
  if body != nil:
    body_599358 = body
  result = call_599356.call(nil, query_599357, nil, nil, body_599358)

var listLabelingJobs* = Call_ListLabelingJobs_599341(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_599342, base: "/",
    url: url_ListLabelingJobs_599343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_599359 = ref object of OpenApiRestCall_597389
proc url_ListLabelingJobsForWorkteam_599361(protocol: Scheme; host: string;
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

proc validate_ListLabelingJobsForWorkteam_599360(path: JsonNode; query: JsonNode;
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
  var valid_599362 = query.getOrDefault("MaxResults")
  valid_599362 = validateParameter(valid_599362, JString, required = false,
                                 default = nil)
  if valid_599362 != nil:
    section.add "MaxResults", valid_599362
  var valid_599363 = query.getOrDefault("NextToken")
  valid_599363 = validateParameter(valid_599363, JString, required = false,
                                 default = nil)
  if valid_599363 != nil:
    section.add "NextToken", valid_599363
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599364 = header.getOrDefault("X-Amz-Target")
  valid_599364 = validateParameter(valid_599364, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_599364 != nil:
    section.add "X-Amz-Target", valid_599364
  var valid_599365 = header.getOrDefault("X-Amz-Signature")
  valid_599365 = validateParameter(valid_599365, JString, required = false,
                                 default = nil)
  if valid_599365 != nil:
    section.add "X-Amz-Signature", valid_599365
  var valid_599366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599366 = validateParameter(valid_599366, JString, required = false,
                                 default = nil)
  if valid_599366 != nil:
    section.add "X-Amz-Content-Sha256", valid_599366
  var valid_599367 = header.getOrDefault("X-Amz-Date")
  valid_599367 = validateParameter(valid_599367, JString, required = false,
                                 default = nil)
  if valid_599367 != nil:
    section.add "X-Amz-Date", valid_599367
  var valid_599368 = header.getOrDefault("X-Amz-Credential")
  valid_599368 = validateParameter(valid_599368, JString, required = false,
                                 default = nil)
  if valid_599368 != nil:
    section.add "X-Amz-Credential", valid_599368
  var valid_599369 = header.getOrDefault("X-Amz-Security-Token")
  valid_599369 = validateParameter(valid_599369, JString, required = false,
                                 default = nil)
  if valid_599369 != nil:
    section.add "X-Amz-Security-Token", valid_599369
  var valid_599370 = header.getOrDefault("X-Amz-Algorithm")
  valid_599370 = validateParameter(valid_599370, JString, required = false,
                                 default = nil)
  if valid_599370 != nil:
    section.add "X-Amz-Algorithm", valid_599370
  var valid_599371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599371 = validateParameter(valid_599371, JString, required = false,
                                 default = nil)
  if valid_599371 != nil:
    section.add "X-Amz-SignedHeaders", valid_599371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599373: Call_ListLabelingJobsForWorkteam_599359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_599373.validator(path, query, header, formData, body)
  let scheme = call_599373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599373.url(scheme.get, call_599373.host, call_599373.base,
                         call_599373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599373, url, valid)

proc call*(call_599374: Call_ListLabelingJobsForWorkteam_599359; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599375 = newJObject()
  var body_599376 = newJObject()
  add(query_599375, "MaxResults", newJString(MaxResults))
  add(query_599375, "NextToken", newJString(NextToken))
  if body != nil:
    body_599376 = body
  result = call_599374.call(nil, query_599375, nil, nil, body_599376)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_599359(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_599360, base: "/",
    url: url_ListLabelingJobsForWorkteam_599361,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_599377 = ref object of OpenApiRestCall_597389
proc url_ListModelPackages_599379(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListModelPackages_599378(path: JsonNode; query: JsonNode;
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
  var valid_599380 = query.getOrDefault("MaxResults")
  valid_599380 = validateParameter(valid_599380, JString, required = false,
                                 default = nil)
  if valid_599380 != nil:
    section.add "MaxResults", valid_599380
  var valid_599381 = query.getOrDefault("NextToken")
  valid_599381 = validateParameter(valid_599381, JString, required = false,
                                 default = nil)
  if valid_599381 != nil:
    section.add "NextToken", valid_599381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599382 = header.getOrDefault("X-Amz-Target")
  valid_599382 = validateParameter(valid_599382, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_599382 != nil:
    section.add "X-Amz-Target", valid_599382
  var valid_599383 = header.getOrDefault("X-Amz-Signature")
  valid_599383 = validateParameter(valid_599383, JString, required = false,
                                 default = nil)
  if valid_599383 != nil:
    section.add "X-Amz-Signature", valid_599383
  var valid_599384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599384 = validateParameter(valid_599384, JString, required = false,
                                 default = nil)
  if valid_599384 != nil:
    section.add "X-Amz-Content-Sha256", valid_599384
  var valid_599385 = header.getOrDefault("X-Amz-Date")
  valid_599385 = validateParameter(valid_599385, JString, required = false,
                                 default = nil)
  if valid_599385 != nil:
    section.add "X-Amz-Date", valid_599385
  var valid_599386 = header.getOrDefault("X-Amz-Credential")
  valid_599386 = validateParameter(valid_599386, JString, required = false,
                                 default = nil)
  if valid_599386 != nil:
    section.add "X-Amz-Credential", valid_599386
  var valid_599387 = header.getOrDefault("X-Amz-Security-Token")
  valid_599387 = validateParameter(valid_599387, JString, required = false,
                                 default = nil)
  if valid_599387 != nil:
    section.add "X-Amz-Security-Token", valid_599387
  var valid_599388 = header.getOrDefault("X-Amz-Algorithm")
  valid_599388 = validateParameter(valid_599388, JString, required = false,
                                 default = nil)
  if valid_599388 != nil:
    section.add "X-Amz-Algorithm", valid_599388
  var valid_599389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599389 = validateParameter(valid_599389, JString, required = false,
                                 default = nil)
  if valid_599389 != nil:
    section.add "X-Amz-SignedHeaders", valid_599389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599391: Call_ListModelPackages_599377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_599391.validator(path, query, header, formData, body)
  let scheme = call_599391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599391.url(scheme.get, call_599391.host, call_599391.base,
                         call_599391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599391, url, valid)

proc call*(call_599392: Call_ListModelPackages_599377; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599393 = newJObject()
  var body_599394 = newJObject()
  add(query_599393, "MaxResults", newJString(MaxResults))
  add(query_599393, "NextToken", newJString(NextToken))
  if body != nil:
    body_599394 = body
  result = call_599392.call(nil, query_599393, nil, nil, body_599394)

var listModelPackages* = Call_ListModelPackages_599377(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_599378, base: "/",
    url: url_ListModelPackages_599379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_599395 = ref object of OpenApiRestCall_597389
proc url_ListModels_599397(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListModels_599396(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599398 = query.getOrDefault("MaxResults")
  valid_599398 = validateParameter(valid_599398, JString, required = false,
                                 default = nil)
  if valid_599398 != nil:
    section.add "MaxResults", valid_599398
  var valid_599399 = query.getOrDefault("NextToken")
  valid_599399 = validateParameter(valid_599399, JString, required = false,
                                 default = nil)
  if valid_599399 != nil:
    section.add "NextToken", valid_599399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599400 = header.getOrDefault("X-Amz-Target")
  valid_599400 = validateParameter(valid_599400, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_599400 != nil:
    section.add "X-Amz-Target", valid_599400
  var valid_599401 = header.getOrDefault("X-Amz-Signature")
  valid_599401 = validateParameter(valid_599401, JString, required = false,
                                 default = nil)
  if valid_599401 != nil:
    section.add "X-Amz-Signature", valid_599401
  var valid_599402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599402 = validateParameter(valid_599402, JString, required = false,
                                 default = nil)
  if valid_599402 != nil:
    section.add "X-Amz-Content-Sha256", valid_599402
  var valid_599403 = header.getOrDefault("X-Amz-Date")
  valid_599403 = validateParameter(valid_599403, JString, required = false,
                                 default = nil)
  if valid_599403 != nil:
    section.add "X-Amz-Date", valid_599403
  var valid_599404 = header.getOrDefault("X-Amz-Credential")
  valid_599404 = validateParameter(valid_599404, JString, required = false,
                                 default = nil)
  if valid_599404 != nil:
    section.add "X-Amz-Credential", valid_599404
  var valid_599405 = header.getOrDefault("X-Amz-Security-Token")
  valid_599405 = validateParameter(valid_599405, JString, required = false,
                                 default = nil)
  if valid_599405 != nil:
    section.add "X-Amz-Security-Token", valid_599405
  var valid_599406 = header.getOrDefault("X-Amz-Algorithm")
  valid_599406 = validateParameter(valid_599406, JString, required = false,
                                 default = nil)
  if valid_599406 != nil:
    section.add "X-Amz-Algorithm", valid_599406
  var valid_599407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599407 = validateParameter(valid_599407, JString, required = false,
                                 default = nil)
  if valid_599407 != nil:
    section.add "X-Amz-SignedHeaders", valid_599407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599409: Call_ListModels_599395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_599409.validator(path, query, header, formData, body)
  let scheme = call_599409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599409.url(scheme.get, call_599409.host, call_599409.base,
                         call_599409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599409, url, valid)

proc call*(call_599410: Call_ListModels_599395; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599411 = newJObject()
  var body_599412 = newJObject()
  add(query_599411, "MaxResults", newJString(MaxResults))
  add(query_599411, "NextToken", newJString(NextToken))
  if body != nil:
    body_599412 = body
  result = call_599410.call(nil, query_599411, nil, nil, body_599412)

var listModels* = Call_ListModels_599395(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_599396,
                                      base: "/", url: url_ListModels_599397,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringExecutions_599413 = ref object of OpenApiRestCall_597389
proc url_ListMonitoringExecutions_599415(protocol: Scheme; host: string;
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

proc validate_ListMonitoringExecutions_599414(path: JsonNode; query: JsonNode;
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
  var valid_599416 = query.getOrDefault("MaxResults")
  valid_599416 = validateParameter(valid_599416, JString, required = false,
                                 default = nil)
  if valid_599416 != nil:
    section.add "MaxResults", valid_599416
  var valid_599417 = query.getOrDefault("NextToken")
  valid_599417 = validateParameter(valid_599417, JString, required = false,
                                 default = nil)
  if valid_599417 != nil:
    section.add "NextToken", valid_599417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599418 = header.getOrDefault("X-Amz-Target")
  valid_599418 = validateParameter(valid_599418, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringExecutions"))
  if valid_599418 != nil:
    section.add "X-Amz-Target", valid_599418
  var valid_599419 = header.getOrDefault("X-Amz-Signature")
  valid_599419 = validateParameter(valid_599419, JString, required = false,
                                 default = nil)
  if valid_599419 != nil:
    section.add "X-Amz-Signature", valid_599419
  var valid_599420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599420 = validateParameter(valid_599420, JString, required = false,
                                 default = nil)
  if valid_599420 != nil:
    section.add "X-Amz-Content-Sha256", valid_599420
  var valid_599421 = header.getOrDefault("X-Amz-Date")
  valid_599421 = validateParameter(valid_599421, JString, required = false,
                                 default = nil)
  if valid_599421 != nil:
    section.add "X-Amz-Date", valid_599421
  var valid_599422 = header.getOrDefault("X-Amz-Credential")
  valid_599422 = validateParameter(valid_599422, JString, required = false,
                                 default = nil)
  if valid_599422 != nil:
    section.add "X-Amz-Credential", valid_599422
  var valid_599423 = header.getOrDefault("X-Amz-Security-Token")
  valid_599423 = validateParameter(valid_599423, JString, required = false,
                                 default = nil)
  if valid_599423 != nil:
    section.add "X-Amz-Security-Token", valid_599423
  var valid_599424 = header.getOrDefault("X-Amz-Algorithm")
  valid_599424 = validateParameter(valid_599424, JString, required = false,
                                 default = nil)
  if valid_599424 != nil:
    section.add "X-Amz-Algorithm", valid_599424
  var valid_599425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599425 = validateParameter(valid_599425, JString, required = false,
                                 default = nil)
  if valid_599425 != nil:
    section.add "X-Amz-SignedHeaders", valid_599425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599427: Call_ListMonitoringExecutions_599413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring job executions.
  ## 
  let valid = call_599427.validator(path, query, header, formData, body)
  let scheme = call_599427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599427.url(scheme.get, call_599427.host, call_599427.base,
                         call_599427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599427, url, valid)

proc call*(call_599428: Call_ListMonitoringExecutions_599413; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringExecutions
  ## Returns list of all monitoring job executions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599429 = newJObject()
  var body_599430 = newJObject()
  add(query_599429, "MaxResults", newJString(MaxResults))
  add(query_599429, "NextToken", newJString(NextToken))
  if body != nil:
    body_599430 = body
  result = call_599428.call(nil, query_599429, nil, nil, body_599430)

var listMonitoringExecutions* = Call_ListMonitoringExecutions_599413(
    name: "listMonitoringExecutions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringExecutions",
    validator: validate_ListMonitoringExecutions_599414, base: "/",
    url: url_ListMonitoringExecutions_599415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMonitoringSchedules_599431 = ref object of OpenApiRestCall_597389
proc url_ListMonitoringSchedules_599433(protocol: Scheme; host: string; base: string;
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

proc validate_ListMonitoringSchedules_599432(path: JsonNode; query: JsonNode;
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
  var valid_599434 = query.getOrDefault("MaxResults")
  valid_599434 = validateParameter(valid_599434, JString, required = false,
                                 default = nil)
  if valid_599434 != nil:
    section.add "MaxResults", valid_599434
  var valid_599435 = query.getOrDefault("NextToken")
  valid_599435 = validateParameter(valid_599435, JString, required = false,
                                 default = nil)
  if valid_599435 != nil:
    section.add "NextToken", valid_599435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599436 = header.getOrDefault("X-Amz-Target")
  valid_599436 = validateParameter(valid_599436, JString, required = true, default = newJString(
      "SageMaker.ListMonitoringSchedules"))
  if valid_599436 != nil:
    section.add "X-Amz-Target", valid_599436
  var valid_599437 = header.getOrDefault("X-Amz-Signature")
  valid_599437 = validateParameter(valid_599437, JString, required = false,
                                 default = nil)
  if valid_599437 != nil:
    section.add "X-Amz-Signature", valid_599437
  var valid_599438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599438 = validateParameter(valid_599438, JString, required = false,
                                 default = nil)
  if valid_599438 != nil:
    section.add "X-Amz-Content-Sha256", valid_599438
  var valid_599439 = header.getOrDefault("X-Amz-Date")
  valid_599439 = validateParameter(valid_599439, JString, required = false,
                                 default = nil)
  if valid_599439 != nil:
    section.add "X-Amz-Date", valid_599439
  var valid_599440 = header.getOrDefault("X-Amz-Credential")
  valid_599440 = validateParameter(valid_599440, JString, required = false,
                                 default = nil)
  if valid_599440 != nil:
    section.add "X-Amz-Credential", valid_599440
  var valid_599441 = header.getOrDefault("X-Amz-Security-Token")
  valid_599441 = validateParameter(valid_599441, JString, required = false,
                                 default = nil)
  if valid_599441 != nil:
    section.add "X-Amz-Security-Token", valid_599441
  var valid_599442 = header.getOrDefault("X-Amz-Algorithm")
  valid_599442 = validateParameter(valid_599442, JString, required = false,
                                 default = nil)
  if valid_599442 != nil:
    section.add "X-Amz-Algorithm", valid_599442
  var valid_599443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599443 = validateParameter(valid_599443, JString, required = false,
                                 default = nil)
  if valid_599443 != nil:
    section.add "X-Amz-SignedHeaders", valid_599443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599445: Call_ListMonitoringSchedules_599431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns list of all monitoring schedules.
  ## 
  let valid = call_599445.validator(path, query, header, formData, body)
  let scheme = call_599445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599445.url(scheme.get, call_599445.host, call_599445.base,
                         call_599445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599445, url, valid)

proc call*(call_599446: Call_ListMonitoringSchedules_599431; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listMonitoringSchedules
  ## Returns list of all monitoring schedules.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599447 = newJObject()
  var body_599448 = newJObject()
  add(query_599447, "MaxResults", newJString(MaxResults))
  add(query_599447, "NextToken", newJString(NextToken))
  if body != nil:
    body_599448 = body
  result = call_599446.call(nil, query_599447, nil, nil, body_599448)

var listMonitoringSchedules* = Call_ListMonitoringSchedules_599431(
    name: "listMonitoringSchedules", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListMonitoringSchedules",
    validator: validate_ListMonitoringSchedules_599432, base: "/",
    url: url_ListMonitoringSchedules_599433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_599449 = ref object of OpenApiRestCall_597389
proc url_ListNotebookInstanceLifecycleConfigs_599451(protocol: Scheme;
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

proc validate_ListNotebookInstanceLifecycleConfigs_599450(path: JsonNode;
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
  var valid_599452 = query.getOrDefault("MaxResults")
  valid_599452 = validateParameter(valid_599452, JString, required = false,
                                 default = nil)
  if valid_599452 != nil:
    section.add "MaxResults", valid_599452
  var valid_599453 = query.getOrDefault("NextToken")
  valid_599453 = validateParameter(valid_599453, JString, required = false,
                                 default = nil)
  if valid_599453 != nil:
    section.add "NextToken", valid_599453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599454 = header.getOrDefault("X-Amz-Target")
  valid_599454 = validateParameter(valid_599454, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_599454 != nil:
    section.add "X-Amz-Target", valid_599454
  var valid_599455 = header.getOrDefault("X-Amz-Signature")
  valid_599455 = validateParameter(valid_599455, JString, required = false,
                                 default = nil)
  if valid_599455 != nil:
    section.add "X-Amz-Signature", valid_599455
  var valid_599456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599456 = validateParameter(valid_599456, JString, required = false,
                                 default = nil)
  if valid_599456 != nil:
    section.add "X-Amz-Content-Sha256", valid_599456
  var valid_599457 = header.getOrDefault("X-Amz-Date")
  valid_599457 = validateParameter(valid_599457, JString, required = false,
                                 default = nil)
  if valid_599457 != nil:
    section.add "X-Amz-Date", valid_599457
  var valid_599458 = header.getOrDefault("X-Amz-Credential")
  valid_599458 = validateParameter(valid_599458, JString, required = false,
                                 default = nil)
  if valid_599458 != nil:
    section.add "X-Amz-Credential", valid_599458
  var valid_599459 = header.getOrDefault("X-Amz-Security-Token")
  valid_599459 = validateParameter(valid_599459, JString, required = false,
                                 default = nil)
  if valid_599459 != nil:
    section.add "X-Amz-Security-Token", valid_599459
  var valid_599460 = header.getOrDefault("X-Amz-Algorithm")
  valid_599460 = validateParameter(valid_599460, JString, required = false,
                                 default = nil)
  if valid_599460 != nil:
    section.add "X-Amz-Algorithm", valid_599460
  var valid_599461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599461 = validateParameter(valid_599461, JString, required = false,
                                 default = nil)
  if valid_599461 != nil:
    section.add "X-Amz-SignedHeaders", valid_599461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599463: Call_ListNotebookInstanceLifecycleConfigs_599449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_599463.validator(path, query, header, formData, body)
  let scheme = call_599463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599463.url(scheme.get, call_599463.host, call_599463.base,
                         call_599463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599463, url, valid)

proc call*(call_599464: Call_ListNotebookInstanceLifecycleConfigs_599449;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599465 = newJObject()
  var body_599466 = newJObject()
  add(query_599465, "MaxResults", newJString(MaxResults))
  add(query_599465, "NextToken", newJString(NextToken))
  if body != nil:
    body_599466 = body
  result = call_599464.call(nil, query_599465, nil, nil, body_599466)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_599449(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_599450, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_599451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_599467 = ref object of OpenApiRestCall_597389
proc url_ListNotebookInstances_599469(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListNotebookInstances_599468(path: JsonNode; query: JsonNode;
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
  var valid_599470 = query.getOrDefault("MaxResults")
  valid_599470 = validateParameter(valid_599470, JString, required = false,
                                 default = nil)
  if valid_599470 != nil:
    section.add "MaxResults", valid_599470
  var valid_599471 = query.getOrDefault("NextToken")
  valid_599471 = validateParameter(valid_599471, JString, required = false,
                                 default = nil)
  if valid_599471 != nil:
    section.add "NextToken", valid_599471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599472 = header.getOrDefault("X-Amz-Target")
  valid_599472 = validateParameter(valid_599472, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_599472 != nil:
    section.add "X-Amz-Target", valid_599472
  var valid_599473 = header.getOrDefault("X-Amz-Signature")
  valid_599473 = validateParameter(valid_599473, JString, required = false,
                                 default = nil)
  if valid_599473 != nil:
    section.add "X-Amz-Signature", valid_599473
  var valid_599474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599474 = validateParameter(valid_599474, JString, required = false,
                                 default = nil)
  if valid_599474 != nil:
    section.add "X-Amz-Content-Sha256", valid_599474
  var valid_599475 = header.getOrDefault("X-Amz-Date")
  valid_599475 = validateParameter(valid_599475, JString, required = false,
                                 default = nil)
  if valid_599475 != nil:
    section.add "X-Amz-Date", valid_599475
  var valid_599476 = header.getOrDefault("X-Amz-Credential")
  valid_599476 = validateParameter(valid_599476, JString, required = false,
                                 default = nil)
  if valid_599476 != nil:
    section.add "X-Amz-Credential", valid_599476
  var valid_599477 = header.getOrDefault("X-Amz-Security-Token")
  valid_599477 = validateParameter(valid_599477, JString, required = false,
                                 default = nil)
  if valid_599477 != nil:
    section.add "X-Amz-Security-Token", valid_599477
  var valid_599478 = header.getOrDefault("X-Amz-Algorithm")
  valid_599478 = validateParameter(valid_599478, JString, required = false,
                                 default = nil)
  if valid_599478 != nil:
    section.add "X-Amz-Algorithm", valid_599478
  var valid_599479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599479 = validateParameter(valid_599479, JString, required = false,
                                 default = nil)
  if valid_599479 != nil:
    section.add "X-Amz-SignedHeaders", valid_599479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599481: Call_ListNotebookInstances_599467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_599481.validator(path, query, header, formData, body)
  let scheme = call_599481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599481.url(scheme.get, call_599481.host, call_599481.base,
                         call_599481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599481, url, valid)

proc call*(call_599482: Call_ListNotebookInstances_599467; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599483 = newJObject()
  var body_599484 = newJObject()
  add(query_599483, "MaxResults", newJString(MaxResults))
  add(query_599483, "NextToken", newJString(NextToken))
  if body != nil:
    body_599484 = body
  result = call_599482.call(nil, query_599483, nil, nil, body_599484)

var listNotebookInstances* = Call_ListNotebookInstances_599467(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_599468, base: "/",
    url: url_ListNotebookInstances_599469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProcessingJobs_599485 = ref object of OpenApiRestCall_597389
proc url_ListProcessingJobs_599487(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProcessingJobs_599486(path: JsonNode; query: JsonNode;
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
  var valid_599488 = query.getOrDefault("MaxResults")
  valid_599488 = validateParameter(valid_599488, JString, required = false,
                                 default = nil)
  if valid_599488 != nil:
    section.add "MaxResults", valid_599488
  var valid_599489 = query.getOrDefault("NextToken")
  valid_599489 = validateParameter(valid_599489, JString, required = false,
                                 default = nil)
  if valid_599489 != nil:
    section.add "NextToken", valid_599489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599490 = header.getOrDefault("X-Amz-Target")
  valid_599490 = validateParameter(valid_599490, JString, required = true, default = newJString(
      "SageMaker.ListProcessingJobs"))
  if valid_599490 != nil:
    section.add "X-Amz-Target", valid_599490
  var valid_599491 = header.getOrDefault("X-Amz-Signature")
  valid_599491 = validateParameter(valid_599491, JString, required = false,
                                 default = nil)
  if valid_599491 != nil:
    section.add "X-Amz-Signature", valid_599491
  var valid_599492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599492 = validateParameter(valid_599492, JString, required = false,
                                 default = nil)
  if valid_599492 != nil:
    section.add "X-Amz-Content-Sha256", valid_599492
  var valid_599493 = header.getOrDefault("X-Amz-Date")
  valid_599493 = validateParameter(valid_599493, JString, required = false,
                                 default = nil)
  if valid_599493 != nil:
    section.add "X-Amz-Date", valid_599493
  var valid_599494 = header.getOrDefault("X-Amz-Credential")
  valid_599494 = validateParameter(valid_599494, JString, required = false,
                                 default = nil)
  if valid_599494 != nil:
    section.add "X-Amz-Credential", valid_599494
  var valid_599495 = header.getOrDefault("X-Amz-Security-Token")
  valid_599495 = validateParameter(valid_599495, JString, required = false,
                                 default = nil)
  if valid_599495 != nil:
    section.add "X-Amz-Security-Token", valid_599495
  var valid_599496 = header.getOrDefault("X-Amz-Algorithm")
  valid_599496 = validateParameter(valid_599496, JString, required = false,
                                 default = nil)
  if valid_599496 != nil:
    section.add "X-Amz-Algorithm", valid_599496
  var valid_599497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599497 = validateParameter(valid_599497, JString, required = false,
                                 default = nil)
  if valid_599497 != nil:
    section.add "X-Amz-SignedHeaders", valid_599497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599499: Call_ListProcessingJobs_599485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists processing jobs that satisfy various filters.
  ## 
  let valid = call_599499.validator(path, query, header, formData, body)
  let scheme = call_599499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599499.url(scheme.get, call_599499.host, call_599499.base,
                         call_599499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599499, url, valid)

proc call*(call_599500: Call_ListProcessingJobs_599485; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProcessingJobs
  ## Lists processing jobs that satisfy various filters.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599501 = newJObject()
  var body_599502 = newJObject()
  add(query_599501, "MaxResults", newJString(MaxResults))
  add(query_599501, "NextToken", newJString(NextToken))
  if body != nil:
    body_599502 = body
  result = call_599500.call(nil, query_599501, nil, nil, body_599502)

var listProcessingJobs* = Call_ListProcessingJobs_599485(
    name: "listProcessingJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListProcessingJobs",
    validator: validate_ListProcessingJobs_599486, base: "/",
    url: url_ListProcessingJobs_599487, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_599503 = ref object of OpenApiRestCall_597389
proc url_ListSubscribedWorkteams_599505(protocol: Scheme; host: string; base: string;
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

proc validate_ListSubscribedWorkteams_599504(path: JsonNode; query: JsonNode;
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
  var valid_599506 = query.getOrDefault("MaxResults")
  valid_599506 = validateParameter(valid_599506, JString, required = false,
                                 default = nil)
  if valid_599506 != nil:
    section.add "MaxResults", valid_599506
  var valid_599507 = query.getOrDefault("NextToken")
  valid_599507 = validateParameter(valid_599507, JString, required = false,
                                 default = nil)
  if valid_599507 != nil:
    section.add "NextToken", valid_599507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599508 = header.getOrDefault("X-Amz-Target")
  valid_599508 = validateParameter(valid_599508, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_599508 != nil:
    section.add "X-Amz-Target", valid_599508
  var valid_599509 = header.getOrDefault("X-Amz-Signature")
  valid_599509 = validateParameter(valid_599509, JString, required = false,
                                 default = nil)
  if valid_599509 != nil:
    section.add "X-Amz-Signature", valid_599509
  var valid_599510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599510 = validateParameter(valid_599510, JString, required = false,
                                 default = nil)
  if valid_599510 != nil:
    section.add "X-Amz-Content-Sha256", valid_599510
  var valid_599511 = header.getOrDefault("X-Amz-Date")
  valid_599511 = validateParameter(valid_599511, JString, required = false,
                                 default = nil)
  if valid_599511 != nil:
    section.add "X-Amz-Date", valid_599511
  var valid_599512 = header.getOrDefault("X-Amz-Credential")
  valid_599512 = validateParameter(valid_599512, JString, required = false,
                                 default = nil)
  if valid_599512 != nil:
    section.add "X-Amz-Credential", valid_599512
  var valid_599513 = header.getOrDefault("X-Amz-Security-Token")
  valid_599513 = validateParameter(valid_599513, JString, required = false,
                                 default = nil)
  if valid_599513 != nil:
    section.add "X-Amz-Security-Token", valid_599513
  var valid_599514 = header.getOrDefault("X-Amz-Algorithm")
  valid_599514 = validateParameter(valid_599514, JString, required = false,
                                 default = nil)
  if valid_599514 != nil:
    section.add "X-Amz-Algorithm", valid_599514
  var valid_599515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599515 = validateParameter(valid_599515, JString, required = false,
                                 default = nil)
  if valid_599515 != nil:
    section.add "X-Amz-SignedHeaders", valid_599515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599517: Call_ListSubscribedWorkteams_599503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_599517.validator(path, query, header, formData, body)
  let scheme = call_599517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599517.url(scheme.get, call_599517.host, call_599517.base,
                         call_599517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599517, url, valid)

proc call*(call_599518: Call_ListSubscribedWorkteams_599503; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599519 = newJObject()
  var body_599520 = newJObject()
  add(query_599519, "MaxResults", newJString(MaxResults))
  add(query_599519, "NextToken", newJString(NextToken))
  if body != nil:
    body_599520 = body
  result = call_599518.call(nil, query_599519, nil, nil, body_599520)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_599503(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_599504, base: "/",
    url: url_ListSubscribedWorkteams_599505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_599521 = ref object of OpenApiRestCall_597389
proc url_ListTags_599523(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_599522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599524 = query.getOrDefault("MaxResults")
  valid_599524 = validateParameter(valid_599524, JString, required = false,
                                 default = nil)
  if valid_599524 != nil:
    section.add "MaxResults", valid_599524
  var valid_599525 = query.getOrDefault("NextToken")
  valid_599525 = validateParameter(valid_599525, JString, required = false,
                                 default = nil)
  if valid_599525 != nil:
    section.add "NextToken", valid_599525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599526 = header.getOrDefault("X-Amz-Target")
  valid_599526 = validateParameter(valid_599526, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_599526 != nil:
    section.add "X-Amz-Target", valid_599526
  var valid_599527 = header.getOrDefault("X-Amz-Signature")
  valid_599527 = validateParameter(valid_599527, JString, required = false,
                                 default = nil)
  if valid_599527 != nil:
    section.add "X-Amz-Signature", valid_599527
  var valid_599528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599528 = validateParameter(valid_599528, JString, required = false,
                                 default = nil)
  if valid_599528 != nil:
    section.add "X-Amz-Content-Sha256", valid_599528
  var valid_599529 = header.getOrDefault("X-Amz-Date")
  valid_599529 = validateParameter(valid_599529, JString, required = false,
                                 default = nil)
  if valid_599529 != nil:
    section.add "X-Amz-Date", valid_599529
  var valid_599530 = header.getOrDefault("X-Amz-Credential")
  valid_599530 = validateParameter(valid_599530, JString, required = false,
                                 default = nil)
  if valid_599530 != nil:
    section.add "X-Amz-Credential", valid_599530
  var valid_599531 = header.getOrDefault("X-Amz-Security-Token")
  valid_599531 = validateParameter(valid_599531, JString, required = false,
                                 default = nil)
  if valid_599531 != nil:
    section.add "X-Amz-Security-Token", valid_599531
  var valid_599532 = header.getOrDefault("X-Amz-Algorithm")
  valid_599532 = validateParameter(valid_599532, JString, required = false,
                                 default = nil)
  if valid_599532 != nil:
    section.add "X-Amz-Algorithm", valid_599532
  var valid_599533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599533 = validateParameter(valid_599533, JString, required = false,
                                 default = nil)
  if valid_599533 != nil:
    section.add "X-Amz-SignedHeaders", valid_599533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599535: Call_ListTags_599521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_599535.validator(path, query, header, formData, body)
  let scheme = call_599535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599535.url(scheme.get, call_599535.host, call_599535.base,
                         call_599535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599535, url, valid)

proc call*(call_599536: Call_ListTags_599521; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599537 = newJObject()
  var body_599538 = newJObject()
  add(query_599537, "MaxResults", newJString(MaxResults))
  add(query_599537, "NextToken", newJString(NextToken))
  if body != nil:
    body_599538 = body
  result = call_599536.call(nil, query_599537, nil, nil, body_599538)

var listTags* = Call_ListTags_599521(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_599522, base: "/",
                                  url: url_ListTags_599523,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_599539 = ref object of OpenApiRestCall_597389
proc url_ListTrainingJobs_599541(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrainingJobs_599540(path: JsonNode; query: JsonNode;
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
  var valid_599542 = query.getOrDefault("MaxResults")
  valid_599542 = validateParameter(valid_599542, JString, required = false,
                                 default = nil)
  if valid_599542 != nil:
    section.add "MaxResults", valid_599542
  var valid_599543 = query.getOrDefault("NextToken")
  valid_599543 = validateParameter(valid_599543, JString, required = false,
                                 default = nil)
  if valid_599543 != nil:
    section.add "NextToken", valid_599543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599544 = header.getOrDefault("X-Amz-Target")
  valid_599544 = validateParameter(valid_599544, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_599544 != nil:
    section.add "X-Amz-Target", valid_599544
  var valid_599545 = header.getOrDefault("X-Amz-Signature")
  valid_599545 = validateParameter(valid_599545, JString, required = false,
                                 default = nil)
  if valid_599545 != nil:
    section.add "X-Amz-Signature", valid_599545
  var valid_599546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599546 = validateParameter(valid_599546, JString, required = false,
                                 default = nil)
  if valid_599546 != nil:
    section.add "X-Amz-Content-Sha256", valid_599546
  var valid_599547 = header.getOrDefault("X-Amz-Date")
  valid_599547 = validateParameter(valid_599547, JString, required = false,
                                 default = nil)
  if valid_599547 != nil:
    section.add "X-Amz-Date", valid_599547
  var valid_599548 = header.getOrDefault("X-Amz-Credential")
  valid_599548 = validateParameter(valid_599548, JString, required = false,
                                 default = nil)
  if valid_599548 != nil:
    section.add "X-Amz-Credential", valid_599548
  var valid_599549 = header.getOrDefault("X-Amz-Security-Token")
  valid_599549 = validateParameter(valid_599549, JString, required = false,
                                 default = nil)
  if valid_599549 != nil:
    section.add "X-Amz-Security-Token", valid_599549
  var valid_599550 = header.getOrDefault("X-Amz-Algorithm")
  valid_599550 = validateParameter(valid_599550, JString, required = false,
                                 default = nil)
  if valid_599550 != nil:
    section.add "X-Amz-Algorithm", valid_599550
  var valid_599551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599551 = validateParameter(valid_599551, JString, required = false,
                                 default = nil)
  if valid_599551 != nil:
    section.add "X-Amz-SignedHeaders", valid_599551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599553: Call_ListTrainingJobs_599539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_599553.validator(path, query, header, formData, body)
  let scheme = call_599553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599553.url(scheme.get, call_599553.host, call_599553.base,
                         call_599553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599553, url, valid)

proc call*(call_599554: Call_ListTrainingJobs_599539; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599555 = newJObject()
  var body_599556 = newJObject()
  add(query_599555, "MaxResults", newJString(MaxResults))
  add(query_599555, "NextToken", newJString(NextToken))
  if body != nil:
    body_599556 = body
  result = call_599554.call(nil, query_599555, nil, nil, body_599556)

var listTrainingJobs* = Call_ListTrainingJobs_599539(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_599540, base: "/",
    url: url_ListTrainingJobs_599541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_599557 = ref object of OpenApiRestCall_597389
proc url_ListTrainingJobsForHyperParameterTuningJob_599559(protocol: Scheme;
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

proc validate_ListTrainingJobsForHyperParameterTuningJob_599558(path: JsonNode;
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
  var valid_599560 = query.getOrDefault("MaxResults")
  valid_599560 = validateParameter(valid_599560, JString, required = false,
                                 default = nil)
  if valid_599560 != nil:
    section.add "MaxResults", valid_599560
  var valid_599561 = query.getOrDefault("NextToken")
  valid_599561 = validateParameter(valid_599561, JString, required = false,
                                 default = nil)
  if valid_599561 != nil:
    section.add "NextToken", valid_599561
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599562 = header.getOrDefault("X-Amz-Target")
  valid_599562 = validateParameter(valid_599562, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_599562 != nil:
    section.add "X-Amz-Target", valid_599562
  var valid_599563 = header.getOrDefault("X-Amz-Signature")
  valid_599563 = validateParameter(valid_599563, JString, required = false,
                                 default = nil)
  if valid_599563 != nil:
    section.add "X-Amz-Signature", valid_599563
  var valid_599564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599564 = validateParameter(valid_599564, JString, required = false,
                                 default = nil)
  if valid_599564 != nil:
    section.add "X-Amz-Content-Sha256", valid_599564
  var valid_599565 = header.getOrDefault("X-Amz-Date")
  valid_599565 = validateParameter(valid_599565, JString, required = false,
                                 default = nil)
  if valid_599565 != nil:
    section.add "X-Amz-Date", valid_599565
  var valid_599566 = header.getOrDefault("X-Amz-Credential")
  valid_599566 = validateParameter(valid_599566, JString, required = false,
                                 default = nil)
  if valid_599566 != nil:
    section.add "X-Amz-Credential", valid_599566
  var valid_599567 = header.getOrDefault("X-Amz-Security-Token")
  valid_599567 = validateParameter(valid_599567, JString, required = false,
                                 default = nil)
  if valid_599567 != nil:
    section.add "X-Amz-Security-Token", valid_599567
  var valid_599568 = header.getOrDefault("X-Amz-Algorithm")
  valid_599568 = validateParameter(valid_599568, JString, required = false,
                                 default = nil)
  if valid_599568 != nil:
    section.add "X-Amz-Algorithm", valid_599568
  var valid_599569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599569 = validateParameter(valid_599569, JString, required = false,
                                 default = nil)
  if valid_599569 != nil:
    section.add "X-Amz-SignedHeaders", valid_599569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599571: Call_ListTrainingJobsForHyperParameterTuningJob_599557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_599571.validator(path, query, header, formData, body)
  let scheme = call_599571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599571.url(scheme.get, call_599571.host, call_599571.base,
                         call_599571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599571, url, valid)

proc call*(call_599572: Call_ListTrainingJobsForHyperParameterTuningJob_599557;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599573 = newJObject()
  var body_599574 = newJObject()
  add(query_599573, "MaxResults", newJString(MaxResults))
  add(query_599573, "NextToken", newJString(NextToken))
  if body != nil:
    body_599574 = body
  result = call_599572.call(nil, query_599573, nil, nil, body_599574)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_599557(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_599558,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_599559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_599575 = ref object of OpenApiRestCall_597389
proc url_ListTransformJobs_599577(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTransformJobs_599576(path: JsonNode; query: JsonNode;
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
  var valid_599578 = query.getOrDefault("MaxResults")
  valid_599578 = validateParameter(valid_599578, JString, required = false,
                                 default = nil)
  if valid_599578 != nil:
    section.add "MaxResults", valid_599578
  var valid_599579 = query.getOrDefault("NextToken")
  valid_599579 = validateParameter(valid_599579, JString, required = false,
                                 default = nil)
  if valid_599579 != nil:
    section.add "NextToken", valid_599579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599580 = header.getOrDefault("X-Amz-Target")
  valid_599580 = validateParameter(valid_599580, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_599580 != nil:
    section.add "X-Amz-Target", valid_599580
  var valid_599581 = header.getOrDefault("X-Amz-Signature")
  valid_599581 = validateParameter(valid_599581, JString, required = false,
                                 default = nil)
  if valid_599581 != nil:
    section.add "X-Amz-Signature", valid_599581
  var valid_599582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599582 = validateParameter(valid_599582, JString, required = false,
                                 default = nil)
  if valid_599582 != nil:
    section.add "X-Amz-Content-Sha256", valid_599582
  var valid_599583 = header.getOrDefault("X-Amz-Date")
  valid_599583 = validateParameter(valid_599583, JString, required = false,
                                 default = nil)
  if valid_599583 != nil:
    section.add "X-Amz-Date", valid_599583
  var valid_599584 = header.getOrDefault("X-Amz-Credential")
  valid_599584 = validateParameter(valid_599584, JString, required = false,
                                 default = nil)
  if valid_599584 != nil:
    section.add "X-Amz-Credential", valid_599584
  var valid_599585 = header.getOrDefault("X-Amz-Security-Token")
  valid_599585 = validateParameter(valid_599585, JString, required = false,
                                 default = nil)
  if valid_599585 != nil:
    section.add "X-Amz-Security-Token", valid_599585
  var valid_599586 = header.getOrDefault("X-Amz-Algorithm")
  valid_599586 = validateParameter(valid_599586, JString, required = false,
                                 default = nil)
  if valid_599586 != nil:
    section.add "X-Amz-Algorithm", valid_599586
  var valid_599587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599587 = validateParameter(valid_599587, JString, required = false,
                                 default = nil)
  if valid_599587 != nil:
    section.add "X-Amz-SignedHeaders", valid_599587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599589: Call_ListTransformJobs_599575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_599589.validator(path, query, header, formData, body)
  let scheme = call_599589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599589.url(scheme.get, call_599589.host, call_599589.base,
                         call_599589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599589, url, valid)

proc call*(call_599590: Call_ListTransformJobs_599575; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599591 = newJObject()
  var body_599592 = newJObject()
  add(query_599591, "MaxResults", newJString(MaxResults))
  add(query_599591, "NextToken", newJString(NextToken))
  if body != nil:
    body_599592 = body
  result = call_599590.call(nil, query_599591, nil, nil, body_599592)

var listTransformJobs* = Call_ListTransformJobs_599575(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_599576, base: "/",
    url: url_ListTransformJobs_599577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrialComponents_599593 = ref object of OpenApiRestCall_597389
proc url_ListTrialComponents_599595(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrialComponents_599594(path: JsonNode; query: JsonNode;
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
  var valid_599596 = query.getOrDefault("MaxResults")
  valid_599596 = validateParameter(valid_599596, JString, required = false,
                                 default = nil)
  if valid_599596 != nil:
    section.add "MaxResults", valid_599596
  var valid_599597 = query.getOrDefault("NextToken")
  valid_599597 = validateParameter(valid_599597, JString, required = false,
                                 default = nil)
  if valid_599597 != nil:
    section.add "NextToken", valid_599597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599598 = header.getOrDefault("X-Amz-Target")
  valid_599598 = validateParameter(valid_599598, JString, required = true, default = newJString(
      "SageMaker.ListTrialComponents"))
  if valid_599598 != nil:
    section.add "X-Amz-Target", valid_599598
  var valid_599599 = header.getOrDefault("X-Amz-Signature")
  valid_599599 = validateParameter(valid_599599, JString, required = false,
                                 default = nil)
  if valid_599599 != nil:
    section.add "X-Amz-Signature", valid_599599
  var valid_599600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599600 = validateParameter(valid_599600, JString, required = false,
                                 default = nil)
  if valid_599600 != nil:
    section.add "X-Amz-Content-Sha256", valid_599600
  var valid_599601 = header.getOrDefault("X-Amz-Date")
  valid_599601 = validateParameter(valid_599601, JString, required = false,
                                 default = nil)
  if valid_599601 != nil:
    section.add "X-Amz-Date", valid_599601
  var valid_599602 = header.getOrDefault("X-Amz-Credential")
  valid_599602 = validateParameter(valid_599602, JString, required = false,
                                 default = nil)
  if valid_599602 != nil:
    section.add "X-Amz-Credential", valid_599602
  var valid_599603 = header.getOrDefault("X-Amz-Security-Token")
  valid_599603 = validateParameter(valid_599603, JString, required = false,
                                 default = nil)
  if valid_599603 != nil:
    section.add "X-Amz-Security-Token", valid_599603
  var valid_599604 = header.getOrDefault("X-Amz-Algorithm")
  valid_599604 = validateParameter(valid_599604, JString, required = false,
                                 default = nil)
  if valid_599604 != nil:
    section.add "X-Amz-Algorithm", valid_599604
  var valid_599605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599605 = validateParameter(valid_599605, JString, required = false,
                                 default = nil)
  if valid_599605 != nil:
    section.add "X-Amz-SignedHeaders", valid_599605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599607: Call_ListTrialComponents_599593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ## 
  let valid = call_599607.validator(path, query, header, formData, body)
  let scheme = call_599607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599607.url(scheme.get, call_599607.host, call_599607.base,
                         call_599607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599607, url, valid)

proc call*(call_599608: Call_ListTrialComponents_599593; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrialComponents
  ## Lists the trial components in your account. You can filter the list to show only components that were created in a specific time range. You can sort the list by trial component name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599609 = newJObject()
  var body_599610 = newJObject()
  add(query_599609, "MaxResults", newJString(MaxResults))
  add(query_599609, "NextToken", newJString(NextToken))
  if body != nil:
    body_599610 = body
  result = call_599608.call(nil, query_599609, nil, nil, body_599610)

var listTrialComponents* = Call_ListTrialComponents_599593(
    name: "listTrialComponents", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrialComponents",
    validator: validate_ListTrialComponents_599594, base: "/",
    url: url_ListTrialComponents_599595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrials_599611 = ref object of OpenApiRestCall_597389
proc url_ListTrials_599613(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTrials_599612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599614 = query.getOrDefault("MaxResults")
  valid_599614 = validateParameter(valid_599614, JString, required = false,
                                 default = nil)
  if valid_599614 != nil:
    section.add "MaxResults", valid_599614
  var valid_599615 = query.getOrDefault("NextToken")
  valid_599615 = validateParameter(valid_599615, JString, required = false,
                                 default = nil)
  if valid_599615 != nil:
    section.add "NextToken", valid_599615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599616 = header.getOrDefault("X-Amz-Target")
  valid_599616 = validateParameter(valid_599616, JString, required = true,
                                 default = newJString("SageMaker.ListTrials"))
  if valid_599616 != nil:
    section.add "X-Amz-Target", valid_599616
  var valid_599617 = header.getOrDefault("X-Amz-Signature")
  valid_599617 = validateParameter(valid_599617, JString, required = false,
                                 default = nil)
  if valid_599617 != nil:
    section.add "X-Amz-Signature", valid_599617
  var valid_599618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599618 = validateParameter(valid_599618, JString, required = false,
                                 default = nil)
  if valid_599618 != nil:
    section.add "X-Amz-Content-Sha256", valid_599618
  var valid_599619 = header.getOrDefault("X-Amz-Date")
  valid_599619 = validateParameter(valid_599619, JString, required = false,
                                 default = nil)
  if valid_599619 != nil:
    section.add "X-Amz-Date", valid_599619
  var valid_599620 = header.getOrDefault("X-Amz-Credential")
  valid_599620 = validateParameter(valid_599620, JString, required = false,
                                 default = nil)
  if valid_599620 != nil:
    section.add "X-Amz-Credential", valid_599620
  var valid_599621 = header.getOrDefault("X-Amz-Security-Token")
  valid_599621 = validateParameter(valid_599621, JString, required = false,
                                 default = nil)
  if valid_599621 != nil:
    section.add "X-Amz-Security-Token", valid_599621
  var valid_599622 = header.getOrDefault("X-Amz-Algorithm")
  valid_599622 = validateParameter(valid_599622, JString, required = false,
                                 default = nil)
  if valid_599622 != nil:
    section.add "X-Amz-Algorithm", valid_599622
  var valid_599623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599623 = validateParameter(valid_599623, JString, required = false,
                                 default = nil)
  if valid_599623 != nil:
    section.add "X-Amz-SignedHeaders", valid_599623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599625: Call_ListTrials_599611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ## 
  let valid = call_599625.validator(path, query, header, formData, body)
  let scheme = call_599625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599625.url(scheme.get, call_599625.host, call_599625.base,
                         call_599625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599625, url, valid)

proc call*(call_599626: Call_ListTrials_599611; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrials
  ## Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599627 = newJObject()
  var body_599628 = newJObject()
  add(query_599627, "MaxResults", newJString(MaxResults))
  add(query_599627, "NextToken", newJString(NextToken))
  if body != nil:
    body_599628 = body
  result = call_599626.call(nil, query_599627, nil, nil, body_599628)

var listTrials* = Call_ListTrials_599611(name: "listTrials",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrials",
                                      validator: validate_ListTrials_599612,
                                      base: "/", url: url_ListTrials_599613,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserProfiles_599629 = ref object of OpenApiRestCall_597389
proc url_ListUserProfiles_599631(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListUserProfiles_599630(path: JsonNode; query: JsonNode;
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
  var valid_599632 = query.getOrDefault("MaxResults")
  valid_599632 = validateParameter(valid_599632, JString, required = false,
                                 default = nil)
  if valid_599632 != nil:
    section.add "MaxResults", valid_599632
  var valid_599633 = query.getOrDefault("NextToken")
  valid_599633 = validateParameter(valid_599633, JString, required = false,
                                 default = nil)
  if valid_599633 != nil:
    section.add "NextToken", valid_599633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599634 = header.getOrDefault("X-Amz-Target")
  valid_599634 = validateParameter(valid_599634, JString, required = true, default = newJString(
      "SageMaker.ListUserProfiles"))
  if valid_599634 != nil:
    section.add "X-Amz-Target", valid_599634
  var valid_599635 = header.getOrDefault("X-Amz-Signature")
  valid_599635 = validateParameter(valid_599635, JString, required = false,
                                 default = nil)
  if valid_599635 != nil:
    section.add "X-Amz-Signature", valid_599635
  var valid_599636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599636 = validateParameter(valid_599636, JString, required = false,
                                 default = nil)
  if valid_599636 != nil:
    section.add "X-Amz-Content-Sha256", valid_599636
  var valid_599637 = header.getOrDefault("X-Amz-Date")
  valid_599637 = validateParameter(valid_599637, JString, required = false,
                                 default = nil)
  if valid_599637 != nil:
    section.add "X-Amz-Date", valid_599637
  var valid_599638 = header.getOrDefault("X-Amz-Credential")
  valid_599638 = validateParameter(valid_599638, JString, required = false,
                                 default = nil)
  if valid_599638 != nil:
    section.add "X-Amz-Credential", valid_599638
  var valid_599639 = header.getOrDefault("X-Amz-Security-Token")
  valid_599639 = validateParameter(valid_599639, JString, required = false,
                                 default = nil)
  if valid_599639 != nil:
    section.add "X-Amz-Security-Token", valid_599639
  var valid_599640 = header.getOrDefault("X-Amz-Algorithm")
  valid_599640 = validateParameter(valid_599640, JString, required = false,
                                 default = nil)
  if valid_599640 != nil:
    section.add "X-Amz-Algorithm", valid_599640
  var valid_599641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599641 = validateParameter(valid_599641, JString, required = false,
                                 default = nil)
  if valid_599641 != nil:
    section.add "X-Amz-SignedHeaders", valid_599641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599643: Call_ListUserProfiles_599629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists user profiles.
  ## 
  let valid = call_599643.validator(path, query, header, formData, body)
  let scheme = call_599643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599643.url(scheme.get, call_599643.host, call_599643.base,
                         call_599643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599643, url, valid)

proc call*(call_599644: Call_ListUserProfiles_599629; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listUserProfiles
  ## Lists user profiles.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599645 = newJObject()
  var body_599646 = newJObject()
  add(query_599645, "MaxResults", newJString(MaxResults))
  add(query_599645, "NextToken", newJString(NextToken))
  if body != nil:
    body_599646 = body
  result = call_599644.call(nil, query_599645, nil, nil, body_599646)

var listUserProfiles* = Call_ListUserProfiles_599629(name: "listUserProfiles",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListUserProfiles",
    validator: validate_ListUserProfiles_599630, base: "/",
    url: url_ListUserProfiles_599631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_599647 = ref object of OpenApiRestCall_597389
proc url_ListWorkteams_599649(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWorkteams_599648(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599650 = query.getOrDefault("MaxResults")
  valid_599650 = validateParameter(valid_599650, JString, required = false,
                                 default = nil)
  if valid_599650 != nil:
    section.add "MaxResults", valid_599650
  var valid_599651 = query.getOrDefault("NextToken")
  valid_599651 = validateParameter(valid_599651, JString, required = false,
                                 default = nil)
  if valid_599651 != nil:
    section.add "NextToken", valid_599651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599652 = header.getOrDefault("X-Amz-Target")
  valid_599652 = validateParameter(valid_599652, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_599652 != nil:
    section.add "X-Amz-Target", valid_599652
  var valid_599653 = header.getOrDefault("X-Amz-Signature")
  valid_599653 = validateParameter(valid_599653, JString, required = false,
                                 default = nil)
  if valid_599653 != nil:
    section.add "X-Amz-Signature", valid_599653
  var valid_599654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599654 = validateParameter(valid_599654, JString, required = false,
                                 default = nil)
  if valid_599654 != nil:
    section.add "X-Amz-Content-Sha256", valid_599654
  var valid_599655 = header.getOrDefault("X-Amz-Date")
  valid_599655 = validateParameter(valid_599655, JString, required = false,
                                 default = nil)
  if valid_599655 != nil:
    section.add "X-Amz-Date", valid_599655
  var valid_599656 = header.getOrDefault("X-Amz-Credential")
  valid_599656 = validateParameter(valid_599656, JString, required = false,
                                 default = nil)
  if valid_599656 != nil:
    section.add "X-Amz-Credential", valid_599656
  var valid_599657 = header.getOrDefault("X-Amz-Security-Token")
  valid_599657 = validateParameter(valid_599657, JString, required = false,
                                 default = nil)
  if valid_599657 != nil:
    section.add "X-Amz-Security-Token", valid_599657
  var valid_599658 = header.getOrDefault("X-Amz-Algorithm")
  valid_599658 = validateParameter(valid_599658, JString, required = false,
                                 default = nil)
  if valid_599658 != nil:
    section.add "X-Amz-Algorithm", valid_599658
  var valid_599659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599659 = validateParameter(valid_599659, JString, required = false,
                                 default = nil)
  if valid_599659 != nil:
    section.add "X-Amz-SignedHeaders", valid_599659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599661: Call_ListWorkteams_599647; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_599661.validator(path, query, header, formData, body)
  let scheme = call_599661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599661.url(scheme.get, call_599661.host, call_599661.base,
                         call_599661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599661, url, valid)

proc call*(call_599662: Call_ListWorkteams_599647; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599663 = newJObject()
  var body_599664 = newJObject()
  add(query_599663, "MaxResults", newJString(MaxResults))
  add(query_599663, "NextToken", newJString(NextToken))
  if body != nil:
    body_599664 = body
  result = call_599662.call(nil, query_599663, nil, nil, body_599664)

var listWorkteams* = Call_ListWorkteams_599647(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_599648, base: "/", url: url_ListWorkteams_599649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_599665 = ref object of OpenApiRestCall_597389
proc url_RenderUiTemplate_599667(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RenderUiTemplate_599666(path: JsonNode; query: JsonNode;
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
  var valid_599668 = header.getOrDefault("X-Amz-Target")
  valid_599668 = validateParameter(valid_599668, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_599668 != nil:
    section.add "X-Amz-Target", valid_599668
  var valid_599669 = header.getOrDefault("X-Amz-Signature")
  valid_599669 = validateParameter(valid_599669, JString, required = false,
                                 default = nil)
  if valid_599669 != nil:
    section.add "X-Amz-Signature", valid_599669
  var valid_599670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599670 = validateParameter(valid_599670, JString, required = false,
                                 default = nil)
  if valid_599670 != nil:
    section.add "X-Amz-Content-Sha256", valid_599670
  var valid_599671 = header.getOrDefault("X-Amz-Date")
  valid_599671 = validateParameter(valid_599671, JString, required = false,
                                 default = nil)
  if valid_599671 != nil:
    section.add "X-Amz-Date", valid_599671
  var valid_599672 = header.getOrDefault("X-Amz-Credential")
  valid_599672 = validateParameter(valid_599672, JString, required = false,
                                 default = nil)
  if valid_599672 != nil:
    section.add "X-Amz-Credential", valid_599672
  var valid_599673 = header.getOrDefault("X-Amz-Security-Token")
  valid_599673 = validateParameter(valid_599673, JString, required = false,
                                 default = nil)
  if valid_599673 != nil:
    section.add "X-Amz-Security-Token", valid_599673
  var valid_599674 = header.getOrDefault("X-Amz-Algorithm")
  valid_599674 = validateParameter(valid_599674, JString, required = false,
                                 default = nil)
  if valid_599674 != nil:
    section.add "X-Amz-Algorithm", valid_599674
  var valid_599675 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599675 = validateParameter(valid_599675, JString, required = false,
                                 default = nil)
  if valid_599675 != nil:
    section.add "X-Amz-SignedHeaders", valid_599675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599677: Call_RenderUiTemplate_599665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_599677.validator(path, query, header, formData, body)
  let scheme = call_599677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599677.url(scheme.get, call_599677.host, call_599677.base,
                         call_599677.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599677, url, valid)

proc call*(call_599678: Call_RenderUiTemplate_599665; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_599679 = newJObject()
  if body != nil:
    body_599679 = body
  result = call_599678.call(nil, nil, nil, nil, body_599679)

var renderUiTemplate* = Call_RenderUiTemplate_599665(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_599666, base: "/",
    url: url_RenderUiTemplate_599667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_599680 = ref object of OpenApiRestCall_597389
proc url_Search_599682(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Search_599681(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
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
  var valid_599683 = query.getOrDefault("MaxResults")
  valid_599683 = validateParameter(valid_599683, JString, required = false,
                                 default = nil)
  if valid_599683 != nil:
    section.add "MaxResults", valid_599683
  var valid_599684 = query.getOrDefault("NextToken")
  valid_599684 = validateParameter(valid_599684, JString, required = false,
                                 default = nil)
  if valid_599684 != nil:
    section.add "NextToken", valid_599684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599685 = header.getOrDefault("X-Amz-Target")
  valid_599685 = validateParameter(valid_599685, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_599685 != nil:
    section.add "X-Amz-Target", valid_599685
  var valid_599686 = header.getOrDefault("X-Amz-Signature")
  valid_599686 = validateParameter(valid_599686, JString, required = false,
                                 default = nil)
  if valid_599686 != nil:
    section.add "X-Amz-Signature", valid_599686
  var valid_599687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599687 = validateParameter(valid_599687, JString, required = false,
                                 default = nil)
  if valid_599687 != nil:
    section.add "X-Amz-Content-Sha256", valid_599687
  var valid_599688 = header.getOrDefault("X-Amz-Date")
  valid_599688 = validateParameter(valid_599688, JString, required = false,
                                 default = nil)
  if valid_599688 != nil:
    section.add "X-Amz-Date", valid_599688
  var valid_599689 = header.getOrDefault("X-Amz-Credential")
  valid_599689 = validateParameter(valid_599689, JString, required = false,
                                 default = nil)
  if valid_599689 != nil:
    section.add "X-Amz-Credential", valid_599689
  var valid_599690 = header.getOrDefault("X-Amz-Security-Token")
  valid_599690 = validateParameter(valid_599690, JString, required = false,
                                 default = nil)
  if valid_599690 != nil:
    section.add "X-Amz-Security-Token", valid_599690
  var valid_599691 = header.getOrDefault("X-Amz-Algorithm")
  valid_599691 = validateParameter(valid_599691, JString, required = false,
                                 default = nil)
  if valid_599691 != nil:
    section.add "X-Amz-Algorithm", valid_599691
  var valid_599692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599692 = validateParameter(valid_599692, JString, required = false,
                                 default = nil)
  if valid_599692 != nil:
    section.add "X-Amz-SignedHeaders", valid_599692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599694: Call_Search_599680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ## 
  let valid = call_599694.validator(path, query, header, formData, body)
  let scheme = call_599694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599694.url(scheme.get, call_599694.host, call_599694.base,
                         call_599694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599694, url, valid)

proc call*(call_599695: Call_Search_599680; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_599696 = newJObject()
  var body_599697 = newJObject()
  add(query_599696, "MaxResults", newJString(MaxResults))
  add(query_599696, "NextToken", newJString(NextToken))
  if body != nil:
    body_599697 = body
  result = call_599695.call(nil, query_599696, nil, nil, body_599697)

var search* = Call_Search_599680(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_599681, base: "/",
                              url: url_Search_599682,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringSchedule_599698 = ref object of OpenApiRestCall_597389
proc url_StartMonitoringSchedule_599700(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringSchedule_599699(path: JsonNode; query: JsonNode;
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
  var valid_599701 = header.getOrDefault("X-Amz-Target")
  valid_599701 = validateParameter(valid_599701, JString, required = true, default = newJString(
      "SageMaker.StartMonitoringSchedule"))
  if valid_599701 != nil:
    section.add "X-Amz-Target", valid_599701
  var valid_599702 = header.getOrDefault("X-Amz-Signature")
  valid_599702 = validateParameter(valid_599702, JString, required = false,
                                 default = nil)
  if valid_599702 != nil:
    section.add "X-Amz-Signature", valid_599702
  var valid_599703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599703 = validateParameter(valid_599703, JString, required = false,
                                 default = nil)
  if valid_599703 != nil:
    section.add "X-Amz-Content-Sha256", valid_599703
  var valid_599704 = header.getOrDefault("X-Amz-Date")
  valid_599704 = validateParameter(valid_599704, JString, required = false,
                                 default = nil)
  if valid_599704 != nil:
    section.add "X-Amz-Date", valid_599704
  var valid_599705 = header.getOrDefault("X-Amz-Credential")
  valid_599705 = validateParameter(valid_599705, JString, required = false,
                                 default = nil)
  if valid_599705 != nil:
    section.add "X-Amz-Credential", valid_599705
  var valid_599706 = header.getOrDefault("X-Amz-Security-Token")
  valid_599706 = validateParameter(valid_599706, JString, required = false,
                                 default = nil)
  if valid_599706 != nil:
    section.add "X-Amz-Security-Token", valid_599706
  var valid_599707 = header.getOrDefault("X-Amz-Algorithm")
  valid_599707 = validateParameter(valid_599707, JString, required = false,
                                 default = nil)
  if valid_599707 != nil:
    section.add "X-Amz-Algorithm", valid_599707
  var valid_599708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599708 = validateParameter(valid_599708, JString, required = false,
                                 default = nil)
  if valid_599708 != nil:
    section.add "X-Amz-SignedHeaders", valid_599708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599710: Call_StartMonitoringSchedule_599698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ## 
  let valid = call_599710.validator(path, query, header, formData, body)
  let scheme = call_599710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599710.url(scheme.get, call_599710.host, call_599710.base,
                         call_599710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599710, url, valid)

proc call*(call_599711: Call_StartMonitoringSchedule_599698; body: JsonNode): Recallable =
  ## startMonitoringSchedule
  ## <p>Starts a previously stopped monitoring schedule.</p> <note> <p>New monitoring schedules are immediately started after creation.</p> </note>
  ##   body: JObject (required)
  var body_599712 = newJObject()
  if body != nil:
    body_599712 = body
  result = call_599711.call(nil, nil, nil, nil, body_599712)

var startMonitoringSchedule* = Call_StartMonitoringSchedule_599698(
    name: "startMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartMonitoringSchedule",
    validator: validate_StartMonitoringSchedule_599699, base: "/",
    url: url_StartMonitoringSchedule_599700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_599713 = ref object of OpenApiRestCall_597389
proc url_StartNotebookInstance_599715(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartNotebookInstance_599714(path: JsonNode; query: JsonNode;
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
  var valid_599716 = header.getOrDefault("X-Amz-Target")
  valid_599716 = validateParameter(valid_599716, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_599716 != nil:
    section.add "X-Amz-Target", valid_599716
  var valid_599717 = header.getOrDefault("X-Amz-Signature")
  valid_599717 = validateParameter(valid_599717, JString, required = false,
                                 default = nil)
  if valid_599717 != nil:
    section.add "X-Amz-Signature", valid_599717
  var valid_599718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599718 = validateParameter(valid_599718, JString, required = false,
                                 default = nil)
  if valid_599718 != nil:
    section.add "X-Amz-Content-Sha256", valid_599718
  var valid_599719 = header.getOrDefault("X-Amz-Date")
  valid_599719 = validateParameter(valid_599719, JString, required = false,
                                 default = nil)
  if valid_599719 != nil:
    section.add "X-Amz-Date", valid_599719
  var valid_599720 = header.getOrDefault("X-Amz-Credential")
  valid_599720 = validateParameter(valid_599720, JString, required = false,
                                 default = nil)
  if valid_599720 != nil:
    section.add "X-Amz-Credential", valid_599720
  var valid_599721 = header.getOrDefault("X-Amz-Security-Token")
  valid_599721 = validateParameter(valid_599721, JString, required = false,
                                 default = nil)
  if valid_599721 != nil:
    section.add "X-Amz-Security-Token", valid_599721
  var valid_599722 = header.getOrDefault("X-Amz-Algorithm")
  valid_599722 = validateParameter(valid_599722, JString, required = false,
                                 default = nil)
  if valid_599722 != nil:
    section.add "X-Amz-Algorithm", valid_599722
  var valid_599723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599723 = validateParameter(valid_599723, JString, required = false,
                                 default = nil)
  if valid_599723 != nil:
    section.add "X-Amz-SignedHeaders", valid_599723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599725: Call_StartNotebookInstance_599713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_599725.validator(path, query, header, formData, body)
  let scheme = call_599725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599725.url(scheme.get, call_599725.host, call_599725.base,
                         call_599725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599725, url, valid)

proc call*(call_599726: Call_StartNotebookInstance_599713; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_599727 = newJObject()
  if body != nil:
    body_599727 = body
  result = call_599726.call(nil, nil, nil, nil, body_599727)

var startNotebookInstance* = Call_StartNotebookInstance_599713(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_599714, base: "/",
    url: url_StartNotebookInstance_599715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutoMLJob_599728 = ref object of OpenApiRestCall_597389
proc url_StopAutoMLJob_599730(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutoMLJob_599729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599731 = header.getOrDefault("X-Amz-Target")
  valid_599731 = validateParameter(valid_599731, JString, required = true, default = newJString(
      "SageMaker.StopAutoMLJob"))
  if valid_599731 != nil:
    section.add "X-Amz-Target", valid_599731
  var valid_599732 = header.getOrDefault("X-Amz-Signature")
  valid_599732 = validateParameter(valid_599732, JString, required = false,
                                 default = nil)
  if valid_599732 != nil:
    section.add "X-Amz-Signature", valid_599732
  var valid_599733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599733 = validateParameter(valid_599733, JString, required = false,
                                 default = nil)
  if valid_599733 != nil:
    section.add "X-Amz-Content-Sha256", valid_599733
  var valid_599734 = header.getOrDefault("X-Amz-Date")
  valid_599734 = validateParameter(valid_599734, JString, required = false,
                                 default = nil)
  if valid_599734 != nil:
    section.add "X-Amz-Date", valid_599734
  var valid_599735 = header.getOrDefault("X-Amz-Credential")
  valid_599735 = validateParameter(valid_599735, JString, required = false,
                                 default = nil)
  if valid_599735 != nil:
    section.add "X-Amz-Credential", valid_599735
  var valid_599736 = header.getOrDefault("X-Amz-Security-Token")
  valid_599736 = validateParameter(valid_599736, JString, required = false,
                                 default = nil)
  if valid_599736 != nil:
    section.add "X-Amz-Security-Token", valid_599736
  var valid_599737 = header.getOrDefault("X-Amz-Algorithm")
  valid_599737 = validateParameter(valid_599737, JString, required = false,
                                 default = nil)
  if valid_599737 != nil:
    section.add "X-Amz-Algorithm", valid_599737
  var valid_599738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599738 = validateParameter(valid_599738, JString, required = false,
                                 default = nil)
  if valid_599738 != nil:
    section.add "X-Amz-SignedHeaders", valid_599738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599740: Call_StopAutoMLJob_599728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A method for forcing the termination of a running job.
  ## 
  let valid = call_599740.validator(path, query, header, formData, body)
  let scheme = call_599740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599740.url(scheme.get, call_599740.host, call_599740.base,
                         call_599740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599740, url, valid)

proc call*(call_599741: Call_StopAutoMLJob_599728; body: JsonNode): Recallable =
  ## stopAutoMLJob
  ## A method for forcing the termination of a running job.
  ##   body: JObject (required)
  var body_599742 = newJObject()
  if body != nil:
    body_599742 = body
  result = call_599741.call(nil, nil, nil, nil, body_599742)

var stopAutoMLJob* = Call_StopAutoMLJob_599728(name: "stopAutoMLJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopAutoMLJob",
    validator: validate_StopAutoMLJob_599729, base: "/", url: url_StopAutoMLJob_599730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_599743 = ref object of OpenApiRestCall_597389
proc url_StopCompilationJob_599745(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopCompilationJob_599744(path: JsonNode; query: JsonNode;
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
  var valid_599746 = header.getOrDefault("X-Amz-Target")
  valid_599746 = validateParameter(valid_599746, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_599746 != nil:
    section.add "X-Amz-Target", valid_599746
  var valid_599747 = header.getOrDefault("X-Amz-Signature")
  valid_599747 = validateParameter(valid_599747, JString, required = false,
                                 default = nil)
  if valid_599747 != nil:
    section.add "X-Amz-Signature", valid_599747
  var valid_599748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599748 = validateParameter(valid_599748, JString, required = false,
                                 default = nil)
  if valid_599748 != nil:
    section.add "X-Amz-Content-Sha256", valid_599748
  var valid_599749 = header.getOrDefault("X-Amz-Date")
  valid_599749 = validateParameter(valid_599749, JString, required = false,
                                 default = nil)
  if valid_599749 != nil:
    section.add "X-Amz-Date", valid_599749
  var valid_599750 = header.getOrDefault("X-Amz-Credential")
  valid_599750 = validateParameter(valid_599750, JString, required = false,
                                 default = nil)
  if valid_599750 != nil:
    section.add "X-Amz-Credential", valid_599750
  var valid_599751 = header.getOrDefault("X-Amz-Security-Token")
  valid_599751 = validateParameter(valid_599751, JString, required = false,
                                 default = nil)
  if valid_599751 != nil:
    section.add "X-Amz-Security-Token", valid_599751
  var valid_599752 = header.getOrDefault("X-Amz-Algorithm")
  valid_599752 = validateParameter(valid_599752, JString, required = false,
                                 default = nil)
  if valid_599752 != nil:
    section.add "X-Amz-Algorithm", valid_599752
  var valid_599753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599753 = validateParameter(valid_599753, JString, required = false,
                                 default = nil)
  if valid_599753 != nil:
    section.add "X-Amz-SignedHeaders", valid_599753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599755: Call_StopCompilationJob_599743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_599755.validator(path, query, header, formData, body)
  let scheme = call_599755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599755.url(scheme.get, call_599755.host, call_599755.base,
                         call_599755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599755, url, valid)

proc call*(call_599756: Call_StopCompilationJob_599743; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_599757 = newJObject()
  if body != nil:
    body_599757 = body
  result = call_599756.call(nil, nil, nil, nil, body_599757)

var stopCompilationJob* = Call_StopCompilationJob_599743(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_599744, base: "/",
    url: url_StopCompilationJob_599745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_599758 = ref object of OpenApiRestCall_597389
proc url_StopHyperParameterTuningJob_599760(protocol: Scheme; host: string;
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

proc validate_StopHyperParameterTuningJob_599759(path: JsonNode; query: JsonNode;
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
  var valid_599761 = header.getOrDefault("X-Amz-Target")
  valid_599761 = validateParameter(valid_599761, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_599761 != nil:
    section.add "X-Amz-Target", valid_599761
  var valid_599762 = header.getOrDefault("X-Amz-Signature")
  valid_599762 = validateParameter(valid_599762, JString, required = false,
                                 default = nil)
  if valid_599762 != nil:
    section.add "X-Amz-Signature", valid_599762
  var valid_599763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599763 = validateParameter(valid_599763, JString, required = false,
                                 default = nil)
  if valid_599763 != nil:
    section.add "X-Amz-Content-Sha256", valid_599763
  var valid_599764 = header.getOrDefault("X-Amz-Date")
  valid_599764 = validateParameter(valid_599764, JString, required = false,
                                 default = nil)
  if valid_599764 != nil:
    section.add "X-Amz-Date", valid_599764
  var valid_599765 = header.getOrDefault("X-Amz-Credential")
  valid_599765 = validateParameter(valid_599765, JString, required = false,
                                 default = nil)
  if valid_599765 != nil:
    section.add "X-Amz-Credential", valid_599765
  var valid_599766 = header.getOrDefault("X-Amz-Security-Token")
  valid_599766 = validateParameter(valid_599766, JString, required = false,
                                 default = nil)
  if valid_599766 != nil:
    section.add "X-Amz-Security-Token", valid_599766
  var valid_599767 = header.getOrDefault("X-Amz-Algorithm")
  valid_599767 = validateParameter(valid_599767, JString, required = false,
                                 default = nil)
  if valid_599767 != nil:
    section.add "X-Amz-Algorithm", valid_599767
  var valid_599768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599768 = validateParameter(valid_599768, JString, required = false,
                                 default = nil)
  if valid_599768 != nil:
    section.add "X-Amz-SignedHeaders", valid_599768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599770: Call_StopHyperParameterTuningJob_599758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_599770.validator(path, query, header, formData, body)
  let scheme = call_599770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599770.url(scheme.get, call_599770.host, call_599770.base,
                         call_599770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599770, url, valid)

proc call*(call_599771: Call_StopHyperParameterTuningJob_599758; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_599772 = newJObject()
  if body != nil:
    body_599772 = body
  result = call_599771.call(nil, nil, nil, nil, body_599772)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_599758(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_599759, base: "/",
    url: url_StopHyperParameterTuningJob_599760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_599773 = ref object of OpenApiRestCall_597389
proc url_StopLabelingJob_599775(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLabelingJob_599774(path: JsonNode; query: JsonNode;
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
  var valid_599776 = header.getOrDefault("X-Amz-Target")
  valid_599776 = validateParameter(valid_599776, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_599776 != nil:
    section.add "X-Amz-Target", valid_599776
  var valid_599777 = header.getOrDefault("X-Amz-Signature")
  valid_599777 = validateParameter(valid_599777, JString, required = false,
                                 default = nil)
  if valid_599777 != nil:
    section.add "X-Amz-Signature", valid_599777
  var valid_599778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599778 = validateParameter(valid_599778, JString, required = false,
                                 default = nil)
  if valid_599778 != nil:
    section.add "X-Amz-Content-Sha256", valid_599778
  var valid_599779 = header.getOrDefault("X-Amz-Date")
  valid_599779 = validateParameter(valid_599779, JString, required = false,
                                 default = nil)
  if valid_599779 != nil:
    section.add "X-Amz-Date", valid_599779
  var valid_599780 = header.getOrDefault("X-Amz-Credential")
  valid_599780 = validateParameter(valid_599780, JString, required = false,
                                 default = nil)
  if valid_599780 != nil:
    section.add "X-Amz-Credential", valid_599780
  var valid_599781 = header.getOrDefault("X-Amz-Security-Token")
  valid_599781 = validateParameter(valid_599781, JString, required = false,
                                 default = nil)
  if valid_599781 != nil:
    section.add "X-Amz-Security-Token", valid_599781
  var valid_599782 = header.getOrDefault("X-Amz-Algorithm")
  valid_599782 = validateParameter(valid_599782, JString, required = false,
                                 default = nil)
  if valid_599782 != nil:
    section.add "X-Amz-Algorithm", valid_599782
  var valid_599783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599783 = validateParameter(valid_599783, JString, required = false,
                                 default = nil)
  if valid_599783 != nil:
    section.add "X-Amz-SignedHeaders", valid_599783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599785: Call_StopLabelingJob_599773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_599785.validator(path, query, header, formData, body)
  let scheme = call_599785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599785.url(scheme.get, call_599785.host, call_599785.base,
                         call_599785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599785, url, valid)

proc call*(call_599786: Call_StopLabelingJob_599773; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_599787 = newJObject()
  if body != nil:
    body_599787 = body
  result = call_599786.call(nil, nil, nil, nil, body_599787)

var stopLabelingJob* = Call_StopLabelingJob_599773(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_599774, base: "/", url: url_StopLabelingJob_599775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringSchedule_599788 = ref object of OpenApiRestCall_597389
proc url_StopMonitoringSchedule_599790(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopMonitoringSchedule_599789(path: JsonNode; query: JsonNode;
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
  var valid_599791 = header.getOrDefault("X-Amz-Target")
  valid_599791 = validateParameter(valid_599791, JString, required = true, default = newJString(
      "SageMaker.StopMonitoringSchedule"))
  if valid_599791 != nil:
    section.add "X-Amz-Target", valid_599791
  var valid_599792 = header.getOrDefault("X-Amz-Signature")
  valid_599792 = validateParameter(valid_599792, JString, required = false,
                                 default = nil)
  if valid_599792 != nil:
    section.add "X-Amz-Signature", valid_599792
  var valid_599793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599793 = validateParameter(valid_599793, JString, required = false,
                                 default = nil)
  if valid_599793 != nil:
    section.add "X-Amz-Content-Sha256", valid_599793
  var valid_599794 = header.getOrDefault("X-Amz-Date")
  valid_599794 = validateParameter(valid_599794, JString, required = false,
                                 default = nil)
  if valid_599794 != nil:
    section.add "X-Amz-Date", valid_599794
  var valid_599795 = header.getOrDefault("X-Amz-Credential")
  valid_599795 = validateParameter(valid_599795, JString, required = false,
                                 default = nil)
  if valid_599795 != nil:
    section.add "X-Amz-Credential", valid_599795
  var valid_599796 = header.getOrDefault("X-Amz-Security-Token")
  valid_599796 = validateParameter(valid_599796, JString, required = false,
                                 default = nil)
  if valid_599796 != nil:
    section.add "X-Amz-Security-Token", valid_599796
  var valid_599797 = header.getOrDefault("X-Amz-Algorithm")
  valid_599797 = validateParameter(valid_599797, JString, required = false,
                                 default = nil)
  if valid_599797 != nil:
    section.add "X-Amz-Algorithm", valid_599797
  var valid_599798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599798 = validateParameter(valid_599798, JString, required = false,
                                 default = nil)
  if valid_599798 != nil:
    section.add "X-Amz-SignedHeaders", valid_599798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599800: Call_StopMonitoringSchedule_599788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a previously started monitoring schedule.
  ## 
  let valid = call_599800.validator(path, query, header, formData, body)
  let scheme = call_599800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599800.url(scheme.get, call_599800.host, call_599800.base,
                         call_599800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599800, url, valid)

proc call*(call_599801: Call_StopMonitoringSchedule_599788; body: JsonNode): Recallable =
  ## stopMonitoringSchedule
  ## Stops a previously started monitoring schedule.
  ##   body: JObject (required)
  var body_599802 = newJObject()
  if body != nil:
    body_599802 = body
  result = call_599801.call(nil, nil, nil, nil, body_599802)

var stopMonitoringSchedule* = Call_StopMonitoringSchedule_599788(
    name: "stopMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopMonitoringSchedule",
    validator: validate_StopMonitoringSchedule_599789, base: "/",
    url: url_StopMonitoringSchedule_599790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_599803 = ref object of OpenApiRestCall_597389
proc url_StopNotebookInstance_599805(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopNotebookInstance_599804(path: JsonNode; query: JsonNode;
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
  var valid_599806 = header.getOrDefault("X-Amz-Target")
  valid_599806 = validateParameter(valid_599806, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_599806 != nil:
    section.add "X-Amz-Target", valid_599806
  var valid_599807 = header.getOrDefault("X-Amz-Signature")
  valid_599807 = validateParameter(valid_599807, JString, required = false,
                                 default = nil)
  if valid_599807 != nil:
    section.add "X-Amz-Signature", valid_599807
  var valid_599808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599808 = validateParameter(valid_599808, JString, required = false,
                                 default = nil)
  if valid_599808 != nil:
    section.add "X-Amz-Content-Sha256", valid_599808
  var valid_599809 = header.getOrDefault("X-Amz-Date")
  valid_599809 = validateParameter(valid_599809, JString, required = false,
                                 default = nil)
  if valid_599809 != nil:
    section.add "X-Amz-Date", valid_599809
  var valid_599810 = header.getOrDefault("X-Amz-Credential")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "X-Amz-Credential", valid_599810
  var valid_599811 = header.getOrDefault("X-Amz-Security-Token")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "X-Amz-Security-Token", valid_599811
  var valid_599812 = header.getOrDefault("X-Amz-Algorithm")
  valid_599812 = validateParameter(valid_599812, JString, required = false,
                                 default = nil)
  if valid_599812 != nil:
    section.add "X-Amz-Algorithm", valid_599812
  var valid_599813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599813 = validateParameter(valid_599813, JString, required = false,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-SignedHeaders", valid_599813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599815: Call_StopNotebookInstance_599803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_599815.validator(path, query, header, formData, body)
  let scheme = call_599815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599815.url(scheme.get, call_599815.host, call_599815.base,
                         call_599815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599815, url, valid)

proc call*(call_599816: Call_StopNotebookInstance_599803; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_599817 = newJObject()
  if body != nil:
    body_599817 = body
  result = call_599816.call(nil, nil, nil, nil, body_599817)

var stopNotebookInstance* = Call_StopNotebookInstance_599803(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_599804, base: "/",
    url: url_StopNotebookInstance_599805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProcessingJob_599818 = ref object of OpenApiRestCall_597389
proc url_StopProcessingJob_599820(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopProcessingJob_599819(path: JsonNode; query: JsonNode;
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
  var valid_599821 = header.getOrDefault("X-Amz-Target")
  valid_599821 = validateParameter(valid_599821, JString, required = true, default = newJString(
      "SageMaker.StopProcessingJob"))
  if valid_599821 != nil:
    section.add "X-Amz-Target", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Signature")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Signature", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Content-Sha256", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Date")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Date", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Security-Token")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Security-Token", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-Algorithm")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-Algorithm", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-SignedHeaders", valid_599828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599830: Call_StopProcessingJob_599818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a processing job.
  ## 
  let valid = call_599830.validator(path, query, header, formData, body)
  let scheme = call_599830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599830.url(scheme.get, call_599830.host, call_599830.base,
                         call_599830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599830, url, valid)

proc call*(call_599831: Call_StopProcessingJob_599818; body: JsonNode): Recallable =
  ## stopProcessingJob
  ## Stops a processing job.
  ##   body: JObject (required)
  var body_599832 = newJObject()
  if body != nil:
    body_599832 = body
  result = call_599831.call(nil, nil, nil, nil, body_599832)

var stopProcessingJob* = Call_StopProcessingJob_599818(name: "stopProcessingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopProcessingJob",
    validator: validate_StopProcessingJob_599819, base: "/",
    url: url_StopProcessingJob_599820, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_599833 = ref object of OpenApiRestCall_597389
proc url_StopTrainingJob_599835(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTrainingJob_599834(path: JsonNode; query: JsonNode;
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
  var valid_599836 = header.getOrDefault("X-Amz-Target")
  valid_599836 = validateParameter(valid_599836, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_599836 != nil:
    section.add "X-Amz-Target", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Date")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Date", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Security-Token")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Security-Token", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Algorithm")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Algorithm", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-SignedHeaders", valid_599843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599845: Call_StopTrainingJob_599833; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_599845.validator(path, query, header, formData, body)
  let scheme = call_599845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599845.url(scheme.get, call_599845.host, call_599845.base,
                         call_599845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599845, url, valid)

proc call*(call_599846: Call_StopTrainingJob_599833; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_599847 = newJObject()
  if body != nil:
    body_599847 = body
  result = call_599846.call(nil, nil, nil, nil, body_599847)

var stopTrainingJob* = Call_StopTrainingJob_599833(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_599834, base: "/", url: url_StopTrainingJob_599835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_599848 = ref object of OpenApiRestCall_597389
proc url_StopTransformJob_599850(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTransformJob_599849(path: JsonNode; query: JsonNode;
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
  var valid_599851 = header.getOrDefault("X-Amz-Target")
  valid_599851 = validateParameter(valid_599851, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_599851 != nil:
    section.add "X-Amz-Target", valid_599851
  var valid_599852 = header.getOrDefault("X-Amz-Signature")
  valid_599852 = validateParameter(valid_599852, JString, required = false,
                                 default = nil)
  if valid_599852 != nil:
    section.add "X-Amz-Signature", valid_599852
  var valid_599853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599853 = validateParameter(valid_599853, JString, required = false,
                                 default = nil)
  if valid_599853 != nil:
    section.add "X-Amz-Content-Sha256", valid_599853
  var valid_599854 = header.getOrDefault("X-Amz-Date")
  valid_599854 = validateParameter(valid_599854, JString, required = false,
                                 default = nil)
  if valid_599854 != nil:
    section.add "X-Amz-Date", valid_599854
  var valid_599855 = header.getOrDefault("X-Amz-Credential")
  valid_599855 = validateParameter(valid_599855, JString, required = false,
                                 default = nil)
  if valid_599855 != nil:
    section.add "X-Amz-Credential", valid_599855
  var valid_599856 = header.getOrDefault("X-Amz-Security-Token")
  valid_599856 = validateParameter(valid_599856, JString, required = false,
                                 default = nil)
  if valid_599856 != nil:
    section.add "X-Amz-Security-Token", valid_599856
  var valid_599857 = header.getOrDefault("X-Amz-Algorithm")
  valid_599857 = validateParameter(valid_599857, JString, required = false,
                                 default = nil)
  if valid_599857 != nil:
    section.add "X-Amz-Algorithm", valid_599857
  var valid_599858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599858 = validateParameter(valid_599858, JString, required = false,
                                 default = nil)
  if valid_599858 != nil:
    section.add "X-Amz-SignedHeaders", valid_599858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599860: Call_StopTransformJob_599848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_599860.validator(path, query, header, formData, body)
  let scheme = call_599860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599860.url(scheme.get, call_599860.host, call_599860.base,
                         call_599860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599860, url, valid)

proc call*(call_599861: Call_StopTransformJob_599848; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_599862 = newJObject()
  if body != nil:
    body_599862 = body
  result = call_599861.call(nil, nil, nil, nil, body_599862)

var stopTransformJob* = Call_StopTransformJob_599848(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_599849, base: "/",
    url: url_StopTransformJob_599850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_599863 = ref object of OpenApiRestCall_597389
proc url_UpdateCodeRepository_599865(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateCodeRepository_599864(path: JsonNode; query: JsonNode;
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
  var valid_599866 = header.getOrDefault("X-Amz-Target")
  valid_599866 = validateParameter(valid_599866, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_599866 != nil:
    section.add "X-Amz-Target", valid_599866
  var valid_599867 = header.getOrDefault("X-Amz-Signature")
  valid_599867 = validateParameter(valid_599867, JString, required = false,
                                 default = nil)
  if valid_599867 != nil:
    section.add "X-Amz-Signature", valid_599867
  var valid_599868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599868 = validateParameter(valid_599868, JString, required = false,
                                 default = nil)
  if valid_599868 != nil:
    section.add "X-Amz-Content-Sha256", valid_599868
  var valid_599869 = header.getOrDefault("X-Amz-Date")
  valid_599869 = validateParameter(valid_599869, JString, required = false,
                                 default = nil)
  if valid_599869 != nil:
    section.add "X-Amz-Date", valid_599869
  var valid_599870 = header.getOrDefault("X-Amz-Credential")
  valid_599870 = validateParameter(valid_599870, JString, required = false,
                                 default = nil)
  if valid_599870 != nil:
    section.add "X-Amz-Credential", valid_599870
  var valid_599871 = header.getOrDefault("X-Amz-Security-Token")
  valid_599871 = validateParameter(valid_599871, JString, required = false,
                                 default = nil)
  if valid_599871 != nil:
    section.add "X-Amz-Security-Token", valid_599871
  var valid_599872 = header.getOrDefault("X-Amz-Algorithm")
  valid_599872 = validateParameter(valid_599872, JString, required = false,
                                 default = nil)
  if valid_599872 != nil:
    section.add "X-Amz-Algorithm", valid_599872
  var valid_599873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599873 = validateParameter(valid_599873, JString, required = false,
                                 default = nil)
  if valid_599873 != nil:
    section.add "X-Amz-SignedHeaders", valid_599873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599875: Call_UpdateCodeRepository_599863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_599875.validator(path, query, header, formData, body)
  let scheme = call_599875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599875.url(scheme.get, call_599875.host, call_599875.base,
                         call_599875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599875, url, valid)

proc call*(call_599876: Call_UpdateCodeRepository_599863; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_599877 = newJObject()
  if body != nil:
    body_599877 = body
  result = call_599876.call(nil, nil, nil, nil, body_599877)

var updateCodeRepository* = Call_UpdateCodeRepository_599863(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_599864, base: "/",
    url: url_UpdateCodeRepository_599865, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDomain_599878 = ref object of OpenApiRestCall_597389
proc url_UpdateDomain_599880(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDomain_599879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599881 = header.getOrDefault("X-Amz-Target")
  valid_599881 = validateParameter(valid_599881, JString, required = true,
                                 default = newJString("SageMaker.UpdateDomain"))
  if valid_599881 != nil:
    section.add "X-Amz-Target", valid_599881
  var valid_599882 = header.getOrDefault("X-Amz-Signature")
  valid_599882 = validateParameter(valid_599882, JString, required = false,
                                 default = nil)
  if valid_599882 != nil:
    section.add "X-Amz-Signature", valid_599882
  var valid_599883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599883 = validateParameter(valid_599883, JString, required = false,
                                 default = nil)
  if valid_599883 != nil:
    section.add "X-Amz-Content-Sha256", valid_599883
  var valid_599884 = header.getOrDefault("X-Amz-Date")
  valid_599884 = validateParameter(valid_599884, JString, required = false,
                                 default = nil)
  if valid_599884 != nil:
    section.add "X-Amz-Date", valid_599884
  var valid_599885 = header.getOrDefault("X-Amz-Credential")
  valid_599885 = validateParameter(valid_599885, JString, required = false,
                                 default = nil)
  if valid_599885 != nil:
    section.add "X-Amz-Credential", valid_599885
  var valid_599886 = header.getOrDefault("X-Amz-Security-Token")
  valid_599886 = validateParameter(valid_599886, JString, required = false,
                                 default = nil)
  if valid_599886 != nil:
    section.add "X-Amz-Security-Token", valid_599886
  var valid_599887 = header.getOrDefault("X-Amz-Algorithm")
  valid_599887 = validateParameter(valid_599887, JString, required = false,
                                 default = nil)
  if valid_599887 != nil:
    section.add "X-Amz-Algorithm", valid_599887
  var valid_599888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599888 = validateParameter(valid_599888, JString, required = false,
                                 default = nil)
  if valid_599888 != nil:
    section.add "X-Amz-SignedHeaders", valid_599888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599890: Call_UpdateDomain_599878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a domain. Changes will impact all of the people in the domain.
  ## 
  let valid = call_599890.validator(path, query, header, formData, body)
  let scheme = call_599890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599890.url(scheme.get, call_599890.host, call_599890.base,
                         call_599890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599890, url, valid)

proc call*(call_599891: Call_UpdateDomain_599878; body: JsonNode): Recallable =
  ## updateDomain
  ## Updates a domain. Changes will impact all of the people in the domain.
  ##   body: JObject (required)
  var body_599892 = newJObject()
  if body != nil:
    body_599892 = body
  result = call_599891.call(nil, nil, nil, nil, body_599892)

var updateDomain* = Call_UpdateDomain_599878(name: "updateDomain",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateDomain",
    validator: validate_UpdateDomain_599879, base: "/", url: url_UpdateDomain_599880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_599893 = ref object of OpenApiRestCall_597389
proc url_UpdateEndpoint_599895(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEndpoint_599894(path: JsonNode; query: JsonNode;
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
  var valid_599896 = header.getOrDefault("X-Amz-Target")
  valid_599896 = validateParameter(valid_599896, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_599896 != nil:
    section.add "X-Amz-Target", valid_599896
  var valid_599897 = header.getOrDefault("X-Amz-Signature")
  valid_599897 = validateParameter(valid_599897, JString, required = false,
                                 default = nil)
  if valid_599897 != nil:
    section.add "X-Amz-Signature", valid_599897
  var valid_599898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599898 = validateParameter(valid_599898, JString, required = false,
                                 default = nil)
  if valid_599898 != nil:
    section.add "X-Amz-Content-Sha256", valid_599898
  var valid_599899 = header.getOrDefault("X-Amz-Date")
  valid_599899 = validateParameter(valid_599899, JString, required = false,
                                 default = nil)
  if valid_599899 != nil:
    section.add "X-Amz-Date", valid_599899
  var valid_599900 = header.getOrDefault("X-Amz-Credential")
  valid_599900 = validateParameter(valid_599900, JString, required = false,
                                 default = nil)
  if valid_599900 != nil:
    section.add "X-Amz-Credential", valid_599900
  var valid_599901 = header.getOrDefault("X-Amz-Security-Token")
  valid_599901 = validateParameter(valid_599901, JString, required = false,
                                 default = nil)
  if valid_599901 != nil:
    section.add "X-Amz-Security-Token", valid_599901
  var valid_599902 = header.getOrDefault("X-Amz-Algorithm")
  valid_599902 = validateParameter(valid_599902, JString, required = false,
                                 default = nil)
  if valid_599902 != nil:
    section.add "X-Amz-Algorithm", valid_599902
  var valid_599903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599903 = validateParameter(valid_599903, JString, required = false,
                                 default = nil)
  if valid_599903 != nil:
    section.add "X-Amz-SignedHeaders", valid_599903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599905: Call_UpdateEndpoint_599893; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_599905.validator(path, query, header, formData, body)
  let scheme = call_599905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599905.url(scheme.get, call_599905.host, call_599905.base,
                         call_599905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599905, url, valid)

proc call*(call_599906: Call_UpdateEndpoint_599893; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_599907 = newJObject()
  if body != nil:
    body_599907 = body
  result = call_599906.call(nil, nil, nil, nil, body_599907)

var updateEndpoint* = Call_UpdateEndpoint_599893(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_599894, base: "/", url: url_UpdateEndpoint_599895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_599908 = ref object of OpenApiRestCall_597389
proc url_UpdateEndpointWeightsAndCapacities_599910(protocol: Scheme; host: string;
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

proc validate_UpdateEndpointWeightsAndCapacities_599909(path: JsonNode;
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
  var valid_599911 = header.getOrDefault("X-Amz-Target")
  valid_599911 = validateParameter(valid_599911, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_599911 != nil:
    section.add "X-Amz-Target", valid_599911
  var valid_599912 = header.getOrDefault("X-Amz-Signature")
  valid_599912 = validateParameter(valid_599912, JString, required = false,
                                 default = nil)
  if valid_599912 != nil:
    section.add "X-Amz-Signature", valid_599912
  var valid_599913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599913 = validateParameter(valid_599913, JString, required = false,
                                 default = nil)
  if valid_599913 != nil:
    section.add "X-Amz-Content-Sha256", valid_599913
  var valid_599914 = header.getOrDefault("X-Amz-Date")
  valid_599914 = validateParameter(valid_599914, JString, required = false,
                                 default = nil)
  if valid_599914 != nil:
    section.add "X-Amz-Date", valid_599914
  var valid_599915 = header.getOrDefault("X-Amz-Credential")
  valid_599915 = validateParameter(valid_599915, JString, required = false,
                                 default = nil)
  if valid_599915 != nil:
    section.add "X-Amz-Credential", valid_599915
  var valid_599916 = header.getOrDefault("X-Amz-Security-Token")
  valid_599916 = validateParameter(valid_599916, JString, required = false,
                                 default = nil)
  if valid_599916 != nil:
    section.add "X-Amz-Security-Token", valid_599916
  var valid_599917 = header.getOrDefault("X-Amz-Algorithm")
  valid_599917 = validateParameter(valid_599917, JString, required = false,
                                 default = nil)
  if valid_599917 != nil:
    section.add "X-Amz-Algorithm", valid_599917
  var valid_599918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599918 = validateParameter(valid_599918, JString, required = false,
                                 default = nil)
  if valid_599918 != nil:
    section.add "X-Amz-SignedHeaders", valid_599918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599920: Call_UpdateEndpointWeightsAndCapacities_599908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_599920.validator(path, query, header, formData, body)
  let scheme = call_599920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599920.url(scheme.get, call_599920.host, call_599920.base,
                         call_599920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599920, url, valid)

proc call*(call_599921: Call_UpdateEndpointWeightsAndCapacities_599908;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_599922 = newJObject()
  if body != nil:
    body_599922 = body
  result = call_599921.call(nil, nil, nil, nil, body_599922)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_599908(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_599909, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_599910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateExperiment_599923 = ref object of OpenApiRestCall_597389
proc url_UpdateExperiment_599925(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateExperiment_599924(path: JsonNode; query: JsonNode;
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
  var valid_599926 = header.getOrDefault("X-Amz-Target")
  valid_599926 = validateParameter(valid_599926, JString, required = true, default = newJString(
      "SageMaker.UpdateExperiment"))
  if valid_599926 != nil:
    section.add "X-Amz-Target", valid_599926
  var valid_599927 = header.getOrDefault("X-Amz-Signature")
  valid_599927 = validateParameter(valid_599927, JString, required = false,
                                 default = nil)
  if valid_599927 != nil:
    section.add "X-Amz-Signature", valid_599927
  var valid_599928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599928 = validateParameter(valid_599928, JString, required = false,
                                 default = nil)
  if valid_599928 != nil:
    section.add "X-Amz-Content-Sha256", valid_599928
  var valid_599929 = header.getOrDefault("X-Amz-Date")
  valid_599929 = validateParameter(valid_599929, JString, required = false,
                                 default = nil)
  if valid_599929 != nil:
    section.add "X-Amz-Date", valid_599929
  var valid_599930 = header.getOrDefault("X-Amz-Credential")
  valid_599930 = validateParameter(valid_599930, JString, required = false,
                                 default = nil)
  if valid_599930 != nil:
    section.add "X-Amz-Credential", valid_599930
  var valid_599931 = header.getOrDefault("X-Amz-Security-Token")
  valid_599931 = validateParameter(valid_599931, JString, required = false,
                                 default = nil)
  if valid_599931 != nil:
    section.add "X-Amz-Security-Token", valid_599931
  var valid_599932 = header.getOrDefault("X-Amz-Algorithm")
  valid_599932 = validateParameter(valid_599932, JString, required = false,
                                 default = nil)
  if valid_599932 != nil:
    section.add "X-Amz-Algorithm", valid_599932
  var valid_599933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599933 = validateParameter(valid_599933, JString, required = false,
                                 default = nil)
  if valid_599933 != nil:
    section.add "X-Amz-SignedHeaders", valid_599933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599935: Call_UpdateExperiment_599923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ## 
  let valid = call_599935.validator(path, query, header, formData, body)
  let scheme = call_599935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599935.url(scheme.get, call_599935.host, call_599935.base,
                         call_599935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599935, url, valid)

proc call*(call_599936: Call_UpdateExperiment_599923; body: JsonNode): Recallable =
  ## updateExperiment
  ## Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
  ##   body: JObject (required)
  var body_599937 = newJObject()
  if body != nil:
    body_599937 = body
  result = call_599936.call(nil, nil, nil, nil, body_599937)

var updateExperiment* = Call_UpdateExperiment_599923(name: "updateExperiment",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateExperiment",
    validator: validate_UpdateExperiment_599924, base: "/",
    url: url_UpdateExperiment_599925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMonitoringSchedule_599938 = ref object of OpenApiRestCall_597389
proc url_UpdateMonitoringSchedule_599940(protocol: Scheme; host: string;
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

proc validate_UpdateMonitoringSchedule_599939(path: JsonNode; query: JsonNode;
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
  var valid_599941 = header.getOrDefault("X-Amz-Target")
  valid_599941 = validateParameter(valid_599941, JString, required = true, default = newJString(
      "SageMaker.UpdateMonitoringSchedule"))
  if valid_599941 != nil:
    section.add "X-Amz-Target", valid_599941
  var valid_599942 = header.getOrDefault("X-Amz-Signature")
  valid_599942 = validateParameter(valid_599942, JString, required = false,
                                 default = nil)
  if valid_599942 != nil:
    section.add "X-Amz-Signature", valid_599942
  var valid_599943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599943 = validateParameter(valid_599943, JString, required = false,
                                 default = nil)
  if valid_599943 != nil:
    section.add "X-Amz-Content-Sha256", valid_599943
  var valid_599944 = header.getOrDefault("X-Amz-Date")
  valid_599944 = validateParameter(valid_599944, JString, required = false,
                                 default = nil)
  if valid_599944 != nil:
    section.add "X-Amz-Date", valid_599944
  var valid_599945 = header.getOrDefault("X-Amz-Credential")
  valid_599945 = validateParameter(valid_599945, JString, required = false,
                                 default = nil)
  if valid_599945 != nil:
    section.add "X-Amz-Credential", valid_599945
  var valid_599946 = header.getOrDefault("X-Amz-Security-Token")
  valid_599946 = validateParameter(valid_599946, JString, required = false,
                                 default = nil)
  if valid_599946 != nil:
    section.add "X-Amz-Security-Token", valid_599946
  var valid_599947 = header.getOrDefault("X-Amz-Algorithm")
  valid_599947 = validateParameter(valid_599947, JString, required = false,
                                 default = nil)
  if valid_599947 != nil:
    section.add "X-Amz-Algorithm", valid_599947
  var valid_599948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599948 = validateParameter(valid_599948, JString, required = false,
                                 default = nil)
  if valid_599948 != nil:
    section.add "X-Amz-SignedHeaders", valid_599948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599950: Call_UpdateMonitoringSchedule_599938; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a previously created schedule.
  ## 
  let valid = call_599950.validator(path, query, header, formData, body)
  let scheme = call_599950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599950.url(scheme.get, call_599950.host, call_599950.base,
                         call_599950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599950, url, valid)

proc call*(call_599951: Call_UpdateMonitoringSchedule_599938; body: JsonNode): Recallable =
  ## updateMonitoringSchedule
  ## Updates a previously created schedule.
  ##   body: JObject (required)
  var body_599952 = newJObject()
  if body != nil:
    body_599952 = body
  result = call_599951.call(nil, nil, nil, nil, body_599952)

var updateMonitoringSchedule* = Call_UpdateMonitoringSchedule_599938(
    name: "updateMonitoringSchedule", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule",
    validator: validate_UpdateMonitoringSchedule_599939, base: "/",
    url: url_UpdateMonitoringSchedule_599940, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_599953 = ref object of OpenApiRestCall_597389
proc url_UpdateNotebookInstance_599955(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateNotebookInstance_599954(path: JsonNode; query: JsonNode;
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
  var valid_599956 = header.getOrDefault("X-Amz-Target")
  valid_599956 = validateParameter(valid_599956, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_599956 != nil:
    section.add "X-Amz-Target", valid_599956
  var valid_599957 = header.getOrDefault("X-Amz-Signature")
  valid_599957 = validateParameter(valid_599957, JString, required = false,
                                 default = nil)
  if valid_599957 != nil:
    section.add "X-Amz-Signature", valid_599957
  var valid_599958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599958 = validateParameter(valid_599958, JString, required = false,
                                 default = nil)
  if valid_599958 != nil:
    section.add "X-Amz-Content-Sha256", valid_599958
  var valid_599959 = header.getOrDefault("X-Amz-Date")
  valid_599959 = validateParameter(valid_599959, JString, required = false,
                                 default = nil)
  if valid_599959 != nil:
    section.add "X-Amz-Date", valid_599959
  var valid_599960 = header.getOrDefault("X-Amz-Credential")
  valid_599960 = validateParameter(valid_599960, JString, required = false,
                                 default = nil)
  if valid_599960 != nil:
    section.add "X-Amz-Credential", valid_599960
  var valid_599961 = header.getOrDefault("X-Amz-Security-Token")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "X-Amz-Security-Token", valid_599961
  var valid_599962 = header.getOrDefault("X-Amz-Algorithm")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Algorithm", valid_599962
  var valid_599963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-SignedHeaders", valid_599963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599965: Call_UpdateNotebookInstance_599953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_599965.validator(path, query, header, formData, body)
  let scheme = call_599965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599965.url(scheme.get, call_599965.host, call_599965.base,
                         call_599965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599965, url, valid)

proc call*(call_599966: Call_UpdateNotebookInstance_599953; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_599967 = newJObject()
  if body != nil:
    body_599967 = body
  result = call_599966.call(nil, nil, nil, nil, body_599967)

var updateNotebookInstance* = Call_UpdateNotebookInstance_599953(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_599954, base: "/",
    url: url_UpdateNotebookInstance_599955, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_599968 = ref object of OpenApiRestCall_597389
proc url_UpdateNotebookInstanceLifecycleConfig_599970(protocol: Scheme;
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

proc validate_UpdateNotebookInstanceLifecycleConfig_599969(path: JsonNode;
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
  var valid_599971 = header.getOrDefault("X-Amz-Target")
  valid_599971 = validateParameter(valid_599971, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_599971 != nil:
    section.add "X-Amz-Target", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Signature")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Signature", valid_599972
  var valid_599973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "X-Amz-Content-Sha256", valid_599973
  var valid_599974 = header.getOrDefault("X-Amz-Date")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Date", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Credential")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Credential", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Security-Token")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Security-Token", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Algorithm")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Algorithm", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-SignedHeaders", valid_599978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599980: Call_UpdateNotebookInstanceLifecycleConfig_599968;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_599980.validator(path, query, header, formData, body)
  let scheme = call_599980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599980.url(scheme.get, call_599980.host, call_599980.base,
                         call_599980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599980, url, valid)

proc call*(call_599981: Call_UpdateNotebookInstanceLifecycleConfig_599968;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_599982 = newJObject()
  if body != nil:
    body_599982 = body
  result = call_599981.call(nil, nil, nil, nil, body_599982)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_599968(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_599969, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_599970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrial_599983 = ref object of OpenApiRestCall_597389
proc url_UpdateTrial_599985(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrial_599984(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599986 = header.getOrDefault("X-Amz-Target")
  valid_599986 = validateParameter(valid_599986, JString, required = true,
                                 default = newJString("SageMaker.UpdateTrial"))
  if valid_599986 != nil:
    section.add "X-Amz-Target", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Signature")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Signature", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Content-Sha256", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Date")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Date", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Security-Token")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Security-Token", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Algorithm")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Algorithm", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-SignedHeaders", valid_599993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599995: Call_UpdateTrial_599983; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the display name of a trial.
  ## 
  let valid = call_599995.validator(path, query, header, formData, body)
  let scheme = call_599995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599995.url(scheme.get, call_599995.host, call_599995.base,
                         call_599995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599995, url, valid)

proc call*(call_599996: Call_UpdateTrial_599983; body: JsonNode): Recallable =
  ## updateTrial
  ## Updates the display name of a trial.
  ##   body: JObject (required)
  var body_599997 = newJObject()
  if body != nil:
    body_599997 = body
  result = call_599996.call(nil, nil, nil, nil, body_599997)

var updateTrial* = Call_UpdateTrial_599983(name: "updateTrial",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.UpdateTrial",
                                        validator: validate_UpdateTrial_599984,
                                        base: "/", url: url_UpdateTrial_599985,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrialComponent_599998 = ref object of OpenApiRestCall_597389
proc url_UpdateTrialComponent_600000(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrialComponent_599999(path: JsonNode; query: JsonNode;
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
  var valid_600001 = header.getOrDefault("X-Amz-Target")
  valid_600001 = validateParameter(valid_600001, JString, required = true, default = newJString(
      "SageMaker.UpdateTrialComponent"))
  if valid_600001 != nil:
    section.add "X-Amz-Target", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Signature")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Signature", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Content-Sha256", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Date")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Date", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Algorithm")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Algorithm", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-SignedHeaders", valid_600008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600010: Call_UpdateTrialComponent_599998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates one or more properties of a trial component.
  ## 
  let valid = call_600010.validator(path, query, header, formData, body)
  let scheme = call_600010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600010.url(scheme.get, call_600010.host, call_600010.base,
                         call_600010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600010, url, valid)

proc call*(call_600011: Call_UpdateTrialComponent_599998; body: JsonNode): Recallable =
  ## updateTrialComponent
  ## Updates one or more properties of a trial component.
  ##   body: JObject (required)
  var body_600012 = newJObject()
  if body != nil:
    body_600012 = body
  result = call_600011.call(nil, nil, nil, nil, body_600012)

var updateTrialComponent* = Call_UpdateTrialComponent_599998(
    name: "updateTrialComponent", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateTrialComponent",
    validator: validate_UpdateTrialComponent_599999, base: "/",
    url: url_UpdateTrialComponent_600000, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserProfile_600013 = ref object of OpenApiRestCall_597389
proc url_UpdateUserProfile_600015(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateUserProfile_600014(path: JsonNode; query: JsonNode;
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
  var valid_600016 = header.getOrDefault("X-Amz-Target")
  valid_600016 = validateParameter(valid_600016, JString, required = true, default = newJString(
      "SageMaker.UpdateUserProfile"))
  if valid_600016 != nil:
    section.add "X-Amz-Target", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Signature")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Signature", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Date")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Date", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Credential")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Credential", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Security-Token")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Security-Token", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Algorithm")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Algorithm", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-SignedHeaders", valid_600023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600025: Call_UpdateUserProfile_600013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a user profile.
  ## 
  let valid = call_600025.validator(path, query, header, formData, body)
  let scheme = call_600025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600025.url(scheme.get, call_600025.host, call_600025.base,
                         call_600025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600025, url, valid)

proc call*(call_600026: Call_UpdateUserProfile_600013; body: JsonNode): Recallable =
  ## updateUserProfile
  ## Updates a user profile.
  ##   body: JObject (required)
  var body_600027 = newJObject()
  if body != nil:
    body_600027 = body
  result = call_600026.call(nil, nil, nil, nil, body_600027)

var updateUserProfile* = Call_UpdateUserProfile_600013(name: "updateUserProfile",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateUserProfile",
    validator: validate_UpdateUserProfile_600014, base: "/",
    url: url_UpdateUserProfile_600015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_600028 = ref object of OpenApiRestCall_597389
proc url_UpdateWorkteam_600030(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWorkteam_600029(path: JsonNode; query: JsonNode;
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
  var valid_600031 = header.getOrDefault("X-Amz-Target")
  valid_600031 = validateParameter(valid_600031, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_600031 != nil:
    section.add "X-Amz-Target", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Signature")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Signature", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Credential")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Credential", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Security-Token")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Security-Token", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Algorithm")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Algorithm", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-SignedHeaders", valid_600038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600040: Call_UpdateWorkteam_600028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_600040.validator(path, query, header, formData, body)
  let scheme = call_600040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600040.url(scheme.get, call_600040.host, call_600040.base,
                         call_600040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600040, url, valid)

proc call*(call_600041: Call_UpdateWorkteam_600028; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_600042 = newJObject()
  if body != nil:
    body_600042 = body
  result = call_600041.call(nil, nil, nil, nil, body_600042)

var updateWorkteam* = Call_UpdateWorkteam_600028(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_600029, base: "/", url: url_UpdateWorkteam_600030,
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
