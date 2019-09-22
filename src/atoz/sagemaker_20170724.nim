
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_602770 = ref object of OpenApiRestCall_602433
proc url_AddTags_602772(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTags_602771(path: JsonNode; query: JsonNode; header: JsonNode;
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
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
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

proc call*(call_602928: Call_AddTags_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"))
  result = hook(call_602928, url, valid)

proc call*(call_602999: Call_AddTags_602770; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_603000 = newJObject()
  if body != nil:
    body_603000 = body
  result = call_602999.call(nil, nil, nil, nil, body_603000)

var addTags* = Call_AddTags_602770(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_602771, base: "/",
                                url: url_AddTags_602772,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_603039 = ref object of OpenApiRestCall_602433
proc url_CreateAlgorithm_603041(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAlgorithm_603040(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateAlgorithm"))
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

proc call*(call_603051: Call_CreateAlgorithm_603039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_603051.validator(path, query, header, formData, body)
  let scheme = call_603051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603051.url(scheme.get, call_603051.host, call_603051.base,
                         call_603051.route, valid.getOrDefault("path"))
  result = hook(call_603051, url, valid)

proc call*(call_603052: Call_CreateAlgorithm_603039; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_603053 = newJObject()
  if body != nil:
    body_603053 = body
  result = call_603052.call(nil, nil, nil, nil, body_603053)

var createAlgorithm* = Call_CreateAlgorithm_603039(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_603040, base: "/", url: url_CreateAlgorithm_603041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_603054 = ref object of OpenApiRestCall_602433
proc url_CreateCodeRepository_603056(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCodeRepository_603055(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateCodeRepository"))
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

proc call*(call_603066: Call_CreateCodeRepository_603054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_603066.validator(path, query, header, formData, body)
  let scheme = call_603066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603066.url(scheme.get, call_603066.host, call_603066.base,
                         call_603066.route, valid.getOrDefault("path"))
  result = hook(call_603066, url, valid)

proc call*(call_603067: Call_CreateCodeRepository_603054; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_603068 = newJObject()
  if body != nil:
    body_603068 = body
  result = call_603067.call(nil, nil, nil, nil, body_603068)

var createCodeRepository* = Call_CreateCodeRepository_603054(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_603055, base: "/",
    url: url_CreateCodeRepository_603056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_603069 = ref object of OpenApiRestCall_602433
proc url_CreateCompilationJob_603071(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCompilationJob_603070(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateCompilationJob"))
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

proc call*(call_603081: Call_CreateCompilationJob_603069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_603081.validator(path, query, header, formData, body)
  let scheme = call_603081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603081.url(scheme.get, call_603081.host, call_603081.base,
                         call_603081.route, valid.getOrDefault("path"))
  result = hook(call_603081, url, valid)

proc call*(call_603082: Call_CreateCompilationJob_603069; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_603083 = newJObject()
  if body != nil:
    body_603083 = body
  result = call_603082.call(nil, nil, nil, nil, body_603083)

var createCompilationJob* = Call_CreateCompilationJob_603069(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_603070, base: "/",
    url: url_CreateCompilationJob_603071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_603084 = ref object of OpenApiRestCall_602433
proc url_CreateEndpoint_603086(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEndpoint_603085(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
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
      "SageMaker.CreateEndpoint"))
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

proc call*(call_603096: Call_CreateEndpoint_603084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_CreateEndpoint_603084; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603098 = newJObject()
  if body != nil:
    body_603098 = body
  result = call_603097.call(nil, nil, nil, nil, body_603098)

var createEndpoint* = Call_CreateEndpoint_603084(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_603085, base: "/", url: url_CreateEndpoint_603086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_603099 = ref object of OpenApiRestCall_602433
proc url_CreateEndpointConfig_603101(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateEndpointConfig_603100(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateEndpointConfig"))
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

proc call*(call_603111: Call_CreateEndpointConfig_603099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_CreateEndpointConfig_603099; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_603113 = newJObject()
  if body != nil:
    body_603113 = body
  result = call_603112.call(nil, nil, nil, nil, body_603113)

var createEndpointConfig* = Call_CreateEndpointConfig_603099(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_603100, base: "/",
    url: url_CreateEndpointConfig_603101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_603114 = ref object of OpenApiRestCall_602433
proc url_CreateHyperParameterTuningJob_603116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateHyperParameterTuningJob_603115(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateHyperParameterTuningJob"))
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

proc call*(call_603126: Call_CreateHyperParameterTuningJob_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_603126.validator(path, query, header, formData, body)
  let scheme = call_603126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603126.url(scheme.get, call_603126.host, call_603126.base,
                         call_603126.route, valid.getOrDefault("path"))
  result = hook(call_603126, url, valid)

proc call*(call_603127: Call_CreateHyperParameterTuningJob_603114; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_603128 = newJObject()
  if body != nil:
    body_603128 = body
  result = call_603127.call(nil, nil, nil, nil, body_603128)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_603114(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_603115, base: "/",
    url: url_CreateHyperParameterTuningJob_603116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_603129 = ref object of OpenApiRestCall_602433
proc url_CreateLabelingJob_603131(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLabelingJob_603130(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateLabelingJob"))
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

proc call*(call_603141: Call_CreateLabelingJob_603129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_CreateLabelingJob_603129; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_603143 = newJObject()
  if body != nil:
    body_603143 = body
  result = call_603142.call(nil, nil, nil, nil, body_603143)

var createLabelingJob* = Call_CreateLabelingJob_603129(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_603130, base: "/",
    url: url_CreateLabelingJob_603131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_603144 = ref object of OpenApiRestCall_602433
proc url_CreateModel_603146(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateModel_603145(path: JsonNode; query: JsonNode; header: JsonNode;
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
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
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

proc call*(call_603156: Call_CreateModel_603144; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_603156.validator(path, query, header, formData, body)
  let scheme = call_603156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603156.url(scheme.get, call_603156.host, call_603156.base,
                         call_603156.route, valid.getOrDefault("path"))
  result = hook(call_603156, url, valid)

proc call*(call_603157: Call_CreateModel_603144; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_603158 = newJObject()
  if body != nil:
    body_603158 = body
  result = call_603157.call(nil, nil, nil, nil, body_603158)

var createModel* = Call_CreateModel_603144(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_603145,
                                        base: "/", url: url_CreateModel_603146,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_603159 = ref object of OpenApiRestCall_602433
proc url_CreateModelPackage_603161(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateModelPackage_603160(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateModelPackage"))
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

proc call*(call_603171: Call_CreateModelPackage_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_603171.validator(path, query, header, formData, body)
  let scheme = call_603171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603171.url(scheme.get, call_603171.host, call_603171.base,
                         call_603171.route, valid.getOrDefault("path"))
  result = hook(call_603171, url, valid)

proc call*(call_603172: Call_CreateModelPackage_603159; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_603173 = newJObject()
  if body != nil:
    body_603173 = body
  result = call_603172.call(nil, nil, nil, nil, body_603173)

var createModelPackage* = Call_CreateModelPackage_603159(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_603160, base: "/",
    url: url_CreateModelPackage_603161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_603174 = ref object of OpenApiRestCall_602433
proc url_CreateNotebookInstance_603176(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNotebookInstance_603175(path: JsonNode; query: JsonNode;
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
      "SageMaker.CreateNotebookInstance"))
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

proc call*(call_603186: Call_CreateNotebookInstance_603174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_603186.validator(path, query, header, formData, body)
  let scheme = call_603186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603186.url(scheme.get, call_603186.host, call_603186.base,
                         call_603186.route, valid.getOrDefault("path"))
  result = hook(call_603186, url, valid)

proc call*(call_603187: Call_CreateNotebookInstance_603174; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603188 = newJObject()
  if body != nil:
    body_603188 = body
  result = call_603187.call(nil, nil, nil, nil, body_603188)

var createNotebookInstance* = Call_CreateNotebookInstance_603174(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_603175, base: "/",
    url: url_CreateNotebookInstance_603176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_603189 = ref object of OpenApiRestCall_602433
proc url_CreateNotebookInstanceLifecycleConfig_603191(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateNotebookInstanceLifecycleConfig_603190(path: JsonNode;
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
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603201: Call_CreateNotebookInstanceLifecycleConfig_603189;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_603201.validator(path, query, header, formData, body)
  let scheme = call_603201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603201.url(scheme.get, call_603201.host, call_603201.base,
                         call_603201.route, valid.getOrDefault("path"))
  result = hook(call_603201, url, valid)

proc call*(call_603202: Call_CreateNotebookInstanceLifecycleConfig_603189;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_603203 = newJObject()
  if body != nil:
    body_603203 = body
  result = call_603202.call(nil, nil, nil, nil, body_603203)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_603189(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_603190, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_603191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_603204 = ref object of OpenApiRestCall_602433
proc url_CreatePresignedNotebookInstanceUrl_603206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePresignedNotebookInstanceUrl_603205(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
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
  var valid_603207 = header.getOrDefault("X-Amz-Date")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Date", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603209 = header.getOrDefault("X-Amz-Target")
  valid_603209 = validateParameter(valid_603209, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_603209 != nil:
    section.add "X-Amz-Target", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Content-Sha256", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Algorithm")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Algorithm", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Signature")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Signature", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-SignedHeaders", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Credential")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Credential", valid_603214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603216: Call_CreatePresignedNotebookInstanceUrl_603204;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_603216.validator(path, query, header, formData, body)
  let scheme = call_603216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603216.url(scheme.get, call_603216.host, call_603216.base,
                         call_603216.route, valid.getOrDefault("path"))
  result = hook(call_603216, url, valid)

proc call*(call_603217: Call_CreatePresignedNotebookInstanceUrl_603204;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_603218 = newJObject()
  if body != nil:
    body_603218 = body
  result = call_603217.call(nil, nil, nil, nil, body_603218)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_603204(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_603205, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_603206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_603219 = ref object of OpenApiRestCall_602433
proc url_CreateTrainingJob_603221(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTrainingJob_603220(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
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
  var valid_603222 = header.getOrDefault("X-Amz-Date")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Date", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Security-Token")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Security-Token", valid_603223
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603224 = header.getOrDefault("X-Amz-Target")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_603224 != nil:
    section.add "X-Amz-Target", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Content-Sha256", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Algorithm")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Algorithm", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Signature")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Signature", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-SignedHeaders", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Credential")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Credential", valid_603229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_CreateTrainingJob_603219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_CreateTrainingJob_603219; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603233 = newJObject()
  if body != nil:
    body_603233 = body
  result = call_603232.call(nil, nil, nil, nil, body_603233)

var createTrainingJob* = Call_CreateTrainingJob_603219(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_603220, base: "/",
    url: url_CreateTrainingJob_603221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_603234 = ref object of OpenApiRestCall_602433
proc url_CreateTransformJob_603236(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTransformJob_603235(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
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
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603239 = header.getOrDefault("X-Amz-Target")
  valid_603239 = validateParameter(valid_603239, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_603239 != nil:
    section.add "X-Amz-Target", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603246: Call_CreateTransformJob_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ## 
  let valid = call_603246.validator(path, query, header, formData, body)
  let scheme = call_603246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603246.url(scheme.get, call_603246.host, call_603246.base,
                         call_603246.route, valid.getOrDefault("path"))
  result = hook(call_603246, url, valid)

proc call*(call_603247: Call_CreateTransformJob_603234; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603248 = newJObject()
  if body != nil:
    body_603248 = body
  result = call_603247.call(nil, nil, nil, nil, body_603248)

var createTransformJob* = Call_CreateTransformJob_603234(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_603235, base: "/",
    url: url_CreateTransformJob_603236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_603249 = ref object of OpenApiRestCall_602433
proc url_CreateWorkteam_603251(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateWorkteam_603250(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603252 = header.getOrDefault("X-Amz-Date")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Date", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603254 = header.getOrDefault("X-Amz-Target")
  valid_603254 = validateParameter(valid_603254, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_603254 != nil:
    section.add "X-Amz-Target", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_CreateWorkteam_603249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_CreateWorkteam_603249; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_603263 = newJObject()
  if body != nil:
    body_603263 = body
  result = call_603262.call(nil, nil, nil, nil, body_603263)

var createWorkteam* = Call_CreateWorkteam_603249(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_603250, base: "/", url: url_CreateWorkteam_603251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_603264 = ref object of OpenApiRestCall_602433
proc url_DeleteAlgorithm_603266(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAlgorithm_603265(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603267 = header.getOrDefault("X-Amz-Date")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Date", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603269 = header.getOrDefault("X-Amz-Target")
  valid_603269 = validateParameter(valid_603269, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_603269 != nil:
    section.add "X-Amz-Target", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603276: Call_DeleteAlgorithm_603264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_603276.validator(path, query, header, formData, body)
  let scheme = call_603276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603276.url(scheme.get, call_603276.host, call_603276.base,
                         call_603276.route, valid.getOrDefault("path"))
  result = hook(call_603276, url, valid)

proc call*(call_603277: Call_DeleteAlgorithm_603264; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_603278 = newJObject()
  if body != nil:
    body_603278 = body
  result = call_603277.call(nil, nil, nil, nil, body_603278)

var deleteAlgorithm* = Call_DeleteAlgorithm_603264(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_603265, base: "/", url: url_DeleteAlgorithm_603266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_603279 = ref object of OpenApiRestCall_602433
proc url_DeleteCodeRepository_603281(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCodeRepository_603280(path: JsonNode; query: JsonNode;
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
      "SageMaker.DeleteCodeRepository"))
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

proc call*(call_603291: Call_DeleteCodeRepository_603279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_603291.validator(path, query, header, formData, body)
  let scheme = call_603291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603291.url(scheme.get, call_603291.host, call_603291.base,
                         call_603291.route, valid.getOrDefault("path"))
  result = hook(call_603291, url, valid)

proc call*(call_603292: Call_DeleteCodeRepository_603279; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_603293 = newJObject()
  if body != nil:
    body_603293 = body
  result = call_603292.call(nil, nil, nil, nil, body_603293)

var deleteCodeRepository* = Call_DeleteCodeRepository_603279(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_603280, base: "/",
    url: url_DeleteCodeRepository_603281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_603294 = ref object of OpenApiRestCall_602433
proc url_DeleteEndpoint_603296(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEndpoint_603295(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603299 = header.getOrDefault("X-Amz-Target")
  valid_603299 = validateParameter(valid_603299, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_603299 != nil:
    section.add "X-Amz-Target", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Content-Sha256", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Signature")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Signature", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-SignedHeaders", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Credential")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Credential", valid_603304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603306: Call_DeleteEndpoint_603294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_603306.validator(path, query, header, formData, body)
  let scheme = call_603306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603306.url(scheme.get, call_603306.host, call_603306.base,
                         call_603306.route, valid.getOrDefault("path"))
  result = hook(call_603306, url, valid)

proc call*(call_603307: Call_DeleteEndpoint_603294; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_603308 = newJObject()
  if body != nil:
    body_603308 = body
  result = call_603307.call(nil, nil, nil, nil, body_603308)

var deleteEndpoint* = Call_DeleteEndpoint_603294(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_603295, base: "/", url: url_DeleteEndpoint_603296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_603309 = ref object of OpenApiRestCall_602433
proc url_DeleteEndpointConfig_603311(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteEndpointConfig_603310(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Security-Token")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Security-Token", valid_603313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603314 = header.getOrDefault("X-Amz-Target")
  valid_603314 = validateParameter(valid_603314, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_603314 != nil:
    section.add "X-Amz-Target", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Content-Sha256", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Algorithm")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Algorithm", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Signature")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Signature", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-SignedHeaders", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Credential")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Credential", valid_603319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603321: Call_DeleteEndpointConfig_603309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_603321.validator(path, query, header, formData, body)
  let scheme = call_603321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603321.url(scheme.get, call_603321.host, call_603321.base,
                         call_603321.route, valid.getOrDefault("path"))
  result = hook(call_603321, url, valid)

proc call*(call_603322: Call_DeleteEndpointConfig_603309; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_603323 = newJObject()
  if body != nil:
    body_603323 = body
  result = call_603322.call(nil, nil, nil, nil, body_603323)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_603309(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_603310, base: "/",
    url: url_DeleteEndpointConfig_603311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_603324 = ref object of OpenApiRestCall_602433
proc url_DeleteModel_603326(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteModel_603325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Security-Token")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Security-Token", valid_603328
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603329 = header.getOrDefault("X-Amz-Target")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_603329 != nil:
    section.add "X-Amz-Target", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Content-Sha256", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Algorithm")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Algorithm", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Signature")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Signature", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-SignedHeaders", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Credential")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Credential", valid_603334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603336: Call_DeleteModel_603324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_603336.validator(path, query, header, formData, body)
  let scheme = call_603336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603336.url(scheme.get, call_603336.host, call_603336.base,
                         call_603336.route, valid.getOrDefault("path"))
  result = hook(call_603336, url, valid)

proc call*(call_603337: Call_DeleteModel_603324; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_603338 = newJObject()
  if body != nil:
    body_603338 = body
  result = call_603337.call(nil, nil, nil, nil, body_603338)

var deleteModel* = Call_DeleteModel_603324(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_603325,
                                        base: "/", url: url_DeleteModel_603326,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_603339 = ref object of OpenApiRestCall_602433
proc url_DeleteModelPackage_603341(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteModelPackage_603340(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603342 = header.getOrDefault("X-Amz-Date")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Date", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Security-Token")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Security-Token", valid_603343
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603344 = header.getOrDefault("X-Amz-Target")
  valid_603344 = validateParameter(valid_603344, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_603344 != nil:
    section.add "X-Amz-Target", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_DeleteModelPackage_603339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_DeleteModelPackage_603339; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_603353 = newJObject()
  if body != nil:
    body_603353 = body
  result = call_603352.call(nil, nil, nil, nil, body_603353)

var deleteModelPackage* = Call_DeleteModelPackage_603339(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_603340, base: "/",
    url: url_DeleteModelPackage_603341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_603354 = ref object of OpenApiRestCall_602433
proc url_DeleteNotebookInstance_603356(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNotebookInstance_603355(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603357 = header.getOrDefault("X-Amz-Date")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Date", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Security-Token")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Security-Token", valid_603358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603359 = header.getOrDefault("X-Amz-Target")
  valid_603359 = validateParameter(valid_603359, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_603359 != nil:
    section.add "X-Amz-Target", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Content-Sha256", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Algorithm")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Algorithm", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Signature")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Signature", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-SignedHeaders", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Credential")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Credential", valid_603364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603366: Call_DeleteNotebookInstance_603354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_603366.validator(path, query, header, formData, body)
  let scheme = call_603366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603366.url(scheme.get, call_603366.host, call_603366.base,
                         call_603366.route, valid.getOrDefault("path"))
  result = hook(call_603366, url, valid)

proc call*(call_603367: Call_DeleteNotebookInstance_603354; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_603368 = newJObject()
  if body != nil:
    body_603368 = body
  result = call_603367.call(nil, nil, nil, nil, body_603368)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_603354(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_603355, base: "/",
    url: url_DeleteNotebookInstance_603356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_603369 = ref object of OpenApiRestCall_602433
proc url_DeleteNotebookInstanceLifecycleConfig_603371(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_603370(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603374 = header.getOrDefault("X-Amz-Target")
  valid_603374 = validateParameter(valid_603374, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_603374 != nil:
    section.add "X-Amz-Target", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_DeleteNotebookInstanceLifecycleConfig_603369;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_DeleteNotebookInstanceLifecycleConfig_603369;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_603383 = newJObject()
  if body != nil:
    body_603383 = body
  result = call_603382.call(nil, nil, nil, nil, body_603383)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_603369(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_603370, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_603371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_603384 = ref object of OpenApiRestCall_602433
proc url_DeleteTags_603386(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTags_603385(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603387 = header.getOrDefault("X-Amz-Date")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Date", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Security-Token")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Security-Token", valid_603388
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603389 = header.getOrDefault("X-Amz-Target")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_603389 != nil:
    section.add "X-Amz-Target", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Content-Sha256", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Algorithm")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Algorithm", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Signature")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Signature", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Credential")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Credential", valid_603394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603396: Call_DeleteTags_603384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_603396.validator(path, query, header, formData, body)
  let scheme = call_603396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603396.url(scheme.get, call_603396.host, call_603396.base,
                         call_603396.route, valid.getOrDefault("path"))
  result = hook(call_603396, url, valid)

proc call*(call_603397: Call_DeleteTags_603384; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_603398 = newJObject()
  if body != nil:
    body_603398 = body
  result = call_603397.call(nil, nil, nil, nil, body_603398)

var deleteTags* = Call_DeleteTags_603384(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_603385,
                                      base: "/", url: url_DeleteTags_603386,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_603399 = ref object of OpenApiRestCall_602433
proc url_DeleteWorkteam_603401(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteWorkteam_603400(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603402 = header.getOrDefault("X-Amz-Date")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Date", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Security-Token")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Security-Token", valid_603403
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603404 = header.getOrDefault("X-Amz-Target")
  valid_603404 = validateParameter(valid_603404, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_603404 != nil:
    section.add "X-Amz-Target", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Content-Sha256", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Signature")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Signature", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Credential")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Credential", valid_603409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603411: Call_DeleteWorkteam_603399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_603411.validator(path, query, header, formData, body)
  let scheme = call_603411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603411.url(scheme.get, call_603411.host, call_603411.base,
                         call_603411.route, valid.getOrDefault("path"))
  result = hook(call_603411, url, valid)

proc call*(call_603412: Call_DeleteWorkteam_603399; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_603413 = newJObject()
  if body != nil:
    body_603413 = body
  result = call_603412.call(nil, nil, nil, nil, body_603413)

var deleteWorkteam* = Call_DeleteWorkteam_603399(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_603400, base: "/", url: url_DeleteWorkteam_603401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_603414 = ref object of OpenApiRestCall_602433
proc url_DescribeAlgorithm_603416(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAlgorithm_603415(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603417 = header.getOrDefault("X-Amz-Date")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Date", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Security-Token")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Security-Token", valid_603418
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603419 = header.getOrDefault("X-Amz-Target")
  valid_603419 = validateParameter(valid_603419, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_603419 != nil:
    section.add "X-Amz-Target", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Content-Sha256", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Algorithm")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Algorithm", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Signature")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Signature", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-SignedHeaders", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Credential")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Credential", valid_603424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603426: Call_DescribeAlgorithm_603414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_603426.validator(path, query, header, formData, body)
  let scheme = call_603426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603426.url(scheme.get, call_603426.host, call_603426.base,
                         call_603426.route, valid.getOrDefault("path"))
  result = hook(call_603426, url, valid)

proc call*(call_603427: Call_DescribeAlgorithm_603414; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_603428 = newJObject()
  if body != nil:
    body_603428 = body
  result = call_603427.call(nil, nil, nil, nil, body_603428)

var describeAlgorithm* = Call_DescribeAlgorithm_603414(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_603415, base: "/",
    url: url_DescribeAlgorithm_603416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_603429 = ref object of OpenApiRestCall_602433
proc url_DescribeCodeRepository_603431(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCodeRepository_603430(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603432 = header.getOrDefault("X-Amz-Date")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Date", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Security-Token")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Security-Token", valid_603433
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603434 = header.getOrDefault("X-Amz-Target")
  valid_603434 = validateParameter(valid_603434, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_603434 != nil:
    section.add "X-Amz-Target", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Credential")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Credential", valid_603439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603441: Call_DescribeCodeRepository_603429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_603441.validator(path, query, header, formData, body)
  let scheme = call_603441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603441.url(scheme.get, call_603441.host, call_603441.base,
                         call_603441.route, valid.getOrDefault("path"))
  result = hook(call_603441, url, valid)

proc call*(call_603442: Call_DescribeCodeRepository_603429; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_603443 = newJObject()
  if body != nil:
    body_603443 = body
  result = call_603442.call(nil, nil, nil, nil, body_603443)

var describeCodeRepository* = Call_DescribeCodeRepository_603429(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_603430, base: "/",
    url: url_DescribeCodeRepository_603431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_603444 = ref object of OpenApiRestCall_602433
proc url_DescribeCompilationJob_603446(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCompilationJob_603445(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603447 = header.getOrDefault("X-Amz-Date")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Date", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Security-Token")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Security-Token", valid_603448
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603449 = header.getOrDefault("X-Amz-Target")
  valid_603449 = validateParameter(valid_603449, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_603449 != nil:
    section.add "X-Amz-Target", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Content-Sha256", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Algorithm")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Algorithm", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Signature")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Signature", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Credential")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Credential", valid_603454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_DescribeCompilationJob_603444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_DescribeCompilationJob_603444; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_603458 = newJObject()
  if body != nil:
    body_603458 = body
  result = call_603457.call(nil, nil, nil, nil, body_603458)

var describeCompilationJob* = Call_DescribeCompilationJob_603444(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_603445, base: "/",
    url: url_DescribeCompilationJob_603446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_603459 = ref object of OpenApiRestCall_602433
proc url_DescribeEndpoint_603461(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpoint_603460(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603462 = header.getOrDefault("X-Amz-Date")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Date", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Security-Token")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Security-Token", valid_603463
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603464 = header.getOrDefault("X-Amz-Target")
  valid_603464 = validateParameter(valid_603464, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_603464 != nil:
    section.add "X-Amz-Target", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Content-Sha256", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Algorithm")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Algorithm", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Signature")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Signature", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-SignedHeaders", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Credential")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Credential", valid_603469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603471: Call_DescribeEndpoint_603459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_603471.validator(path, query, header, formData, body)
  let scheme = call_603471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603471.url(scheme.get, call_603471.host, call_603471.base,
                         call_603471.route, valid.getOrDefault("path"))
  result = hook(call_603471, url, valid)

proc call*(call_603472: Call_DescribeEndpoint_603459; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_603473 = newJObject()
  if body != nil:
    body_603473 = body
  result = call_603472.call(nil, nil, nil, nil, body_603473)

var describeEndpoint* = Call_DescribeEndpoint_603459(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_603460, base: "/",
    url: url_DescribeEndpoint_603461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_603474 = ref object of OpenApiRestCall_602433
proc url_DescribeEndpointConfig_603476(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeEndpointConfig_603475(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603477 = header.getOrDefault("X-Amz-Date")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Date", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Security-Token")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Security-Token", valid_603478
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603479 = header.getOrDefault("X-Amz-Target")
  valid_603479 = validateParameter(valid_603479, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_603479 != nil:
    section.add "X-Amz-Target", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Content-Sha256", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Algorithm")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Algorithm", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Signature")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Signature", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-SignedHeaders", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Credential")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Credential", valid_603484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603486: Call_DescribeEndpointConfig_603474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_603486.validator(path, query, header, formData, body)
  let scheme = call_603486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603486.url(scheme.get, call_603486.host, call_603486.base,
                         call_603486.route, valid.getOrDefault("path"))
  result = hook(call_603486, url, valid)

proc call*(call_603487: Call_DescribeEndpointConfig_603474; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_603488 = newJObject()
  if body != nil:
    body_603488 = body
  result = call_603487.call(nil, nil, nil, nil, body_603488)

var describeEndpointConfig* = Call_DescribeEndpointConfig_603474(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_603475, base: "/",
    url: url_DescribeEndpointConfig_603476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_603489 = ref object of OpenApiRestCall_602433
proc url_DescribeHyperParameterTuningJob_603491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeHyperParameterTuningJob_603490(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603492 = header.getOrDefault("X-Amz-Date")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Date", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Security-Token")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Security-Token", valid_603493
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603494 = header.getOrDefault("X-Amz-Target")
  valid_603494 = validateParameter(valid_603494, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_603494 != nil:
    section.add "X-Amz-Target", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Content-Sha256", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Algorithm")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Algorithm", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-SignedHeaders", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Credential")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Credential", valid_603499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603501: Call_DescribeHyperParameterTuningJob_603489;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_603501.validator(path, query, header, formData, body)
  let scheme = call_603501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603501.url(scheme.get, call_603501.host, call_603501.base,
                         call_603501.route, valid.getOrDefault("path"))
  result = hook(call_603501, url, valid)

proc call*(call_603502: Call_DescribeHyperParameterTuningJob_603489; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_603503 = newJObject()
  if body != nil:
    body_603503 = body
  result = call_603502.call(nil, nil, nil, nil, body_603503)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_603489(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_603490, base: "/",
    url: url_DescribeHyperParameterTuningJob_603491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_603504 = ref object of OpenApiRestCall_602433
proc url_DescribeLabelingJob_603506(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeLabelingJob_603505(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603507 = header.getOrDefault("X-Amz-Date")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Date", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Security-Token")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Security-Token", valid_603508
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603509 = header.getOrDefault("X-Amz-Target")
  valid_603509 = validateParameter(valid_603509, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_603509 != nil:
    section.add "X-Amz-Target", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Content-Sha256", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Algorithm")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Algorithm", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-SignedHeaders", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Credential")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Credential", valid_603514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603516: Call_DescribeLabelingJob_603504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_603516.validator(path, query, header, formData, body)
  let scheme = call_603516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603516.url(scheme.get, call_603516.host, call_603516.base,
                         call_603516.route, valid.getOrDefault("path"))
  result = hook(call_603516, url, valid)

proc call*(call_603517: Call_DescribeLabelingJob_603504; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_603518 = newJObject()
  if body != nil:
    body_603518 = body
  result = call_603517.call(nil, nil, nil, nil, body_603518)

var describeLabelingJob* = Call_DescribeLabelingJob_603504(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_603505, base: "/",
    url: url_DescribeLabelingJob_603506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_603519 = ref object of OpenApiRestCall_602433
proc url_DescribeModel_603521(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeModel_603520(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603522 = header.getOrDefault("X-Amz-Date")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Date", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Security-Token")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Security-Token", valid_603523
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603524 = header.getOrDefault("X-Amz-Target")
  valid_603524 = validateParameter(valid_603524, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_603524 != nil:
    section.add "X-Amz-Target", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Content-Sha256", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Algorithm")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Algorithm", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Signature")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Signature", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-SignedHeaders", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Credential")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Credential", valid_603529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603531: Call_DescribeModel_603519; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_603531.validator(path, query, header, formData, body)
  let scheme = call_603531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603531.url(scheme.get, call_603531.host, call_603531.base,
                         call_603531.route, valid.getOrDefault("path"))
  result = hook(call_603531, url, valid)

proc call*(call_603532: Call_DescribeModel_603519; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_603533 = newJObject()
  if body != nil:
    body_603533 = body
  result = call_603532.call(nil, nil, nil, nil, body_603533)

var describeModel* = Call_DescribeModel_603519(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_603520, base: "/", url: url_DescribeModel_603521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_603534 = ref object of OpenApiRestCall_602433
proc url_DescribeModelPackage_603536(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeModelPackage_603535(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603537 = header.getOrDefault("X-Amz-Date")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Date", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Security-Token")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Security-Token", valid_603538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603539 = header.getOrDefault("X-Amz-Target")
  valid_603539 = validateParameter(valid_603539, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_603539 != nil:
    section.add "X-Amz-Target", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Content-Sha256", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Algorithm")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Algorithm", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Signature")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Signature", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-SignedHeaders", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Credential")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Credential", valid_603544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603546: Call_DescribeModelPackage_603534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_603546.validator(path, query, header, formData, body)
  let scheme = call_603546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603546.url(scheme.get, call_603546.host, call_603546.base,
                         call_603546.route, valid.getOrDefault("path"))
  result = hook(call_603546, url, valid)

proc call*(call_603547: Call_DescribeModelPackage_603534; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_603548 = newJObject()
  if body != nil:
    body_603548 = body
  result = call_603547.call(nil, nil, nil, nil, body_603548)

var describeModelPackage* = Call_DescribeModelPackage_603534(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_603535, base: "/",
    url: url_DescribeModelPackage_603536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_603549 = ref object of OpenApiRestCall_602433
proc url_DescribeNotebookInstance_603551(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeNotebookInstance_603550(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603552 = header.getOrDefault("X-Amz-Date")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Date", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Security-Token")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Security-Token", valid_603553
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603554 = header.getOrDefault("X-Amz-Target")
  valid_603554 = validateParameter(valid_603554, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_603554 != nil:
    section.add "X-Amz-Target", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Content-Sha256", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Algorithm")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Algorithm", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Signature")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Signature", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-SignedHeaders", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Credential")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Credential", valid_603559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603561: Call_DescribeNotebookInstance_603549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_603561.validator(path, query, header, formData, body)
  let scheme = call_603561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603561.url(scheme.get, call_603561.host, call_603561.base,
                         call_603561.route, valid.getOrDefault("path"))
  result = hook(call_603561, url, valid)

proc call*(call_603562: Call_DescribeNotebookInstance_603549; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_603563 = newJObject()
  if body != nil:
    body_603563 = body
  result = call_603562.call(nil, nil, nil, nil, body_603563)

var describeNotebookInstance* = Call_DescribeNotebookInstance_603549(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_603550, base: "/",
    url: url_DescribeNotebookInstance_603551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_603564 = ref object of OpenApiRestCall_602433
proc url_DescribeNotebookInstanceLifecycleConfig_603566(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_603565(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603567 = header.getOrDefault("X-Amz-Date")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Date", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Security-Token")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Security-Token", valid_603568
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603569 = header.getOrDefault("X-Amz-Target")
  valid_603569 = validateParameter(valid_603569, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_603569 != nil:
    section.add "X-Amz-Target", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Content-Sha256", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Algorithm")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Algorithm", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Signature")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Signature", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-SignedHeaders", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Credential")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Credential", valid_603574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603576: Call_DescribeNotebookInstanceLifecycleConfig_603564;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_603576.validator(path, query, header, formData, body)
  let scheme = call_603576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603576.url(scheme.get, call_603576.host, call_603576.base,
                         call_603576.route, valid.getOrDefault("path"))
  result = hook(call_603576, url, valid)

proc call*(call_603577: Call_DescribeNotebookInstanceLifecycleConfig_603564;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_603578 = newJObject()
  if body != nil:
    body_603578 = body
  result = call_603577.call(nil, nil, nil, nil, body_603578)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_603564(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_603565, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_603566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_603579 = ref object of OpenApiRestCall_602433
proc url_DescribeSubscribedWorkteam_603581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSubscribedWorkteam_603580(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603582 = header.getOrDefault("X-Amz-Date")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Date", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-Security-Token")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-Security-Token", valid_603583
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603584 = header.getOrDefault("X-Amz-Target")
  valid_603584 = validateParameter(valid_603584, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_603584 != nil:
    section.add "X-Amz-Target", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Content-Sha256", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Algorithm")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Algorithm", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Signature")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Signature", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-SignedHeaders", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_DescribeSubscribedWorkteam_603579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"))
  result = hook(call_603591, url, valid)

proc call*(call_603592: Call_DescribeSubscribedWorkteam_603579; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_603593 = newJObject()
  if body != nil:
    body_603593 = body
  result = call_603592.call(nil, nil, nil, nil, body_603593)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_603579(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_603580, base: "/",
    url: url_DescribeSubscribedWorkteam_603581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_603594 = ref object of OpenApiRestCall_602433
proc url_DescribeTrainingJob_603596(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTrainingJob_603595(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603597 = header.getOrDefault("X-Amz-Date")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Date", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-Security-Token")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-Security-Token", valid_603598
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603599 = header.getOrDefault("X-Amz-Target")
  valid_603599 = validateParameter(valid_603599, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_603599 != nil:
    section.add "X-Amz-Target", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Content-Sha256", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Algorithm")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Algorithm", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Signature")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Signature", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-SignedHeaders", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Credential")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Credential", valid_603604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603606: Call_DescribeTrainingJob_603594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_603606.validator(path, query, header, formData, body)
  let scheme = call_603606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603606.url(scheme.get, call_603606.host, call_603606.base,
                         call_603606.route, valid.getOrDefault("path"))
  result = hook(call_603606, url, valid)

proc call*(call_603607: Call_DescribeTrainingJob_603594; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_603608 = newJObject()
  if body != nil:
    body_603608 = body
  result = call_603607.call(nil, nil, nil, nil, body_603608)

var describeTrainingJob* = Call_DescribeTrainingJob_603594(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_603595, base: "/",
    url: url_DescribeTrainingJob_603596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_603609 = ref object of OpenApiRestCall_602433
proc url_DescribeTransformJob_603611(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTransformJob_603610(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603612 = header.getOrDefault("X-Amz-Date")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Date", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Security-Token")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Security-Token", valid_603613
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603614 = header.getOrDefault("X-Amz-Target")
  valid_603614 = validateParameter(valid_603614, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_603614 != nil:
    section.add "X-Amz-Target", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Content-Sha256", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Algorithm")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Algorithm", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Signature")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Signature", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-SignedHeaders", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Credential")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Credential", valid_603619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603621: Call_DescribeTransformJob_603609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_603621.validator(path, query, header, formData, body)
  let scheme = call_603621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603621.url(scheme.get, call_603621.host, call_603621.base,
                         call_603621.route, valid.getOrDefault("path"))
  result = hook(call_603621, url, valid)

proc call*(call_603622: Call_DescribeTransformJob_603609; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_603623 = newJObject()
  if body != nil:
    body_603623 = body
  result = call_603622.call(nil, nil, nil, nil, body_603623)

var describeTransformJob* = Call_DescribeTransformJob_603609(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_603610, base: "/",
    url: url_DescribeTransformJob_603611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_603624 = ref object of OpenApiRestCall_602433
proc url_DescribeWorkteam_603626(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeWorkteam_603625(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603627 = header.getOrDefault("X-Amz-Date")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Date", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Security-Token")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Security-Token", valid_603628
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603629 = header.getOrDefault("X-Amz-Target")
  valid_603629 = validateParameter(valid_603629, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_603629 != nil:
    section.add "X-Amz-Target", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Content-Sha256", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Algorithm")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Algorithm", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Signature")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Signature", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-SignedHeaders", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Credential")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Credential", valid_603634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603636: Call_DescribeWorkteam_603624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_603636.validator(path, query, header, formData, body)
  let scheme = call_603636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603636.url(scheme.get, call_603636.host, call_603636.base,
                         call_603636.route, valid.getOrDefault("path"))
  result = hook(call_603636, url, valid)

proc call*(call_603637: Call_DescribeWorkteam_603624; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_603638 = newJObject()
  if body != nil:
    body_603638 = body
  result = call_603637.call(nil, nil, nil, nil, body_603638)

var describeWorkteam* = Call_DescribeWorkteam_603624(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_603625, base: "/",
    url: url_DescribeWorkteam_603626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_603639 = ref object of OpenApiRestCall_602433
proc url_GetSearchSuggestions_603641(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSearchSuggestions_603640(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603642 = header.getOrDefault("X-Amz-Date")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Date", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Security-Token")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Security-Token", valid_603643
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603644 = header.getOrDefault("X-Amz-Target")
  valid_603644 = validateParameter(valid_603644, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_603644 != nil:
    section.add "X-Amz-Target", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Content-Sha256", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Algorithm")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Algorithm", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Signature")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Signature", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-SignedHeaders", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Credential")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Credential", valid_603649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603651: Call_GetSearchSuggestions_603639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_603651.validator(path, query, header, formData, body)
  let scheme = call_603651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603651.url(scheme.get, call_603651.host, call_603651.base,
                         call_603651.route, valid.getOrDefault("path"))
  result = hook(call_603651, url, valid)

proc call*(call_603652: Call_GetSearchSuggestions_603639; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_603653 = newJObject()
  if body != nil:
    body_603653 = body
  result = call_603652.call(nil, nil, nil, nil, body_603653)

var getSearchSuggestions* = Call_GetSearchSuggestions_603639(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_603640, base: "/",
    url: url_GetSearchSuggestions_603641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_603654 = ref object of OpenApiRestCall_602433
proc url_ListAlgorithms_603656(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAlgorithms_603655(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the machine learning algorithms that have been created.
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
  var valid_603657 = header.getOrDefault("X-Amz-Date")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Date", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Security-Token")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Security-Token", valid_603658
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603659 = header.getOrDefault("X-Amz-Target")
  valid_603659 = validateParameter(valid_603659, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_603659 != nil:
    section.add "X-Amz-Target", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Content-Sha256", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Algorithm")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Algorithm", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Signature")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Signature", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-SignedHeaders", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Credential")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Credential", valid_603664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603666: Call_ListAlgorithms_603654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_603666.validator(path, query, header, formData, body)
  let scheme = call_603666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603666.url(scheme.get, call_603666.host, call_603666.base,
                         call_603666.route, valid.getOrDefault("path"))
  result = hook(call_603666, url, valid)

proc call*(call_603667: Call_ListAlgorithms_603654; body: JsonNode): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   body: JObject (required)
  var body_603668 = newJObject()
  if body != nil:
    body_603668 = body
  result = call_603667.call(nil, nil, nil, nil, body_603668)

var listAlgorithms* = Call_ListAlgorithms_603654(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_603655, base: "/", url: url_ListAlgorithms_603656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_603669 = ref object of OpenApiRestCall_602433
proc url_ListCodeRepositories_603671(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCodeRepositories_603670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the Git repositories in your account.
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
  var valid_603672 = header.getOrDefault("X-Amz-Date")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Date", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Security-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Security-Token", valid_603673
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603674 = header.getOrDefault("X-Amz-Target")
  valid_603674 = validateParameter(valid_603674, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_603674 != nil:
    section.add "X-Amz-Target", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Content-Sha256", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Algorithm")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Algorithm", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Signature")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Signature", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-SignedHeaders", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Credential")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Credential", valid_603679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603681: Call_ListCodeRepositories_603669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_603681.validator(path, query, header, formData, body)
  let scheme = call_603681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603681.url(scheme.get, call_603681.host, call_603681.base,
                         call_603681.route, valid.getOrDefault("path"))
  result = hook(call_603681, url, valid)

proc call*(call_603682: Call_ListCodeRepositories_603669; body: JsonNode): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   body: JObject (required)
  var body_603683 = newJObject()
  if body != nil:
    body_603683 = body
  result = call_603682.call(nil, nil, nil, nil, body_603683)

var listCodeRepositories* = Call_ListCodeRepositories_603669(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_603670, base: "/",
    url: url_ListCodeRepositories_603671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_603684 = ref object of OpenApiRestCall_602433
proc url_ListCompilationJobs_603686(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCompilationJobs_603685(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_603687 = query.getOrDefault("NextToken")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "NextToken", valid_603687
  var valid_603688 = query.getOrDefault("MaxResults")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "MaxResults", valid_603688
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
  var valid_603689 = header.getOrDefault("X-Amz-Date")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Date", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Security-Token")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Security-Token", valid_603690
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603691 = header.getOrDefault("X-Amz-Target")
  valid_603691 = validateParameter(valid_603691, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_603691 != nil:
    section.add "X-Amz-Target", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Content-Sha256", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Algorithm")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Algorithm", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Signature")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Signature", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-SignedHeaders", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Credential")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Credential", valid_603696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_ListCompilationJobs_603684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_ListCompilationJobs_603684; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603700 = newJObject()
  var body_603701 = newJObject()
  add(query_603700, "NextToken", newJString(NextToken))
  if body != nil:
    body_603701 = body
  add(query_603700, "MaxResults", newJString(MaxResults))
  result = call_603699.call(nil, query_603700, nil, nil, body_603701)

var listCompilationJobs* = Call_ListCompilationJobs_603684(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_603685, base: "/",
    url: url_ListCompilationJobs_603686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_603703 = ref object of OpenApiRestCall_602433
proc url_ListEndpointConfigs_603705(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEndpointConfigs_603704(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_603706 = query.getOrDefault("NextToken")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "NextToken", valid_603706
  var valid_603707 = query.getOrDefault("MaxResults")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "MaxResults", valid_603707
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
  var valid_603708 = header.getOrDefault("X-Amz-Date")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Date", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Security-Token")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Security-Token", valid_603709
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603710 = header.getOrDefault("X-Amz-Target")
  valid_603710 = validateParameter(valid_603710, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_603710 != nil:
    section.add "X-Amz-Target", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Content-Sha256", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Algorithm")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Algorithm", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Signature")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Signature", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-SignedHeaders", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Credential")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Credential", valid_603715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603717: Call_ListEndpointConfigs_603703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_603717.validator(path, query, header, formData, body)
  let scheme = call_603717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603717.url(scheme.get, call_603717.host, call_603717.base,
                         call_603717.route, valid.getOrDefault("path"))
  result = hook(call_603717, url, valid)

proc call*(call_603718: Call_ListEndpointConfigs_603703; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603719 = newJObject()
  var body_603720 = newJObject()
  add(query_603719, "NextToken", newJString(NextToken))
  if body != nil:
    body_603720 = body
  add(query_603719, "MaxResults", newJString(MaxResults))
  result = call_603718.call(nil, query_603719, nil, nil, body_603720)

var listEndpointConfigs* = Call_ListEndpointConfigs_603703(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_603704, base: "/",
    url: url_ListEndpointConfigs_603705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_603721 = ref object of OpenApiRestCall_602433
proc url_ListEndpoints_603723(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEndpoints_603722(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603724 = query.getOrDefault("NextToken")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "NextToken", valid_603724
  var valid_603725 = query.getOrDefault("MaxResults")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "MaxResults", valid_603725
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
  var valid_603726 = header.getOrDefault("X-Amz-Date")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Date", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Security-Token")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Security-Token", valid_603727
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603728 = header.getOrDefault("X-Amz-Target")
  valid_603728 = validateParameter(valid_603728, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_603728 != nil:
    section.add "X-Amz-Target", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Content-Sha256", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Algorithm")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Algorithm", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Signature")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Signature", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-SignedHeaders", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Credential")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Credential", valid_603733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603735: Call_ListEndpoints_603721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_603735.validator(path, query, header, formData, body)
  let scheme = call_603735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603735.url(scheme.get, call_603735.host, call_603735.base,
                         call_603735.route, valid.getOrDefault("path"))
  result = hook(call_603735, url, valid)

proc call*(call_603736: Call_ListEndpoints_603721; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603737 = newJObject()
  var body_603738 = newJObject()
  add(query_603737, "NextToken", newJString(NextToken))
  if body != nil:
    body_603738 = body
  add(query_603737, "MaxResults", newJString(MaxResults))
  result = call_603736.call(nil, query_603737, nil, nil, body_603738)

var listEndpoints* = Call_ListEndpoints_603721(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_603722, base: "/", url: url_ListEndpoints_603723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_603739 = ref object of OpenApiRestCall_602433
proc url_ListHyperParameterTuningJobs_603741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListHyperParameterTuningJobs_603740(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603742 = query.getOrDefault("NextToken")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "NextToken", valid_603742
  var valid_603743 = query.getOrDefault("MaxResults")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "MaxResults", valid_603743
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
  var valid_603744 = header.getOrDefault("X-Amz-Date")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Date", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Security-Token")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Security-Token", valid_603745
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603746 = header.getOrDefault("X-Amz-Target")
  valid_603746 = validateParameter(valid_603746, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_603746 != nil:
    section.add "X-Amz-Target", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Content-Sha256", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Algorithm")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Algorithm", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Signature")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Signature", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-SignedHeaders", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Credential")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Credential", valid_603751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603753: Call_ListHyperParameterTuningJobs_603739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_603753.validator(path, query, header, formData, body)
  let scheme = call_603753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603753.url(scheme.get, call_603753.host, call_603753.base,
                         call_603753.route, valid.getOrDefault("path"))
  result = hook(call_603753, url, valid)

proc call*(call_603754: Call_ListHyperParameterTuningJobs_603739; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603755 = newJObject()
  var body_603756 = newJObject()
  add(query_603755, "NextToken", newJString(NextToken))
  if body != nil:
    body_603756 = body
  add(query_603755, "MaxResults", newJString(MaxResults))
  result = call_603754.call(nil, query_603755, nil, nil, body_603756)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_603739(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_603740, base: "/",
    url: url_ListHyperParameterTuningJobs_603741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_603757 = ref object of OpenApiRestCall_602433
proc url_ListLabelingJobs_603759(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLabelingJobs_603758(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_603760 = query.getOrDefault("NextToken")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "NextToken", valid_603760
  var valid_603761 = query.getOrDefault("MaxResults")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "MaxResults", valid_603761
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
  var valid_603762 = header.getOrDefault("X-Amz-Date")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Date", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Security-Token")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Security-Token", valid_603763
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603764 = header.getOrDefault("X-Amz-Target")
  valid_603764 = validateParameter(valid_603764, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_603764 != nil:
    section.add "X-Amz-Target", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Content-Sha256", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Algorithm")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Algorithm", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Signature")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Signature", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-SignedHeaders", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Credential")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Credential", valid_603769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603771: Call_ListLabelingJobs_603757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_603771.validator(path, query, header, formData, body)
  let scheme = call_603771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603771.url(scheme.get, call_603771.host, call_603771.base,
                         call_603771.route, valid.getOrDefault("path"))
  result = hook(call_603771, url, valid)

proc call*(call_603772: Call_ListLabelingJobs_603757; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603773 = newJObject()
  var body_603774 = newJObject()
  add(query_603773, "NextToken", newJString(NextToken))
  if body != nil:
    body_603774 = body
  add(query_603773, "MaxResults", newJString(MaxResults))
  result = call_603772.call(nil, query_603773, nil, nil, body_603774)

var listLabelingJobs* = Call_ListLabelingJobs_603757(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_603758, base: "/",
    url: url_ListLabelingJobs_603759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_603775 = ref object of OpenApiRestCall_602433
proc url_ListLabelingJobsForWorkteam_603777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLabelingJobsForWorkteam_603776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603778 = query.getOrDefault("NextToken")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "NextToken", valid_603778
  var valid_603779 = query.getOrDefault("MaxResults")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "MaxResults", valid_603779
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
  var valid_603780 = header.getOrDefault("X-Amz-Date")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Date", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Security-Token")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Security-Token", valid_603781
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603782 = header.getOrDefault("X-Amz-Target")
  valid_603782 = validateParameter(valid_603782, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_603782 != nil:
    section.add "X-Amz-Target", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Content-Sha256", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Algorithm")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Algorithm", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Signature")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Signature", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-SignedHeaders", valid_603786
  var valid_603787 = header.getOrDefault("X-Amz-Credential")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Credential", valid_603787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603789: Call_ListLabelingJobsForWorkteam_603775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_603789.validator(path, query, header, formData, body)
  let scheme = call_603789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603789.url(scheme.get, call_603789.host, call_603789.base,
                         call_603789.route, valid.getOrDefault("path"))
  result = hook(call_603789, url, valid)

proc call*(call_603790: Call_ListLabelingJobsForWorkteam_603775; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603791 = newJObject()
  var body_603792 = newJObject()
  add(query_603791, "NextToken", newJString(NextToken))
  if body != nil:
    body_603792 = body
  add(query_603791, "MaxResults", newJString(MaxResults))
  result = call_603790.call(nil, query_603791, nil, nil, body_603792)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_603775(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_603776, base: "/",
    url: url_ListLabelingJobsForWorkteam_603777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_603793 = ref object of OpenApiRestCall_602433
proc url_ListModelPackages_603795(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListModelPackages_603794(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the model packages that have been created.
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
  var valid_603796 = header.getOrDefault("X-Amz-Date")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Date", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Security-Token")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Security-Token", valid_603797
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603798 = header.getOrDefault("X-Amz-Target")
  valid_603798 = validateParameter(valid_603798, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_603798 != nil:
    section.add "X-Amz-Target", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603805: Call_ListModelPackages_603793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_603805.validator(path, query, header, formData, body)
  let scheme = call_603805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603805.url(scheme.get, call_603805.host, call_603805.base,
                         call_603805.route, valid.getOrDefault("path"))
  result = hook(call_603805, url, valid)

proc call*(call_603806: Call_ListModelPackages_603793; body: JsonNode): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   body: JObject (required)
  var body_603807 = newJObject()
  if body != nil:
    body_603807 = body
  result = call_603806.call(nil, nil, nil, nil, body_603807)

var listModelPackages* = Call_ListModelPackages_603793(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_603794, base: "/",
    url: url_ListModelPackages_603795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_603808 = ref object of OpenApiRestCall_602433
proc url_ListModels_603810(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListModels_603809(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603811 = query.getOrDefault("NextToken")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "NextToken", valid_603811
  var valid_603812 = query.getOrDefault("MaxResults")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "MaxResults", valid_603812
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
  var valid_603813 = header.getOrDefault("X-Amz-Date")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Date", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Security-Token")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Security-Token", valid_603814
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603815 = header.getOrDefault("X-Amz-Target")
  valid_603815 = validateParameter(valid_603815, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_603815 != nil:
    section.add "X-Amz-Target", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Content-Sha256", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-Algorithm")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-Algorithm", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Signature")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Signature", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-SignedHeaders", valid_603819
  var valid_603820 = header.getOrDefault("X-Amz-Credential")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Credential", valid_603820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603822: Call_ListModels_603808; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_603822.validator(path, query, header, formData, body)
  let scheme = call_603822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603822.url(scheme.get, call_603822.host, call_603822.base,
                         call_603822.route, valid.getOrDefault("path"))
  result = hook(call_603822, url, valid)

proc call*(call_603823: Call_ListModels_603808; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603824 = newJObject()
  var body_603825 = newJObject()
  add(query_603824, "NextToken", newJString(NextToken))
  if body != nil:
    body_603825 = body
  add(query_603824, "MaxResults", newJString(MaxResults))
  result = call_603823.call(nil, query_603824, nil, nil, body_603825)

var listModels* = Call_ListModels_603808(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_603809,
                                      base: "/", url: url_ListModels_603810,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_603826 = ref object of OpenApiRestCall_602433
proc url_ListNotebookInstanceLifecycleConfigs_603828(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNotebookInstanceLifecycleConfigs_603827(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603829 = query.getOrDefault("NextToken")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "NextToken", valid_603829
  var valid_603830 = query.getOrDefault("MaxResults")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "MaxResults", valid_603830
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
  var valid_603831 = header.getOrDefault("X-Amz-Date")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Date", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Security-Token")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Security-Token", valid_603832
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603833 = header.getOrDefault("X-Amz-Target")
  valid_603833 = validateParameter(valid_603833, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_603833 != nil:
    section.add "X-Amz-Target", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Content-Sha256", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-Algorithm")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Algorithm", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Signature")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Signature", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-SignedHeaders", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Credential")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Credential", valid_603838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603840: Call_ListNotebookInstanceLifecycleConfigs_603826;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_603840.validator(path, query, header, formData, body)
  let scheme = call_603840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603840.url(scheme.get, call_603840.host, call_603840.base,
                         call_603840.route, valid.getOrDefault("path"))
  result = hook(call_603840, url, valid)

proc call*(call_603841: Call_ListNotebookInstanceLifecycleConfigs_603826;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603842 = newJObject()
  var body_603843 = newJObject()
  add(query_603842, "NextToken", newJString(NextToken))
  if body != nil:
    body_603843 = body
  add(query_603842, "MaxResults", newJString(MaxResults))
  result = call_603841.call(nil, query_603842, nil, nil, body_603843)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_603826(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_603827, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_603828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_603844 = ref object of OpenApiRestCall_602433
proc url_ListNotebookInstances_603846(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListNotebookInstances_603845(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603847 = query.getOrDefault("NextToken")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "NextToken", valid_603847
  var valid_603848 = query.getOrDefault("MaxResults")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "MaxResults", valid_603848
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
  var valid_603849 = header.getOrDefault("X-Amz-Date")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Date", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Security-Token")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Security-Token", valid_603850
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603851 = header.getOrDefault("X-Amz-Target")
  valid_603851 = validateParameter(valid_603851, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_603851 != nil:
    section.add "X-Amz-Target", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Content-Sha256", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Algorithm")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Algorithm", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Signature")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Signature", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-SignedHeaders", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Credential")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Credential", valid_603856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603858: Call_ListNotebookInstances_603844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_603858.validator(path, query, header, formData, body)
  let scheme = call_603858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603858.url(scheme.get, call_603858.host, call_603858.base,
                         call_603858.route, valid.getOrDefault("path"))
  result = hook(call_603858, url, valid)

proc call*(call_603859: Call_ListNotebookInstances_603844; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603860 = newJObject()
  var body_603861 = newJObject()
  add(query_603860, "NextToken", newJString(NextToken))
  if body != nil:
    body_603861 = body
  add(query_603860, "MaxResults", newJString(MaxResults))
  result = call_603859.call(nil, query_603860, nil, nil, body_603861)

var listNotebookInstances* = Call_ListNotebookInstances_603844(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_603845, base: "/",
    url: url_ListNotebookInstances_603846, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_603862 = ref object of OpenApiRestCall_602433
proc url_ListSubscribedWorkteams_603864(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSubscribedWorkteams_603863(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603865 = query.getOrDefault("NextToken")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "NextToken", valid_603865
  var valid_603866 = query.getOrDefault("MaxResults")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "MaxResults", valid_603866
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
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Security-Token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Security-Token", valid_603868
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603869 = header.getOrDefault("X-Amz-Target")
  valid_603869 = validateParameter(valid_603869, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_603869 != nil:
    section.add "X-Amz-Target", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Content-Sha256", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Algorithm")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Algorithm", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Signature")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Signature", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-SignedHeaders", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Credential")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Credential", valid_603874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603876: Call_ListSubscribedWorkteams_603862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_603876.validator(path, query, header, formData, body)
  let scheme = call_603876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603876.url(scheme.get, call_603876.host, call_603876.base,
                         call_603876.route, valid.getOrDefault("path"))
  result = hook(call_603876, url, valid)

proc call*(call_603877: Call_ListSubscribedWorkteams_603862; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603878 = newJObject()
  var body_603879 = newJObject()
  add(query_603878, "NextToken", newJString(NextToken))
  if body != nil:
    body_603879 = body
  add(query_603878, "MaxResults", newJString(MaxResults))
  result = call_603877.call(nil, query_603878, nil, nil, body_603879)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_603862(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_603863, base: "/",
    url: url_ListSubscribedWorkteams_603864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_603880 = ref object of OpenApiRestCall_602433
proc url_ListTags_603882(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTags_603881(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603883 = query.getOrDefault("NextToken")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "NextToken", valid_603883
  var valid_603884 = query.getOrDefault("MaxResults")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "MaxResults", valid_603884
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
  var valid_603885 = header.getOrDefault("X-Amz-Date")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Date", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Security-Token")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Security-Token", valid_603886
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603887 = header.getOrDefault("X-Amz-Target")
  valid_603887 = validateParameter(valid_603887, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_603887 != nil:
    section.add "X-Amz-Target", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Content-Sha256", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Algorithm")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Algorithm", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Signature")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Signature", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  var valid_603892 = header.getOrDefault("X-Amz-Credential")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Credential", valid_603892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603894: Call_ListTags_603880; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_603894.validator(path, query, header, formData, body)
  let scheme = call_603894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603894.url(scheme.get, call_603894.host, call_603894.base,
                         call_603894.route, valid.getOrDefault("path"))
  result = hook(call_603894, url, valid)

proc call*(call_603895: Call_ListTags_603880; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603896 = newJObject()
  var body_603897 = newJObject()
  add(query_603896, "NextToken", newJString(NextToken))
  if body != nil:
    body_603897 = body
  add(query_603896, "MaxResults", newJString(MaxResults))
  result = call_603895.call(nil, query_603896, nil, nil, body_603897)

var listTags* = Call_ListTags_603880(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_603881, base: "/",
                                  url: url_ListTags_603882,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_603898 = ref object of OpenApiRestCall_602433
proc url_ListTrainingJobs_603900(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrainingJobs_603899(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_603901 = query.getOrDefault("NextToken")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "NextToken", valid_603901
  var valid_603902 = query.getOrDefault("MaxResults")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "MaxResults", valid_603902
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
  var valid_603903 = header.getOrDefault("X-Amz-Date")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Date", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Security-Token")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Security-Token", valid_603904
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603905 = header.getOrDefault("X-Amz-Target")
  valid_603905 = validateParameter(valid_603905, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_603905 != nil:
    section.add "X-Amz-Target", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603912: Call_ListTrainingJobs_603898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_603912.validator(path, query, header, formData, body)
  let scheme = call_603912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603912.url(scheme.get, call_603912.host, call_603912.base,
                         call_603912.route, valid.getOrDefault("path"))
  result = hook(call_603912, url, valid)

proc call*(call_603913: Call_ListTrainingJobs_603898; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603914 = newJObject()
  var body_603915 = newJObject()
  add(query_603914, "NextToken", newJString(NextToken))
  if body != nil:
    body_603915 = body
  add(query_603914, "MaxResults", newJString(MaxResults))
  result = call_603913.call(nil, query_603914, nil, nil, body_603915)

var listTrainingJobs* = Call_ListTrainingJobs_603898(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_603899, base: "/",
    url: url_ListTrainingJobs_603900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_603916 = ref object of OpenApiRestCall_602433
proc url_ListTrainingJobsForHyperParameterTuningJob_603918(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_603917(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603919 = query.getOrDefault("NextToken")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "NextToken", valid_603919
  var valid_603920 = query.getOrDefault("MaxResults")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "MaxResults", valid_603920
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
  var valid_603921 = header.getOrDefault("X-Amz-Date")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Date", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Security-Token")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Security-Token", valid_603922
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603923 = header.getOrDefault("X-Amz-Target")
  valid_603923 = validateParameter(valid_603923, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_603923 != nil:
    section.add "X-Amz-Target", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Content-Sha256", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Algorithm")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Algorithm", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Signature")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Signature", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-SignedHeaders", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Credential")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Credential", valid_603928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603930: Call_ListTrainingJobsForHyperParameterTuningJob_603916;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_603930.validator(path, query, header, formData, body)
  let scheme = call_603930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603930.url(scheme.get, call_603930.host, call_603930.base,
                         call_603930.route, valid.getOrDefault("path"))
  result = hook(call_603930, url, valid)

proc call*(call_603931: Call_ListTrainingJobsForHyperParameterTuningJob_603916;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603932 = newJObject()
  var body_603933 = newJObject()
  add(query_603932, "NextToken", newJString(NextToken))
  if body != nil:
    body_603933 = body
  add(query_603932, "MaxResults", newJString(MaxResults))
  result = call_603931.call(nil, query_603932, nil, nil, body_603933)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_603916(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_603917,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_603918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_603934 = ref object of OpenApiRestCall_602433
proc url_ListTransformJobs_603936(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTransformJobs_603935(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_603937 = query.getOrDefault("NextToken")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "NextToken", valid_603937
  var valid_603938 = query.getOrDefault("MaxResults")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "MaxResults", valid_603938
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
  var valid_603939 = header.getOrDefault("X-Amz-Date")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Date", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Security-Token")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Security-Token", valid_603940
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603941 = header.getOrDefault("X-Amz-Target")
  valid_603941 = validateParameter(valid_603941, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_603941 != nil:
    section.add "X-Amz-Target", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Content-Sha256", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Algorithm")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Algorithm", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Signature")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Signature", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-SignedHeaders", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Credential")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Credential", valid_603946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603948: Call_ListTransformJobs_603934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_603948.validator(path, query, header, formData, body)
  let scheme = call_603948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603948.url(scheme.get, call_603948.host, call_603948.base,
                         call_603948.route, valid.getOrDefault("path"))
  result = hook(call_603948, url, valid)

proc call*(call_603949: Call_ListTransformJobs_603934; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603950 = newJObject()
  var body_603951 = newJObject()
  add(query_603950, "NextToken", newJString(NextToken))
  if body != nil:
    body_603951 = body
  add(query_603950, "MaxResults", newJString(MaxResults))
  result = call_603949.call(nil, query_603950, nil, nil, body_603951)

var listTransformJobs* = Call_ListTransformJobs_603934(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_603935, base: "/",
    url: url_ListTransformJobs_603936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_603952 = ref object of OpenApiRestCall_602433
proc url_ListWorkteams_603954(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListWorkteams_603953(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603955 = query.getOrDefault("NextToken")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "NextToken", valid_603955
  var valid_603956 = query.getOrDefault("MaxResults")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "MaxResults", valid_603956
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
  var valid_603957 = header.getOrDefault("X-Amz-Date")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Date", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Security-Token")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Security-Token", valid_603958
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603959 = header.getOrDefault("X-Amz-Target")
  valid_603959 = validateParameter(valid_603959, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_603959 != nil:
    section.add "X-Amz-Target", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Content-Sha256", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Algorithm")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Algorithm", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Signature")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Signature", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-SignedHeaders", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Credential")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Credential", valid_603964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603966: Call_ListWorkteams_603952; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_603966.validator(path, query, header, formData, body)
  let scheme = call_603966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603966.url(scheme.get, call_603966.host, call_603966.base,
                         call_603966.route, valid.getOrDefault("path"))
  result = hook(call_603966, url, valid)

proc call*(call_603967: Call_ListWorkteams_603952; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603968 = newJObject()
  var body_603969 = newJObject()
  add(query_603968, "NextToken", newJString(NextToken))
  if body != nil:
    body_603969 = body
  add(query_603968, "MaxResults", newJString(MaxResults))
  result = call_603967.call(nil, query_603968, nil, nil, body_603969)

var listWorkteams* = Call_ListWorkteams_603952(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_603953, base: "/", url: url_ListWorkteams_603954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_603970 = ref object of OpenApiRestCall_602433
proc url_RenderUiTemplate_603972(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RenderUiTemplate_603971(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603973 = header.getOrDefault("X-Amz-Date")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Date", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Security-Token")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Security-Token", valid_603974
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603975 = header.getOrDefault("X-Amz-Target")
  valid_603975 = validateParameter(valid_603975, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_603975 != nil:
    section.add "X-Amz-Target", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Content-Sha256", valid_603976
  var valid_603977 = header.getOrDefault("X-Amz-Algorithm")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Algorithm", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Signature")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Signature", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-SignedHeaders", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Credential")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Credential", valid_603980
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603982: Call_RenderUiTemplate_603970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_603982.validator(path, query, header, formData, body)
  let scheme = call_603982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603982.url(scheme.get, call_603982.host, call_603982.base,
                         call_603982.route, valid.getOrDefault("path"))
  result = hook(call_603982, url, valid)

proc call*(call_603983: Call_RenderUiTemplate_603970; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_603984 = newJObject()
  if body != nil:
    body_603984 = body
  result = call_603983.call(nil, nil, nil, nil, body_603984)

var renderUiTemplate* = Call_RenderUiTemplate_603970(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_603971, base: "/",
    url: url_RenderUiTemplate_603972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_603985 = ref object of OpenApiRestCall_602433
proc url_Search_603987(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_Search_603986(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
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
  var valid_603988 = query.getOrDefault("NextToken")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "NextToken", valid_603988
  var valid_603989 = query.getOrDefault("MaxResults")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "MaxResults", valid_603989
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
  var valid_603990 = header.getOrDefault("X-Amz-Date")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Date", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Security-Token")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Security-Token", valid_603991
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603992 = header.getOrDefault("X-Amz-Target")
  valid_603992 = validateParameter(valid_603992, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_603992 != nil:
    section.add "X-Amz-Target", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Content-Sha256", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Algorithm")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Algorithm", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Signature")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Signature", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-SignedHeaders", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-Credential")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Credential", valid_603997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603999: Call_Search_603985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ## 
  let valid = call_603999.validator(path, query, header, formData, body)
  let scheme = call_603999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603999.url(scheme.get, call_603999.host, call_603999.base,
                         call_603999.route, valid.getOrDefault("path"))
  result = hook(call_603999, url, valid)

proc call*(call_604000: Call_Search_603985; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604001 = newJObject()
  var body_604002 = newJObject()
  add(query_604001, "NextToken", newJString(NextToken))
  if body != nil:
    body_604002 = body
  add(query_604001, "MaxResults", newJString(MaxResults))
  result = call_604000.call(nil, query_604001, nil, nil, body_604002)

var search* = Call_Search_603985(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_603986, base: "/",
                              url: url_Search_603987,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_604003 = ref object of OpenApiRestCall_602433
proc url_StartNotebookInstance_604005(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartNotebookInstance_604004(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604006 = header.getOrDefault("X-Amz-Date")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Date", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Security-Token")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Security-Token", valid_604007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604008 = header.getOrDefault("X-Amz-Target")
  valid_604008 = validateParameter(valid_604008, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_604008 != nil:
    section.add "X-Amz-Target", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Content-Sha256", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Algorithm")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Algorithm", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Signature")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Signature", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-SignedHeaders", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Credential")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Credential", valid_604013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604015: Call_StartNotebookInstance_604003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_604015.validator(path, query, header, formData, body)
  let scheme = call_604015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604015.url(scheme.get, call_604015.host, call_604015.base,
                         call_604015.route, valid.getOrDefault("path"))
  result = hook(call_604015, url, valid)

proc call*(call_604016: Call_StartNotebookInstance_604003; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_604017 = newJObject()
  if body != nil:
    body_604017 = body
  result = call_604016.call(nil, nil, nil, nil, body_604017)

var startNotebookInstance* = Call_StartNotebookInstance_604003(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_604004, base: "/",
    url: url_StartNotebookInstance_604005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_604018 = ref object of OpenApiRestCall_602433
proc url_StopCompilationJob_604020(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopCompilationJob_604019(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604021 = header.getOrDefault("X-Amz-Date")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Date", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Security-Token")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Security-Token", valid_604022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604023 = header.getOrDefault("X-Amz-Target")
  valid_604023 = validateParameter(valid_604023, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_604023 != nil:
    section.add "X-Amz-Target", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Content-Sha256", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Algorithm")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Algorithm", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Signature")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Signature", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-SignedHeaders", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Credential")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Credential", valid_604028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604030: Call_StopCompilationJob_604018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_604030.validator(path, query, header, formData, body)
  let scheme = call_604030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604030.url(scheme.get, call_604030.host, call_604030.base,
                         call_604030.route, valid.getOrDefault("path"))
  result = hook(call_604030, url, valid)

proc call*(call_604031: Call_StopCompilationJob_604018; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_604032 = newJObject()
  if body != nil:
    body_604032 = body
  result = call_604031.call(nil, nil, nil, nil, body_604032)

var stopCompilationJob* = Call_StopCompilationJob_604018(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_604019, base: "/",
    url: url_StopCompilationJob_604020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_604033 = ref object of OpenApiRestCall_602433
proc url_StopHyperParameterTuningJob_604035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopHyperParameterTuningJob_604034(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604036 = header.getOrDefault("X-Amz-Date")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Date", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Security-Token")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Security-Token", valid_604037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604038 = header.getOrDefault("X-Amz-Target")
  valid_604038 = validateParameter(valid_604038, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_604038 != nil:
    section.add "X-Amz-Target", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Content-Sha256", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Algorithm")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Algorithm", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Signature")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Signature", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-SignedHeaders", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Credential")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Credential", valid_604043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604045: Call_StopHyperParameterTuningJob_604033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_604045.validator(path, query, header, formData, body)
  let scheme = call_604045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604045.url(scheme.get, call_604045.host, call_604045.base,
                         call_604045.route, valid.getOrDefault("path"))
  result = hook(call_604045, url, valid)

proc call*(call_604046: Call_StopHyperParameterTuningJob_604033; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_604047 = newJObject()
  if body != nil:
    body_604047 = body
  result = call_604046.call(nil, nil, nil, nil, body_604047)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_604033(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_604034, base: "/",
    url: url_StopHyperParameterTuningJob_604035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_604048 = ref object of OpenApiRestCall_602433
proc url_StopLabelingJob_604050(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopLabelingJob_604049(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604051 = header.getOrDefault("X-Amz-Date")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Date", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Security-Token")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Security-Token", valid_604052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604053 = header.getOrDefault("X-Amz-Target")
  valid_604053 = validateParameter(valid_604053, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_604053 != nil:
    section.add "X-Amz-Target", valid_604053
  var valid_604054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Content-Sha256", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Algorithm")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Algorithm", valid_604055
  var valid_604056 = header.getOrDefault("X-Amz-Signature")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "X-Amz-Signature", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-SignedHeaders", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Credential")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Credential", valid_604058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604060: Call_StopLabelingJob_604048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_604060.validator(path, query, header, formData, body)
  let scheme = call_604060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604060.url(scheme.get, call_604060.host, call_604060.base,
                         call_604060.route, valid.getOrDefault("path"))
  result = hook(call_604060, url, valid)

proc call*(call_604061: Call_StopLabelingJob_604048; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_604062 = newJObject()
  if body != nil:
    body_604062 = body
  result = call_604061.call(nil, nil, nil, nil, body_604062)

var stopLabelingJob* = Call_StopLabelingJob_604048(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_604049, base: "/", url: url_StopLabelingJob_604050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_604063 = ref object of OpenApiRestCall_602433
proc url_StopNotebookInstance_604065(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopNotebookInstance_604064(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604066 = header.getOrDefault("X-Amz-Date")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Date", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Security-Token")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Security-Token", valid_604067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604068 = header.getOrDefault("X-Amz-Target")
  valid_604068 = validateParameter(valid_604068, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_604068 != nil:
    section.add "X-Amz-Target", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Content-Sha256", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Algorithm")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Algorithm", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Signature")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Signature", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-SignedHeaders", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Credential")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Credential", valid_604073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604075: Call_StopNotebookInstance_604063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_604075.validator(path, query, header, formData, body)
  let scheme = call_604075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604075.url(scheme.get, call_604075.host, call_604075.base,
                         call_604075.route, valid.getOrDefault("path"))
  result = hook(call_604075, url, valid)

proc call*(call_604076: Call_StopNotebookInstance_604063; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_604077 = newJObject()
  if body != nil:
    body_604077 = body
  result = call_604076.call(nil, nil, nil, nil, body_604077)

var stopNotebookInstance* = Call_StopNotebookInstance_604063(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_604064, base: "/",
    url: url_StopNotebookInstance_604065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_604078 = ref object of OpenApiRestCall_602433
proc url_StopTrainingJob_604080(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTrainingJob_604079(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604081 = header.getOrDefault("X-Amz-Date")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Date", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Security-Token")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Security-Token", valid_604082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604083 = header.getOrDefault("X-Amz-Target")
  valid_604083 = validateParameter(valid_604083, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_604083 != nil:
    section.add "X-Amz-Target", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Content-Sha256", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Algorithm")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Algorithm", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Signature")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Signature", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-SignedHeaders", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Credential")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Credential", valid_604088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604090: Call_StopTrainingJob_604078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_604090.validator(path, query, header, formData, body)
  let scheme = call_604090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604090.url(scheme.get, call_604090.host, call_604090.base,
                         call_604090.route, valid.getOrDefault("path"))
  result = hook(call_604090, url, valid)

proc call*(call_604091: Call_StopTrainingJob_604078; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_604092 = newJObject()
  if body != nil:
    body_604092 = body
  result = call_604091.call(nil, nil, nil, nil, body_604092)

var stopTrainingJob* = Call_StopTrainingJob_604078(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_604079, base: "/", url: url_StopTrainingJob_604080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_604093 = ref object of OpenApiRestCall_602433
proc url_StopTransformJob_604095(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTransformJob_604094(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604096 = header.getOrDefault("X-Amz-Date")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Date", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Security-Token")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Security-Token", valid_604097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604098 = header.getOrDefault("X-Amz-Target")
  valid_604098 = validateParameter(valid_604098, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_604098 != nil:
    section.add "X-Amz-Target", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Content-Sha256", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Algorithm")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Algorithm", valid_604100
  var valid_604101 = header.getOrDefault("X-Amz-Signature")
  valid_604101 = validateParameter(valid_604101, JString, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "X-Amz-Signature", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-SignedHeaders", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Credential")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Credential", valid_604103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604105: Call_StopTransformJob_604093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_604105.validator(path, query, header, formData, body)
  let scheme = call_604105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604105.url(scheme.get, call_604105.host, call_604105.base,
                         call_604105.route, valid.getOrDefault("path"))
  result = hook(call_604105, url, valid)

proc call*(call_604106: Call_StopTransformJob_604093; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_604107 = newJObject()
  if body != nil:
    body_604107 = body
  result = call_604106.call(nil, nil, nil, nil, body_604107)

var stopTransformJob* = Call_StopTransformJob_604093(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_604094, base: "/",
    url: url_StopTransformJob_604095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_604108 = ref object of OpenApiRestCall_602433
proc url_UpdateCodeRepository_604110(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCodeRepository_604109(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604111 = header.getOrDefault("X-Amz-Date")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Date", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Security-Token")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Security-Token", valid_604112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604113 = header.getOrDefault("X-Amz-Target")
  valid_604113 = validateParameter(valid_604113, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_604113 != nil:
    section.add "X-Amz-Target", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Content-Sha256", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Algorithm")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Algorithm", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-Signature")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-Signature", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-SignedHeaders", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Credential")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Credential", valid_604118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604120: Call_UpdateCodeRepository_604108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_604120.validator(path, query, header, formData, body)
  let scheme = call_604120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604120.url(scheme.get, call_604120.host, call_604120.base,
                         call_604120.route, valid.getOrDefault("path"))
  result = hook(call_604120, url, valid)

proc call*(call_604121: Call_UpdateCodeRepository_604108; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_604122 = newJObject()
  if body != nil:
    body_604122 = body
  result = call_604121.call(nil, nil, nil, nil, body_604122)

var updateCodeRepository* = Call_UpdateCodeRepository_604108(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_604109, base: "/",
    url: url_UpdateCodeRepository_604110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_604123 = ref object of OpenApiRestCall_602433
proc url_UpdateEndpoint_604125(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEndpoint_604124(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604126 = header.getOrDefault("X-Amz-Date")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Date", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Security-Token")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Security-Token", valid_604127
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604128 = header.getOrDefault("X-Amz-Target")
  valid_604128 = validateParameter(valid_604128, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_604128 != nil:
    section.add "X-Amz-Target", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Content-Sha256", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Algorithm")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Algorithm", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Signature")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Signature", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-SignedHeaders", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-Credential")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Credential", valid_604133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604135: Call_UpdateEndpoint_604123; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_604135.validator(path, query, header, formData, body)
  let scheme = call_604135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604135.url(scheme.get, call_604135.host, call_604135.base,
                         call_604135.route, valid.getOrDefault("path"))
  result = hook(call_604135, url, valid)

proc call*(call_604136: Call_UpdateEndpoint_604123; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_604137 = newJObject()
  if body != nil:
    body_604137 = body
  result = call_604136.call(nil, nil, nil, nil, body_604137)

var updateEndpoint* = Call_UpdateEndpoint_604123(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_604124, base: "/", url: url_UpdateEndpoint_604125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_604138 = ref object of OpenApiRestCall_602433
proc url_UpdateEndpointWeightsAndCapacities_604140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateEndpointWeightsAndCapacities_604139(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604141 = header.getOrDefault("X-Amz-Date")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Date", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Security-Token")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Security-Token", valid_604142
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604143 = header.getOrDefault("X-Amz-Target")
  valid_604143 = validateParameter(valid_604143, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_604143 != nil:
    section.add "X-Amz-Target", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Content-Sha256", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Algorithm")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Algorithm", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Signature")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Signature", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-SignedHeaders", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Credential")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Credential", valid_604148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604150: Call_UpdateEndpointWeightsAndCapacities_604138;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_604150.validator(path, query, header, formData, body)
  let scheme = call_604150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604150.url(scheme.get, call_604150.host, call_604150.base,
                         call_604150.route, valid.getOrDefault("path"))
  result = hook(call_604150, url, valid)

proc call*(call_604151: Call_UpdateEndpointWeightsAndCapacities_604138;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_604152 = newJObject()
  if body != nil:
    body_604152 = body
  result = call_604151.call(nil, nil, nil, nil, body_604152)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_604138(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_604139, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_604140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_604153 = ref object of OpenApiRestCall_602433
proc url_UpdateNotebookInstance_604155(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateNotebookInstance_604154(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604156 = header.getOrDefault("X-Amz-Date")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Date", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Security-Token")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Security-Token", valid_604157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604158 = header.getOrDefault("X-Amz-Target")
  valid_604158 = validateParameter(valid_604158, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_604158 != nil:
    section.add "X-Amz-Target", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Content-Sha256", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Algorithm")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Algorithm", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Signature")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Signature", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-SignedHeaders", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Credential")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Credential", valid_604163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604165: Call_UpdateNotebookInstance_604153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_604165.validator(path, query, header, formData, body)
  let scheme = call_604165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604165.url(scheme.get, call_604165.host, call_604165.base,
                         call_604165.route, valid.getOrDefault("path"))
  result = hook(call_604165, url, valid)

proc call*(call_604166: Call_UpdateNotebookInstance_604153; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_604167 = newJObject()
  if body != nil:
    body_604167 = body
  result = call_604166.call(nil, nil, nil, nil, body_604167)

var updateNotebookInstance* = Call_UpdateNotebookInstance_604153(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_604154, base: "/",
    url: url_UpdateNotebookInstance_604155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_604168 = ref object of OpenApiRestCall_602433
proc url_UpdateNotebookInstanceLifecycleConfig_604170(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_604169(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604171 = header.getOrDefault("X-Amz-Date")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Date", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Security-Token")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Security-Token", valid_604172
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604173 = header.getOrDefault("X-Amz-Target")
  valid_604173 = validateParameter(valid_604173, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_604173 != nil:
    section.add "X-Amz-Target", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Content-Sha256", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Algorithm")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Algorithm", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Signature")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Signature", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-SignedHeaders", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Credential")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Credential", valid_604178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604180: Call_UpdateNotebookInstanceLifecycleConfig_604168;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_604180.validator(path, query, header, formData, body)
  let scheme = call_604180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604180.url(scheme.get, call_604180.host, call_604180.base,
                         call_604180.route, valid.getOrDefault("path"))
  result = hook(call_604180, url, valid)

proc call*(call_604181: Call_UpdateNotebookInstanceLifecycleConfig_604168;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_604182 = newJObject()
  if body != nil:
    body_604182 = body
  result = call_604181.call(nil, nil, nil, nil, body_604182)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_604168(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_604169, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_604170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_604183 = ref object of OpenApiRestCall_602433
proc url_UpdateWorkteam_604185(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateWorkteam_604184(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604186 = header.getOrDefault("X-Amz-Date")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Date", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Security-Token")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Security-Token", valid_604187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604188 = header.getOrDefault("X-Amz-Target")
  valid_604188 = validateParameter(valid_604188, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_604188 != nil:
    section.add "X-Amz-Target", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Content-Sha256", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Algorithm")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Algorithm", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-Signature")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Signature", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-SignedHeaders", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Credential")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Credential", valid_604193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604195: Call_UpdateWorkteam_604183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_604195.validator(path, query, header, formData, body)
  let scheme = call_604195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604195.url(scheme.get, call_604195.host, call_604195.base,
                         call_604195.route, valid.getOrDefault("path"))
  result = hook(call_604195, url, valid)

proc call*(call_604196: Call_UpdateWorkteam_604183; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_604197 = newJObject()
  if body != nil:
    body_604197 = body
  result = call_604196.call(nil, nil, nil, nil, body_604197)

var updateWorkteam* = Call_UpdateWorkteam_604183(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_604184, base: "/", url: url_UpdateWorkteam_604185,
    schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
