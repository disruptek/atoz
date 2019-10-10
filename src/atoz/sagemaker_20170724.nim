
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_602803 = ref object of OpenApiRestCall_602466
proc url_AddTags_602805(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTags_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_AddTags_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_AddTags_602803; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var addTags* = Call_AddTags_602803(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_602804, base: "/",
                                url: url_AddTags_602805,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_603072 = ref object of OpenApiRestCall_602466
proc url_CreateAlgorithm_603074(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAlgorithm_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CreateAlgorithm_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CreateAlgorithm_603072; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var createAlgorithm* = Call_CreateAlgorithm_603072(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_603073, base: "/", url: url_CreateAlgorithm_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_603087 = ref object of OpenApiRestCall_602466
proc url_CreateCodeRepository_603089(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCodeRepository_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateCodeRepository_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateCodeRepository_603087; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createCodeRepository* = Call_CreateCodeRepository_603087(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_603088, base: "/",
    url: url_CreateCodeRepository_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_603102 = ref object of OpenApiRestCall_602466
proc url_CreateCompilationJob_603104(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCompilationJob_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateCompilationJob_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateCompilationJob_603102; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createCompilationJob* = Call_CreateCompilationJob_603102(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_603103, base: "/",
    url: url_CreateCompilationJob_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_603117 = ref object of OpenApiRestCall_602466
proc url_CreateEndpoint_603119(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEndpoint_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateEndpoint_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateEndpoint_603117; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createEndpoint* = Call_CreateEndpoint_603117(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_603118, base: "/", url: url_CreateEndpoint_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_603132 = ref object of OpenApiRestCall_602466
proc url_CreateEndpointConfig_603134(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEndpointConfig_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateEndpointConfig_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateEndpointConfig_603132; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createEndpointConfig* = Call_CreateEndpointConfig_603132(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_603133, base: "/",
    url: url_CreateEndpointConfig_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_603147 = ref object of OpenApiRestCall_602466
proc url_CreateHyperParameterTuningJob_603149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHyperParameterTuningJob_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateHyperParameterTuningJob_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateHyperParameterTuningJob_603147; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_603147(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_603148, base: "/",
    url: url_CreateHyperParameterTuningJob_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_603162 = ref object of OpenApiRestCall_602466
proc url_CreateLabelingJob_603164(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLabelingJob_603163(path: JsonNode; query: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateLabelingJob_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateLabelingJob_603162; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createLabelingJob* = Call_CreateLabelingJob_603162(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_603163, base: "/",
    url: url_CreateLabelingJob_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_603177 = ref object of OpenApiRestCall_602466
proc url_CreateModel_603179(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateModel_603178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_CreateModel_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_CreateModel_603177; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var createModel* = Call_CreateModel_603177(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_603178,
                                        base: "/", url: url_CreateModel_603179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_603192 = ref object of OpenApiRestCall_602466
proc url_CreateModelPackage_603194(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateModelPackage_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_CreateModelPackage_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_CreateModelPackage_603192; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var createModelPackage* = Call_CreateModelPackage_603192(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_603193, base: "/",
    url: url_CreateModelPackage_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_603207 = ref object of OpenApiRestCall_602466
proc url_CreateNotebookInstance_603209(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNotebookInstance_603208(path: JsonNode; query: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_CreateNotebookInstance_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_CreateNotebookInstance_603207; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var createNotebookInstance* = Call_CreateNotebookInstance_603207(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_603208, base: "/",
    url: url_CreateNotebookInstance_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_603222 = ref object of OpenApiRestCall_602466
proc url_CreateNotebookInstanceLifecycleConfig_603224(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_603223(path: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_CreateNotebookInstanceLifecycleConfig_603222;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_CreateNotebookInstanceLifecycleConfig_603222;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_603222(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_603223, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_603237 = ref object of OpenApiRestCall_602466
proc url_CreatePresignedNotebookInstanceUrl_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePresignedNotebookInstanceUrl_603238(path: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_CreatePresignedNotebookInstanceUrl_603237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_CreatePresignedNotebookInstanceUrl_603237;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_603237(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_603238, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_603252 = ref object of OpenApiRestCall_602466
proc url_CreateTrainingJob_603254(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrainingJob_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_CreateTrainingJob_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_CreateTrainingJob_603252; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var createTrainingJob* = Call_CreateTrainingJob_603252(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_603253, base: "/",
    url: url_CreateTrainingJob_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_603267 = ref object of OpenApiRestCall_602466
proc url_CreateTransformJob_603269(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTransformJob_603268(path: JsonNode; query: JsonNode;
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_CreateTransformJob_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_CreateTransformJob_603267; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var createTransformJob* = Call_CreateTransformJob_603267(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_603268, base: "/",
    url: url_CreateTransformJob_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_603282 = ref object of OpenApiRestCall_602466
proc url_CreateWorkteam_603284(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkteam_603283(path: JsonNode; query: JsonNode;
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_CreateWorkteam_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_CreateWorkteam_603282; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var createWorkteam* = Call_CreateWorkteam_603282(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_603283, base: "/", url: url_CreateWorkteam_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_603297 = ref object of OpenApiRestCall_602466
proc url_DeleteAlgorithm_603299(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAlgorithm_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DeleteAlgorithm_603297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DeleteAlgorithm_603297; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var deleteAlgorithm* = Call_DeleteAlgorithm_603297(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_603298, base: "/", url: url_DeleteAlgorithm_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_603312 = ref object of OpenApiRestCall_602466
proc url_DeleteCodeRepository_603314(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCodeRepository_603313(path: JsonNode; query: JsonNode;
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DeleteCodeRepository_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DeleteCodeRepository_603312; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var deleteCodeRepository* = Call_DeleteCodeRepository_603312(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_603313, base: "/",
    url: url_DeleteCodeRepository_603314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_603327 = ref object of OpenApiRestCall_602466
proc url_DeleteEndpoint_603329(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEndpoint_603328(path: JsonNode; query: JsonNode;
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DeleteEndpoint_603327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DeleteEndpoint_603327; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var deleteEndpoint* = Call_DeleteEndpoint_603327(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_603328, base: "/", url: url_DeleteEndpoint_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_603342 = ref object of OpenApiRestCall_602466
proc url_DeleteEndpointConfig_603344(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEndpointConfig_603343(path: JsonNode; query: JsonNode;
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
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DeleteEndpointConfig_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DeleteEndpointConfig_603342; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_603342(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_603343, base: "/",
    url: url_DeleteEndpointConfig_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_603357 = ref object of OpenApiRestCall_602466
proc url_DeleteModel_603359(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteModel_603358(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DeleteModel_603357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DeleteModel_603357; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var deleteModel* = Call_DeleteModel_603357(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_603358,
                                        base: "/", url: url_DeleteModel_603359,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_603372 = ref object of OpenApiRestCall_602466
proc url_DeleteModelPackage_603374(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteModelPackage_603373(path: JsonNode; query: JsonNode;
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DeleteModelPackage_603372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DeleteModelPackage_603372; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var deleteModelPackage* = Call_DeleteModelPackage_603372(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_603373, base: "/",
    url: url_DeleteModelPackage_603374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_603387 = ref object of OpenApiRestCall_602466
proc url_DeleteNotebookInstance_603389(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNotebookInstance_603388(path: JsonNode; query: JsonNode;
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DeleteNotebookInstance_603387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DeleteNotebookInstance_603387; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_603387(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_603388, base: "/",
    url: url_DeleteNotebookInstance_603389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_603402 = ref object of OpenApiRestCall_602466
proc url_DeleteNotebookInstanceLifecycleConfig_603404(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_603403(path: JsonNode;
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
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_DeleteNotebookInstanceLifecycleConfig_603402;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_DeleteNotebookInstanceLifecycleConfig_603402;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_603402(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_603403, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_603404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_603417 = ref object of OpenApiRestCall_602466
proc url_DeleteTags_603419(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_603418(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_DeleteTags_603417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_DeleteTags_603417; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var deleteTags* = Call_DeleteTags_603417(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_603418,
                                      base: "/", url: url_DeleteTags_603419,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_603432 = ref object of OpenApiRestCall_602466
proc url_DeleteWorkteam_603434(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkteam_603433(path: JsonNode; query: JsonNode;
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
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_DeleteWorkteam_603432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_DeleteWorkteam_603432; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_603446 = newJObject()
  if body != nil:
    body_603446 = body
  result = call_603445.call(nil, nil, nil, nil, body_603446)

var deleteWorkteam* = Call_DeleteWorkteam_603432(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_603433, base: "/", url: url_DeleteWorkteam_603434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_603447 = ref object of OpenApiRestCall_602466
proc url_DescribeAlgorithm_603449(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAlgorithm_603448(path: JsonNode; query: JsonNode;
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
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_DescribeAlgorithm_603447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_DescribeAlgorithm_603447; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_603461 = newJObject()
  if body != nil:
    body_603461 = body
  result = call_603460.call(nil, nil, nil, nil, body_603461)

var describeAlgorithm* = Call_DescribeAlgorithm_603447(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_603448, base: "/",
    url: url_DescribeAlgorithm_603449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_603462 = ref object of OpenApiRestCall_602466
proc url_DescribeCodeRepository_603464(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCodeRepository_603463(path: JsonNode; query: JsonNode;
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
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_DescribeCodeRepository_603462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_DescribeCodeRepository_603462; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_603476 = newJObject()
  if body != nil:
    body_603476 = body
  result = call_603475.call(nil, nil, nil, nil, body_603476)

var describeCodeRepository* = Call_DescribeCodeRepository_603462(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_603463, base: "/",
    url: url_DescribeCodeRepository_603464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_603477 = ref object of OpenApiRestCall_602466
proc url_DescribeCompilationJob_603479(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCompilationJob_603478(path: JsonNode; query: JsonNode;
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
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DescribeCompilationJob_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DescribeCompilationJob_603477; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_603491 = newJObject()
  if body != nil:
    body_603491 = body
  result = call_603490.call(nil, nil, nil, nil, body_603491)

var describeCompilationJob* = Call_DescribeCompilationJob_603477(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_603478, base: "/",
    url: url_DescribeCompilationJob_603479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_603492 = ref object of OpenApiRestCall_602466
proc url_DescribeEndpoint_603494(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoint_603493(path: JsonNode; query: JsonNode;
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
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_DescribeEndpoint_603492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_DescribeEndpoint_603492; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_603506 = newJObject()
  if body != nil:
    body_603506 = body
  result = call_603505.call(nil, nil, nil, nil, body_603506)

var describeEndpoint* = Call_DescribeEndpoint_603492(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_603493, base: "/",
    url: url_DescribeEndpoint_603494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_603507 = ref object of OpenApiRestCall_602466
proc url_DescribeEndpointConfig_603509(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpointConfig_603508(path: JsonNode; query: JsonNode;
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
  var valid_603510 = header.getOrDefault("X-Amz-Date")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Date", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Security-Token")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Security-Token", valid_603511
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603512 = header.getOrDefault("X-Amz-Target")
  valid_603512 = validateParameter(valid_603512, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_603512 != nil:
    section.add "X-Amz-Target", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Algorithm")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Algorithm", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Signature")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Signature", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Credential")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Credential", valid_603517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_DescribeEndpointConfig_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_DescribeEndpointConfig_603507; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_603521 = newJObject()
  if body != nil:
    body_603521 = body
  result = call_603520.call(nil, nil, nil, nil, body_603521)

var describeEndpointConfig* = Call_DescribeEndpointConfig_603507(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_603508, base: "/",
    url: url_DescribeEndpointConfig_603509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_603522 = ref object of OpenApiRestCall_602466
proc url_DescribeHyperParameterTuningJob_603524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeHyperParameterTuningJob_603523(path: JsonNode;
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
  var valid_603525 = header.getOrDefault("X-Amz-Date")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Date", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Security-Token")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Security-Token", valid_603526
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603527 = header.getOrDefault("X-Amz-Target")
  valid_603527 = validateParameter(valid_603527, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_603527 != nil:
    section.add "X-Amz-Target", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Content-Sha256", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Algorithm")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Algorithm", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Signature")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Signature", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Credential")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Credential", valid_603532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603534: Call_DescribeHyperParameterTuningJob_603522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_603534.validator(path, query, header, formData, body)
  let scheme = call_603534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603534.url(scheme.get, call_603534.host, call_603534.base,
                         call_603534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603534, url, valid)

proc call*(call_603535: Call_DescribeHyperParameterTuningJob_603522; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_603536 = newJObject()
  if body != nil:
    body_603536 = body
  result = call_603535.call(nil, nil, nil, nil, body_603536)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_603522(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_603523, base: "/",
    url: url_DescribeHyperParameterTuningJob_603524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_603537 = ref object of OpenApiRestCall_602466
proc url_DescribeLabelingJob_603539(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLabelingJob_603538(path: JsonNode; query: JsonNode;
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
  var valid_603540 = header.getOrDefault("X-Amz-Date")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Date", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Security-Token")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Security-Token", valid_603541
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603542 = header.getOrDefault("X-Amz-Target")
  valid_603542 = validateParameter(valid_603542, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_603542 != nil:
    section.add "X-Amz-Target", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603549: Call_DescribeLabelingJob_603537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_603549.validator(path, query, header, formData, body)
  let scheme = call_603549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603549.url(scheme.get, call_603549.host, call_603549.base,
                         call_603549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603549, url, valid)

proc call*(call_603550: Call_DescribeLabelingJob_603537; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_603551 = newJObject()
  if body != nil:
    body_603551 = body
  result = call_603550.call(nil, nil, nil, nil, body_603551)

var describeLabelingJob* = Call_DescribeLabelingJob_603537(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_603538, base: "/",
    url: url_DescribeLabelingJob_603539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_603552 = ref object of OpenApiRestCall_602466
proc url_DescribeModel_603554(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeModel_603553(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603555 = header.getOrDefault("X-Amz-Date")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Date", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Security-Token")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Security-Token", valid_603556
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603557 = header.getOrDefault("X-Amz-Target")
  valid_603557 = validateParameter(valid_603557, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_603557 != nil:
    section.add "X-Amz-Target", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603564: Call_DescribeModel_603552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_603564.validator(path, query, header, formData, body)
  let scheme = call_603564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603564.url(scheme.get, call_603564.host, call_603564.base,
                         call_603564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603564, url, valid)

proc call*(call_603565: Call_DescribeModel_603552; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_603566 = newJObject()
  if body != nil:
    body_603566 = body
  result = call_603565.call(nil, nil, nil, nil, body_603566)

var describeModel* = Call_DescribeModel_603552(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_603553, base: "/", url: url_DescribeModel_603554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_603567 = ref object of OpenApiRestCall_602466
proc url_DescribeModelPackage_603569(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeModelPackage_603568(path: JsonNode; query: JsonNode;
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
  var valid_603570 = header.getOrDefault("X-Amz-Date")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Date", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Security-Token")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Security-Token", valid_603571
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603572 = header.getOrDefault("X-Amz-Target")
  valid_603572 = validateParameter(valid_603572, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_603572 != nil:
    section.add "X-Amz-Target", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Content-Sha256", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Signature")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Signature", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_DescribeModelPackage_603567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_DescribeModelPackage_603567; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_603581 = newJObject()
  if body != nil:
    body_603581 = body
  result = call_603580.call(nil, nil, nil, nil, body_603581)

var describeModelPackage* = Call_DescribeModelPackage_603567(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_603568, base: "/",
    url: url_DescribeModelPackage_603569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_603582 = ref object of OpenApiRestCall_602466
proc url_DescribeNotebookInstance_603584(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNotebookInstance_603583(path: JsonNode; query: JsonNode;
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
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Security-Token")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Security-Token", valid_603586
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603587 = header.getOrDefault("X-Amz-Target")
  valid_603587 = validateParameter(valid_603587, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_603587 != nil:
    section.add "X-Amz-Target", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Content-Sha256", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Algorithm")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Algorithm", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Signature")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Signature", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603594: Call_DescribeNotebookInstance_603582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_603594.validator(path, query, header, formData, body)
  let scheme = call_603594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603594.url(scheme.get, call_603594.host, call_603594.base,
                         call_603594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603594, url, valid)

proc call*(call_603595: Call_DescribeNotebookInstance_603582; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_603596 = newJObject()
  if body != nil:
    body_603596 = body
  result = call_603595.call(nil, nil, nil, nil, body_603596)

var describeNotebookInstance* = Call_DescribeNotebookInstance_603582(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_603583, base: "/",
    url: url_DescribeNotebookInstance_603584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_603597 = ref object of OpenApiRestCall_602466
proc url_DescribeNotebookInstanceLifecycleConfig_603599(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_603598(path: JsonNode;
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
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603602 = header.getOrDefault("X-Amz-Target")
  valid_603602 = validateParameter(valid_603602, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_603602 != nil:
    section.add "X-Amz-Target", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Content-Sha256", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Algorithm")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Algorithm", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Signature")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Signature", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Credential")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Credential", valid_603607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603609: Call_DescribeNotebookInstanceLifecycleConfig_603597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_603609.validator(path, query, header, formData, body)
  let scheme = call_603609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603609.url(scheme.get, call_603609.host, call_603609.base,
                         call_603609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603609, url, valid)

proc call*(call_603610: Call_DescribeNotebookInstanceLifecycleConfig_603597;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_603611 = newJObject()
  if body != nil:
    body_603611 = body
  result = call_603610.call(nil, nil, nil, nil, body_603611)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_603597(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_603598, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_603599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_603612 = ref object of OpenApiRestCall_602466
proc url_DescribeSubscribedWorkteam_603614(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSubscribedWorkteam_603613(path: JsonNode; query: JsonNode;
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
  var valid_603615 = header.getOrDefault("X-Amz-Date")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Date", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Security-Token")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Security-Token", valid_603616
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603617 = header.getOrDefault("X-Amz-Target")
  valid_603617 = validateParameter(valid_603617, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_603617 != nil:
    section.add "X-Amz-Target", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Algorithm")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Algorithm", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Signature")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Signature", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Credential")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Credential", valid_603622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_DescribeSubscribedWorkteam_603612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_DescribeSubscribedWorkteam_603612; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_603626 = newJObject()
  if body != nil:
    body_603626 = body
  result = call_603625.call(nil, nil, nil, nil, body_603626)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_603612(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_603613, base: "/",
    url: url_DescribeSubscribedWorkteam_603614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_603627 = ref object of OpenApiRestCall_602466
proc url_DescribeTrainingJob_603629(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrainingJob_603628(path: JsonNode; query: JsonNode;
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
  var valid_603630 = header.getOrDefault("X-Amz-Date")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Date", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Security-Token")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Security-Token", valid_603631
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603632 = header.getOrDefault("X-Amz-Target")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_603632 != nil:
    section.add "X-Amz-Target", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_DescribeTrainingJob_603627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_DescribeTrainingJob_603627; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_603641 = newJObject()
  if body != nil:
    body_603641 = body
  result = call_603640.call(nil, nil, nil, nil, body_603641)

var describeTrainingJob* = Call_DescribeTrainingJob_603627(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_603628, base: "/",
    url: url_DescribeTrainingJob_603629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_603642 = ref object of OpenApiRestCall_602466
proc url_DescribeTransformJob_603644(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTransformJob_603643(path: JsonNode; query: JsonNode;
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
  var valid_603645 = header.getOrDefault("X-Amz-Date")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Date", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Security-Token")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Security-Token", valid_603646
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603647 = header.getOrDefault("X-Amz-Target")
  valid_603647 = validateParameter(valid_603647, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_603647 != nil:
    section.add "X-Amz-Target", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Content-Sha256", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Algorithm")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Algorithm", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Signature")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Signature", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603654: Call_DescribeTransformJob_603642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_603654.validator(path, query, header, formData, body)
  let scheme = call_603654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603654.url(scheme.get, call_603654.host, call_603654.base,
                         call_603654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603654, url, valid)

proc call*(call_603655: Call_DescribeTransformJob_603642; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_603656 = newJObject()
  if body != nil:
    body_603656 = body
  result = call_603655.call(nil, nil, nil, nil, body_603656)

var describeTransformJob* = Call_DescribeTransformJob_603642(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_603643, base: "/",
    url: url_DescribeTransformJob_603644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_603657 = ref object of OpenApiRestCall_602466
proc url_DescribeWorkteam_603659(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkteam_603658(path: JsonNode; query: JsonNode;
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
  var valid_603660 = header.getOrDefault("X-Amz-Date")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Date", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Security-Token")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Security-Token", valid_603661
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603662 = header.getOrDefault("X-Amz-Target")
  valid_603662 = validateParameter(valid_603662, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_603662 != nil:
    section.add "X-Amz-Target", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Content-Sha256", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Algorithm")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Algorithm", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Signature")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Signature", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Credential")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Credential", valid_603667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603669: Call_DescribeWorkteam_603657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_603669.validator(path, query, header, formData, body)
  let scheme = call_603669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603669.url(scheme.get, call_603669.host, call_603669.base,
                         call_603669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603669, url, valid)

proc call*(call_603670: Call_DescribeWorkteam_603657; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_603671 = newJObject()
  if body != nil:
    body_603671 = body
  result = call_603670.call(nil, nil, nil, nil, body_603671)

var describeWorkteam* = Call_DescribeWorkteam_603657(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_603658, base: "/",
    url: url_DescribeWorkteam_603659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_603672 = ref object of OpenApiRestCall_602466
proc url_GetSearchSuggestions_603674(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSearchSuggestions_603673(path: JsonNode; query: JsonNode;
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
  var valid_603675 = header.getOrDefault("X-Amz-Date")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Date", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603677 = header.getOrDefault("X-Amz-Target")
  valid_603677 = validateParameter(valid_603677, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_603677 != nil:
    section.add "X-Amz-Target", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Content-Sha256", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Algorithm")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Algorithm", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Signature")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Signature", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  var valid_603682 = header.getOrDefault("X-Amz-Credential")
  valid_603682 = validateParameter(valid_603682, JString, required = false,
                                 default = nil)
  if valid_603682 != nil:
    section.add "X-Amz-Credential", valid_603682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603684: Call_GetSearchSuggestions_603672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_603684.validator(path, query, header, formData, body)
  let scheme = call_603684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603684.url(scheme.get, call_603684.host, call_603684.base,
                         call_603684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603684, url, valid)

proc call*(call_603685: Call_GetSearchSuggestions_603672; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_603686 = newJObject()
  if body != nil:
    body_603686 = body
  result = call_603685.call(nil, nil, nil, nil, body_603686)

var getSearchSuggestions* = Call_GetSearchSuggestions_603672(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_603673, base: "/",
    url: url_GetSearchSuggestions_603674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_603687 = ref object of OpenApiRestCall_602466
proc url_ListAlgorithms_603689(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAlgorithms_603688(path: JsonNode; query: JsonNode;
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
  var valid_603690 = header.getOrDefault("X-Amz-Date")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Date", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603692 = header.getOrDefault("X-Amz-Target")
  valid_603692 = validateParameter(valid_603692, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_603692 != nil:
    section.add "X-Amz-Target", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603699: Call_ListAlgorithms_603687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_603699.validator(path, query, header, formData, body)
  let scheme = call_603699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603699.url(scheme.get, call_603699.host, call_603699.base,
                         call_603699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603699, url, valid)

proc call*(call_603700: Call_ListAlgorithms_603687; body: JsonNode): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   body: JObject (required)
  var body_603701 = newJObject()
  if body != nil:
    body_603701 = body
  result = call_603700.call(nil, nil, nil, nil, body_603701)

var listAlgorithms* = Call_ListAlgorithms_603687(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_603688, base: "/", url: url_ListAlgorithms_603689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_603702 = ref object of OpenApiRestCall_602466
proc url_ListCodeRepositories_603704(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCodeRepositories_603703(path: JsonNode; query: JsonNode;
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
  var valid_603705 = header.getOrDefault("X-Amz-Date")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Date", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Security-Token")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Security-Token", valid_603706
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603707 = header.getOrDefault("X-Amz-Target")
  valid_603707 = validateParameter(valid_603707, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_603707 != nil:
    section.add "X-Amz-Target", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_ListCodeRepositories_603702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_ListCodeRepositories_603702; body: JsonNode): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   body: JObject (required)
  var body_603716 = newJObject()
  if body != nil:
    body_603716 = body
  result = call_603715.call(nil, nil, nil, nil, body_603716)

var listCodeRepositories* = Call_ListCodeRepositories_603702(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_603703, base: "/",
    url: url_ListCodeRepositories_603704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_603717 = ref object of OpenApiRestCall_602466
proc url_ListCompilationJobs_603719(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCompilationJobs_603718(path: JsonNode; query: JsonNode;
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
  var valid_603720 = query.getOrDefault("NextToken")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "NextToken", valid_603720
  var valid_603721 = query.getOrDefault("MaxResults")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "MaxResults", valid_603721
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
  var valid_603722 = header.getOrDefault("X-Amz-Date")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Date", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Security-Token")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Security-Token", valid_603723
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603724 = header.getOrDefault("X-Amz-Target")
  valid_603724 = validateParameter(valid_603724, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_603724 != nil:
    section.add "X-Amz-Target", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Content-Sha256", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Algorithm")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Algorithm", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Signature")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Signature", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-SignedHeaders", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Credential")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Credential", valid_603729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_ListCompilationJobs_603717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_ListCompilationJobs_603717; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603733 = newJObject()
  var body_603734 = newJObject()
  add(query_603733, "NextToken", newJString(NextToken))
  if body != nil:
    body_603734 = body
  add(query_603733, "MaxResults", newJString(MaxResults))
  result = call_603732.call(nil, query_603733, nil, nil, body_603734)

var listCompilationJobs* = Call_ListCompilationJobs_603717(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_603718, base: "/",
    url: url_ListCompilationJobs_603719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_603736 = ref object of OpenApiRestCall_602466
proc url_ListEndpointConfigs_603738(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEndpointConfigs_603737(path: JsonNode; query: JsonNode;
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
  var valid_603739 = query.getOrDefault("NextToken")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "NextToken", valid_603739
  var valid_603740 = query.getOrDefault("MaxResults")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "MaxResults", valid_603740
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
  var valid_603741 = header.getOrDefault("X-Amz-Date")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Date", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Security-Token")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Security-Token", valid_603742
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603743 = header.getOrDefault("X-Amz-Target")
  valid_603743 = validateParameter(valid_603743, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_603743 != nil:
    section.add "X-Amz-Target", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Algorithm")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Algorithm", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Signature")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Signature", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-SignedHeaders", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Credential")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Credential", valid_603748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603750: Call_ListEndpointConfigs_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_603750.validator(path, query, header, formData, body)
  let scheme = call_603750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603750.url(scheme.get, call_603750.host, call_603750.base,
                         call_603750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603750, url, valid)

proc call*(call_603751: Call_ListEndpointConfigs_603736; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603752 = newJObject()
  var body_603753 = newJObject()
  add(query_603752, "NextToken", newJString(NextToken))
  if body != nil:
    body_603753 = body
  add(query_603752, "MaxResults", newJString(MaxResults))
  result = call_603751.call(nil, query_603752, nil, nil, body_603753)

var listEndpointConfigs* = Call_ListEndpointConfigs_603736(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_603737, base: "/",
    url: url_ListEndpointConfigs_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_603754 = ref object of OpenApiRestCall_602466
proc url_ListEndpoints_603756(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEndpoints_603755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603757 = query.getOrDefault("NextToken")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "NextToken", valid_603757
  var valid_603758 = query.getOrDefault("MaxResults")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "MaxResults", valid_603758
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
  var valid_603759 = header.getOrDefault("X-Amz-Date")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Date", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Security-Token")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Security-Token", valid_603760
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603761 = header.getOrDefault("X-Amz-Target")
  valid_603761 = validateParameter(valid_603761, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_603761 != nil:
    section.add "X-Amz-Target", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Content-Sha256", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Algorithm")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Algorithm", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Signature")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Signature", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-SignedHeaders", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Credential")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Credential", valid_603766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603768: Call_ListEndpoints_603754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_603768.validator(path, query, header, formData, body)
  let scheme = call_603768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603768.url(scheme.get, call_603768.host, call_603768.base,
                         call_603768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603768, url, valid)

proc call*(call_603769: Call_ListEndpoints_603754; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603770 = newJObject()
  var body_603771 = newJObject()
  add(query_603770, "NextToken", newJString(NextToken))
  if body != nil:
    body_603771 = body
  add(query_603770, "MaxResults", newJString(MaxResults))
  result = call_603769.call(nil, query_603770, nil, nil, body_603771)

var listEndpoints* = Call_ListEndpoints_603754(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_603755, base: "/", url: url_ListEndpoints_603756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_603772 = ref object of OpenApiRestCall_602466
proc url_ListHyperParameterTuningJobs_603774(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHyperParameterTuningJobs_603773(path: JsonNode; query: JsonNode;
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
  var valid_603775 = query.getOrDefault("NextToken")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "NextToken", valid_603775
  var valid_603776 = query.getOrDefault("MaxResults")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "MaxResults", valid_603776
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
  var valid_603777 = header.getOrDefault("X-Amz-Date")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Date", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Security-Token")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Security-Token", valid_603778
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603779 = header.getOrDefault("X-Amz-Target")
  valid_603779 = validateParameter(valid_603779, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_603779 != nil:
    section.add "X-Amz-Target", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Content-Sha256", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Algorithm")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Algorithm", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Signature")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Signature", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-SignedHeaders", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Credential")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Credential", valid_603784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603786: Call_ListHyperParameterTuningJobs_603772; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_603786.validator(path, query, header, formData, body)
  let scheme = call_603786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603786.url(scheme.get, call_603786.host, call_603786.base,
                         call_603786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603786, url, valid)

proc call*(call_603787: Call_ListHyperParameterTuningJobs_603772; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603788 = newJObject()
  var body_603789 = newJObject()
  add(query_603788, "NextToken", newJString(NextToken))
  if body != nil:
    body_603789 = body
  add(query_603788, "MaxResults", newJString(MaxResults))
  result = call_603787.call(nil, query_603788, nil, nil, body_603789)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_603772(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_603773, base: "/",
    url: url_ListHyperParameterTuningJobs_603774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_603790 = ref object of OpenApiRestCall_602466
proc url_ListLabelingJobs_603792(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLabelingJobs_603791(path: JsonNode; query: JsonNode;
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
  var valid_603793 = query.getOrDefault("NextToken")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "NextToken", valid_603793
  var valid_603794 = query.getOrDefault("MaxResults")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "MaxResults", valid_603794
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
  var valid_603795 = header.getOrDefault("X-Amz-Date")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Date", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Security-Token")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Security-Token", valid_603796
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603797 = header.getOrDefault("X-Amz-Target")
  valid_603797 = validateParameter(valid_603797, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_603797 != nil:
    section.add "X-Amz-Target", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Content-Sha256", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Algorithm")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Algorithm", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Signature")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Signature", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-Credential")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Credential", valid_603802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_ListLabelingJobs_603790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_ListLabelingJobs_603790; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603806 = newJObject()
  var body_603807 = newJObject()
  add(query_603806, "NextToken", newJString(NextToken))
  if body != nil:
    body_603807 = body
  add(query_603806, "MaxResults", newJString(MaxResults))
  result = call_603805.call(nil, query_603806, nil, nil, body_603807)

var listLabelingJobs* = Call_ListLabelingJobs_603790(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_603791, base: "/",
    url: url_ListLabelingJobs_603792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_603808 = ref object of OpenApiRestCall_602466
proc url_ListLabelingJobsForWorkteam_603810(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLabelingJobsForWorkteam_603809(path: JsonNode; query: JsonNode;
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
  valid_603815 = validateParameter(valid_603815, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
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

proc call*(call_603822: Call_ListLabelingJobsForWorkteam_603808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_603822.validator(path, query, header, formData, body)
  let scheme = call_603822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603822.url(scheme.get, call_603822.host, call_603822.base,
                         call_603822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603822, url, valid)

proc call*(call_603823: Call_ListLabelingJobsForWorkteam_603808; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
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

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_603808(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_603809, base: "/",
    url: url_ListLabelingJobsForWorkteam_603810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_603826 = ref object of OpenApiRestCall_602466
proc url_ListModelPackages_603828(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListModelPackages_603827(path: JsonNode; query: JsonNode;
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
  var valid_603829 = header.getOrDefault("X-Amz-Date")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Date", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Security-Token")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Security-Token", valid_603830
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603831 = header.getOrDefault("X-Amz-Target")
  valid_603831 = validateParameter(valid_603831, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_603831 != nil:
    section.add "X-Amz-Target", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Content-Sha256", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Algorithm")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Algorithm", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-SignedHeaders", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Credential")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Credential", valid_603836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603838: Call_ListModelPackages_603826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_603838.validator(path, query, header, formData, body)
  let scheme = call_603838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603838.url(scheme.get, call_603838.host, call_603838.base,
                         call_603838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603838, url, valid)

proc call*(call_603839: Call_ListModelPackages_603826; body: JsonNode): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   body: JObject (required)
  var body_603840 = newJObject()
  if body != nil:
    body_603840 = body
  result = call_603839.call(nil, nil, nil, nil, body_603840)

var listModelPackages* = Call_ListModelPackages_603826(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_603827, base: "/",
    url: url_ListModelPackages_603828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_603841 = ref object of OpenApiRestCall_602466
proc url_ListModels_603843(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListModels_603842(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603844 = query.getOrDefault("NextToken")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "NextToken", valid_603844
  var valid_603845 = query.getOrDefault("MaxResults")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "MaxResults", valid_603845
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
  var valid_603846 = header.getOrDefault("X-Amz-Date")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Date", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Security-Token")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Security-Token", valid_603847
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603848 = header.getOrDefault("X-Amz-Target")
  valid_603848 = validateParameter(valid_603848, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_603848 != nil:
    section.add "X-Amz-Target", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Content-Sha256", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-Algorithm")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-Algorithm", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Signature")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Signature", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-SignedHeaders", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Credential")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Credential", valid_603853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603855: Call_ListModels_603841; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_603855.validator(path, query, header, formData, body)
  let scheme = call_603855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603855.url(scheme.get, call_603855.host, call_603855.base,
                         call_603855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603855, url, valid)

proc call*(call_603856: Call_ListModels_603841; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603857 = newJObject()
  var body_603858 = newJObject()
  add(query_603857, "NextToken", newJString(NextToken))
  if body != nil:
    body_603858 = body
  add(query_603857, "MaxResults", newJString(MaxResults))
  result = call_603856.call(nil, query_603857, nil, nil, body_603858)

var listModels* = Call_ListModels_603841(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_603842,
                                      base: "/", url: url_ListModels_603843,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_603859 = ref object of OpenApiRestCall_602466
proc url_ListNotebookInstanceLifecycleConfigs_603861(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_603860(path: JsonNode;
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
  var valid_603862 = query.getOrDefault("NextToken")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "NextToken", valid_603862
  var valid_603863 = query.getOrDefault("MaxResults")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "MaxResults", valid_603863
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
  var valid_603864 = header.getOrDefault("X-Amz-Date")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Date", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Security-Token")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Security-Token", valid_603865
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603866 = header.getOrDefault("X-Amz-Target")
  valid_603866 = validateParameter(valid_603866, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_603866 != nil:
    section.add "X-Amz-Target", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Content-Sha256", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Algorithm")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Algorithm", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Signature")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Signature", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-SignedHeaders", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Credential")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Credential", valid_603871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603873: Call_ListNotebookInstanceLifecycleConfigs_603859;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_603873.validator(path, query, header, formData, body)
  let scheme = call_603873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603873.url(scheme.get, call_603873.host, call_603873.base,
                         call_603873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603873, url, valid)

proc call*(call_603874: Call_ListNotebookInstanceLifecycleConfigs_603859;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603875 = newJObject()
  var body_603876 = newJObject()
  add(query_603875, "NextToken", newJString(NextToken))
  if body != nil:
    body_603876 = body
  add(query_603875, "MaxResults", newJString(MaxResults))
  result = call_603874.call(nil, query_603875, nil, nil, body_603876)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_603859(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_603860, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_603861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_603877 = ref object of OpenApiRestCall_602466
proc url_ListNotebookInstances_603879(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNotebookInstances_603878(path: JsonNode; query: JsonNode;
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
  var valid_603880 = query.getOrDefault("NextToken")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "NextToken", valid_603880
  var valid_603881 = query.getOrDefault("MaxResults")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "MaxResults", valid_603881
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
  var valid_603882 = header.getOrDefault("X-Amz-Date")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Date", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Security-Token")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Security-Token", valid_603883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603884 = header.getOrDefault("X-Amz-Target")
  valid_603884 = validateParameter(valid_603884, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_603884 != nil:
    section.add "X-Amz-Target", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Content-Sha256", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Algorithm")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Algorithm", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Signature")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Signature", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-SignedHeaders", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Credential")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Credential", valid_603889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603891: Call_ListNotebookInstances_603877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_603891.validator(path, query, header, formData, body)
  let scheme = call_603891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603891.url(scheme.get, call_603891.host, call_603891.base,
                         call_603891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603891, url, valid)

proc call*(call_603892: Call_ListNotebookInstances_603877; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603893 = newJObject()
  var body_603894 = newJObject()
  add(query_603893, "NextToken", newJString(NextToken))
  if body != nil:
    body_603894 = body
  add(query_603893, "MaxResults", newJString(MaxResults))
  result = call_603892.call(nil, query_603893, nil, nil, body_603894)

var listNotebookInstances* = Call_ListNotebookInstances_603877(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_603878, base: "/",
    url: url_ListNotebookInstances_603879, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_603895 = ref object of OpenApiRestCall_602466
proc url_ListSubscribedWorkteams_603897(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscribedWorkteams_603896(path: JsonNode; query: JsonNode;
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
  var valid_603898 = query.getOrDefault("NextToken")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "NextToken", valid_603898
  var valid_603899 = query.getOrDefault("MaxResults")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "MaxResults", valid_603899
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
  var valid_603900 = header.getOrDefault("X-Amz-Date")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Date", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Security-Token")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Security-Token", valid_603901
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603902 = header.getOrDefault("X-Amz-Target")
  valid_603902 = validateParameter(valid_603902, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_603902 != nil:
    section.add "X-Amz-Target", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Content-Sha256", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Algorithm")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Algorithm", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Signature")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Signature", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-SignedHeaders", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Credential")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Credential", valid_603907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603909: Call_ListSubscribedWorkteams_603895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_603909.validator(path, query, header, formData, body)
  let scheme = call_603909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603909.url(scheme.get, call_603909.host, call_603909.base,
                         call_603909.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603909, url, valid)

proc call*(call_603910: Call_ListSubscribedWorkteams_603895; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603911 = newJObject()
  var body_603912 = newJObject()
  add(query_603911, "NextToken", newJString(NextToken))
  if body != nil:
    body_603912 = body
  add(query_603911, "MaxResults", newJString(MaxResults))
  result = call_603910.call(nil, query_603911, nil, nil, body_603912)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_603895(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_603896, base: "/",
    url: url_ListSubscribedWorkteams_603897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_603913 = ref object of OpenApiRestCall_602466
proc url_ListTags_603915(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_603914(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603916 = query.getOrDefault("NextToken")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "NextToken", valid_603916
  var valid_603917 = query.getOrDefault("MaxResults")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "MaxResults", valid_603917
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
  var valid_603918 = header.getOrDefault("X-Amz-Date")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Date", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Security-Token")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Security-Token", valid_603919
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603920 = header.getOrDefault("X-Amz-Target")
  valid_603920 = validateParameter(valid_603920, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_603920 != nil:
    section.add "X-Amz-Target", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Content-Sha256", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Algorithm")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Algorithm", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Signature")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Signature", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-SignedHeaders", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Credential")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Credential", valid_603925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603927: Call_ListTags_603913; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_603927.validator(path, query, header, formData, body)
  let scheme = call_603927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603927.url(scheme.get, call_603927.host, call_603927.base,
                         call_603927.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603927, url, valid)

proc call*(call_603928: Call_ListTags_603913; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603929 = newJObject()
  var body_603930 = newJObject()
  add(query_603929, "NextToken", newJString(NextToken))
  if body != nil:
    body_603930 = body
  add(query_603929, "MaxResults", newJString(MaxResults))
  result = call_603928.call(nil, query_603929, nil, nil, body_603930)

var listTags* = Call_ListTags_603913(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_603914, base: "/",
                                  url: url_ListTags_603915,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_603931 = ref object of OpenApiRestCall_602466
proc url_ListTrainingJobs_603933(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrainingJobs_603932(path: JsonNode; query: JsonNode;
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
  var valid_603934 = query.getOrDefault("NextToken")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "NextToken", valid_603934
  var valid_603935 = query.getOrDefault("MaxResults")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "MaxResults", valid_603935
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
  var valid_603936 = header.getOrDefault("X-Amz-Date")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Date", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Security-Token")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Security-Token", valid_603937
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603938 = header.getOrDefault("X-Amz-Target")
  valid_603938 = validateParameter(valid_603938, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_603938 != nil:
    section.add "X-Amz-Target", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Content-Sha256", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Algorithm")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Algorithm", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Signature")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Signature", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-SignedHeaders", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Credential")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Credential", valid_603943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603945: Call_ListTrainingJobs_603931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_603945.validator(path, query, header, formData, body)
  let scheme = call_603945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603945.url(scheme.get, call_603945.host, call_603945.base,
                         call_603945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603945, url, valid)

proc call*(call_603946: Call_ListTrainingJobs_603931; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603947 = newJObject()
  var body_603948 = newJObject()
  add(query_603947, "NextToken", newJString(NextToken))
  if body != nil:
    body_603948 = body
  add(query_603947, "MaxResults", newJString(MaxResults))
  result = call_603946.call(nil, query_603947, nil, nil, body_603948)

var listTrainingJobs* = Call_ListTrainingJobs_603931(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_603932, base: "/",
    url: url_ListTrainingJobs_603933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_603949 = ref object of OpenApiRestCall_602466
proc url_ListTrainingJobsForHyperParameterTuningJob_603951(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_603950(path: JsonNode;
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
  var valid_603952 = query.getOrDefault("NextToken")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "NextToken", valid_603952
  var valid_603953 = query.getOrDefault("MaxResults")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "MaxResults", valid_603953
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
  var valid_603954 = header.getOrDefault("X-Amz-Date")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Date", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Security-Token")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Security-Token", valid_603955
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603956 = header.getOrDefault("X-Amz-Target")
  valid_603956 = validateParameter(valid_603956, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_603956 != nil:
    section.add "X-Amz-Target", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Content-Sha256", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Algorithm")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Algorithm", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Signature")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Signature", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-SignedHeaders", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Credential")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Credential", valid_603961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603963: Call_ListTrainingJobsForHyperParameterTuningJob_603949;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_603963.validator(path, query, header, formData, body)
  let scheme = call_603963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603963.url(scheme.get, call_603963.host, call_603963.base,
                         call_603963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603963, url, valid)

proc call*(call_603964: Call_ListTrainingJobsForHyperParameterTuningJob_603949;
          body: JsonNode; NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603965 = newJObject()
  var body_603966 = newJObject()
  add(query_603965, "NextToken", newJString(NextToken))
  if body != nil:
    body_603966 = body
  add(query_603965, "MaxResults", newJString(MaxResults))
  result = call_603964.call(nil, query_603965, nil, nil, body_603966)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_603949(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_603950,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_603951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_603967 = ref object of OpenApiRestCall_602466
proc url_ListTransformJobs_603969(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTransformJobs_603968(path: JsonNode; query: JsonNode;
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
  var valid_603970 = query.getOrDefault("NextToken")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "NextToken", valid_603970
  var valid_603971 = query.getOrDefault("MaxResults")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "MaxResults", valid_603971
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
  var valid_603972 = header.getOrDefault("X-Amz-Date")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Date", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Security-Token")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Security-Token", valid_603973
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603974 = header.getOrDefault("X-Amz-Target")
  valid_603974 = validateParameter(valid_603974, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_603974 != nil:
    section.add "X-Amz-Target", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Content-Sha256", valid_603975
  var valid_603976 = header.getOrDefault("X-Amz-Algorithm")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "X-Amz-Algorithm", valid_603976
  var valid_603977 = header.getOrDefault("X-Amz-Signature")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Signature", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-SignedHeaders", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Credential")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Credential", valid_603979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603981: Call_ListTransformJobs_603967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_603981.validator(path, query, header, formData, body)
  let scheme = call_603981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603981.url(scheme.get, call_603981.host, call_603981.base,
                         call_603981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603981, url, valid)

proc call*(call_603982: Call_ListTransformJobs_603967; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603983 = newJObject()
  var body_603984 = newJObject()
  add(query_603983, "NextToken", newJString(NextToken))
  if body != nil:
    body_603984 = body
  add(query_603983, "MaxResults", newJString(MaxResults))
  result = call_603982.call(nil, query_603983, nil, nil, body_603984)

var listTransformJobs* = Call_ListTransformJobs_603967(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_603968, base: "/",
    url: url_ListTransformJobs_603969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_603985 = ref object of OpenApiRestCall_602466
proc url_ListWorkteams_603987(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkteams_603986(path: JsonNode; query: JsonNode; header: JsonNode;
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
  valid_603992 = validateParameter(valid_603992, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
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

proc call*(call_603999: Call_ListWorkteams_603985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_603999.validator(path, query, header, formData, body)
  let scheme = call_603999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603999.url(scheme.get, call_603999.host, call_603999.base,
                         call_603999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603999, url, valid)

proc call*(call_604000: Call_ListWorkteams_603985; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
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

var listWorkteams* = Call_ListWorkteams_603985(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_603986, base: "/", url: url_ListWorkteams_603987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_604003 = ref object of OpenApiRestCall_602466
proc url_RenderUiTemplate_604005(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RenderUiTemplate_604004(path: JsonNode; query: JsonNode;
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
      "SageMaker.RenderUiTemplate"))
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

proc call*(call_604015: Call_RenderUiTemplate_604003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_604015.validator(path, query, header, formData, body)
  let scheme = call_604015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604015.url(scheme.get, call_604015.host, call_604015.base,
                         call_604015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604015, url, valid)

proc call*(call_604016: Call_RenderUiTemplate_604003; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_604017 = newJObject()
  if body != nil:
    body_604017 = body
  result = call_604016.call(nil, nil, nil, nil, body_604017)

var renderUiTemplate* = Call_RenderUiTemplate_604003(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_604004, base: "/",
    url: url_RenderUiTemplate_604005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_604018 = ref object of OpenApiRestCall_602466
proc url_Search_604020(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Search_604019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_604021 = query.getOrDefault("NextToken")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "NextToken", valid_604021
  var valid_604022 = query.getOrDefault("MaxResults")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "MaxResults", valid_604022
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
  var valid_604023 = header.getOrDefault("X-Amz-Date")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Date", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Security-Token")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Security-Token", valid_604024
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604025 = header.getOrDefault("X-Amz-Target")
  valid_604025 = validateParameter(valid_604025, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_604025 != nil:
    section.add "X-Amz-Target", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Content-Sha256", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Algorithm")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Algorithm", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Signature")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Signature", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-SignedHeaders", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Credential")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Credential", valid_604030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604032: Call_Search_604018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ## 
  let valid = call_604032.validator(path, query, header, formData, body)
  let scheme = call_604032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604032.url(scheme.get, call_604032.host, call_604032.base,
                         call_604032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604032, url, valid)

proc call*(call_604033: Call_Search_604018; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_604034 = newJObject()
  var body_604035 = newJObject()
  add(query_604034, "NextToken", newJString(NextToken))
  if body != nil:
    body_604035 = body
  add(query_604034, "MaxResults", newJString(MaxResults))
  result = call_604033.call(nil, query_604034, nil, nil, body_604035)

var search* = Call_Search_604018(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_604019, base: "/",
                              url: url_Search_604020,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_604036 = ref object of OpenApiRestCall_602466
proc url_StartNotebookInstance_604038(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartNotebookInstance_604037(path: JsonNode; query: JsonNode;
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
  var valid_604039 = header.getOrDefault("X-Amz-Date")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Date", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Security-Token")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Security-Token", valid_604040
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604041 = header.getOrDefault("X-Amz-Target")
  valid_604041 = validateParameter(valid_604041, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_604041 != nil:
    section.add "X-Amz-Target", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Content-Sha256", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Signature")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Signature", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-SignedHeaders", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Credential")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Credential", valid_604046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604048: Call_StartNotebookInstance_604036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_604048.validator(path, query, header, formData, body)
  let scheme = call_604048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604048.url(scheme.get, call_604048.host, call_604048.base,
                         call_604048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604048, url, valid)

proc call*(call_604049: Call_StartNotebookInstance_604036; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_604050 = newJObject()
  if body != nil:
    body_604050 = body
  result = call_604049.call(nil, nil, nil, nil, body_604050)

var startNotebookInstance* = Call_StartNotebookInstance_604036(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_604037, base: "/",
    url: url_StartNotebookInstance_604038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_604051 = ref object of OpenApiRestCall_602466
proc url_StopCompilationJob_604053(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCompilationJob_604052(path: JsonNode; query: JsonNode;
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
  var valid_604054 = header.getOrDefault("X-Amz-Date")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "X-Amz-Date", valid_604054
  var valid_604055 = header.getOrDefault("X-Amz-Security-Token")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "X-Amz-Security-Token", valid_604055
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604056 = header.getOrDefault("X-Amz-Target")
  valid_604056 = validateParameter(valid_604056, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_604056 != nil:
    section.add "X-Amz-Target", valid_604056
  var valid_604057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "X-Amz-Content-Sha256", valid_604057
  var valid_604058 = header.getOrDefault("X-Amz-Algorithm")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Algorithm", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Signature")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Signature", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-SignedHeaders", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Credential")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Credential", valid_604061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604063: Call_StopCompilationJob_604051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_604063.validator(path, query, header, formData, body)
  let scheme = call_604063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604063.url(scheme.get, call_604063.host, call_604063.base,
                         call_604063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604063, url, valid)

proc call*(call_604064: Call_StopCompilationJob_604051; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_604065 = newJObject()
  if body != nil:
    body_604065 = body
  result = call_604064.call(nil, nil, nil, nil, body_604065)

var stopCompilationJob* = Call_StopCompilationJob_604051(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_604052, base: "/",
    url: url_StopCompilationJob_604053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_604066 = ref object of OpenApiRestCall_602466
proc url_StopHyperParameterTuningJob_604068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopHyperParameterTuningJob_604067(path: JsonNode; query: JsonNode;
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
  var valid_604069 = header.getOrDefault("X-Amz-Date")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Date", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Security-Token")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Security-Token", valid_604070
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604071 = header.getOrDefault("X-Amz-Target")
  valid_604071 = validateParameter(valid_604071, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_604071 != nil:
    section.add "X-Amz-Target", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Content-Sha256", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Algorithm")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Algorithm", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Signature")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Signature", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-SignedHeaders", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Credential")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Credential", valid_604076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604078: Call_StopHyperParameterTuningJob_604066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_604078.validator(path, query, header, formData, body)
  let scheme = call_604078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604078.url(scheme.get, call_604078.host, call_604078.base,
                         call_604078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604078, url, valid)

proc call*(call_604079: Call_StopHyperParameterTuningJob_604066; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_604080 = newJObject()
  if body != nil:
    body_604080 = body
  result = call_604079.call(nil, nil, nil, nil, body_604080)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_604066(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_604067, base: "/",
    url: url_StopHyperParameterTuningJob_604068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_604081 = ref object of OpenApiRestCall_602466
proc url_StopLabelingJob_604083(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopLabelingJob_604082(path: JsonNode; query: JsonNode;
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
  var valid_604084 = header.getOrDefault("X-Amz-Date")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Date", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Security-Token")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Security-Token", valid_604085
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604086 = header.getOrDefault("X-Amz-Target")
  valid_604086 = validateParameter(valid_604086, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_604086 != nil:
    section.add "X-Amz-Target", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Content-Sha256", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Algorithm")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Algorithm", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Signature")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Signature", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-SignedHeaders", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Credential")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Credential", valid_604091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604093: Call_StopLabelingJob_604081; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_604093.validator(path, query, header, formData, body)
  let scheme = call_604093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604093.url(scheme.get, call_604093.host, call_604093.base,
                         call_604093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604093, url, valid)

proc call*(call_604094: Call_StopLabelingJob_604081; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_604095 = newJObject()
  if body != nil:
    body_604095 = body
  result = call_604094.call(nil, nil, nil, nil, body_604095)

var stopLabelingJob* = Call_StopLabelingJob_604081(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_604082, base: "/", url: url_StopLabelingJob_604083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_604096 = ref object of OpenApiRestCall_602466
proc url_StopNotebookInstance_604098(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopNotebookInstance_604097(path: JsonNode; query: JsonNode;
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
  var valid_604099 = header.getOrDefault("X-Amz-Date")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Date", valid_604099
  var valid_604100 = header.getOrDefault("X-Amz-Security-Token")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "X-Amz-Security-Token", valid_604100
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604101 = header.getOrDefault("X-Amz-Target")
  valid_604101 = validateParameter(valid_604101, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_604101 != nil:
    section.add "X-Amz-Target", valid_604101
  var valid_604102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604102 = validateParameter(valid_604102, JString, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "X-Amz-Content-Sha256", valid_604102
  var valid_604103 = header.getOrDefault("X-Amz-Algorithm")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Algorithm", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-Signature")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-Signature", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-SignedHeaders", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Credential")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Credential", valid_604106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604108: Call_StopNotebookInstance_604096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_604108.validator(path, query, header, formData, body)
  let scheme = call_604108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604108.url(scheme.get, call_604108.host, call_604108.base,
                         call_604108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604108, url, valid)

proc call*(call_604109: Call_StopNotebookInstance_604096; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_604110 = newJObject()
  if body != nil:
    body_604110 = body
  result = call_604109.call(nil, nil, nil, nil, body_604110)

var stopNotebookInstance* = Call_StopNotebookInstance_604096(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_604097, base: "/",
    url: url_StopNotebookInstance_604098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_604111 = ref object of OpenApiRestCall_602466
proc url_StopTrainingJob_604113(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrainingJob_604112(path: JsonNode; query: JsonNode;
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
  var valid_604114 = header.getOrDefault("X-Amz-Date")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Date", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Security-Token")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Security-Token", valid_604115
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604116 = header.getOrDefault("X-Amz-Target")
  valid_604116 = validateParameter(valid_604116, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_604116 != nil:
    section.add "X-Amz-Target", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Content-Sha256", valid_604117
  var valid_604118 = header.getOrDefault("X-Amz-Algorithm")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Algorithm", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Signature")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Signature", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-SignedHeaders", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Credential")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Credential", valid_604121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604123: Call_StopTrainingJob_604111; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_604123.validator(path, query, header, formData, body)
  let scheme = call_604123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604123.url(scheme.get, call_604123.host, call_604123.base,
                         call_604123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604123, url, valid)

proc call*(call_604124: Call_StopTrainingJob_604111; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_604125 = newJObject()
  if body != nil:
    body_604125 = body
  result = call_604124.call(nil, nil, nil, nil, body_604125)

var stopTrainingJob* = Call_StopTrainingJob_604111(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_604112, base: "/", url: url_StopTrainingJob_604113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_604126 = ref object of OpenApiRestCall_602466
proc url_StopTransformJob_604128(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTransformJob_604127(path: JsonNode; query: JsonNode;
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
  var valid_604129 = header.getOrDefault("X-Amz-Date")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Date", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Security-Token")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Security-Token", valid_604130
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604131 = header.getOrDefault("X-Amz-Target")
  valid_604131 = validateParameter(valid_604131, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_604131 != nil:
    section.add "X-Amz-Target", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Content-Sha256", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-Algorithm")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-Algorithm", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Signature")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Signature", valid_604134
  var valid_604135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "X-Amz-SignedHeaders", valid_604135
  var valid_604136 = header.getOrDefault("X-Amz-Credential")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "X-Amz-Credential", valid_604136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604138: Call_StopTransformJob_604126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_604138.validator(path, query, header, formData, body)
  let scheme = call_604138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604138.url(scheme.get, call_604138.host, call_604138.base,
                         call_604138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604138, url, valid)

proc call*(call_604139: Call_StopTransformJob_604126; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_604140 = newJObject()
  if body != nil:
    body_604140 = body
  result = call_604139.call(nil, nil, nil, nil, body_604140)

var stopTransformJob* = Call_StopTransformJob_604126(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_604127, base: "/",
    url: url_StopTransformJob_604128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_604141 = ref object of OpenApiRestCall_602466
proc url_UpdateCodeRepository_604143(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCodeRepository_604142(path: JsonNode; query: JsonNode;
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
  var valid_604144 = header.getOrDefault("X-Amz-Date")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Date", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604146 = header.getOrDefault("X-Amz-Target")
  valid_604146 = validateParameter(valid_604146, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_604146 != nil:
    section.add "X-Amz-Target", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Content-Sha256", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Algorithm")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Algorithm", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Signature")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Signature", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-SignedHeaders", valid_604150
  var valid_604151 = header.getOrDefault("X-Amz-Credential")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "X-Amz-Credential", valid_604151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_UpdateCodeRepository_604141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604153, url, valid)

proc call*(call_604154: Call_UpdateCodeRepository_604141; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_604155 = newJObject()
  if body != nil:
    body_604155 = body
  result = call_604154.call(nil, nil, nil, nil, body_604155)

var updateCodeRepository* = Call_UpdateCodeRepository_604141(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_604142, base: "/",
    url: url_UpdateCodeRepository_604143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_604156 = ref object of OpenApiRestCall_602466
proc url_UpdateEndpoint_604158(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEndpoint_604157(path: JsonNode; query: JsonNode;
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
  var valid_604159 = header.getOrDefault("X-Amz-Date")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Date", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Security-Token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Security-Token", valid_604160
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604161 = header.getOrDefault("X-Amz-Target")
  valid_604161 = validateParameter(valid_604161, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_604161 != nil:
    section.add "X-Amz-Target", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Content-Sha256", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Algorithm")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Algorithm", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-Signature")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Signature", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-SignedHeaders", valid_604165
  var valid_604166 = header.getOrDefault("X-Amz-Credential")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "X-Amz-Credential", valid_604166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604168: Call_UpdateEndpoint_604156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_604168.validator(path, query, header, formData, body)
  let scheme = call_604168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604168.url(scheme.get, call_604168.host, call_604168.base,
                         call_604168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604168, url, valid)

proc call*(call_604169: Call_UpdateEndpoint_604156; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_604170 = newJObject()
  if body != nil:
    body_604170 = body
  result = call_604169.call(nil, nil, nil, nil, body_604170)

var updateEndpoint* = Call_UpdateEndpoint_604156(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_604157, base: "/", url: url_UpdateEndpoint_604158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_604171 = ref object of OpenApiRestCall_602466
proc url_UpdateEndpointWeightsAndCapacities_604173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEndpointWeightsAndCapacities_604172(path: JsonNode;
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
  var valid_604174 = header.getOrDefault("X-Amz-Date")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Date", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-Security-Token")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-Security-Token", valid_604175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604176 = header.getOrDefault("X-Amz-Target")
  valid_604176 = validateParameter(valid_604176, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_604176 != nil:
    section.add "X-Amz-Target", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Content-Sha256", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Algorithm")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Algorithm", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Signature")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Signature", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-SignedHeaders", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Credential")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Credential", valid_604181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_UpdateEndpointWeightsAndCapacities_604171;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_UpdateEndpointWeightsAndCapacities_604171;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_604185 = newJObject()
  if body != nil:
    body_604185 = body
  result = call_604184.call(nil, nil, nil, nil, body_604185)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_604171(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_604172, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_604173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_604186 = ref object of OpenApiRestCall_602466
proc url_UpdateNotebookInstance_604188(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNotebookInstance_604187(path: JsonNode; query: JsonNode;
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
  var valid_604189 = header.getOrDefault("X-Amz-Date")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Date", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-Security-Token")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-Security-Token", valid_604190
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604191 = header.getOrDefault("X-Amz-Target")
  valid_604191 = validateParameter(valid_604191, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_604191 != nil:
    section.add "X-Amz-Target", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Content-Sha256", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Algorithm")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Algorithm", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Signature")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Signature", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-SignedHeaders", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Credential")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Credential", valid_604196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604198: Call_UpdateNotebookInstance_604186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_604198.validator(path, query, header, formData, body)
  let scheme = call_604198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604198.url(scheme.get, call_604198.host, call_604198.base,
                         call_604198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604198, url, valid)

proc call*(call_604199: Call_UpdateNotebookInstance_604186; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_604200 = newJObject()
  if body != nil:
    body_604200 = body
  result = call_604199.call(nil, nil, nil, nil, body_604200)

var updateNotebookInstance* = Call_UpdateNotebookInstance_604186(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_604187, base: "/",
    url: url_UpdateNotebookInstance_604188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_604201 = ref object of OpenApiRestCall_602466
proc url_UpdateNotebookInstanceLifecycleConfig_604203(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_604202(path: JsonNode;
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
  var valid_604204 = header.getOrDefault("X-Amz-Date")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "X-Amz-Date", valid_604204
  var valid_604205 = header.getOrDefault("X-Amz-Security-Token")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "X-Amz-Security-Token", valid_604205
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604206 = header.getOrDefault("X-Amz-Target")
  valid_604206 = validateParameter(valid_604206, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_604206 != nil:
    section.add "X-Amz-Target", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Content-Sha256", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Algorithm")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Algorithm", valid_604208
  var valid_604209 = header.getOrDefault("X-Amz-Signature")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Signature", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-SignedHeaders", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Credential")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Credential", valid_604211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604213: Call_UpdateNotebookInstanceLifecycleConfig_604201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_604213.validator(path, query, header, formData, body)
  let scheme = call_604213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604213.url(scheme.get, call_604213.host, call_604213.base,
                         call_604213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604213, url, valid)

proc call*(call_604214: Call_UpdateNotebookInstanceLifecycleConfig_604201;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_604215 = newJObject()
  if body != nil:
    body_604215 = body
  result = call_604214.call(nil, nil, nil, nil, body_604215)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_604201(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_604202, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_604203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_604216 = ref object of OpenApiRestCall_602466
proc url_UpdateWorkteam_604218(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkteam_604217(path: JsonNode; query: JsonNode;
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
  var valid_604219 = header.getOrDefault("X-Amz-Date")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Date", valid_604219
  var valid_604220 = header.getOrDefault("X-Amz-Security-Token")
  valid_604220 = validateParameter(valid_604220, JString, required = false,
                                 default = nil)
  if valid_604220 != nil:
    section.add "X-Amz-Security-Token", valid_604220
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604221 = header.getOrDefault("X-Amz-Target")
  valid_604221 = validateParameter(valid_604221, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_604221 != nil:
    section.add "X-Amz-Target", valid_604221
  var valid_604222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "X-Amz-Content-Sha256", valid_604222
  var valid_604223 = header.getOrDefault("X-Amz-Algorithm")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Algorithm", valid_604223
  var valid_604224 = header.getOrDefault("X-Amz-Signature")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Signature", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-SignedHeaders", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Credential")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Credential", valid_604226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604228: Call_UpdateWorkteam_604216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_604228.validator(path, query, header, formData, body)
  let scheme = call_604228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604228.url(scheme.get, call_604228.host, call_604228.base,
                         call_604228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604228, url, valid)

proc call*(call_604229: Call_UpdateWorkteam_604216; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_604230 = newJObject()
  if body != nil:
    body_604230 = body
  result = call_604229.call(nil, nil, nil, nil, body_604230)

var updateWorkteam* = Call_UpdateWorkteam_604216(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_604217, base: "/", url: url_UpdateWorkteam_604218,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
