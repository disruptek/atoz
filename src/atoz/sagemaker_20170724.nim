
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_590703 = ref object of OpenApiRestCall_590364
proc url_AddTags_590705(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTags_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true,
                                 default = newJString("SageMaker.AddTags"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_AddTags_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_AddTags_590703; body: JsonNode): Recallable =
  ## addTags
  ## <p>Adds or overwrites one or more tags for the specified Amazon SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">AWS Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a>CreateHyperParameterTuningJob</a> </p> </note>
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var addTags* = Call_AddTags_590703(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "api.sagemaker.amazonaws.com",
                                route: "/#X-Amz-Target=SageMaker.AddTags",
                                validator: validate_AddTags_590704, base: "/",
                                url: url_AddTags_590705,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlgorithm_590972 = ref object of OpenApiRestCall_590364
proc url_CreateAlgorithm_590974(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAlgorithm_590973(path: JsonNode; query: JsonNode;
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
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "SageMaker.CreateAlgorithm"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_CreateAlgorithm_590972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_CreateAlgorithm_590972; body: JsonNode): Recallable =
  ## createAlgorithm
  ## Create a machine learning algorithm that you can use in Amazon SageMaker and list in the AWS Marketplace.
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var createAlgorithm* = Call_CreateAlgorithm_590972(name: "createAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateAlgorithm",
    validator: validate_CreateAlgorithm_590973, base: "/", url: url_CreateAlgorithm_590974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCodeRepository_590987 = ref object of OpenApiRestCall_590364
proc url_CreateCodeRepository_590989(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCodeRepository_590988(path: JsonNode; query: JsonNode;
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
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "SageMaker.CreateCodeRepository"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_CreateCodeRepository_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_CreateCodeRepository_590987; body: JsonNode): Recallable =
  ## createCodeRepository
  ## <p>Creates a Git repository as a resource in your Amazon SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your Amazon SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit</a> or in any other Git repository.</p>
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var createCodeRepository* = Call_CreateCodeRepository_590987(
    name: "createCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCodeRepository",
    validator: validate_CreateCodeRepository_590988, base: "/",
    url: url_CreateCodeRepository_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCompilationJob_591002 = ref object of OpenApiRestCall_590364
proc url_CreateCompilationJob_591004(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCompilationJob_591003(path: JsonNode; query: JsonNode;
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
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "SageMaker.CreateCompilationJob"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateCompilationJob_591002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateCompilationJob_591002; body: JsonNode): Recallable =
  ## createCompilationJob
  ## <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with AWS IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p> <code>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job</code> </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a>StopCompilationJob</a>. To get information about a particular model compilation job, use <a>DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var createCompilationJob* = Call_CreateCompilationJob_591002(
    name: "createCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateCompilationJob",
    validator: validate_CreateCompilationJob_591003, base: "/",
    url: url_CreateCompilationJob_591004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpoint_591017 = ref object of OpenApiRestCall_590364
proc url_CreateEndpoint_591019(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEndpoint_591018(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "SageMaker.CreateEndpoint"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_CreateEndpoint_591017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_CreateEndpoint_591017; body: JsonNode): Recallable =
  ## createEndpoint
  ## <p>Creates an endpoint using the endpoint configuration specified in the request. Amazon SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <note> <p> Use this API only for hosting models using Amazon SageMaker hosting services. </p> <p> You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an AWS Region in your AWS account. </p> <p>When it receives the request, Amazon SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. Amazon SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>For an example, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/ex1.html">Exercise 1: Using the K-Means Algorithm Provided by Amazon SageMaker</a>. </p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, Amazon SageMaker uses AWS Security Token Service to download model artifacts from the S3 path you provided. AWS STS is activated in your IAM user account by default. If you previously deactivated AWS STS for a region, you need to reactivate AWS STS for that region. For more information, see <a href="IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating AWS STS i an AWS Region</a> in the <i>AWS Identity and Access Management User Guide</i>.</p>
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var createEndpoint* = Call_CreateEndpoint_591017(name: "createEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpoint",
    validator: validate_CreateEndpoint_591018, base: "/", url: url_CreateEndpoint_591019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEndpointConfig_591032 = ref object of OpenApiRestCall_590364
proc url_CreateEndpointConfig_591034(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEndpointConfig_591033(path: JsonNode; query: JsonNode;
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
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "SageMaker.CreateEndpointConfig"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_CreateEndpointConfig_591032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_CreateEndpointConfig_591032; body: JsonNode): Recallable =
  ## createEndpointConfig
  ## <p>Creates an endpoint configuration that Amazon SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want Amazon SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API only if you want to use Amazon SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define one or more <code>ProductionVariant</code>s, each of which identifies a model. Each <code>ProductionVariant</code> parameter also describes the resources that you want Amazon SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. Amazon SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p>
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var createEndpointConfig* = Call_CreateEndpointConfig_591032(
    name: "createEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateEndpointConfig",
    validator: validate_CreateEndpointConfig_591033, base: "/",
    url: url_CreateEndpointConfig_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHyperParameterTuningJob_591047 = ref object of OpenApiRestCall_590364
proc url_CreateHyperParameterTuningJob_591049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHyperParameterTuningJob_591048(path: JsonNode; query: JsonNode;
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
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true, default = newJString(
      "SageMaker.CreateHyperParameterTuningJob"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_CreateHyperParameterTuningJob_591047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_CreateHyperParameterTuningJob_591047; body: JsonNode): Recallable =
  ## createHyperParameterTuningJob
  ## Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var createHyperParameterTuningJob* = Call_CreateHyperParameterTuningJob_591047(
    name: "createHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob",
    validator: validate_CreateHyperParameterTuningJob_591048, base: "/",
    url: url_CreateHyperParameterTuningJob_591049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLabelingJob_591062 = ref object of OpenApiRestCall_590364
proc url_CreateLabelingJob_591064(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLabelingJob_591063(path: JsonNode; query: JsonNode;
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
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true, default = newJString(
      "SageMaker.CreateLabelingJob"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_CreateLabelingJob_591062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_CreateLabelingJob_591062; body: JsonNode): Recallable =
  ## createLabelingJob
  ## <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models.</p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the AWS Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p>
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var createLabelingJob* = Call_CreateLabelingJob_591062(name: "createLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateLabelingJob",
    validator: validate_CreateLabelingJob_591063, base: "/",
    url: url_CreateLabelingJob_591064, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModel_591077 = ref object of OpenApiRestCall_590364
proc url_CreateModel_591079(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateModel_591078(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true,
                                 default = newJString("SageMaker.CreateModel"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_CreateModel_591077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_CreateModel_591077; body: JsonNode): Recallable =
  ## createModel
  ## <p>Creates a model in Amazon SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the docker image containing inference code, artifacts (from prior training), and custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use Amazon SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. Amazon SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. Amazon SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the <code>CreateModel</code> request, you must define a container with the <code>PrimaryContainer</code> parameter.</p> <p>In the request, you also provide an IAM role that Amazon SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other AWS resources, you grant necessary permissions via this role.</p>
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var createModel* = Call_CreateModel_591077(name: "createModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.CreateModel",
                                        validator: validate_CreateModel_591078,
                                        base: "/", url: url_CreateModel_591079,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateModelPackage_591092 = ref object of OpenApiRestCall_590364
proc url_CreateModelPackage_591094(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateModelPackage_591093(path: JsonNode; query: JsonNode;
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
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true, default = newJString(
      "SageMaker.CreateModelPackage"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_CreateModelPackage_591092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_CreateModelPackage_591092; body: JsonNode): Recallable =
  ## createModelPackage
  ## <p>Creates a model package that you can use to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in AWS Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p>
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var createModelPackage* = Call_CreateModelPackage_591092(
    name: "createModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateModelPackage",
    validator: validate_CreateModelPackage_591093, base: "/",
    url: url_CreateModelPackage_591094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstance_591107 = ref object of OpenApiRestCall_590364
proc url_CreateNotebookInstance_591109(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNotebookInstance_591108(path: JsonNode; query: JsonNode;
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
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstance"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_CreateNotebookInstance_591107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_CreateNotebookInstance_591107; body: JsonNode): Recallable =
  ## createNotebookInstance
  ## <p>Creates an Amazon SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. Amazon SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>Amazon SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use Amazon SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, Amazon SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the Amazon SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, Amazon SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, Amazon SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the Amazon SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, Amazon SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, Amazon SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After Amazon SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating Amazon SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var createNotebookInstance* = Call_CreateNotebookInstance_591107(
    name: "createNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstance",
    validator: validate_CreateNotebookInstance_591108, base: "/",
    url: url_CreateNotebookInstance_591109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNotebookInstanceLifecycleConfig_591122 = ref object of OpenApiRestCall_590364
proc url_CreateNotebookInstanceLifecycleConfig_591124(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateNotebookInstanceLifecycleConfig_591123(path: JsonNode;
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
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true, default = newJString(
      "SageMaker.CreateNotebookInstanceLifecycleConfig"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_CreateNotebookInstanceLifecycleConfig_591122;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_CreateNotebookInstanceLifecycleConfig_591122;
          body: JsonNode): Recallable =
  ## createNotebookInstanceLifecycleConfig
  ## <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var createNotebookInstanceLifecycleConfig* = Call_CreateNotebookInstanceLifecycleConfig_591122(
    name: "createNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig",
    validator: validate_CreateNotebookInstanceLifecycleConfig_591123, base: "/",
    url: url_CreateNotebookInstanceLifecycleConfig_591124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePresignedNotebookInstanceUrl_591137 = ref object of OpenApiRestCall_590364
proc url_CreatePresignedNotebookInstanceUrl_591139(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePresignedNotebookInstanceUrl_591138(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591140 = header.getOrDefault("X-Amz-Target")
  valid_591140 = validateParameter(valid_591140, JString, required = true, default = newJString(
      "SageMaker.CreatePresignedNotebookInstanceUrl"))
  if valid_591140 != nil:
    section.add "X-Amz-Target", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Signature")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Signature", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Content-Sha256", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Date")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Date", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Credential")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Credential", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Security-Token")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Security-Token", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Algorithm")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Algorithm", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-SignedHeaders", valid_591147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591149: Call_CreatePresignedNotebookInstanceUrl_591137;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_CreatePresignedNotebookInstanceUrl_591137;
          body: JsonNode): Recallable =
  ## createPresignedNotebookInstanceUrl
  ## <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the Amazon SageMaker console, when you choose <code>Open</code> next to a notebook instance, Amazon SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p>IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.For example, you can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-ip-filter.html">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the AWS console sign-in page.</p> </note>
  ##   body: JObject (required)
  var body_591151 = newJObject()
  if body != nil:
    body_591151 = body
  result = call_591150.call(nil, nil, nil, nil, body_591151)

var createPresignedNotebookInstanceUrl* = Call_CreatePresignedNotebookInstanceUrl_591137(
    name: "createPresignedNotebookInstanceUrl", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl",
    validator: validate_CreatePresignedNotebookInstanceUrl_591138, base: "/",
    url: url_CreatePresignedNotebookInstanceUrl_591139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrainingJob_591152 = ref object of OpenApiRestCall_590364
proc url_CreateTrainingJob_591154(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTrainingJob_591153(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591155 = header.getOrDefault("X-Amz-Target")
  valid_591155 = validateParameter(valid_591155, JString, required = true, default = newJString(
      "SageMaker.CreateTrainingJob"))
  if valid_591155 != nil:
    section.add "X-Amz-Target", valid_591155
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591164: Call_CreateTrainingJob_591152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_CreateTrainingJob_591152; body: JsonNode): Recallable =
  ## createTrainingJob
  ## <p>Starts a model training job. After training completes, Amazon SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than Amazon SageMaker, provided that you know how to use them for inferences. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> </li> <li> <p> <code>InputDataConfig</code> - Describes the training dataset and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want Amazon SageMaker to save the results of model training. </p> <p/> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleARN</code> - The Amazon Resource Number (ARN) that Amazon SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that Amazon SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long you are willing to to wait for a managed spot training job to complete. </p> </li> </ul> <p> For more information about Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var createTrainingJob* = Call_CreateTrainingJob_591152(name: "createTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTrainingJob",
    validator: validate_CreateTrainingJob_591153, base: "/",
    url: url_CreateTrainingJob_591154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTransformJob_591167 = ref object of OpenApiRestCall_590364
proc url_CreateTransformJob_591169(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTransformJob_591168(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591170 = header.getOrDefault("X-Amz-Target")
  valid_591170 = validateParameter(valid_591170, JString, required = true, default = newJString(
      "SageMaker.CreateTransformJob"))
  if valid_591170 != nil:
    section.add "X-Amz-Target", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Signature")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Signature", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Content-Sha256", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Date")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Date", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Credential")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Credential", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Security-Token")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Security-Token", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Algorithm")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Algorithm", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-SignedHeaders", valid_591177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_CreateTransformJob_591167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_CreateTransformJob_591167; body: JsonNode): Recallable =
  ## createTransformJob
  ## <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an AWS Region in an AWS account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same AWS Region and AWS account. For information on creating a model, see <a>CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p> For more information about how batch transformation works Amazon SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">How It Works</a>. </p>
  ##   body: JObject (required)
  var body_591181 = newJObject()
  if body != nil:
    body_591181 = body
  result = call_591180.call(nil, nil, nil, nil, body_591181)

var createTransformJob* = Call_CreateTransformJob_591167(
    name: "createTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateTransformJob",
    validator: validate_CreateTransformJob_591168, base: "/",
    url: url_CreateTransformJob_591169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkteam_591182 = ref object of OpenApiRestCall_590364
proc url_CreateWorkteam_591184(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWorkteam_591183(path: JsonNode; query: JsonNode;
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
  var valid_591185 = header.getOrDefault("X-Amz-Target")
  valid_591185 = validateParameter(valid_591185, JString, required = true, default = newJString(
      "SageMaker.CreateWorkteam"))
  if valid_591185 != nil:
    section.add "X-Amz-Target", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Signature")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Signature", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Content-Sha256", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Date")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Date", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Credential")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Credential", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Security-Token")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Security-Token", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Algorithm")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Algorithm", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-SignedHeaders", valid_591192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591194: Call_CreateWorkteam_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ## 
  let valid = call_591194.validator(path, query, header, formData, body)
  let scheme = call_591194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591194.url(scheme.get, call_591194.host, call_591194.base,
                         call_591194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591194, url, valid)

proc call*(call_591195: Call_CreateWorkteam_591182; body: JsonNode): Recallable =
  ## createWorkteam
  ## <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
  ##   body: JObject (required)
  var body_591196 = newJObject()
  if body != nil:
    body_591196 = body
  result = call_591195.call(nil, nil, nil, nil, body_591196)

var createWorkteam* = Call_CreateWorkteam_591182(name: "createWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.CreateWorkteam",
    validator: validate_CreateWorkteam_591183, base: "/", url: url_CreateWorkteam_591184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlgorithm_591197 = ref object of OpenApiRestCall_590364
proc url_DeleteAlgorithm_591199(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAlgorithm_591198(path: JsonNode; query: JsonNode;
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
  var valid_591200 = header.getOrDefault("X-Amz-Target")
  valid_591200 = validateParameter(valid_591200, JString, required = true, default = newJString(
      "SageMaker.DeleteAlgorithm"))
  if valid_591200 != nil:
    section.add "X-Amz-Target", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Signature")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Signature", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Content-Sha256", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Date")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Date", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Credential")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Credential", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Security-Token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Security-Token", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Algorithm")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Algorithm", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-SignedHeaders", valid_591207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591209: Call_DeleteAlgorithm_591197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified algorithm from your account.
  ## 
  let valid = call_591209.validator(path, query, header, formData, body)
  let scheme = call_591209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591209.url(scheme.get, call_591209.host, call_591209.base,
                         call_591209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591209, url, valid)

proc call*(call_591210: Call_DeleteAlgorithm_591197; body: JsonNode): Recallable =
  ## deleteAlgorithm
  ## Removes the specified algorithm from your account.
  ##   body: JObject (required)
  var body_591211 = newJObject()
  if body != nil:
    body_591211 = body
  result = call_591210.call(nil, nil, nil, nil, body_591211)

var deleteAlgorithm* = Call_DeleteAlgorithm_591197(name: "deleteAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteAlgorithm",
    validator: validate_DeleteAlgorithm_591198, base: "/", url: url_DeleteAlgorithm_591199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCodeRepository_591212 = ref object of OpenApiRestCall_590364
proc url_DeleteCodeRepository_591214(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCodeRepository_591213(path: JsonNode; query: JsonNode;
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
  var valid_591215 = header.getOrDefault("X-Amz-Target")
  valid_591215 = validateParameter(valid_591215, JString, required = true, default = newJString(
      "SageMaker.DeleteCodeRepository"))
  if valid_591215 != nil:
    section.add "X-Amz-Target", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Signature")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Signature", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Content-Sha256", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Date")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Date", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Credential")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Credential", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Security-Token")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Security-Token", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Algorithm")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Algorithm", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-SignedHeaders", valid_591222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591224: Call_DeleteCodeRepository_591212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified Git repository from your account.
  ## 
  let valid = call_591224.validator(path, query, header, formData, body)
  let scheme = call_591224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591224.url(scheme.get, call_591224.host, call_591224.base,
                         call_591224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591224, url, valid)

proc call*(call_591225: Call_DeleteCodeRepository_591212; body: JsonNode): Recallable =
  ## deleteCodeRepository
  ## Deletes the specified Git repository from your account.
  ##   body: JObject (required)
  var body_591226 = newJObject()
  if body != nil:
    body_591226 = body
  result = call_591225.call(nil, nil, nil, nil, body_591226)

var deleteCodeRepository* = Call_DeleteCodeRepository_591212(
    name: "deleteCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteCodeRepository",
    validator: validate_DeleteCodeRepository_591213, base: "/",
    url: url_DeleteCodeRepository_591214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpoint_591227 = ref object of OpenApiRestCall_590364
proc url_DeleteEndpoint_591229(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEndpoint_591228(path: JsonNode; query: JsonNode;
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
  var valid_591230 = header.getOrDefault("X-Amz-Target")
  valid_591230 = validateParameter(valid_591230, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpoint"))
  if valid_591230 != nil:
    section.add "X-Amz-Target", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Signature")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Signature", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Content-Sha256", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-Date")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-Date", valid_591233
  var valid_591234 = header.getOrDefault("X-Amz-Credential")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "X-Amz-Credential", valid_591234
  var valid_591235 = header.getOrDefault("X-Amz-Security-Token")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "X-Amz-Security-Token", valid_591235
  var valid_591236 = header.getOrDefault("X-Amz-Algorithm")
  valid_591236 = validateParameter(valid_591236, JString, required = false,
                                 default = nil)
  if valid_591236 != nil:
    section.add "X-Amz-Algorithm", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-SignedHeaders", valid_591237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591239: Call_DeleteEndpoint_591227; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ## 
  let valid = call_591239.validator(path, query, header, formData, body)
  let scheme = call_591239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591239.url(scheme.get, call_591239.host, call_591239.base,
                         call_591239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591239, url, valid)

proc call*(call_591240: Call_DeleteEndpoint_591227; body: JsonNode): Recallable =
  ## deleteEndpoint
  ## <p>Deletes an endpoint. Amazon SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>Amazon SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p>
  ##   body: JObject (required)
  var body_591241 = newJObject()
  if body != nil:
    body_591241 = body
  result = call_591240.call(nil, nil, nil, nil, body_591241)

var deleteEndpoint* = Call_DeleteEndpoint_591227(name: "deleteEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpoint",
    validator: validate_DeleteEndpoint_591228, base: "/", url: url_DeleteEndpoint_591229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEndpointConfig_591242 = ref object of OpenApiRestCall_590364
proc url_DeleteEndpointConfig_591244(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEndpointConfig_591243(path: JsonNode; query: JsonNode;
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
  var valid_591245 = header.getOrDefault("X-Amz-Target")
  valid_591245 = validateParameter(valid_591245, JString, required = true, default = newJString(
      "SageMaker.DeleteEndpointConfig"))
  if valid_591245 != nil:
    section.add "X-Amz-Target", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Signature")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Signature", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-Content-Sha256", valid_591247
  var valid_591248 = header.getOrDefault("X-Amz-Date")
  valid_591248 = validateParameter(valid_591248, JString, required = false,
                                 default = nil)
  if valid_591248 != nil:
    section.add "X-Amz-Date", valid_591248
  var valid_591249 = header.getOrDefault("X-Amz-Credential")
  valid_591249 = validateParameter(valid_591249, JString, required = false,
                                 default = nil)
  if valid_591249 != nil:
    section.add "X-Amz-Credential", valid_591249
  var valid_591250 = header.getOrDefault("X-Amz-Security-Token")
  valid_591250 = validateParameter(valid_591250, JString, required = false,
                                 default = nil)
  if valid_591250 != nil:
    section.add "X-Amz-Security-Token", valid_591250
  var valid_591251 = header.getOrDefault("X-Amz-Algorithm")
  valid_591251 = validateParameter(valid_591251, JString, required = false,
                                 default = nil)
  if valid_591251 != nil:
    section.add "X-Amz-Algorithm", valid_591251
  var valid_591252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "X-Amz-SignedHeaders", valid_591252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591254: Call_DeleteEndpointConfig_591242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ## 
  let valid = call_591254.validator(path, query, header, formData, body)
  let scheme = call_591254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591254.url(scheme.get, call_591254.host, call_591254.base,
                         call_591254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591254, url, valid)

proc call*(call_591255: Call_DeleteEndpointConfig_591242; body: JsonNode): Recallable =
  ## deleteEndpointConfig
  ## Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. 
  ##   body: JObject (required)
  var body_591256 = newJObject()
  if body != nil:
    body_591256 = body
  result = call_591255.call(nil, nil, nil, nil, body_591256)

var deleteEndpointConfig* = Call_DeleteEndpointConfig_591242(
    name: "deleteEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteEndpointConfig",
    validator: validate_DeleteEndpointConfig_591243, base: "/",
    url: url_DeleteEndpointConfig_591244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModel_591257 = ref object of OpenApiRestCall_590364
proc url_DeleteModel_591259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteModel_591258(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591260 = header.getOrDefault("X-Amz-Target")
  valid_591260 = validateParameter(valid_591260, JString, required = true,
                                 default = newJString("SageMaker.DeleteModel"))
  if valid_591260 != nil:
    section.add "X-Amz-Target", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Signature")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Signature", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Content-Sha256", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-Date")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-Date", valid_591263
  var valid_591264 = header.getOrDefault("X-Amz-Credential")
  valid_591264 = validateParameter(valid_591264, JString, required = false,
                                 default = nil)
  if valid_591264 != nil:
    section.add "X-Amz-Credential", valid_591264
  var valid_591265 = header.getOrDefault("X-Amz-Security-Token")
  valid_591265 = validateParameter(valid_591265, JString, required = false,
                                 default = nil)
  if valid_591265 != nil:
    section.add "X-Amz-Security-Token", valid_591265
  var valid_591266 = header.getOrDefault("X-Amz-Algorithm")
  valid_591266 = validateParameter(valid_591266, JString, required = false,
                                 default = nil)
  if valid_591266 != nil:
    section.add "X-Amz-Algorithm", valid_591266
  var valid_591267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591267 = validateParameter(valid_591267, JString, required = false,
                                 default = nil)
  if valid_591267 != nil:
    section.add "X-Amz-SignedHeaders", valid_591267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591269: Call_DeleteModel_591257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ## 
  let valid = call_591269.validator(path, query, header, formData, body)
  let scheme = call_591269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591269.url(scheme.get, call_591269.host, call_591269.base,
                         call_591269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591269, url, valid)

proc call*(call_591270: Call_DeleteModel_591257; body: JsonNode): Recallable =
  ## deleteModel
  ## Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in Amazon SageMaker when you called the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
  ##   body: JObject (required)
  var body_591271 = newJObject()
  if body != nil:
    body_591271 = body
  result = call_591270.call(nil, nil, nil, nil, body_591271)

var deleteModel* = Call_DeleteModel_591257(name: "deleteModel",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteModel",
                                        validator: validate_DeleteModel_591258,
                                        base: "/", url: url_DeleteModel_591259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteModelPackage_591272 = ref object of OpenApiRestCall_590364
proc url_DeleteModelPackage_591274(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteModelPackage_591273(path: JsonNode; query: JsonNode;
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
  var valid_591275 = header.getOrDefault("X-Amz-Target")
  valid_591275 = validateParameter(valid_591275, JString, required = true, default = newJString(
      "SageMaker.DeleteModelPackage"))
  if valid_591275 != nil:
    section.add "X-Amz-Target", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Signature")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Signature", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Content-Sha256", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Date")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Date", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Credential")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Credential", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Security-Token")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Security-Token", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-Algorithm")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-Algorithm", valid_591281
  var valid_591282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591282 = validateParameter(valid_591282, JString, required = false,
                                 default = nil)
  if valid_591282 != nil:
    section.add "X-Amz-SignedHeaders", valid_591282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591284: Call_DeleteModelPackage_591272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ## 
  let valid = call_591284.validator(path, query, header, formData, body)
  let scheme = call_591284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591284.url(scheme.get, call_591284.host, call_591284.base,
                         call_591284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591284, url, valid)

proc call*(call_591285: Call_DeleteModelPackage_591272; body: JsonNode): Recallable =
  ## deleteModelPackage
  ## <p>Deletes a model package.</p> <p>A model package is used to create Amazon SageMaker models or list on AWS Marketplace. Buyers can subscribe to model packages listed on AWS Marketplace to create models in Amazon SageMaker.</p>
  ##   body: JObject (required)
  var body_591286 = newJObject()
  if body != nil:
    body_591286 = body
  result = call_591285.call(nil, nil, nil, nil, body_591286)

var deleteModelPackage* = Call_DeleteModelPackage_591272(
    name: "deleteModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteModelPackage",
    validator: validate_DeleteModelPackage_591273, base: "/",
    url: url_DeleteModelPackage_591274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstance_591287 = ref object of OpenApiRestCall_590364
proc url_DeleteNotebookInstance_591289(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNotebookInstance_591288(path: JsonNode; query: JsonNode;
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
  var valid_591290 = header.getOrDefault("X-Amz-Target")
  valid_591290 = validateParameter(valid_591290, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstance"))
  if valid_591290 != nil:
    section.add "X-Amz-Target", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Signature")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Signature", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Content-Sha256", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Date")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Date", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Credential")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Credential", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Security-Token")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Security-Token", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Algorithm")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Algorithm", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-SignedHeaders", valid_591297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591299: Call_DeleteNotebookInstance_591287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ## 
  let valid = call_591299.validator(path, query, header, formData, body)
  let scheme = call_591299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591299.url(scheme.get, call_591299.host, call_591299.base,
                         call_591299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591299, url, valid)

proc call*(call_591300: Call_DeleteNotebookInstance_591287; body: JsonNode): Recallable =
  ## deleteNotebookInstance
  ## <p> Deletes an Amazon SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. Amazon SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
  ##   body: JObject (required)
  var body_591301 = newJObject()
  if body != nil:
    body_591301 = body
  result = call_591300.call(nil, nil, nil, nil, body_591301)

var deleteNotebookInstance* = Call_DeleteNotebookInstance_591287(
    name: "deleteNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstance",
    validator: validate_DeleteNotebookInstance_591288, base: "/",
    url: url_DeleteNotebookInstance_591289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNotebookInstanceLifecycleConfig_591302 = ref object of OpenApiRestCall_590364
proc url_DeleteNotebookInstanceLifecycleConfig_591304(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteNotebookInstanceLifecycleConfig_591303(path: JsonNode;
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
  var valid_591305 = header.getOrDefault("X-Amz-Target")
  valid_591305 = validateParameter(valid_591305, JString, required = true, default = newJString(
      "SageMaker.DeleteNotebookInstanceLifecycleConfig"))
  if valid_591305 != nil:
    section.add "X-Amz-Target", valid_591305
  var valid_591306 = header.getOrDefault("X-Amz-Signature")
  valid_591306 = validateParameter(valid_591306, JString, required = false,
                                 default = nil)
  if valid_591306 != nil:
    section.add "X-Amz-Signature", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Content-Sha256", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Date")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Date", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Credential")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Credential", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Security-Token")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Security-Token", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Algorithm")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Algorithm", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-SignedHeaders", valid_591312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591314: Call_DeleteNotebookInstanceLifecycleConfig_591302;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes a notebook instance lifecycle configuration.
  ## 
  let valid = call_591314.validator(path, query, header, formData, body)
  let scheme = call_591314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591314.url(scheme.get, call_591314.host, call_591314.base,
                         call_591314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591314, url, valid)

proc call*(call_591315: Call_DeleteNotebookInstanceLifecycleConfig_591302;
          body: JsonNode): Recallable =
  ## deleteNotebookInstanceLifecycleConfig
  ## Deletes a notebook instance lifecycle configuration.
  ##   body: JObject (required)
  var body_591316 = newJObject()
  if body != nil:
    body_591316 = body
  result = call_591315.call(nil, nil, nil, nil, body_591316)

var deleteNotebookInstanceLifecycleConfig* = Call_DeleteNotebookInstanceLifecycleConfig_591302(
    name: "deleteNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig",
    validator: validate_DeleteNotebookInstanceLifecycleConfig_591303, base: "/",
    url: url_DeleteNotebookInstanceLifecycleConfig_591304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_591317 = ref object of OpenApiRestCall_590364
proc url_DeleteTags_591319(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_591318(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591320 = header.getOrDefault("X-Amz-Target")
  valid_591320 = validateParameter(valid_591320, JString, required = true,
                                 default = newJString("SageMaker.DeleteTags"))
  if valid_591320 != nil:
    section.add "X-Amz-Target", valid_591320
  var valid_591321 = header.getOrDefault("X-Amz-Signature")
  valid_591321 = validateParameter(valid_591321, JString, required = false,
                                 default = nil)
  if valid_591321 != nil:
    section.add "X-Amz-Signature", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Content-Sha256", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Date")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Date", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Credential")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Credential", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Security-Token")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Security-Token", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Algorithm")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Algorithm", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-SignedHeaders", valid_591327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591329: Call_DeleteTags_591317; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ## 
  let valid = call_591329.validator(path, query, header, formData, body)
  let scheme = call_591329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591329.url(scheme.get, call_591329.host, call_591329.base,
                         call_591329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591329, url, valid)

proc call*(call_591330: Call_DeleteTags_591317; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags from an Amazon SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note>
  ##   body: JObject (required)
  var body_591331 = newJObject()
  if body != nil:
    body_591331 = body
  result = call_591330.call(nil, nil, nil, nil, body_591331)

var deleteTags* = Call_DeleteTags_591317(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.DeleteTags",
                                      validator: validate_DeleteTags_591318,
                                      base: "/", url: url_DeleteTags_591319,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkteam_591332 = ref object of OpenApiRestCall_590364
proc url_DeleteWorkteam_591334(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWorkteam_591333(path: JsonNode; query: JsonNode;
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
  var valid_591335 = header.getOrDefault("X-Amz-Target")
  valid_591335 = validateParameter(valid_591335, JString, required = true, default = newJString(
      "SageMaker.DeleteWorkteam"))
  if valid_591335 != nil:
    section.add "X-Amz-Target", valid_591335
  var valid_591336 = header.getOrDefault("X-Amz-Signature")
  valid_591336 = validateParameter(valid_591336, JString, required = false,
                                 default = nil)
  if valid_591336 != nil:
    section.add "X-Amz-Signature", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Content-Sha256", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Date")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Date", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Credential")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Credential", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-Security-Token")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-Security-Token", valid_591340
  var valid_591341 = header.getOrDefault("X-Amz-Algorithm")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Algorithm", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-SignedHeaders", valid_591342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591344: Call_DeleteWorkteam_591332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing work team. This operation can't be undone.
  ## 
  let valid = call_591344.validator(path, query, header, formData, body)
  let scheme = call_591344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591344.url(scheme.get, call_591344.host, call_591344.base,
                         call_591344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591344, url, valid)

proc call*(call_591345: Call_DeleteWorkteam_591332; body: JsonNode): Recallable =
  ## deleteWorkteam
  ## Deletes an existing work team. This operation can't be undone.
  ##   body: JObject (required)
  var body_591346 = newJObject()
  if body != nil:
    body_591346 = body
  result = call_591345.call(nil, nil, nil, nil, body_591346)

var deleteWorkteam* = Call_DeleteWorkteam_591332(name: "deleteWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DeleteWorkteam",
    validator: validate_DeleteWorkteam_591333, base: "/", url: url_DeleteWorkteam_591334,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAlgorithm_591347 = ref object of OpenApiRestCall_590364
proc url_DescribeAlgorithm_591349(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAlgorithm_591348(path: JsonNode; query: JsonNode;
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
  var valid_591350 = header.getOrDefault("X-Amz-Target")
  valid_591350 = validateParameter(valid_591350, JString, required = true, default = newJString(
      "SageMaker.DescribeAlgorithm"))
  if valid_591350 != nil:
    section.add "X-Amz-Target", valid_591350
  var valid_591351 = header.getOrDefault("X-Amz-Signature")
  valid_591351 = validateParameter(valid_591351, JString, required = false,
                                 default = nil)
  if valid_591351 != nil:
    section.add "X-Amz-Signature", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Content-Sha256", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Date")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Date", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-Credential")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-Credential", valid_591354
  var valid_591355 = header.getOrDefault("X-Amz-Security-Token")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-Security-Token", valid_591355
  var valid_591356 = header.getOrDefault("X-Amz-Algorithm")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Algorithm", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-SignedHeaders", valid_591357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591359: Call_DescribeAlgorithm_591347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a description of the specified algorithm that is in your account.
  ## 
  let valid = call_591359.validator(path, query, header, formData, body)
  let scheme = call_591359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591359.url(scheme.get, call_591359.host, call_591359.base,
                         call_591359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591359, url, valid)

proc call*(call_591360: Call_DescribeAlgorithm_591347; body: JsonNode): Recallable =
  ## describeAlgorithm
  ## Returns a description of the specified algorithm that is in your account.
  ##   body: JObject (required)
  var body_591361 = newJObject()
  if body != nil:
    body_591361 = body
  result = call_591360.call(nil, nil, nil, nil, body_591361)

var describeAlgorithm* = Call_DescribeAlgorithm_591347(name: "describeAlgorithm",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeAlgorithm",
    validator: validate_DescribeAlgorithm_591348, base: "/",
    url: url_DescribeAlgorithm_591349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCodeRepository_591362 = ref object of OpenApiRestCall_590364
proc url_DescribeCodeRepository_591364(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCodeRepository_591363(path: JsonNode; query: JsonNode;
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
  var valid_591365 = header.getOrDefault("X-Amz-Target")
  valid_591365 = validateParameter(valid_591365, JString, required = true, default = newJString(
      "SageMaker.DescribeCodeRepository"))
  if valid_591365 != nil:
    section.add "X-Amz-Target", valid_591365
  var valid_591366 = header.getOrDefault("X-Amz-Signature")
  valid_591366 = validateParameter(valid_591366, JString, required = false,
                                 default = nil)
  if valid_591366 != nil:
    section.add "X-Amz-Signature", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Content-Sha256", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Date")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Date", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Credential")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Credential", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-Security-Token")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Security-Token", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Algorithm")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Algorithm", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-SignedHeaders", valid_591372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591374: Call_DescribeCodeRepository_591362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about the specified Git repository.
  ## 
  let valid = call_591374.validator(path, query, header, formData, body)
  let scheme = call_591374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591374.url(scheme.get, call_591374.host, call_591374.base,
                         call_591374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591374, url, valid)

proc call*(call_591375: Call_DescribeCodeRepository_591362; body: JsonNode): Recallable =
  ## describeCodeRepository
  ## Gets details about the specified Git repository.
  ##   body: JObject (required)
  var body_591376 = newJObject()
  if body != nil:
    body_591376 = body
  result = call_591375.call(nil, nil, nil, nil, body_591376)

var describeCodeRepository* = Call_DescribeCodeRepository_591362(
    name: "describeCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCodeRepository",
    validator: validate_DescribeCodeRepository_591363, base: "/",
    url: url_DescribeCodeRepository_591364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCompilationJob_591377 = ref object of OpenApiRestCall_590364
proc url_DescribeCompilationJob_591379(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCompilationJob_591378(path: JsonNode; query: JsonNode;
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
  var valid_591380 = header.getOrDefault("X-Amz-Target")
  valid_591380 = validateParameter(valid_591380, JString, required = true, default = newJString(
      "SageMaker.DescribeCompilationJob"))
  if valid_591380 != nil:
    section.add "X-Amz-Target", valid_591380
  var valid_591381 = header.getOrDefault("X-Amz-Signature")
  valid_591381 = validateParameter(valid_591381, JString, required = false,
                                 default = nil)
  if valid_591381 != nil:
    section.add "X-Amz-Signature", valid_591381
  var valid_591382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591382 = validateParameter(valid_591382, JString, required = false,
                                 default = nil)
  if valid_591382 != nil:
    section.add "X-Amz-Content-Sha256", valid_591382
  var valid_591383 = header.getOrDefault("X-Amz-Date")
  valid_591383 = validateParameter(valid_591383, JString, required = false,
                                 default = nil)
  if valid_591383 != nil:
    section.add "X-Amz-Date", valid_591383
  var valid_591384 = header.getOrDefault("X-Amz-Credential")
  valid_591384 = validateParameter(valid_591384, JString, required = false,
                                 default = nil)
  if valid_591384 != nil:
    section.add "X-Amz-Credential", valid_591384
  var valid_591385 = header.getOrDefault("X-Amz-Security-Token")
  valid_591385 = validateParameter(valid_591385, JString, required = false,
                                 default = nil)
  if valid_591385 != nil:
    section.add "X-Amz-Security-Token", valid_591385
  var valid_591386 = header.getOrDefault("X-Amz-Algorithm")
  valid_591386 = validateParameter(valid_591386, JString, required = false,
                                 default = nil)
  if valid_591386 != nil:
    section.add "X-Amz-Algorithm", valid_591386
  var valid_591387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-SignedHeaders", valid_591387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591389: Call_DescribeCompilationJob_591377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ## 
  let valid = call_591389.validator(path, query, header, formData, body)
  let scheme = call_591389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591389.url(scheme.get, call_591389.host, call_591389.base,
                         call_591389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591389, url, valid)

proc call*(call_591390: Call_DescribeCompilationJob_591377; body: JsonNode): Recallable =
  ## describeCompilationJob
  ## <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a>ListCompilationJobs</a>.</p>
  ##   body: JObject (required)
  var body_591391 = newJObject()
  if body != nil:
    body_591391 = body
  result = call_591390.call(nil, nil, nil, nil, body_591391)

var describeCompilationJob* = Call_DescribeCompilationJob_591377(
    name: "describeCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeCompilationJob",
    validator: validate_DescribeCompilationJob_591378, base: "/",
    url: url_DescribeCompilationJob_591379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpoint_591392 = ref object of OpenApiRestCall_590364
proc url_DescribeEndpoint_591394(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpoint_591393(path: JsonNode; query: JsonNode;
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
  var valid_591395 = header.getOrDefault("X-Amz-Target")
  valid_591395 = validateParameter(valid_591395, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpoint"))
  if valid_591395 != nil:
    section.add "X-Amz-Target", valid_591395
  var valid_591396 = header.getOrDefault("X-Amz-Signature")
  valid_591396 = validateParameter(valid_591396, JString, required = false,
                                 default = nil)
  if valid_591396 != nil:
    section.add "X-Amz-Signature", valid_591396
  var valid_591397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591397 = validateParameter(valid_591397, JString, required = false,
                                 default = nil)
  if valid_591397 != nil:
    section.add "X-Amz-Content-Sha256", valid_591397
  var valid_591398 = header.getOrDefault("X-Amz-Date")
  valid_591398 = validateParameter(valid_591398, JString, required = false,
                                 default = nil)
  if valid_591398 != nil:
    section.add "X-Amz-Date", valid_591398
  var valid_591399 = header.getOrDefault("X-Amz-Credential")
  valid_591399 = validateParameter(valid_591399, JString, required = false,
                                 default = nil)
  if valid_591399 != nil:
    section.add "X-Amz-Credential", valid_591399
  var valid_591400 = header.getOrDefault("X-Amz-Security-Token")
  valid_591400 = validateParameter(valid_591400, JString, required = false,
                                 default = nil)
  if valid_591400 != nil:
    section.add "X-Amz-Security-Token", valid_591400
  var valid_591401 = header.getOrDefault("X-Amz-Algorithm")
  valid_591401 = validateParameter(valid_591401, JString, required = false,
                                 default = nil)
  if valid_591401 != nil:
    section.add "X-Amz-Algorithm", valid_591401
  var valid_591402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-SignedHeaders", valid_591402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591404: Call_DescribeEndpoint_591392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint.
  ## 
  let valid = call_591404.validator(path, query, header, formData, body)
  let scheme = call_591404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591404.url(scheme.get, call_591404.host, call_591404.base,
                         call_591404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591404, url, valid)

proc call*(call_591405: Call_DescribeEndpoint_591392; body: JsonNode): Recallable =
  ## describeEndpoint
  ## Returns the description of an endpoint.
  ##   body: JObject (required)
  var body_591406 = newJObject()
  if body != nil:
    body_591406 = body
  result = call_591405.call(nil, nil, nil, nil, body_591406)

var describeEndpoint* = Call_DescribeEndpoint_591392(name: "describeEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpoint",
    validator: validate_DescribeEndpoint_591393, base: "/",
    url: url_DescribeEndpoint_591394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEndpointConfig_591407 = ref object of OpenApiRestCall_590364
proc url_DescribeEndpointConfig_591409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEndpointConfig_591408(path: JsonNode; query: JsonNode;
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
  var valid_591410 = header.getOrDefault("X-Amz-Target")
  valid_591410 = validateParameter(valid_591410, JString, required = true, default = newJString(
      "SageMaker.DescribeEndpointConfig"))
  if valid_591410 != nil:
    section.add "X-Amz-Target", valid_591410
  var valid_591411 = header.getOrDefault("X-Amz-Signature")
  valid_591411 = validateParameter(valid_591411, JString, required = false,
                                 default = nil)
  if valid_591411 != nil:
    section.add "X-Amz-Signature", valid_591411
  var valid_591412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591412 = validateParameter(valid_591412, JString, required = false,
                                 default = nil)
  if valid_591412 != nil:
    section.add "X-Amz-Content-Sha256", valid_591412
  var valid_591413 = header.getOrDefault("X-Amz-Date")
  valid_591413 = validateParameter(valid_591413, JString, required = false,
                                 default = nil)
  if valid_591413 != nil:
    section.add "X-Amz-Date", valid_591413
  var valid_591414 = header.getOrDefault("X-Amz-Credential")
  valid_591414 = validateParameter(valid_591414, JString, required = false,
                                 default = nil)
  if valid_591414 != nil:
    section.add "X-Amz-Credential", valid_591414
  var valid_591415 = header.getOrDefault("X-Amz-Security-Token")
  valid_591415 = validateParameter(valid_591415, JString, required = false,
                                 default = nil)
  if valid_591415 != nil:
    section.add "X-Amz-Security-Token", valid_591415
  var valid_591416 = header.getOrDefault("X-Amz-Algorithm")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Algorithm", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-SignedHeaders", valid_591417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591419: Call_DescribeEndpointConfig_591407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ## 
  let valid = call_591419.validator(path, query, header, formData, body)
  let scheme = call_591419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591419.url(scheme.get, call_591419.host, call_591419.base,
                         call_591419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591419, url, valid)

proc call*(call_591420: Call_DescribeEndpointConfig_591407; body: JsonNode): Recallable =
  ## describeEndpointConfig
  ## Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
  ##   body: JObject (required)
  var body_591421 = newJObject()
  if body != nil:
    body_591421 = body
  result = call_591420.call(nil, nil, nil, nil, body_591421)

var describeEndpointConfig* = Call_DescribeEndpointConfig_591407(
    name: "describeEndpointConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeEndpointConfig",
    validator: validate_DescribeEndpointConfig_591408, base: "/",
    url: url_DescribeEndpointConfig_591409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHyperParameterTuningJob_591422 = ref object of OpenApiRestCall_590364
proc url_DescribeHyperParameterTuningJob_591424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeHyperParameterTuningJob_591423(path: JsonNode;
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
  var valid_591425 = header.getOrDefault("X-Amz-Target")
  valid_591425 = validateParameter(valid_591425, JString, required = true, default = newJString(
      "SageMaker.DescribeHyperParameterTuningJob"))
  if valid_591425 != nil:
    section.add "X-Amz-Target", valid_591425
  var valid_591426 = header.getOrDefault("X-Amz-Signature")
  valid_591426 = validateParameter(valid_591426, JString, required = false,
                                 default = nil)
  if valid_591426 != nil:
    section.add "X-Amz-Signature", valid_591426
  var valid_591427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591427 = validateParameter(valid_591427, JString, required = false,
                                 default = nil)
  if valid_591427 != nil:
    section.add "X-Amz-Content-Sha256", valid_591427
  var valid_591428 = header.getOrDefault("X-Amz-Date")
  valid_591428 = validateParameter(valid_591428, JString, required = false,
                                 default = nil)
  if valid_591428 != nil:
    section.add "X-Amz-Date", valid_591428
  var valid_591429 = header.getOrDefault("X-Amz-Credential")
  valid_591429 = validateParameter(valid_591429, JString, required = false,
                                 default = nil)
  if valid_591429 != nil:
    section.add "X-Amz-Credential", valid_591429
  var valid_591430 = header.getOrDefault("X-Amz-Security-Token")
  valid_591430 = validateParameter(valid_591430, JString, required = false,
                                 default = nil)
  if valid_591430 != nil:
    section.add "X-Amz-Security-Token", valid_591430
  var valid_591431 = header.getOrDefault("X-Amz-Algorithm")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Algorithm", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-SignedHeaders", valid_591432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591434: Call_DescribeHyperParameterTuningJob_591422;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a description of a hyperparameter tuning job.
  ## 
  let valid = call_591434.validator(path, query, header, formData, body)
  let scheme = call_591434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591434.url(scheme.get, call_591434.host, call_591434.base,
                         call_591434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591434, url, valid)

proc call*(call_591435: Call_DescribeHyperParameterTuningJob_591422; body: JsonNode): Recallable =
  ## describeHyperParameterTuningJob
  ## Gets a description of a hyperparameter tuning job.
  ##   body: JObject (required)
  var body_591436 = newJObject()
  if body != nil:
    body_591436 = body
  result = call_591435.call(nil, nil, nil, nil, body_591436)

var describeHyperParameterTuningJob* = Call_DescribeHyperParameterTuningJob_591422(
    name: "describeHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob",
    validator: validate_DescribeHyperParameterTuningJob_591423, base: "/",
    url: url_DescribeHyperParameterTuningJob_591424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLabelingJob_591437 = ref object of OpenApiRestCall_590364
proc url_DescribeLabelingJob_591439(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLabelingJob_591438(path: JsonNode; query: JsonNode;
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
  var valid_591440 = header.getOrDefault("X-Amz-Target")
  valid_591440 = validateParameter(valid_591440, JString, required = true, default = newJString(
      "SageMaker.DescribeLabelingJob"))
  if valid_591440 != nil:
    section.add "X-Amz-Target", valid_591440
  var valid_591441 = header.getOrDefault("X-Amz-Signature")
  valid_591441 = validateParameter(valid_591441, JString, required = false,
                                 default = nil)
  if valid_591441 != nil:
    section.add "X-Amz-Signature", valid_591441
  var valid_591442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591442 = validateParameter(valid_591442, JString, required = false,
                                 default = nil)
  if valid_591442 != nil:
    section.add "X-Amz-Content-Sha256", valid_591442
  var valid_591443 = header.getOrDefault("X-Amz-Date")
  valid_591443 = validateParameter(valid_591443, JString, required = false,
                                 default = nil)
  if valid_591443 != nil:
    section.add "X-Amz-Date", valid_591443
  var valid_591444 = header.getOrDefault("X-Amz-Credential")
  valid_591444 = validateParameter(valid_591444, JString, required = false,
                                 default = nil)
  if valid_591444 != nil:
    section.add "X-Amz-Credential", valid_591444
  var valid_591445 = header.getOrDefault("X-Amz-Security-Token")
  valid_591445 = validateParameter(valid_591445, JString, required = false,
                                 default = nil)
  if valid_591445 != nil:
    section.add "X-Amz-Security-Token", valid_591445
  var valid_591446 = header.getOrDefault("X-Amz-Algorithm")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Algorithm", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-SignedHeaders", valid_591447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591449: Call_DescribeLabelingJob_591437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a labeling job.
  ## 
  let valid = call_591449.validator(path, query, header, formData, body)
  let scheme = call_591449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591449.url(scheme.get, call_591449.host, call_591449.base,
                         call_591449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591449, url, valid)

proc call*(call_591450: Call_DescribeLabelingJob_591437; body: JsonNode): Recallable =
  ## describeLabelingJob
  ## Gets information about a labeling job.
  ##   body: JObject (required)
  var body_591451 = newJObject()
  if body != nil:
    body_591451 = body
  result = call_591450.call(nil, nil, nil, nil, body_591451)

var describeLabelingJob* = Call_DescribeLabelingJob_591437(
    name: "describeLabelingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeLabelingJob",
    validator: validate_DescribeLabelingJob_591438, base: "/",
    url: url_DescribeLabelingJob_591439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModel_591452 = ref object of OpenApiRestCall_590364
proc url_DescribeModel_591454(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeModel_591453(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591455 = header.getOrDefault("X-Amz-Target")
  valid_591455 = validateParameter(valid_591455, JString, required = true, default = newJString(
      "SageMaker.DescribeModel"))
  if valid_591455 != nil:
    section.add "X-Amz-Target", valid_591455
  var valid_591456 = header.getOrDefault("X-Amz-Signature")
  valid_591456 = validateParameter(valid_591456, JString, required = false,
                                 default = nil)
  if valid_591456 != nil:
    section.add "X-Amz-Signature", valid_591456
  var valid_591457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591457 = validateParameter(valid_591457, JString, required = false,
                                 default = nil)
  if valid_591457 != nil:
    section.add "X-Amz-Content-Sha256", valid_591457
  var valid_591458 = header.getOrDefault("X-Amz-Date")
  valid_591458 = validateParameter(valid_591458, JString, required = false,
                                 default = nil)
  if valid_591458 != nil:
    section.add "X-Amz-Date", valid_591458
  var valid_591459 = header.getOrDefault("X-Amz-Credential")
  valid_591459 = validateParameter(valid_591459, JString, required = false,
                                 default = nil)
  if valid_591459 != nil:
    section.add "X-Amz-Credential", valid_591459
  var valid_591460 = header.getOrDefault("X-Amz-Security-Token")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Security-Token", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Algorithm")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Algorithm", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-SignedHeaders", valid_591462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591464: Call_DescribeModel_591452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ## 
  let valid = call_591464.validator(path, query, header, formData, body)
  let scheme = call_591464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591464.url(scheme.get, call_591464.host, call_591464.base,
                         call_591464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591464, url, valid)

proc call*(call_591465: Call_DescribeModel_591452; body: JsonNode): Recallable =
  ## describeModel
  ## Describes a model that you created using the <code>CreateModel</code> API.
  ##   body: JObject (required)
  var body_591466 = newJObject()
  if body != nil:
    body_591466 = body
  result = call_591465.call(nil, nil, nil, nil, body_591466)

var describeModel* = Call_DescribeModel_591452(name: "describeModel",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModel",
    validator: validate_DescribeModel_591453, base: "/", url: url_DescribeModel_591454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeModelPackage_591467 = ref object of OpenApiRestCall_590364
proc url_DescribeModelPackage_591469(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeModelPackage_591468(path: JsonNode; query: JsonNode;
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
  var valid_591470 = header.getOrDefault("X-Amz-Target")
  valid_591470 = validateParameter(valid_591470, JString, required = true, default = newJString(
      "SageMaker.DescribeModelPackage"))
  if valid_591470 != nil:
    section.add "X-Amz-Target", valid_591470
  var valid_591471 = header.getOrDefault("X-Amz-Signature")
  valid_591471 = validateParameter(valid_591471, JString, required = false,
                                 default = nil)
  if valid_591471 != nil:
    section.add "X-Amz-Signature", valid_591471
  var valid_591472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591472 = validateParameter(valid_591472, JString, required = false,
                                 default = nil)
  if valid_591472 != nil:
    section.add "X-Amz-Content-Sha256", valid_591472
  var valid_591473 = header.getOrDefault("X-Amz-Date")
  valid_591473 = validateParameter(valid_591473, JString, required = false,
                                 default = nil)
  if valid_591473 != nil:
    section.add "X-Amz-Date", valid_591473
  var valid_591474 = header.getOrDefault("X-Amz-Credential")
  valid_591474 = validateParameter(valid_591474, JString, required = false,
                                 default = nil)
  if valid_591474 != nil:
    section.add "X-Amz-Credential", valid_591474
  var valid_591475 = header.getOrDefault("X-Amz-Security-Token")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "X-Amz-Security-Token", valid_591475
  var valid_591476 = header.getOrDefault("X-Amz-Algorithm")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "X-Amz-Algorithm", valid_591476
  var valid_591477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-SignedHeaders", valid_591477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591479: Call_DescribeModelPackage_591467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ## 
  let valid = call_591479.validator(path, query, header, formData, body)
  let scheme = call_591479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591479.url(scheme.get, call_591479.host, call_591479.base,
                         call_591479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591479, url, valid)

proc call*(call_591480: Call_DescribeModelPackage_591467; body: JsonNode): Recallable =
  ## describeModelPackage
  ## <p>Returns a description of the specified model package, which is used to create Amazon SageMaker models or list them on AWS Marketplace.</p> <p>To create models in Amazon SageMaker, buyers can subscribe to model packages listed on AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_591481 = newJObject()
  if body != nil:
    body_591481 = body
  result = call_591480.call(nil, nil, nil, nil, body_591481)

var describeModelPackage* = Call_DescribeModelPackage_591467(
    name: "describeModelPackage", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeModelPackage",
    validator: validate_DescribeModelPackage_591468, base: "/",
    url: url_DescribeModelPackage_591469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstance_591482 = ref object of OpenApiRestCall_590364
proc url_DescribeNotebookInstance_591484(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNotebookInstance_591483(path: JsonNode; query: JsonNode;
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
  var valid_591485 = header.getOrDefault("X-Amz-Target")
  valid_591485 = validateParameter(valid_591485, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstance"))
  if valid_591485 != nil:
    section.add "X-Amz-Target", valid_591485
  var valid_591486 = header.getOrDefault("X-Amz-Signature")
  valid_591486 = validateParameter(valid_591486, JString, required = false,
                                 default = nil)
  if valid_591486 != nil:
    section.add "X-Amz-Signature", valid_591486
  var valid_591487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591487 = validateParameter(valid_591487, JString, required = false,
                                 default = nil)
  if valid_591487 != nil:
    section.add "X-Amz-Content-Sha256", valid_591487
  var valid_591488 = header.getOrDefault("X-Amz-Date")
  valid_591488 = validateParameter(valid_591488, JString, required = false,
                                 default = nil)
  if valid_591488 != nil:
    section.add "X-Amz-Date", valid_591488
  var valid_591489 = header.getOrDefault("X-Amz-Credential")
  valid_591489 = validateParameter(valid_591489, JString, required = false,
                                 default = nil)
  if valid_591489 != nil:
    section.add "X-Amz-Credential", valid_591489
  var valid_591490 = header.getOrDefault("X-Amz-Security-Token")
  valid_591490 = validateParameter(valid_591490, JString, required = false,
                                 default = nil)
  if valid_591490 != nil:
    section.add "X-Amz-Security-Token", valid_591490
  var valid_591491 = header.getOrDefault("X-Amz-Algorithm")
  valid_591491 = validateParameter(valid_591491, JString, required = false,
                                 default = nil)
  if valid_591491 != nil:
    section.add "X-Amz-Algorithm", valid_591491
  var valid_591492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591492 = validateParameter(valid_591492, JString, required = false,
                                 default = nil)
  if valid_591492 != nil:
    section.add "X-Amz-SignedHeaders", valid_591492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591494: Call_DescribeNotebookInstance_591482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a notebook instance.
  ## 
  let valid = call_591494.validator(path, query, header, formData, body)
  let scheme = call_591494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591494.url(scheme.get, call_591494.host, call_591494.base,
                         call_591494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591494, url, valid)

proc call*(call_591495: Call_DescribeNotebookInstance_591482; body: JsonNode): Recallable =
  ## describeNotebookInstance
  ## Returns information about a notebook instance.
  ##   body: JObject (required)
  var body_591496 = newJObject()
  if body != nil:
    body_591496 = body
  result = call_591495.call(nil, nil, nil, nil, body_591496)

var describeNotebookInstance* = Call_DescribeNotebookInstance_591482(
    name: "describeNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstance",
    validator: validate_DescribeNotebookInstance_591483, base: "/",
    url: url_DescribeNotebookInstance_591484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNotebookInstanceLifecycleConfig_591497 = ref object of OpenApiRestCall_590364
proc url_DescribeNotebookInstanceLifecycleConfig_591499(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeNotebookInstanceLifecycleConfig_591498(path: JsonNode;
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
  var valid_591500 = header.getOrDefault("X-Amz-Target")
  valid_591500 = validateParameter(valid_591500, JString, required = true, default = newJString(
      "SageMaker.DescribeNotebookInstanceLifecycleConfig"))
  if valid_591500 != nil:
    section.add "X-Amz-Target", valid_591500
  var valid_591501 = header.getOrDefault("X-Amz-Signature")
  valid_591501 = validateParameter(valid_591501, JString, required = false,
                                 default = nil)
  if valid_591501 != nil:
    section.add "X-Amz-Signature", valid_591501
  var valid_591502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591502 = validateParameter(valid_591502, JString, required = false,
                                 default = nil)
  if valid_591502 != nil:
    section.add "X-Amz-Content-Sha256", valid_591502
  var valid_591503 = header.getOrDefault("X-Amz-Date")
  valid_591503 = validateParameter(valid_591503, JString, required = false,
                                 default = nil)
  if valid_591503 != nil:
    section.add "X-Amz-Date", valid_591503
  var valid_591504 = header.getOrDefault("X-Amz-Credential")
  valid_591504 = validateParameter(valid_591504, JString, required = false,
                                 default = nil)
  if valid_591504 != nil:
    section.add "X-Amz-Credential", valid_591504
  var valid_591505 = header.getOrDefault("X-Amz-Security-Token")
  valid_591505 = validateParameter(valid_591505, JString, required = false,
                                 default = nil)
  if valid_591505 != nil:
    section.add "X-Amz-Security-Token", valid_591505
  var valid_591506 = header.getOrDefault("X-Amz-Algorithm")
  valid_591506 = validateParameter(valid_591506, JString, required = false,
                                 default = nil)
  if valid_591506 != nil:
    section.add "X-Amz-Algorithm", valid_591506
  var valid_591507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591507 = validateParameter(valid_591507, JString, required = false,
                                 default = nil)
  if valid_591507 != nil:
    section.add "X-Amz-SignedHeaders", valid_591507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591509: Call_DescribeNotebookInstanceLifecycleConfig_591497;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ## 
  let valid = call_591509.validator(path, query, header, formData, body)
  let scheme = call_591509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591509.url(scheme.get, call_591509.host, call_591509.base,
                         call_591509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591509, url, valid)

proc call*(call_591510: Call_DescribeNotebookInstanceLifecycleConfig_591497;
          body: JsonNode): Recallable =
  ## describeNotebookInstanceLifecycleConfig
  ## <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
  ##   body: JObject (required)
  var body_591511 = newJObject()
  if body != nil:
    body_591511 = body
  result = call_591510.call(nil, nil, nil, nil, body_591511)

var describeNotebookInstanceLifecycleConfig* = Call_DescribeNotebookInstanceLifecycleConfig_591497(
    name: "describeNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig",
    validator: validate_DescribeNotebookInstanceLifecycleConfig_591498, base: "/",
    url: url_DescribeNotebookInstanceLifecycleConfig_591499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSubscribedWorkteam_591512 = ref object of OpenApiRestCall_590364
proc url_DescribeSubscribedWorkteam_591514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSubscribedWorkteam_591513(path: JsonNode; query: JsonNode;
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
  var valid_591515 = header.getOrDefault("X-Amz-Target")
  valid_591515 = validateParameter(valid_591515, JString, required = true, default = newJString(
      "SageMaker.DescribeSubscribedWorkteam"))
  if valid_591515 != nil:
    section.add "X-Amz-Target", valid_591515
  var valid_591516 = header.getOrDefault("X-Amz-Signature")
  valid_591516 = validateParameter(valid_591516, JString, required = false,
                                 default = nil)
  if valid_591516 != nil:
    section.add "X-Amz-Signature", valid_591516
  var valid_591517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591517 = validateParameter(valid_591517, JString, required = false,
                                 default = nil)
  if valid_591517 != nil:
    section.add "X-Amz-Content-Sha256", valid_591517
  var valid_591518 = header.getOrDefault("X-Amz-Date")
  valid_591518 = validateParameter(valid_591518, JString, required = false,
                                 default = nil)
  if valid_591518 != nil:
    section.add "X-Amz-Date", valid_591518
  var valid_591519 = header.getOrDefault("X-Amz-Credential")
  valid_591519 = validateParameter(valid_591519, JString, required = false,
                                 default = nil)
  if valid_591519 != nil:
    section.add "X-Amz-Credential", valid_591519
  var valid_591520 = header.getOrDefault("X-Amz-Security-Token")
  valid_591520 = validateParameter(valid_591520, JString, required = false,
                                 default = nil)
  if valid_591520 != nil:
    section.add "X-Amz-Security-Token", valid_591520
  var valid_591521 = header.getOrDefault("X-Amz-Algorithm")
  valid_591521 = validateParameter(valid_591521, JString, required = false,
                                 default = nil)
  if valid_591521 != nil:
    section.add "X-Amz-Algorithm", valid_591521
  var valid_591522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591522 = validateParameter(valid_591522, JString, required = false,
                                 default = nil)
  if valid_591522 != nil:
    section.add "X-Amz-SignedHeaders", valid_591522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591524: Call_DescribeSubscribedWorkteam_591512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ## 
  let valid = call_591524.validator(path, query, header, formData, body)
  let scheme = call_591524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591524.url(scheme.get, call_591524.host, call_591524.base,
                         call_591524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591524, url, valid)

proc call*(call_591525: Call_DescribeSubscribedWorkteam_591512; body: JsonNode): Recallable =
  ## describeSubscribedWorkteam
  ## Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the AWS Marketplace.
  ##   body: JObject (required)
  var body_591526 = newJObject()
  if body != nil:
    body_591526 = body
  result = call_591525.call(nil, nil, nil, nil, body_591526)

var describeSubscribedWorkteam* = Call_DescribeSubscribedWorkteam_591512(
    name: "describeSubscribedWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam",
    validator: validate_DescribeSubscribedWorkteam_591513, base: "/",
    url: url_DescribeSubscribedWorkteam_591514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrainingJob_591527 = ref object of OpenApiRestCall_590364
proc url_DescribeTrainingJob_591529(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTrainingJob_591528(path: JsonNode; query: JsonNode;
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
  var valid_591530 = header.getOrDefault("X-Amz-Target")
  valid_591530 = validateParameter(valid_591530, JString, required = true, default = newJString(
      "SageMaker.DescribeTrainingJob"))
  if valid_591530 != nil:
    section.add "X-Amz-Target", valid_591530
  var valid_591531 = header.getOrDefault("X-Amz-Signature")
  valid_591531 = validateParameter(valid_591531, JString, required = false,
                                 default = nil)
  if valid_591531 != nil:
    section.add "X-Amz-Signature", valid_591531
  var valid_591532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591532 = validateParameter(valid_591532, JString, required = false,
                                 default = nil)
  if valid_591532 != nil:
    section.add "X-Amz-Content-Sha256", valid_591532
  var valid_591533 = header.getOrDefault("X-Amz-Date")
  valid_591533 = validateParameter(valid_591533, JString, required = false,
                                 default = nil)
  if valid_591533 != nil:
    section.add "X-Amz-Date", valid_591533
  var valid_591534 = header.getOrDefault("X-Amz-Credential")
  valid_591534 = validateParameter(valid_591534, JString, required = false,
                                 default = nil)
  if valid_591534 != nil:
    section.add "X-Amz-Credential", valid_591534
  var valid_591535 = header.getOrDefault("X-Amz-Security-Token")
  valid_591535 = validateParameter(valid_591535, JString, required = false,
                                 default = nil)
  if valid_591535 != nil:
    section.add "X-Amz-Security-Token", valid_591535
  var valid_591536 = header.getOrDefault("X-Amz-Algorithm")
  valid_591536 = validateParameter(valid_591536, JString, required = false,
                                 default = nil)
  if valid_591536 != nil:
    section.add "X-Amz-Algorithm", valid_591536
  var valid_591537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591537 = validateParameter(valid_591537, JString, required = false,
                                 default = nil)
  if valid_591537 != nil:
    section.add "X-Amz-SignedHeaders", valid_591537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591539: Call_DescribeTrainingJob_591527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a training job.
  ## 
  let valid = call_591539.validator(path, query, header, formData, body)
  let scheme = call_591539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591539.url(scheme.get, call_591539.host, call_591539.base,
                         call_591539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591539, url, valid)

proc call*(call_591540: Call_DescribeTrainingJob_591527; body: JsonNode): Recallable =
  ## describeTrainingJob
  ## Returns information about a training job.
  ##   body: JObject (required)
  var body_591541 = newJObject()
  if body != nil:
    body_591541 = body
  result = call_591540.call(nil, nil, nil, nil, body_591541)

var describeTrainingJob* = Call_DescribeTrainingJob_591527(
    name: "describeTrainingJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTrainingJob",
    validator: validate_DescribeTrainingJob_591528, base: "/",
    url: url_DescribeTrainingJob_591529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTransformJob_591542 = ref object of OpenApiRestCall_590364
proc url_DescribeTransformJob_591544(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTransformJob_591543(path: JsonNode; query: JsonNode;
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
  var valid_591545 = header.getOrDefault("X-Amz-Target")
  valid_591545 = validateParameter(valid_591545, JString, required = true, default = newJString(
      "SageMaker.DescribeTransformJob"))
  if valid_591545 != nil:
    section.add "X-Amz-Target", valid_591545
  var valid_591546 = header.getOrDefault("X-Amz-Signature")
  valid_591546 = validateParameter(valid_591546, JString, required = false,
                                 default = nil)
  if valid_591546 != nil:
    section.add "X-Amz-Signature", valid_591546
  var valid_591547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591547 = validateParameter(valid_591547, JString, required = false,
                                 default = nil)
  if valid_591547 != nil:
    section.add "X-Amz-Content-Sha256", valid_591547
  var valid_591548 = header.getOrDefault("X-Amz-Date")
  valid_591548 = validateParameter(valid_591548, JString, required = false,
                                 default = nil)
  if valid_591548 != nil:
    section.add "X-Amz-Date", valid_591548
  var valid_591549 = header.getOrDefault("X-Amz-Credential")
  valid_591549 = validateParameter(valid_591549, JString, required = false,
                                 default = nil)
  if valid_591549 != nil:
    section.add "X-Amz-Credential", valid_591549
  var valid_591550 = header.getOrDefault("X-Amz-Security-Token")
  valid_591550 = validateParameter(valid_591550, JString, required = false,
                                 default = nil)
  if valid_591550 != nil:
    section.add "X-Amz-Security-Token", valid_591550
  var valid_591551 = header.getOrDefault("X-Amz-Algorithm")
  valid_591551 = validateParameter(valid_591551, JString, required = false,
                                 default = nil)
  if valid_591551 != nil:
    section.add "X-Amz-Algorithm", valid_591551
  var valid_591552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591552 = validateParameter(valid_591552, JString, required = false,
                                 default = nil)
  if valid_591552 != nil:
    section.add "X-Amz-SignedHeaders", valid_591552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591554: Call_DescribeTransformJob_591542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a transform job.
  ## 
  let valid = call_591554.validator(path, query, header, formData, body)
  let scheme = call_591554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591554.url(scheme.get, call_591554.host, call_591554.base,
                         call_591554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591554, url, valid)

proc call*(call_591555: Call_DescribeTransformJob_591542; body: JsonNode): Recallable =
  ## describeTransformJob
  ## Returns information about a transform job.
  ##   body: JObject (required)
  var body_591556 = newJObject()
  if body != nil:
    body_591556 = body
  result = call_591555.call(nil, nil, nil, nil, body_591556)

var describeTransformJob* = Call_DescribeTransformJob_591542(
    name: "describeTransformJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeTransformJob",
    validator: validate_DescribeTransformJob_591543, base: "/",
    url: url_DescribeTransformJob_591544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeWorkteam_591557 = ref object of OpenApiRestCall_590364
proc url_DescribeWorkteam_591559(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeWorkteam_591558(path: JsonNode; query: JsonNode;
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
  var valid_591560 = header.getOrDefault("X-Amz-Target")
  valid_591560 = validateParameter(valid_591560, JString, required = true, default = newJString(
      "SageMaker.DescribeWorkteam"))
  if valid_591560 != nil:
    section.add "X-Amz-Target", valid_591560
  var valid_591561 = header.getOrDefault("X-Amz-Signature")
  valid_591561 = validateParameter(valid_591561, JString, required = false,
                                 default = nil)
  if valid_591561 != nil:
    section.add "X-Amz-Signature", valid_591561
  var valid_591562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591562 = validateParameter(valid_591562, JString, required = false,
                                 default = nil)
  if valid_591562 != nil:
    section.add "X-Amz-Content-Sha256", valid_591562
  var valid_591563 = header.getOrDefault("X-Amz-Date")
  valid_591563 = validateParameter(valid_591563, JString, required = false,
                                 default = nil)
  if valid_591563 != nil:
    section.add "X-Amz-Date", valid_591563
  var valid_591564 = header.getOrDefault("X-Amz-Credential")
  valid_591564 = validateParameter(valid_591564, JString, required = false,
                                 default = nil)
  if valid_591564 != nil:
    section.add "X-Amz-Credential", valid_591564
  var valid_591565 = header.getOrDefault("X-Amz-Security-Token")
  valid_591565 = validateParameter(valid_591565, JString, required = false,
                                 default = nil)
  if valid_591565 != nil:
    section.add "X-Amz-Security-Token", valid_591565
  var valid_591566 = header.getOrDefault("X-Amz-Algorithm")
  valid_591566 = validateParameter(valid_591566, JString, required = false,
                                 default = nil)
  if valid_591566 != nil:
    section.add "X-Amz-Algorithm", valid_591566
  var valid_591567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591567 = validateParameter(valid_591567, JString, required = false,
                                 default = nil)
  if valid_591567 != nil:
    section.add "X-Amz-SignedHeaders", valid_591567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591569: Call_DescribeWorkteam_591557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ## 
  let valid = call_591569.validator(path, query, header, formData, body)
  let scheme = call_591569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591569.url(scheme.get, call_591569.host, call_591569.base,
                         call_591569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591569, url, valid)

proc call*(call_591570: Call_DescribeWorkteam_591557; body: JsonNode): Recallable =
  ## describeWorkteam
  ## Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var body_591571 = newJObject()
  if body != nil:
    body_591571 = body
  result = call_591570.call(nil, nil, nil, nil, body_591571)

var describeWorkteam* = Call_DescribeWorkteam_591557(name: "describeWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.DescribeWorkteam",
    validator: validate_DescribeWorkteam_591558, base: "/",
    url: url_DescribeWorkteam_591559, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSearchSuggestions_591572 = ref object of OpenApiRestCall_590364
proc url_GetSearchSuggestions_591574(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSearchSuggestions_591573(path: JsonNode; query: JsonNode;
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
  var valid_591575 = header.getOrDefault("X-Amz-Target")
  valid_591575 = validateParameter(valid_591575, JString, required = true, default = newJString(
      "SageMaker.GetSearchSuggestions"))
  if valid_591575 != nil:
    section.add "X-Amz-Target", valid_591575
  var valid_591576 = header.getOrDefault("X-Amz-Signature")
  valid_591576 = validateParameter(valid_591576, JString, required = false,
                                 default = nil)
  if valid_591576 != nil:
    section.add "X-Amz-Signature", valid_591576
  var valid_591577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591577 = validateParameter(valid_591577, JString, required = false,
                                 default = nil)
  if valid_591577 != nil:
    section.add "X-Amz-Content-Sha256", valid_591577
  var valid_591578 = header.getOrDefault("X-Amz-Date")
  valid_591578 = validateParameter(valid_591578, JString, required = false,
                                 default = nil)
  if valid_591578 != nil:
    section.add "X-Amz-Date", valid_591578
  var valid_591579 = header.getOrDefault("X-Amz-Credential")
  valid_591579 = validateParameter(valid_591579, JString, required = false,
                                 default = nil)
  if valid_591579 != nil:
    section.add "X-Amz-Credential", valid_591579
  var valid_591580 = header.getOrDefault("X-Amz-Security-Token")
  valid_591580 = validateParameter(valid_591580, JString, required = false,
                                 default = nil)
  if valid_591580 != nil:
    section.add "X-Amz-Security-Token", valid_591580
  var valid_591581 = header.getOrDefault("X-Amz-Algorithm")
  valid_591581 = validateParameter(valid_591581, JString, required = false,
                                 default = nil)
  if valid_591581 != nil:
    section.add "X-Amz-Algorithm", valid_591581
  var valid_591582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591582 = validateParameter(valid_591582, JString, required = false,
                                 default = nil)
  if valid_591582 != nil:
    section.add "X-Amz-SignedHeaders", valid_591582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591584: Call_GetSearchSuggestions_591572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ## 
  let valid = call_591584.validator(path, query, header, formData, body)
  let scheme = call_591584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591584.url(scheme.get, call_591584.host, call_591584.base,
                         call_591584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591584, url, valid)

proc call*(call_591585: Call_GetSearchSuggestions_591572; body: JsonNode): Recallable =
  ## getSearchSuggestions
  ## An auto-complete API for the search functionality in the Amazon SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
  ##   body: JObject (required)
  var body_591586 = newJObject()
  if body != nil:
    body_591586 = body
  result = call_591585.call(nil, nil, nil, nil, body_591586)

var getSearchSuggestions* = Call_GetSearchSuggestions_591572(
    name: "getSearchSuggestions", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.GetSearchSuggestions",
    validator: validate_GetSearchSuggestions_591573, base: "/",
    url: url_GetSearchSuggestions_591574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAlgorithms_591587 = ref object of OpenApiRestCall_590364
proc url_ListAlgorithms_591589(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAlgorithms_591588(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591590 = header.getOrDefault("X-Amz-Target")
  valid_591590 = validateParameter(valid_591590, JString, required = true, default = newJString(
      "SageMaker.ListAlgorithms"))
  if valid_591590 != nil:
    section.add "X-Amz-Target", valid_591590
  var valid_591591 = header.getOrDefault("X-Amz-Signature")
  valid_591591 = validateParameter(valid_591591, JString, required = false,
                                 default = nil)
  if valid_591591 != nil:
    section.add "X-Amz-Signature", valid_591591
  var valid_591592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591592 = validateParameter(valid_591592, JString, required = false,
                                 default = nil)
  if valid_591592 != nil:
    section.add "X-Amz-Content-Sha256", valid_591592
  var valid_591593 = header.getOrDefault("X-Amz-Date")
  valid_591593 = validateParameter(valid_591593, JString, required = false,
                                 default = nil)
  if valid_591593 != nil:
    section.add "X-Amz-Date", valid_591593
  var valid_591594 = header.getOrDefault("X-Amz-Credential")
  valid_591594 = validateParameter(valid_591594, JString, required = false,
                                 default = nil)
  if valid_591594 != nil:
    section.add "X-Amz-Credential", valid_591594
  var valid_591595 = header.getOrDefault("X-Amz-Security-Token")
  valid_591595 = validateParameter(valid_591595, JString, required = false,
                                 default = nil)
  if valid_591595 != nil:
    section.add "X-Amz-Security-Token", valid_591595
  var valid_591596 = header.getOrDefault("X-Amz-Algorithm")
  valid_591596 = validateParameter(valid_591596, JString, required = false,
                                 default = nil)
  if valid_591596 != nil:
    section.add "X-Amz-Algorithm", valid_591596
  var valid_591597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591597 = validateParameter(valid_591597, JString, required = false,
                                 default = nil)
  if valid_591597 != nil:
    section.add "X-Amz-SignedHeaders", valid_591597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591599: Call_ListAlgorithms_591587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the machine learning algorithms that have been created.
  ## 
  let valid = call_591599.validator(path, query, header, formData, body)
  let scheme = call_591599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591599.url(scheme.get, call_591599.host, call_591599.base,
                         call_591599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591599, url, valid)

proc call*(call_591600: Call_ListAlgorithms_591587; body: JsonNode): Recallable =
  ## listAlgorithms
  ## Lists the machine learning algorithms that have been created.
  ##   body: JObject (required)
  var body_591601 = newJObject()
  if body != nil:
    body_591601 = body
  result = call_591600.call(nil, nil, nil, nil, body_591601)

var listAlgorithms* = Call_ListAlgorithms_591587(name: "listAlgorithms",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListAlgorithms",
    validator: validate_ListAlgorithms_591588, base: "/", url: url_ListAlgorithms_591589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCodeRepositories_591602 = ref object of OpenApiRestCall_590364
proc url_ListCodeRepositories_591604(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCodeRepositories_591603(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591605 = header.getOrDefault("X-Amz-Target")
  valid_591605 = validateParameter(valid_591605, JString, required = true, default = newJString(
      "SageMaker.ListCodeRepositories"))
  if valid_591605 != nil:
    section.add "X-Amz-Target", valid_591605
  var valid_591606 = header.getOrDefault("X-Amz-Signature")
  valid_591606 = validateParameter(valid_591606, JString, required = false,
                                 default = nil)
  if valid_591606 != nil:
    section.add "X-Amz-Signature", valid_591606
  var valid_591607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591607 = validateParameter(valid_591607, JString, required = false,
                                 default = nil)
  if valid_591607 != nil:
    section.add "X-Amz-Content-Sha256", valid_591607
  var valid_591608 = header.getOrDefault("X-Amz-Date")
  valid_591608 = validateParameter(valid_591608, JString, required = false,
                                 default = nil)
  if valid_591608 != nil:
    section.add "X-Amz-Date", valid_591608
  var valid_591609 = header.getOrDefault("X-Amz-Credential")
  valid_591609 = validateParameter(valid_591609, JString, required = false,
                                 default = nil)
  if valid_591609 != nil:
    section.add "X-Amz-Credential", valid_591609
  var valid_591610 = header.getOrDefault("X-Amz-Security-Token")
  valid_591610 = validateParameter(valid_591610, JString, required = false,
                                 default = nil)
  if valid_591610 != nil:
    section.add "X-Amz-Security-Token", valid_591610
  var valid_591611 = header.getOrDefault("X-Amz-Algorithm")
  valid_591611 = validateParameter(valid_591611, JString, required = false,
                                 default = nil)
  if valid_591611 != nil:
    section.add "X-Amz-Algorithm", valid_591611
  var valid_591612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591612 = validateParameter(valid_591612, JString, required = false,
                                 default = nil)
  if valid_591612 != nil:
    section.add "X-Amz-SignedHeaders", valid_591612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591614: Call_ListCodeRepositories_591602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the Git repositories in your account.
  ## 
  let valid = call_591614.validator(path, query, header, formData, body)
  let scheme = call_591614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591614.url(scheme.get, call_591614.host, call_591614.base,
                         call_591614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591614, url, valid)

proc call*(call_591615: Call_ListCodeRepositories_591602; body: JsonNode): Recallable =
  ## listCodeRepositories
  ## Gets a list of the Git repositories in your account.
  ##   body: JObject (required)
  var body_591616 = newJObject()
  if body != nil:
    body_591616 = body
  result = call_591615.call(nil, nil, nil, nil, body_591616)

var listCodeRepositories* = Call_ListCodeRepositories_591602(
    name: "listCodeRepositories", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCodeRepositories",
    validator: validate_ListCodeRepositories_591603, base: "/",
    url: url_ListCodeRepositories_591604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompilationJobs_591617 = ref object of OpenApiRestCall_590364
proc url_ListCompilationJobs_591619(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCompilationJobs_591618(path: JsonNode; query: JsonNode;
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
  var valid_591620 = query.getOrDefault("MaxResults")
  valid_591620 = validateParameter(valid_591620, JString, required = false,
                                 default = nil)
  if valid_591620 != nil:
    section.add "MaxResults", valid_591620
  var valid_591621 = query.getOrDefault("NextToken")
  valid_591621 = validateParameter(valid_591621, JString, required = false,
                                 default = nil)
  if valid_591621 != nil:
    section.add "NextToken", valid_591621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591622 = header.getOrDefault("X-Amz-Target")
  valid_591622 = validateParameter(valid_591622, JString, required = true, default = newJString(
      "SageMaker.ListCompilationJobs"))
  if valid_591622 != nil:
    section.add "X-Amz-Target", valid_591622
  var valid_591623 = header.getOrDefault("X-Amz-Signature")
  valid_591623 = validateParameter(valid_591623, JString, required = false,
                                 default = nil)
  if valid_591623 != nil:
    section.add "X-Amz-Signature", valid_591623
  var valid_591624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591624 = validateParameter(valid_591624, JString, required = false,
                                 default = nil)
  if valid_591624 != nil:
    section.add "X-Amz-Content-Sha256", valid_591624
  var valid_591625 = header.getOrDefault("X-Amz-Date")
  valid_591625 = validateParameter(valid_591625, JString, required = false,
                                 default = nil)
  if valid_591625 != nil:
    section.add "X-Amz-Date", valid_591625
  var valid_591626 = header.getOrDefault("X-Amz-Credential")
  valid_591626 = validateParameter(valid_591626, JString, required = false,
                                 default = nil)
  if valid_591626 != nil:
    section.add "X-Amz-Credential", valid_591626
  var valid_591627 = header.getOrDefault("X-Amz-Security-Token")
  valid_591627 = validateParameter(valid_591627, JString, required = false,
                                 default = nil)
  if valid_591627 != nil:
    section.add "X-Amz-Security-Token", valid_591627
  var valid_591628 = header.getOrDefault("X-Amz-Algorithm")
  valid_591628 = validateParameter(valid_591628, JString, required = false,
                                 default = nil)
  if valid_591628 != nil:
    section.add "X-Amz-Algorithm", valid_591628
  var valid_591629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591629 = validateParameter(valid_591629, JString, required = false,
                                 default = nil)
  if valid_591629 != nil:
    section.add "X-Amz-SignedHeaders", valid_591629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591631: Call_ListCompilationJobs_591617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ## 
  let valid = call_591631.validator(path, query, header, formData, body)
  let scheme = call_591631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591631.url(scheme.get, call_591631.host, call_591631.base,
                         call_591631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591631, url, valid)

proc call*(call_591632: Call_ListCompilationJobs_591617; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCompilationJobs
  ## <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a>CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a>DescribeCompilationJob</a>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591633 = newJObject()
  var body_591634 = newJObject()
  add(query_591633, "MaxResults", newJString(MaxResults))
  add(query_591633, "NextToken", newJString(NextToken))
  if body != nil:
    body_591634 = body
  result = call_591632.call(nil, query_591633, nil, nil, body_591634)

var listCompilationJobs* = Call_ListCompilationJobs_591617(
    name: "listCompilationJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListCompilationJobs",
    validator: validate_ListCompilationJobs_591618, base: "/",
    url: url_ListCompilationJobs_591619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpointConfigs_591636 = ref object of OpenApiRestCall_590364
proc url_ListEndpointConfigs_591638(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEndpointConfigs_591637(path: JsonNode; query: JsonNode;
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
  var valid_591639 = query.getOrDefault("MaxResults")
  valid_591639 = validateParameter(valid_591639, JString, required = false,
                                 default = nil)
  if valid_591639 != nil:
    section.add "MaxResults", valid_591639
  var valid_591640 = query.getOrDefault("NextToken")
  valid_591640 = validateParameter(valid_591640, JString, required = false,
                                 default = nil)
  if valid_591640 != nil:
    section.add "NextToken", valid_591640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591641 = header.getOrDefault("X-Amz-Target")
  valid_591641 = validateParameter(valid_591641, JString, required = true, default = newJString(
      "SageMaker.ListEndpointConfigs"))
  if valid_591641 != nil:
    section.add "X-Amz-Target", valid_591641
  var valid_591642 = header.getOrDefault("X-Amz-Signature")
  valid_591642 = validateParameter(valid_591642, JString, required = false,
                                 default = nil)
  if valid_591642 != nil:
    section.add "X-Amz-Signature", valid_591642
  var valid_591643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591643 = validateParameter(valid_591643, JString, required = false,
                                 default = nil)
  if valid_591643 != nil:
    section.add "X-Amz-Content-Sha256", valid_591643
  var valid_591644 = header.getOrDefault("X-Amz-Date")
  valid_591644 = validateParameter(valid_591644, JString, required = false,
                                 default = nil)
  if valid_591644 != nil:
    section.add "X-Amz-Date", valid_591644
  var valid_591645 = header.getOrDefault("X-Amz-Credential")
  valid_591645 = validateParameter(valid_591645, JString, required = false,
                                 default = nil)
  if valid_591645 != nil:
    section.add "X-Amz-Credential", valid_591645
  var valid_591646 = header.getOrDefault("X-Amz-Security-Token")
  valid_591646 = validateParameter(valid_591646, JString, required = false,
                                 default = nil)
  if valid_591646 != nil:
    section.add "X-Amz-Security-Token", valid_591646
  var valid_591647 = header.getOrDefault("X-Amz-Algorithm")
  valid_591647 = validateParameter(valid_591647, JString, required = false,
                                 default = nil)
  if valid_591647 != nil:
    section.add "X-Amz-Algorithm", valid_591647
  var valid_591648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591648 = validateParameter(valid_591648, JString, required = false,
                                 default = nil)
  if valid_591648 != nil:
    section.add "X-Amz-SignedHeaders", valid_591648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591650: Call_ListEndpointConfigs_591636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoint configurations.
  ## 
  let valid = call_591650.validator(path, query, header, formData, body)
  let scheme = call_591650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591650.url(scheme.get, call_591650.host, call_591650.base,
                         call_591650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591650, url, valid)

proc call*(call_591651: Call_ListEndpointConfigs_591636; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpointConfigs
  ## Lists endpoint configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591652 = newJObject()
  var body_591653 = newJObject()
  add(query_591652, "MaxResults", newJString(MaxResults))
  add(query_591652, "NextToken", newJString(NextToken))
  if body != nil:
    body_591653 = body
  result = call_591651.call(nil, query_591652, nil, nil, body_591653)

var listEndpointConfigs* = Call_ListEndpointConfigs_591636(
    name: "listEndpointConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpointConfigs",
    validator: validate_ListEndpointConfigs_591637, base: "/",
    url: url_ListEndpointConfigs_591638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEndpoints_591654 = ref object of OpenApiRestCall_590364
proc url_ListEndpoints_591656(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEndpoints_591655(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591657 = query.getOrDefault("MaxResults")
  valid_591657 = validateParameter(valid_591657, JString, required = false,
                                 default = nil)
  if valid_591657 != nil:
    section.add "MaxResults", valid_591657
  var valid_591658 = query.getOrDefault("NextToken")
  valid_591658 = validateParameter(valid_591658, JString, required = false,
                                 default = nil)
  if valid_591658 != nil:
    section.add "NextToken", valid_591658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591659 = header.getOrDefault("X-Amz-Target")
  valid_591659 = validateParameter(valid_591659, JString, required = true, default = newJString(
      "SageMaker.ListEndpoints"))
  if valid_591659 != nil:
    section.add "X-Amz-Target", valid_591659
  var valid_591660 = header.getOrDefault("X-Amz-Signature")
  valid_591660 = validateParameter(valid_591660, JString, required = false,
                                 default = nil)
  if valid_591660 != nil:
    section.add "X-Amz-Signature", valid_591660
  var valid_591661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591661 = validateParameter(valid_591661, JString, required = false,
                                 default = nil)
  if valid_591661 != nil:
    section.add "X-Amz-Content-Sha256", valid_591661
  var valid_591662 = header.getOrDefault("X-Amz-Date")
  valid_591662 = validateParameter(valid_591662, JString, required = false,
                                 default = nil)
  if valid_591662 != nil:
    section.add "X-Amz-Date", valid_591662
  var valid_591663 = header.getOrDefault("X-Amz-Credential")
  valid_591663 = validateParameter(valid_591663, JString, required = false,
                                 default = nil)
  if valid_591663 != nil:
    section.add "X-Amz-Credential", valid_591663
  var valid_591664 = header.getOrDefault("X-Amz-Security-Token")
  valid_591664 = validateParameter(valid_591664, JString, required = false,
                                 default = nil)
  if valid_591664 != nil:
    section.add "X-Amz-Security-Token", valid_591664
  var valid_591665 = header.getOrDefault("X-Amz-Algorithm")
  valid_591665 = validateParameter(valid_591665, JString, required = false,
                                 default = nil)
  if valid_591665 != nil:
    section.add "X-Amz-Algorithm", valid_591665
  var valid_591666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591666 = validateParameter(valid_591666, JString, required = false,
                                 default = nil)
  if valid_591666 != nil:
    section.add "X-Amz-SignedHeaders", valid_591666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591668: Call_ListEndpoints_591654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists endpoints.
  ## 
  let valid = call_591668.validator(path, query, header, formData, body)
  let scheme = call_591668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591668.url(scheme.get, call_591668.host, call_591668.base,
                         call_591668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591668, url, valid)

proc call*(call_591669: Call_ListEndpoints_591654; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listEndpoints
  ## Lists endpoints.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591670 = newJObject()
  var body_591671 = newJObject()
  add(query_591670, "MaxResults", newJString(MaxResults))
  add(query_591670, "NextToken", newJString(NextToken))
  if body != nil:
    body_591671 = body
  result = call_591669.call(nil, query_591670, nil, nil, body_591671)

var listEndpoints* = Call_ListEndpoints_591654(name: "listEndpoints",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListEndpoints",
    validator: validate_ListEndpoints_591655, base: "/", url: url_ListEndpoints_591656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHyperParameterTuningJobs_591672 = ref object of OpenApiRestCall_590364
proc url_ListHyperParameterTuningJobs_591674(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHyperParameterTuningJobs_591673(path: JsonNode; query: JsonNode;
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
  var valid_591675 = query.getOrDefault("MaxResults")
  valid_591675 = validateParameter(valid_591675, JString, required = false,
                                 default = nil)
  if valid_591675 != nil:
    section.add "MaxResults", valid_591675
  var valid_591676 = query.getOrDefault("NextToken")
  valid_591676 = validateParameter(valid_591676, JString, required = false,
                                 default = nil)
  if valid_591676 != nil:
    section.add "NextToken", valid_591676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591677 = header.getOrDefault("X-Amz-Target")
  valid_591677 = validateParameter(valid_591677, JString, required = true, default = newJString(
      "SageMaker.ListHyperParameterTuningJobs"))
  if valid_591677 != nil:
    section.add "X-Amz-Target", valid_591677
  var valid_591678 = header.getOrDefault("X-Amz-Signature")
  valid_591678 = validateParameter(valid_591678, JString, required = false,
                                 default = nil)
  if valid_591678 != nil:
    section.add "X-Amz-Signature", valid_591678
  var valid_591679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591679 = validateParameter(valid_591679, JString, required = false,
                                 default = nil)
  if valid_591679 != nil:
    section.add "X-Amz-Content-Sha256", valid_591679
  var valid_591680 = header.getOrDefault("X-Amz-Date")
  valid_591680 = validateParameter(valid_591680, JString, required = false,
                                 default = nil)
  if valid_591680 != nil:
    section.add "X-Amz-Date", valid_591680
  var valid_591681 = header.getOrDefault("X-Amz-Credential")
  valid_591681 = validateParameter(valid_591681, JString, required = false,
                                 default = nil)
  if valid_591681 != nil:
    section.add "X-Amz-Credential", valid_591681
  var valid_591682 = header.getOrDefault("X-Amz-Security-Token")
  valid_591682 = validateParameter(valid_591682, JString, required = false,
                                 default = nil)
  if valid_591682 != nil:
    section.add "X-Amz-Security-Token", valid_591682
  var valid_591683 = header.getOrDefault("X-Amz-Algorithm")
  valid_591683 = validateParameter(valid_591683, JString, required = false,
                                 default = nil)
  if valid_591683 != nil:
    section.add "X-Amz-Algorithm", valid_591683
  var valid_591684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591684 = validateParameter(valid_591684, JString, required = false,
                                 default = nil)
  if valid_591684 != nil:
    section.add "X-Amz-SignedHeaders", valid_591684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591686: Call_ListHyperParameterTuningJobs_591672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ## 
  let valid = call_591686.validator(path, query, header, formData, body)
  let scheme = call_591686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591686.url(scheme.get, call_591686.host, call_591686.base,
                         call_591686.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591686, url, valid)

proc call*(call_591687: Call_ListHyperParameterTuningJobs_591672; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listHyperParameterTuningJobs
  ## Gets a list of <a>HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591688 = newJObject()
  var body_591689 = newJObject()
  add(query_591688, "MaxResults", newJString(MaxResults))
  add(query_591688, "NextToken", newJString(NextToken))
  if body != nil:
    body_591689 = body
  result = call_591687.call(nil, query_591688, nil, nil, body_591689)

var listHyperParameterTuningJobs* = Call_ListHyperParameterTuningJobs_591672(
    name: "listHyperParameterTuningJobs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs",
    validator: validate_ListHyperParameterTuningJobs_591673, base: "/",
    url: url_ListHyperParameterTuningJobs_591674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobs_591690 = ref object of OpenApiRestCall_590364
proc url_ListLabelingJobs_591692(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLabelingJobs_591691(path: JsonNode; query: JsonNode;
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
  var valid_591693 = query.getOrDefault("MaxResults")
  valid_591693 = validateParameter(valid_591693, JString, required = false,
                                 default = nil)
  if valid_591693 != nil:
    section.add "MaxResults", valid_591693
  var valid_591694 = query.getOrDefault("NextToken")
  valid_591694 = validateParameter(valid_591694, JString, required = false,
                                 default = nil)
  if valid_591694 != nil:
    section.add "NextToken", valid_591694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591695 = header.getOrDefault("X-Amz-Target")
  valid_591695 = validateParameter(valid_591695, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobs"))
  if valid_591695 != nil:
    section.add "X-Amz-Target", valid_591695
  var valid_591696 = header.getOrDefault("X-Amz-Signature")
  valid_591696 = validateParameter(valid_591696, JString, required = false,
                                 default = nil)
  if valid_591696 != nil:
    section.add "X-Amz-Signature", valid_591696
  var valid_591697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591697 = validateParameter(valid_591697, JString, required = false,
                                 default = nil)
  if valid_591697 != nil:
    section.add "X-Amz-Content-Sha256", valid_591697
  var valid_591698 = header.getOrDefault("X-Amz-Date")
  valid_591698 = validateParameter(valid_591698, JString, required = false,
                                 default = nil)
  if valid_591698 != nil:
    section.add "X-Amz-Date", valid_591698
  var valid_591699 = header.getOrDefault("X-Amz-Credential")
  valid_591699 = validateParameter(valid_591699, JString, required = false,
                                 default = nil)
  if valid_591699 != nil:
    section.add "X-Amz-Credential", valid_591699
  var valid_591700 = header.getOrDefault("X-Amz-Security-Token")
  valid_591700 = validateParameter(valid_591700, JString, required = false,
                                 default = nil)
  if valid_591700 != nil:
    section.add "X-Amz-Security-Token", valid_591700
  var valid_591701 = header.getOrDefault("X-Amz-Algorithm")
  valid_591701 = validateParameter(valid_591701, JString, required = false,
                                 default = nil)
  if valid_591701 != nil:
    section.add "X-Amz-Algorithm", valid_591701
  var valid_591702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591702 = validateParameter(valid_591702, JString, required = false,
                                 default = nil)
  if valid_591702 != nil:
    section.add "X-Amz-SignedHeaders", valid_591702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591704: Call_ListLabelingJobs_591690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs.
  ## 
  let valid = call_591704.validator(path, query, header, formData, body)
  let scheme = call_591704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591704.url(scheme.get, call_591704.host, call_591704.base,
                         call_591704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591704, url, valid)

proc call*(call_591705: Call_ListLabelingJobs_591690; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobs
  ## Gets a list of labeling jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591706 = newJObject()
  var body_591707 = newJObject()
  add(query_591706, "MaxResults", newJString(MaxResults))
  add(query_591706, "NextToken", newJString(NextToken))
  if body != nil:
    body_591707 = body
  result = call_591705.call(nil, query_591706, nil, nil, body_591707)

var listLabelingJobs* = Call_ListLabelingJobs_591690(name: "listLabelingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobs",
    validator: validate_ListLabelingJobs_591691, base: "/",
    url: url_ListLabelingJobs_591692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLabelingJobsForWorkteam_591708 = ref object of OpenApiRestCall_590364
proc url_ListLabelingJobsForWorkteam_591710(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLabelingJobsForWorkteam_591709(path: JsonNode; query: JsonNode;
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
  var valid_591711 = query.getOrDefault("MaxResults")
  valid_591711 = validateParameter(valid_591711, JString, required = false,
                                 default = nil)
  if valid_591711 != nil:
    section.add "MaxResults", valid_591711
  var valid_591712 = query.getOrDefault("NextToken")
  valid_591712 = validateParameter(valid_591712, JString, required = false,
                                 default = nil)
  if valid_591712 != nil:
    section.add "NextToken", valid_591712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591713 = header.getOrDefault("X-Amz-Target")
  valid_591713 = validateParameter(valid_591713, JString, required = true, default = newJString(
      "SageMaker.ListLabelingJobsForWorkteam"))
  if valid_591713 != nil:
    section.add "X-Amz-Target", valid_591713
  var valid_591714 = header.getOrDefault("X-Amz-Signature")
  valid_591714 = validateParameter(valid_591714, JString, required = false,
                                 default = nil)
  if valid_591714 != nil:
    section.add "X-Amz-Signature", valid_591714
  var valid_591715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591715 = validateParameter(valid_591715, JString, required = false,
                                 default = nil)
  if valid_591715 != nil:
    section.add "X-Amz-Content-Sha256", valid_591715
  var valid_591716 = header.getOrDefault("X-Amz-Date")
  valid_591716 = validateParameter(valid_591716, JString, required = false,
                                 default = nil)
  if valid_591716 != nil:
    section.add "X-Amz-Date", valid_591716
  var valid_591717 = header.getOrDefault("X-Amz-Credential")
  valid_591717 = validateParameter(valid_591717, JString, required = false,
                                 default = nil)
  if valid_591717 != nil:
    section.add "X-Amz-Credential", valid_591717
  var valid_591718 = header.getOrDefault("X-Amz-Security-Token")
  valid_591718 = validateParameter(valid_591718, JString, required = false,
                                 default = nil)
  if valid_591718 != nil:
    section.add "X-Amz-Security-Token", valid_591718
  var valid_591719 = header.getOrDefault("X-Amz-Algorithm")
  valid_591719 = validateParameter(valid_591719, JString, required = false,
                                 default = nil)
  if valid_591719 != nil:
    section.add "X-Amz-Algorithm", valid_591719
  var valid_591720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591720 = validateParameter(valid_591720, JString, required = false,
                                 default = nil)
  if valid_591720 != nil:
    section.add "X-Amz-SignedHeaders", valid_591720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591722: Call_ListLabelingJobsForWorkteam_591708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of labeling jobs assigned to a specified work team.
  ## 
  let valid = call_591722.validator(path, query, header, formData, body)
  let scheme = call_591722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591722.url(scheme.get, call_591722.host, call_591722.base,
                         call_591722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591722, url, valid)

proc call*(call_591723: Call_ListLabelingJobsForWorkteam_591708; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLabelingJobsForWorkteam
  ## Gets a list of labeling jobs assigned to a specified work team.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591724 = newJObject()
  var body_591725 = newJObject()
  add(query_591724, "MaxResults", newJString(MaxResults))
  add(query_591724, "NextToken", newJString(NextToken))
  if body != nil:
    body_591725 = body
  result = call_591723.call(nil, query_591724, nil, nil, body_591725)

var listLabelingJobsForWorkteam* = Call_ListLabelingJobsForWorkteam_591708(
    name: "listLabelingJobsForWorkteam", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam",
    validator: validate_ListLabelingJobsForWorkteam_591709, base: "/",
    url: url_ListLabelingJobsForWorkteam_591710,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModelPackages_591726 = ref object of OpenApiRestCall_590364
proc url_ListModelPackages_591728(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListModelPackages_591727(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591729 = header.getOrDefault("X-Amz-Target")
  valid_591729 = validateParameter(valid_591729, JString, required = true, default = newJString(
      "SageMaker.ListModelPackages"))
  if valid_591729 != nil:
    section.add "X-Amz-Target", valid_591729
  var valid_591730 = header.getOrDefault("X-Amz-Signature")
  valid_591730 = validateParameter(valid_591730, JString, required = false,
                                 default = nil)
  if valid_591730 != nil:
    section.add "X-Amz-Signature", valid_591730
  var valid_591731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591731 = validateParameter(valid_591731, JString, required = false,
                                 default = nil)
  if valid_591731 != nil:
    section.add "X-Amz-Content-Sha256", valid_591731
  var valid_591732 = header.getOrDefault("X-Amz-Date")
  valid_591732 = validateParameter(valid_591732, JString, required = false,
                                 default = nil)
  if valid_591732 != nil:
    section.add "X-Amz-Date", valid_591732
  var valid_591733 = header.getOrDefault("X-Amz-Credential")
  valid_591733 = validateParameter(valid_591733, JString, required = false,
                                 default = nil)
  if valid_591733 != nil:
    section.add "X-Amz-Credential", valid_591733
  var valid_591734 = header.getOrDefault("X-Amz-Security-Token")
  valid_591734 = validateParameter(valid_591734, JString, required = false,
                                 default = nil)
  if valid_591734 != nil:
    section.add "X-Amz-Security-Token", valid_591734
  var valid_591735 = header.getOrDefault("X-Amz-Algorithm")
  valid_591735 = validateParameter(valid_591735, JString, required = false,
                                 default = nil)
  if valid_591735 != nil:
    section.add "X-Amz-Algorithm", valid_591735
  var valid_591736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591736 = validateParameter(valid_591736, JString, required = false,
                                 default = nil)
  if valid_591736 != nil:
    section.add "X-Amz-SignedHeaders", valid_591736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591738: Call_ListModelPackages_591726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the model packages that have been created.
  ## 
  let valid = call_591738.validator(path, query, header, formData, body)
  let scheme = call_591738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591738.url(scheme.get, call_591738.host, call_591738.base,
                         call_591738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591738, url, valid)

proc call*(call_591739: Call_ListModelPackages_591726; body: JsonNode): Recallable =
  ## listModelPackages
  ## Lists the model packages that have been created.
  ##   body: JObject (required)
  var body_591740 = newJObject()
  if body != nil:
    body_591740 = body
  result = call_591739.call(nil, nil, nil, nil, body_591740)

var listModelPackages* = Call_ListModelPackages_591726(name: "listModelPackages",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListModelPackages",
    validator: validate_ListModelPackages_591727, base: "/",
    url: url_ListModelPackages_591728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListModels_591741 = ref object of OpenApiRestCall_590364
proc url_ListModels_591743(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListModels_591742(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591744 = query.getOrDefault("MaxResults")
  valid_591744 = validateParameter(valid_591744, JString, required = false,
                                 default = nil)
  if valid_591744 != nil:
    section.add "MaxResults", valid_591744
  var valid_591745 = query.getOrDefault("NextToken")
  valid_591745 = validateParameter(valid_591745, JString, required = false,
                                 default = nil)
  if valid_591745 != nil:
    section.add "NextToken", valid_591745
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591746 = header.getOrDefault("X-Amz-Target")
  valid_591746 = validateParameter(valid_591746, JString, required = true,
                                 default = newJString("SageMaker.ListModels"))
  if valid_591746 != nil:
    section.add "X-Amz-Target", valid_591746
  var valid_591747 = header.getOrDefault("X-Amz-Signature")
  valid_591747 = validateParameter(valid_591747, JString, required = false,
                                 default = nil)
  if valid_591747 != nil:
    section.add "X-Amz-Signature", valid_591747
  var valid_591748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591748 = validateParameter(valid_591748, JString, required = false,
                                 default = nil)
  if valid_591748 != nil:
    section.add "X-Amz-Content-Sha256", valid_591748
  var valid_591749 = header.getOrDefault("X-Amz-Date")
  valid_591749 = validateParameter(valid_591749, JString, required = false,
                                 default = nil)
  if valid_591749 != nil:
    section.add "X-Amz-Date", valid_591749
  var valid_591750 = header.getOrDefault("X-Amz-Credential")
  valid_591750 = validateParameter(valid_591750, JString, required = false,
                                 default = nil)
  if valid_591750 != nil:
    section.add "X-Amz-Credential", valid_591750
  var valid_591751 = header.getOrDefault("X-Amz-Security-Token")
  valid_591751 = validateParameter(valid_591751, JString, required = false,
                                 default = nil)
  if valid_591751 != nil:
    section.add "X-Amz-Security-Token", valid_591751
  var valid_591752 = header.getOrDefault("X-Amz-Algorithm")
  valid_591752 = validateParameter(valid_591752, JString, required = false,
                                 default = nil)
  if valid_591752 != nil:
    section.add "X-Amz-Algorithm", valid_591752
  var valid_591753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591753 = validateParameter(valid_591753, JString, required = false,
                                 default = nil)
  if valid_591753 != nil:
    section.add "X-Amz-SignedHeaders", valid_591753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591755: Call_ListModels_591741; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ## 
  let valid = call_591755.validator(path, query, header, formData, body)
  let scheme = call_591755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591755.url(scheme.get, call_591755.host, call_591755.base,
                         call_591755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591755, url, valid)

proc call*(call_591756: Call_ListModels_591741; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listModels
  ## Lists models created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_CreateModel.html">CreateModel</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591757 = newJObject()
  var body_591758 = newJObject()
  add(query_591757, "MaxResults", newJString(MaxResults))
  add(query_591757, "NextToken", newJString(NextToken))
  if body != nil:
    body_591758 = body
  result = call_591756.call(nil, query_591757, nil, nil, body_591758)

var listModels* = Call_ListModels_591741(name: "listModels",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListModels",
                                      validator: validate_ListModels_591742,
                                      base: "/", url: url_ListModels_591743,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstanceLifecycleConfigs_591759 = ref object of OpenApiRestCall_590364
proc url_ListNotebookInstanceLifecycleConfigs_591761(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNotebookInstanceLifecycleConfigs_591760(path: JsonNode;
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
  var valid_591762 = query.getOrDefault("MaxResults")
  valid_591762 = validateParameter(valid_591762, JString, required = false,
                                 default = nil)
  if valid_591762 != nil:
    section.add "MaxResults", valid_591762
  var valid_591763 = query.getOrDefault("NextToken")
  valid_591763 = validateParameter(valid_591763, JString, required = false,
                                 default = nil)
  if valid_591763 != nil:
    section.add "NextToken", valid_591763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591764 = header.getOrDefault("X-Amz-Target")
  valid_591764 = validateParameter(valid_591764, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstanceLifecycleConfigs"))
  if valid_591764 != nil:
    section.add "X-Amz-Target", valid_591764
  var valid_591765 = header.getOrDefault("X-Amz-Signature")
  valid_591765 = validateParameter(valid_591765, JString, required = false,
                                 default = nil)
  if valid_591765 != nil:
    section.add "X-Amz-Signature", valid_591765
  var valid_591766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591766 = validateParameter(valid_591766, JString, required = false,
                                 default = nil)
  if valid_591766 != nil:
    section.add "X-Amz-Content-Sha256", valid_591766
  var valid_591767 = header.getOrDefault("X-Amz-Date")
  valid_591767 = validateParameter(valid_591767, JString, required = false,
                                 default = nil)
  if valid_591767 != nil:
    section.add "X-Amz-Date", valid_591767
  var valid_591768 = header.getOrDefault("X-Amz-Credential")
  valid_591768 = validateParameter(valid_591768, JString, required = false,
                                 default = nil)
  if valid_591768 != nil:
    section.add "X-Amz-Credential", valid_591768
  var valid_591769 = header.getOrDefault("X-Amz-Security-Token")
  valid_591769 = validateParameter(valid_591769, JString, required = false,
                                 default = nil)
  if valid_591769 != nil:
    section.add "X-Amz-Security-Token", valid_591769
  var valid_591770 = header.getOrDefault("X-Amz-Algorithm")
  valid_591770 = validateParameter(valid_591770, JString, required = false,
                                 default = nil)
  if valid_591770 != nil:
    section.add "X-Amz-Algorithm", valid_591770
  var valid_591771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591771 = validateParameter(valid_591771, JString, required = false,
                                 default = nil)
  if valid_591771 != nil:
    section.add "X-Amz-SignedHeaders", valid_591771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591773: Call_ListNotebookInstanceLifecycleConfigs_591759;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_591773.validator(path, query, header, formData, body)
  let scheme = call_591773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591773.url(scheme.get, call_591773.host, call_591773.base,
                         call_591773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591773, url, valid)

proc call*(call_591774: Call_ListNotebookInstanceLifecycleConfigs_591759;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstanceLifecycleConfigs
  ## Lists notebook instance lifestyle configurations created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591775 = newJObject()
  var body_591776 = newJObject()
  add(query_591775, "MaxResults", newJString(MaxResults))
  add(query_591775, "NextToken", newJString(NextToken))
  if body != nil:
    body_591776 = body
  result = call_591774.call(nil, query_591775, nil, nil, body_591776)

var listNotebookInstanceLifecycleConfigs* = Call_ListNotebookInstanceLifecycleConfigs_591759(
    name: "listNotebookInstanceLifecycleConfigs", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs",
    validator: validate_ListNotebookInstanceLifecycleConfigs_591760, base: "/",
    url: url_ListNotebookInstanceLifecycleConfigs_591761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNotebookInstances_591777 = ref object of OpenApiRestCall_590364
proc url_ListNotebookInstances_591779(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListNotebookInstances_591778(path: JsonNode; query: JsonNode;
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
  var valid_591780 = query.getOrDefault("MaxResults")
  valid_591780 = validateParameter(valid_591780, JString, required = false,
                                 default = nil)
  if valid_591780 != nil:
    section.add "MaxResults", valid_591780
  var valid_591781 = query.getOrDefault("NextToken")
  valid_591781 = validateParameter(valid_591781, JString, required = false,
                                 default = nil)
  if valid_591781 != nil:
    section.add "NextToken", valid_591781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591782 = header.getOrDefault("X-Amz-Target")
  valid_591782 = validateParameter(valid_591782, JString, required = true, default = newJString(
      "SageMaker.ListNotebookInstances"))
  if valid_591782 != nil:
    section.add "X-Amz-Target", valid_591782
  var valid_591783 = header.getOrDefault("X-Amz-Signature")
  valid_591783 = validateParameter(valid_591783, JString, required = false,
                                 default = nil)
  if valid_591783 != nil:
    section.add "X-Amz-Signature", valid_591783
  var valid_591784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591784 = validateParameter(valid_591784, JString, required = false,
                                 default = nil)
  if valid_591784 != nil:
    section.add "X-Amz-Content-Sha256", valid_591784
  var valid_591785 = header.getOrDefault("X-Amz-Date")
  valid_591785 = validateParameter(valid_591785, JString, required = false,
                                 default = nil)
  if valid_591785 != nil:
    section.add "X-Amz-Date", valid_591785
  var valid_591786 = header.getOrDefault("X-Amz-Credential")
  valid_591786 = validateParameter(valid_591786, JString, required = false,
                                 default = nil)
  if valid_591786 != nil:
    section.add "X-Amz-Credential", valid_591786
  var valid_591787 = header.getOrDefault("X-Amz-Security-Token")
  valid_591787 = validateParameter(valid_591787, JString, required = false,
                                 default = nil)
  if valid_591787 != nil:
    section.add "X-Amz-Security-Token", valid_591787
  var valid_591788 = header.getOrDefault("X-Amz-Algorithm")
  valid_591788 = validateParameter(valid_591788, JString, required = false,
                                 default = nil)
  if valid_591788 != nil:
    section.add "X-Amz-Algorithm", valid_591788
  var valid_591789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591789 = validateParameter(valid_591789, JString, required = false,
                                 default = nil)
  if valid_591789 != nil:
    section.add "X-Amz-SignedHeaders", valid_591789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591791: Call_ListNotebookInstances_591777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ## 
  let valid = call_591791.validator(path, query, header, formData, body)
  let scheme = call_591791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591791.url(scheme.get, call_591791.host, call_591791.base,
                         call_591791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591791, url, valid)

proc call*(call_591792: Call_ListNotebookInstances_591777; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listNotebookInstances
  ## Returns a list of the Amazon SageMaker notebook instances in the requester's account in an AWS Region. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591793 = newJObject()
  var body_591794 = newJObject()
  add(query_591793, "MaxResults", newJString(MaxResults))
  add(query_591793, "NextToken", newJString(NextToken))
  if body != nil:
    body_591794 = body
  result = call_591792.call(nil, query_591793, nil, nil, body_591794)

var listNotebookInstances* = Call_ListNotebookInstances_591777(
    name: "listNotebookInstances", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListNotebookInstances",
    validator: validate_ListNotebookInstances_591778, base: "/",
    url: url_ListNotebookInstances_591779, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedWorkteams_591795 = ref object of OpenApiRestCall_590364
proc url_ListSubscribedWorkteams_591797(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscribedWorkteams_591796(path: JsonNode; query: JsonNode;
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
  var valid_591798 = query.getOrDefault("MaxResults")
  valid_591798 = validateParameter(valid_591798, JString, required = false,
                                 default = nil)
  if valid_591798 != nil:
    section.add "MaxResults", valid_591798
  var valid_591799 = query.getOrDefault("NextToken")
  valid_591799 = validateParameter(valid_591799, JString, required = false,
                                 default = nil)
  if valid_591799 != nil:
    section.add "NextToken", valid_591799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591800 = header.getOrDefault("X-Amz-Target")
  valid_591800 = validateParameter(valid_591800, JString, required = true, default = newJString(
      "SageMaker.ListSubscribedWorkteams"))
  if valid_591800 != nil:
    section.add "X-Amz-Target", valid_591800
  var valid_591801 = header.getOrDefault("X-Amz-Signature")
  valid_591801 = validateParameter(valid_591801, JString, required = false,
                                 default = nil)
  if valid_591801 != nil:
    section.add "X-Amz-Signature", valid_591801
  var valid_591802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591802 = validateParameter(valid_591802, JString, required = false,
                                 default = nil)
  if valid_591802 != nil:
    section.add "X-Amz-Content-Sha256", valid_591802
  var valid_591803 = header.getOrDefault("X-Amz-Date")
  valid_591803 = validateParameter(valid_591803, JString, required = false,
                                 default = nil)
  if valid_591803 != nil:
    section.add "X-Amz-Date", valid_591803
  var valid_591804 = header.getOrDefault("X-Amz-Credential")
  valid_591804 = validateParameter(valid_591804, JString, required = false,
                                 default = nil)
  if valid_591804 != nil:
    section.add "X-Amz-Credential", valid_591804
  var valid_591805 = header.getOrDefault("X-Amz-Security-Token")
  valid_591805 = validateParameter(valid_591805, JString, required = false,
                                 default = nil)
  if valid_591805 != nil:
    section.add "X-Amz-Security-Token", valid_591805
  var valid_591806 = header.getOrDefault("X-Amz-Algorithm")
  valid_591806 = validateParameter(valid_591806, JString, required = false,
                                 default = nil)
  if valid_591806 != nil:
    section.add "X-Amz-Algorithm", valid_591806
  var valid_591807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591807 = validateParameter(valid_591807, JString, required = false,
                                 default = nil)
  if valid_591807 != nil:
    section.add "X-Amz-SignedHeaders", valid_591807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591809: Call_ListSubscribedWorkteams_591795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_591809.validator(path, query, header, formData, body)
  let scheme = call_591809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591809.url(scheme.get, call_591809.host, call_591809.base,
                         call_591809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591809, url, valid)

proc call*(call_591810: Call_ListSubscribedWorkteams_591795; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listSubscribedWorkteams
  ## Gets a list of the work teams that you are subscribed to in the AWS Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591811 = newJObject()
  var body_591812 = newJObject()
  add(query_591811, "MaxResults", newJString(MaxResults))
  add(query_591811, "NextToken", newJString(NextToken))
  if body != nil:
    body_591812 = body
  result = call_591810.call(nil, query_591811, nil, nil, body_591812)

var listSubscribedWorkteams* = Call_ListSubscribedWorkteams_591795(
    name: "listSubscribedWorkteams", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams",
    validator: validate_ListSubscribedWorkteams_591796, base: "/",
    url: url_ListSubscribedWorkteams_591797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_591813 = ref object of OpenApiRestCall_590364
proc url_ListTags_591815(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTags_591814(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591816 = query.getOrDefault("MaxResults")
  valid_591816 = validateParameter(valid_591816, JString, required = false,
                                 default = nil)
  if valid_591816 != nil:
    section.add "MaxResults", valid_591816
  var valid_591817 = query.getOrDefault("NextToken")
  valid_591817 = validateParameter(valid_591817, JString, required = false,
                                 default = nil)
  if valid_591817 != nil:
    section.add "NextToken", valid_591817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591818 = header.getOrDefault("X-Amz-Target")
  valid_591818 = validateParameter(valid_591818, JString, required = true,
                                 default = newJString("SageMaker.ListTags"))
  if valid_591818 != nil:
    section.add "X-Amz-Target", valid_591818
  var valid_591819 = header.getOrDefault("X-Amz-Signature")
  valid_591819 = validateParameter(valid_591819, JString, required = false,
                                 default = nil)
  if valid_591819 != nil:
    section.add "X-Amz-Signature", valid_591819
  var valid_591820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591820 = validateParameter(valid_591820, JString, required = false,
                                 default = nil)
  if valid_591820 != nil:
    section.add "X-Amz-Content-Sha256", valid_591820
  var valid_591821 = header.getOrDefault("X-Amz-Date")
  valid_591821 = validateParameter(valid_591821, JString, required = false,
                                 default = nil)
  if valid_591821 != nil:
    section.add "X-Amz-Date", valid_591821
  var valid_591822 = header.getOrDefault("X-Amz-Credential")
  valid_591822 = validateParameter(valid_591822, JString, required = false,
                                 default = nil)
  if valid_591822 != nil:
    section.add "X-Amz-Credential", valid_591822
  var valid_591823 = header.getOrDefault("X-Amz-Security-Token")
  valid_591823 = validateParameter(valid_591823, JString, required = false,
                                 default = nil)
  if valid_591823 != nil:
    section.add "X-Amz-Security-Token", valid_591823
  var valid_591824 = header.getOrDefault("X-Amz-Algorithm")
  valid_591824 = validateParameter(valid_591824, JString, required = false,
                                 default = nil)
  if valid_591824 != nil:
    section.add "X-Amz-Algorithm", valid_591824
  var valid_591825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591825 = validateParameter(valid_591825, JString, required = false,
                                 default = nil)
  if valid_591825 != nil:
    section.add "X-Amz-SignedHeaders", valid_591825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591827: Call_ListTags_591813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the tags for the specified Amazon SageMaker resource.
  ## 
  let valid = call_591827.validator(path, query, header, formData, body)
  let scheme = call_591827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591827.url(scheme.get, call_591827.host, call_591827.base,
                         call_591827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591827, url, valid)

proc call*(call_591828: Call_ListTags_591813; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTags
  ## Returns the tags for the specified Amazon SageMaker resource.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591829 = newJObject()
  var body_591830 = newJObject()
  add(query_591829, "MaxResults", newJString(MaxResults))
  add(query_591829, "NextToken", newJString(NextToken))
  if body != nil:
    body_591830 = body
  result = call_591828.call(nil, query_591829, nil, nil, body_591830)

var listTags* = Call_ListTags_591813(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "api.sagemaker.amazonaws.com",
                                  route: "/#X-Amz-Target=SageMaker.ListTags",
                                  validator: validate_ListTags_591814, base: "/",
                                  url: url_ListTags_591815,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobs_591831 = ref object of OpenApiRestCall_590364
proc url_ListTrainingJobs_591833(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrainingJobs_591832(path: JsonNode; query: JsonNode;
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
  var valid_591834 = query.getOrDefault("MaxResults")
  valid_591834 = validateParameter(valid_591834, JString, required = false,
                                 default = nil)
  if valid_591834 != nil:
    section.add "MaxResults", valid_591834
  var valid_591835 = query.getOrDefault("NextToken")
  valid_591835 = validateParameter(valid_591835, JString, required = false,
                                 default = nil)
  if valid_591835 != nil:
    section.add "NextToken", valid_591835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591836 = header.getOrDefault("X-Amz-Target")
  valid_591836 = validateParameter(valid_591836, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobs"))
  if valid_591836 != nil:
    section.add "X-Amz-Target", valid_591836
  var valid_591837 = header.getOrDefault("X-Amz-Signature")
  valid_591837 = validateParameter(valid_591837, JString, required = false,
                                 default = nil)
  if valid_591837 != nil:
    section.add "X-Amz-Signature", valid_591837
  var valid_591838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591838 = validateParameter(valid_591838, JString, required = false,
                                 default = nil)
  if valid_591838 != nil:
    section.add "X-Amz-Content-Sha256", valid_591838
  var valid_591839 = header.getOrDefault("X-Amz-Date")
  valid_591839 = validateParameter(valid_591839, JString, required = false,
                                 default = nil)
  if valid_591839 != nil:
    section.add "X-Amz-Date", valid_591839
  var valid_591840 = header.getOrDefault("X-Amz-Credential")
  valid_591840 = validateParameter(valid_591840, JString, required = false,
                                 default = nil)
  if valid_591840 != nil:
    section.add "X-Amz-Credential", valid_591840
  var valid_591841 = header.getOrDefault("X-Amz-Security-Token")
  valid_591841 = validateParameter(valid_591841, JString, required = false,
                                 default = nil)
  if valid_591841 != nil:
    section.add "X-Amz-Security-Token", valid_591841
  var valid_591842 = header.getOrDefault("X-Amz-Algorithm")
  valid_591842 = validateParameter(valid_591842, JString, required = false,
                                 default = nil)
  if valid_591842 != nil:
    section.add "X-Amz-Algorithm", valid_591842
  var valid_591843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591843 = validateParameter(valid_591843, JString, required = false,
                                 default = nil)
  if valid_591843 != nil:
    section.add "X-Amz-SignedHeaders", valid_591843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591845: Call_ListTrainingJobs_591831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists training jobs.
  ## 
  let valid = call_591845.validator(path, query, header, formData, body)
  let scheme = call_591845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591845.url(scheme.get, call_591845.host, call_591845.base,
                         call_591845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591845, url, valid)

proc call*(call_591846: Call_ListTrainingJobs_591831; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobs
  ## Lists training jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591847 = newJObject()
  var body_591848 = newJObject()
  add(query_591847, "MaxResults", newJString(MaxResults))
  add(query_591847, "NextToken", newJString(NextToken))
  if body != nil:
    body_591848 = body
  result = call_591846.call(nil, query_591847, nil, nil, body_591848)

var listTrainingJobs* = Call_ListTrainingJobs_591831(name: "listTrainingJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTrainingJobs",
    validator: validate_ListTrainingJobs_591832, base: "/",
    url: url_ListTrainingJobs_591833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrainingJobsForHyperParameterTuningJob_591849 = ref object of OpenApiRestCall_590364
proc url_ListTrainingJobsForHyperParameterTuningJob_591851(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTrainingJobsForHyperParameterTuningJob_591850(path: JsonNode;
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
  var valid_591852 = query.getOrDefault("MaxResults")
  valid_591852 = validateParameter(valid_591852, JString, required = false,
                                 default = nil)
  if valid_591852 != nil:
    section.add "MaxResults", valid_591852
  var valid_591853 = query.getOrDefault("NextToken")
  valid_591853 = validateParameter(valid_591853, JString, required = false,
                                 default = nil)
  if valid_591853 != nil:
    section.add "NextToken", valid_591853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591854 = header.getOrDefault("X-Amz-Target")
  valid_591854 = validateParameter(valid_591854, JString, required = true, default = newJString(
      "SageMaker.ListTrainingJobsForHyperParameterTuningJob"))
  if valid_591854 != nil:
    section.add "X-Amz-Target", valid_591854
  var valid_591855 = header.getOrDefault("X-Amz-Signature")
  valid_591855 = validateParameter(valid_591855, JString, required = false,
                                 default = nil)
  if valid_591855 != nil:
    section.add "X-Amz-Signature", valid_591855
  var valid_591856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591856 = validateParameter(valid_591856, JString, required = false,
                                 default = nil)
  if valid_591856 != nil:
    section.add "X-Amz-Content-Sha256", valid_591856
  var valid_591857 = header.getOrDefault("X-Amz-Date")
  valid_591857 = validateParameter(valid_591857, JString, required = false,
                                 default = nil)
  if valid_591857 != nil:
    section.add "X-Amz-Date", valid_591857
  var valid_591858 = header.getOrDefault("X-Amz-Credential")
  valid_591858 = validateParameter(valid_591858, JString, required = false,
                                 default = nil)
  if valid_591858 != nil:
    section.add "X-Amz-Credential", valid_591858
  var valid_591859 = header.getOrDefault("X-Amz-Security-Token")
  valid_591859 = validateParameter(valid_591859, JString, required = false,
                                 default = nil)
  if valid_591859 != nil:
    section.add "X-Amz-Security-Token", valid_591859
  var valid_591860 = header.getOrDefault("X-Amz-Algorithm")
  valid_591860 = validateParameter(valid_591860, JString, required = false,
                                 default = nil)
  if valid_591860 != nil:
    section.add "X-Amz-Algorithm", valid_591860
  var valid_591861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591861 = validateParameter(valid_591861, JString, required = false,
                                 default = nil)
  if valid_591861 != nil:
    section.add "X-Amz-SignedHeaders", valid_591861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591863: Call_ListTrainingJobsForHyperParameterTuningJob_591849;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ## 
  let valid = call_591863.validator(path, query, header, formData, body)
  let scheme = call_591863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591863.url(scheme.get, call_591863.host, call_591863.base,
                         call_591863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591863, url, valid)

proc call*(call_591864: Call_ListTrainingJobsForHyperParameterTuningJob_591849;
          body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTrainingJobsForHyperParameterTuningJob
  ## Gets a list of <a>TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591865 = newJObject()
  var body_591866 = newJObject()
  add(query_591865, "MaxResults", newJString(MaxResults))
  add(query_591865, "NextToken", newJString(NextToken))
  if body != nil:
    body_591866 = body
  result = call_591864.call(nil, query_591865, nil, nil, body_591866)

var listTrainingJobsForHyperParameterTuningJob* = Call_ListTrainingJobsForHyperParameterTuningJob_591849(
    name: "listTrainingJobsForHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com", route: "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob",
    validator: validate_ListTrainingJobsForHyperParameterTuningJob_591850,
    base: "/", url: url_ListTrainingJobsForHyperParameterTuningJob_591851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTransformJobs_591867 = ref object of OpenApiRestCall_590364
proc url_ListTransformJobs_591869(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTransformJobs_591868(path: JsonNode; query: JsonNode;
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
  var valid_591870 = query.getOrDefault("MaxResults")
  valid_591870 = validateParameter(valid_591870, JString, required = false,
                                 default = nil)
  if valid_591870 != nil:
    section.add "MaxResults", valid_591870
  var valid_591871 = query.getOrDefault("NextToken")
  valid_591871 = validateParameter(valid_591871, JString, required = false,
                                 default = nil)
  if valid_591871 != nil:
    section.add "NextToken", valid_591871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591872 = header.getOrDefault("X-Amz-Target")
  valid_591872 = validateParameter(valid_591872, JString, required = true, default = newJString(
      "SageMaker.ListTransformJobs"))
  if valid_591872 != nil:
    section.add "X-Amz-Target", valid_591872
  var valid_591873 = header.getOrDefault("X-Amz-Signature")
  valid_591873 = validateParameter(valid_591873, JString, required = false,
                                 default = nil)
  if valid_591873 != nil:
    section.add "X-Amz-Signature", valid_591873
  var valid_591874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591874 = validateParameter(valid_591874, JString, required = false,
                                 default = nil)
  if valid_591874 != nil:
    section.add "X-Amz-Content-Sha256", valid_591874
  var valid_591875 = header.getOrDefault("X-Amz-Date")
  valid_591875 = validateParameter(valid_591875, JString, required = false,
                                 default = nil)
  if valid_591875 != nil:
    section.add "X-Amz-Date", valid_591875
  var valid_591876 = header.getOrDefault("X-Amz-Credential")
  valid_591876 = validateParameter(valid_591876, JString, required = false,
                                 default = nil)
  if valid_591876 != nil:
    section.add "X-Amz-Credential", valid_591876
  var valid_591877 = header.getOrDefault("X-Amz-Security-Token")
  valid_591877 = validateParameter(valid_591877, JString, required = false,
                                 default = nil)
  if valid_591877 != nil:
    section.add "X-Amz-Security-Token", valid_591877
  var valid_591878 = header.getOrDefault("X-Amz-Algorithm")
  valid_591878 = validateParameter(valid_591878, JString, required = false,
                                 default = nil)
  if valid_591878 != nil:
    section.add "X-Amz-Algorithm", valid_591878
  var valid_591879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591879 = validateParameter(valid_591879, JString, required = false,
                                 default = nil)
  if valid_591879 != nil:
    section.add "X-Amz-SignedHeaders", valid_591879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591881: Call_ListTransformJobs_591867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists transform jobs.
  ## 
  let valid = call_591881.validator(path, query, header, formData, body)
  let scheme = call_591881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591881.url(scheme.get, call_591881.host, call_591881.base,
                         call_591881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591881, url, valid)

proc call*(call_591882: Call_ListTransformJobs_591867; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTransformJobs
  ## Lists transform jobs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591883 = newJObject()
  var body_591884 = newJObject()
  add(query_591883, "MaxResults", newJString(MaxResults))
  add(query_591883, "NextToken", newJString(NextToken))
  if body != nil:
    body_591884 = body
  result = call_591882.call(nil, query_591883, nil, nil, body_591884)

var listTransformJobs* = Call_ListTransformJobs_591867(name: "listTransformJobs",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListTransformJobs",
    validator: validate_ListTransformJobs_591868, base: "/",
    url: url_ListTransformJobs_591869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkteams_591885 = ref object of OpenApiRestCall_590364
proc url_ListWorkteams_591887(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWorkteams_591886(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591888 = query.getOrDefault("MaxResults")
  valid_591888 = validateParameter(valid_591888, JString, required = false,
                                 default = nil)
  if valid_591888 != nil:
    section.add "MaxResults", valid_591888
  var valid_591889 = query.getOrDefault("NextToken")
  valid_591889 = validateParameter(valid_591889, JString, required = false,
                                 default = nil)
  if valid_591889 != nil:
    section.add "NextToken", valid_591889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591890 = header.getOrDefault("X-Amz-Target")
  valid_591890 = validateParameter(valid_591890, JString, required = true, default = newJString(
      "SageMaker.ListWorkteams"))
  if valid_591890 != nil:
    section.add "X-Amz-Target", valid_591890
  var valid_591891 = header.getOrDefault("X-Amz-Signature")
  valid_591891 = validateParameter(valid_591891, JString, required = false,
                                 default = nil)
  if valid_591891 != nil:
    section.add "X-Amz-Signature", valid_591891
  var valid_591892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591892 = validateParameter(valid_591892, JString, required = false,
                                 default = nil)
  if valid_591892 != nil:
    section.add "X-Amz-Content-Sha256", valid_591892
  var valid_591893 = header.getOrDefault("X-Amz-Date")
  valid_591893 = validateParameter(valid_591893, JString, required = false,
                                 default = nil)
  if valid_591893 != nil:
    section.add "X-Amz-Date", valid_591893
  var valid_591894 = header.getOrDefault("X-Amz-Credential")
  valid_591894 = validateParameter(valid_591894, JString, required = false,
                                 default = nil)
  if valid_591894 != nil:
    section.add "X-Amz-Credential", valid_591894
  var valid_591895 = header.getOrDefault("X-Amz-Security-Token")
  valid_591895 = validateParameter(valid_591895, JString, required = false,
                                 default = nil)
  if valid_591895 != nil:
    section.add "X-Amz-Security-Token", valid_591895
  var valid_591896 = header.getOrDefault("X-Amz-Algorithm")
  valid_591896 = validateParameter(valid_591896, JString, required = false,
                                 default = nil)
  if valid_591896 != nil:
    section.add "X-Amz-Algorithm", valid_591896
  var valid_591897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591897 = validateParameter(valid_591897, JString, required = false,
                                 default = nil)
  if valid_591897 != nil:
    section.add "X-Amz-SignedHeaders", valid_591897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591899: Call_ListWorkteams_591885; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ## 
  let valid = call_591899.validator(path, query, header, formData, body)
  let scheme = call_591899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591899.url(scheme.get, call_591899.host, call_591899.base,
                         call_591899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591899, url, valid)

proc call*(call_591900: Call_ListWorkteams_591885; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkteams
  ## Gets a list of work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591901 = newJObject()
  var body_591902 = newJObject()
  add(query_591901, "MaxResults", newJString(MaxResults))
  add(query_591901, "NextToken", newJString(NextToken))
  if body != nil:
    body_591902 = body
  result = call_591900.call(nil, query_591901, nil, nil, body_591902)

var listWorkteams* = Call_ListWorkteams_591885(name: "listWorkteams",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.ListWorkteams",
    validator: validate_ListWorkteams_591886, base: "/", url: url_ListWorkteams_591887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RenderUiTemplate_591903 = ref object of OpenApiRestCall_590364
proc url_RenderUiTemplate_591905(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RenderUiTemplate_591904(path: JsonNode; query: JsonNode;
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
  var valid_591906 = header.getOrDefault("X-Amz-Target")
  valid_591906 = validateParameter(valid_591906, JString, required = true, default = newJString(
      "SageMaker.RenderUiTemplate"))
  if valid_591906 != nil:
    section.add "X-Amz-Target", valid_591906
  var valid_591907 = header.getOrDefault("X-Amz-Signature")
  valid_591907 = validateParameter(valid_591907, JString, required = false,
                                 default = nil)
  if valid_591907 != nil:
    section.add "X-Amz-Signature", valid_591907
  var valid_591908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591908 = validateParameter(valid_591908, JString, required = false,
                                 default = nil)
  if valid_591908 != nil:
    section.add "X-Amz-Content-Sha256", valid_591908
  var valid_591909 = header.getOrDefault("X-Amz-Date")
  valid_591909 = validateParameter(valid_591909, JString, required = false,
                                 default = nil)
  if valid_591909 != nil:
    section.add "X-Amz-Date", valid_591909
  var valid_591910 = header.getOrDefault("X-Amz-Credential")
  valid_591910 = validateParameter(valid_591910, JString, required = false,
                                 default = nil)
  if valid_591910 != nil:
    section.add "X-Amz-Credential", valid_591910
  var valid_591911 = header.getOrDefault("X-Amz-Security-Token")
  valid_591911 = validateParameter(valid_591911, JString, required = false,
                                 default = nil)
  if valid_591911 != nil:
    section.add "X-Amz-Security-Token", valid_591911
  var valid_591912 = header.getOrDefault("X-Amz-Algorithm")
  valid_591912 = validateParameter(valid_591912, JString, required = false,
                                 default = nil)
  if valid_591912 != nil:
    section.add "X-Amz-Algorithm", valid_591912
  var valid_591913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591913 = validateParameter(valid_591913, JString, required = false,
                                 default = nil)
  if valid_591913 != nil:
    section.add "X-Amz-SignedHeaders", valid_591913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591915: Call_RenderUiTemplate_591903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renders the UI template so that you can preview the worker's experience. 
  ## 
  let valid = call_591915.validator(path, query, header, formData, body)
  let scheme = call_591915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591915.url(scheme.get, call_591915.host, call_591915.base,
                         call_591915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591915, url, valid)

proc call*(call_591916: Call_RenderUiTemplate_591903; body: JsonNode): Recallable =
  ## renderUiTemplate
  ## Renders the UI template so that you can preview the worker's experience. 
  ##   body: JObject (required)
  var body_591917 = newJObject()
  if body != nil:
    body_591917 = body
  result = call_591916.call(nil, nil, nil, nil, body_591917)

var renderUiTemplate* = Call_RenderUiTemplate_591903(name: "renderUiTemplate",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.RenderUiTemplate",
    validator: validate_RenderUiTemplate_591904, base: "/",
    url: url_RenderUiTemplate_591905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Search_591918 = ref object of OpenApiRestCall_590364
proc url_Search_591920(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Search_591919(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591921 = query.getOrDefault("MaxResults")
  valid_591921 = validateParameter(valid_591921, JString, required = false,
                                 default = nil)
  if valid_591921 != nil:
    section.add "MaxResults", valid_591921
  var valid_591922 = query.getOrDefault("NextToken")
  valid_591922 = validateParameter(valid_591922, JString, required = false,
                                 default = nil)
  if valid_591922 != nil:
    section.add "NextToken", valid_591922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591923 = header.getOrDefault("X-Amz-Target")
  valid_591923 = validateParameter(valid_591923, JString, required = true,
                                 default = newJString("SageMaker.Search"))
  if valid_591923 != nil:
    section.add "X-Amz-Target", valid_591923
  var valid_591924 = header.getOrDefault("X-Amz-Signature")
  valid_591924 = validateParameter(valid_591924, JString, required = false,
                                 default = nil)
  if valid_591924 != nil:
    section.add "X-Amz-Signature", valid_591924
  var valid_591925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591925 = validateParameter(valid_591925, JString, required = false,
                                 default = nil)
  if valid_591925 != nil:
    section.add "X-Amz-Content-Sha256", valid_591925
  var valid_591926 = header.getOrDefault("X-Amz-Date")
  valid_591926 = validateParameter(valid_591926, JString, required = false,
                                 default = nil)
  if valid_591926 != nil:
    section.add "X-Amz-Date", valid_591926
  var valid_591927 = header.getOrDefault("X-Amz-Credential")
  valid_591927 = validateParameter(valid_591927, JString, required = false,
                                 default = nil)
  if valid_591927 != nil:
    section.add "X-Amz-Credential", valid_591927
  var valid_591928 = header.getOrDefault("X-Amz-Security-Token")
  valid_591928 = validateParameter(valid_591928, JString, required = false,
                                 default = nil)
  if valid_591928 != nil:
    section.add "X-Amz-Security-Token", valid_591928
  var valid_591929 = header.getOrDefault("X-Amz-Algorithm")
  valid_591929 = validateParameter(valid_591929, JString, required = false,
                                 default = nil)
  if valid_591929 != nil:
    section.add "X-Amz-Algorithm", valid_591929
  var valid_591930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591930 = validateParameter(valid_591930, JString, required = false,
                                 default = nil)
  if valid_591930 != nil:
    section.add "X-Amz-SignedHeaders", valid_591930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591932: Call_Search_591918; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ## 
  let valid = call_591932.validator(path, query, header, formData, body)
  let scheme = call_591932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591932.url(scheme.get, call_591932.host, call_591932.base,
                         call_591932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591932, url, valid)

proc call*(call_591933: Call_Search_591918; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## search
  ## <p>Finds Amazon SageMaker resources that match a search query. Matching resource objects are returned as a list of <code>SearchResult</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numerical, text, Booleans, and timestamps.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591934 = newJObject()
  var body_591935 = newJObject()
  add(query_591934, "MaxResults", newJString(MaxResults))
  add(query_591934, "NextToken", newJString(NextToken))
  if body != nil:
    body_591935 = body
  result = call_591933.call(nil, query_591934, nil, nil, body_591935)

var search* = Call_Search_591918(name: "search", meth: HttpMethod.HttpPost,
                              host: "api.sagemaker.amazonaws.com",
                              route: "/#X-Amz-Target=SageMaker.Search",
                              validator: validate_Search_591919, base: "/",
                              url: url_Search_591920,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartNotebookInstance_591936 = ref object of OpenApiRestCall_590364
proc url_StartNotebookInstance_591938(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartNotebookInstance_591937(path: JsonNode; query: JsonNode;
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
  var valid_591939 = header.getOrDefault("X-Amz-Target")
  valid_591939 = validateParameter(valid_591939, JString, required = true, default = newJString(
      "SageMaker.StartNotebookInstance"))
  if valid_591939 != nil:
    section.add "X-Amz-Target", valid_591939
  var valid_591940 = header.getOrDefault("X-Amz-Signature")
  valid_591940 = validateParameter(valid_591940, JString, required = false,
                                 default = nil)
  if valid_591940 != nil:
    section.add "X-Amz-Signature", valid_591940
  var valid_591941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591941 = validateParameter(valid_591941, JString, required = false,
                                 default = nil)
  if valid_591941 != nil:
    section.add "X-Amz-Content-Sha256", valid_591941
  var valid_591942 = header.getOrDefault("X-Amz-Date")
  valid_591942 = validateParameter(valid_591942, JString, required = false,
                                 default = nil)
  if valid_591942 != nil:
    section.add "X-Amz-Date", valid_591942
  var valid_591943 = header.getOrDefault("X-Amz-Credential")
  valid_591943 = validateParameter(valid_591943, JString, required = false,
                                 default = nil)
  if valid_591943 != nil:
    section.add "X-Amz-Credential", valid_591943
  var valid_591944 = header.getOrDefault("X-Amz-Security-Token")
  valid_591944 = validateParameter(valid_591944, JString, required = false,
                                 default = nil)
  if valid_591944 != nil:
    section.add "X-Amz-Security-Token", valid_591944
  var valid_591945 = header.getOrDefault("X-Amz-Algorithm")
  valid_591945 = validateParameter(valid_591945, JString, required = false,
                                 default = nil)
  if valid_591945 != nil:
    section.add "X-Amz-Algorithm", valid_591945
  var valid_591946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591946 = validateParameter(valid_591946, JString, required = false,
                                 default = nil)
  if valid_591946 != nil:
    section.add "X-Amz-SignedHeaders", valid_591946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591948: Call_StartNotebookInstance_591936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ## 
  let valid = call_591948.validator(path, query, header, formData, body)
  let scheme = call_591948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591948.url(scheme.get, call_591948.host, call_591948.base,
                         call_591948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591948, url, valid)

proc call*(call_591949: Call_StartNotebookInstance_591936; body: JsonNode): Recallable =
  ## startNotebookInstance
  ## Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, Amazon SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
  ##   body: JObject (required)
  var body_591950 = newJObject()
  if body != nil:
    body_591950 = body
  result = call_591949.call(nil, nil, nil, nil, body_591950)

var startNotebookInstance* = Call_StartNotebookInstance_591936(
    name: "startNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StartNotebookInstance",
    validator: validate_StartNotebookInstance_591937, base: "/",
    url: url_StartNotebookInstance_591938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCompilationJob_591951 = ref object of OpenApiRestCall_590364
proc url_StopCompilationJob_591953(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopCompilationJob_591952(path: JsonNode; query: JsonNode;
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
  var valid_591954 = header.getOrDefault("X-Amz-Target")
  valid_591954 = validateParameter(valid_591954, JString, required = true, default = newJString(
      "SageMaker.StopCompilationJob"))
  if valid_591954 != nil:
    section.add "X-Amz-Target", valid_591954
  var valid_591955 = header.getOrDefault("X-Amz-Signature")
  valid_591955 = validateParameter(valid_591955, JString, required = false,
                                 default = nil)
  if valid_591955 != nil:
    section.add "X-Amz-Signature", valid_591955
  var valid_591956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591956 = validateParameter(valid_591956, JString, required = false,
                                 default = nil)
  if valid_591956 != nil:
    section.add "X-Amz-Content-Sha256", valid_591956
  var valid_591957 = header.getOrDefault("X-Amz-Date")
  valid_591957 = validateParameter(valid_591957, JString, required = false,
                                 default = nil)
  if valid_591957 != nil:
    section.add "X-Amz-Date", valid_591957
  var valid_591958 = header.getOrDefault("X-Amz-Credential")
  valid_591958 = validateParameter(valid_591958, JString, required = false,
                                 default = nil)
  if valid_591958 != nil:
    section.add "X-Amz-Credential", valid_591958
  var valid_591959 = header.getOrDefault("X-Amz-Security-Token")
  valid_591959 = validateParameter(valid_591959, JString, required = false,
                                 default = nil)
  if valid_591959 != nil:
    section.add "X-Amz-Security-Token", valid_591959
  var valid_591960 = header.getOrDefault("X-Amz-Algorithm")
  valid_591960 = validateParameter(valid_591960, JString, required = false,
                                 default = nil)
  if valid_591960 != nil:
    section.add "X-Amz-Algorithm", valid_591960
  var valid_591961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591961 = validateParameter(valid_591961, JString, required = false,
                                 default = nil)
  if valid_591961 != nil:
    section.add "X-Amz-SignedHeaders", valid_591961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591963: Call_StopCompilationJob_591951; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ## 
  let valid = call_591963.validator(path, query, header, formData, body)
  let scheme = call_591963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591963.url(scheme.get, call_591963.host, call_591963.base,
                         call_591963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591963, url, valid)

proc call*(call_591964: Call_StopCompilationJob_591951; body: JsonNode): Recallable =
  ## stopCompilationJob
  ## <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <a>CompilationJobSummary$CompilationJobStatus</a> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <a>CompilationJobSummary$CompilationJobStatus</a> to <code>Stopped</code>. </p>
  ##   body: JObject (required)
  var body_591965 = newJObject()
  if body != nil:
    body_591965 = body
  result = call_591964.call(nil, nil, nil, nil, body_591965)

var stopCompilationJob* = Call_StopCompilationJob_591951(
    name: "stopCompilationJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopCompilationJob",
    validator: validate_StopCompilationJob_591952, base: "/",
    url: url_StopCompilationJob_591953, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHyperParameterTuningJob_591966 = ref object of OpenApiRestCall_590364
proc url_StopHyperParameterTuningJob_591968(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopHyperParameterTuningJob_591967(path: JsonNode; query: JsonNode;
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
  var valid_591969 = header.getOrDefault("X-Amz-Target")
  valid_591969 = validateParameter(valid_591969, JString, required = true, default = newJString(
      "SageMaker.StopHyperParameterTuningJob"))
  if valid_591969 != nil:
    section.add "X-Amz-Target", valid_591969
  var valid_591970 = header.getOrDefault("X-Amz-Signature")
  valid_591970 = validateParameter(valid_591970, JString, required = false,
                                 default = nil)
  if valid_591970 != nil:
    section.add "X-Amz-Signature", valid_591970
  var valid_591971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591971 = validateParameter(valid_591971, JString, required = false,
                                 default = nil)
  if valid_591971 != nil:
    section.add "X-Amz-Content-Sha256", valid_591971
  var valid_591972 = header.getOrDefault("X-Amz-Date")
  valid_591972 = validateParameter(valid_591972, JString, required = false,
                                 default = nil)
  if valid_591972 != nil:
    section.add "X-Amz-Date", valid_591972
  var valid_591973 = header.getOrDefault("X-Amz-Credential")
  valid_591973 = validateParameter(valid_591973, JString, required = false,
                                 default = nil)
  if valid_591973 != nil:
    section.add "X-Amz-Credential", valid_591973
  var valid_591974 = header.getOrDefault("X-Amz-Security-Token")
  valid_591974 = validateParameter(valid_591974, JString, required = false,
                                 default = nil)
  if valid_591974 != nil:
    section.add "X-Amz-Security-Token", valid_591974
  var valid_591975 = header.getOrDefault("X-Amz-Algorithm")
  valid_591975 = validateParameter(valid_591975, JString, required = false,
                                 default = nil)
  if valid_591975 != nil:
    section.add "X-Amz-Algorithm", valid_591975
  var valid_591976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591976 = validateParameter(valid_591976, JString, required = false,
                                 default = nil)
  if valid_591976 != nil:
    section.add "X-Amz-SignedHeaders", valid_591976
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591978: Call_StopHyperParameterTuningJob_591966; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ## 
  let valid = call_591978.validator(path, query, header, formData, body)
  let scheme = call_591978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591978.url(scheme.get, call_591978.host, call_591978.base,
                         call_591978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591978, url, valid)

proc call*(call_591979: Call_StopHyperParameterTuningJob_591966; body: JsonNode): Recallable =
  ## stopHyperParameterTuningJob
  ## <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
  ##   body: JObject (required)
  var body_591980 = newJObject()
  if body != nil:
    body_591980 = body
  result = call_591979.call(nil, nil, nil, nil, body_591980)

var stopHyperParameterTuningJob* = Call_StopHyperParameterTuningJob_591966(
    name: "stopHyperParameterTuningJob", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob",
    validator: validate_StopHyperParameterTuningJob_591967, base: "/",
    url: url_StopHyperParameterTuningJob_591968,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLabelingJob_591981 = ref object of OpenApiRestCall_590364
proc url_StopLabelingJob_591983(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopLabelingJob_591982(path: JsonNode; query: JsonNode;
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
  var valid_591984 = header.getOrDefault("X-Amz-Target")
  valid_591984 = validateParameter(valid_591984, JString, required = true, default = newJString(
      "SageMaker.StopLabelingJob"))
  if valid_591984 != nil:
    section.add "X-Amz-Target", valid_591984
  var valid_591985 = header.getOrDefault("X-Amz-Signature")
  valid_591985 = validateParameter(valid_591985, JString, required = false,
                                 default = nil)
  if valid_591985 != nil:
    section.add "X-Amz-Signature", valid_591985
  var valid_591986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591986 = validateParameter(valid_591986, JString, required = false,
                                 default = nil)
  if valid_591986 != nil:
    section.add "X-Amz-Content-Sha256", valid_591986
  var valid_591987 = header.getOrDefault("X-Amz-Date")
  valid_591987 = validateParameter(valid_591987, JString, required = false,
                                 default = nil)
  if valid_591987 != nil:
    section.add "X-Amz-Date", valid_591987
  var valid_591988 = header.getOrDefault("X-Amz-Credential")
  valid_591988 = validateParameter(valid_591988, JString, required = false,
                                 default = nil)
  if valid_591988 != nil:
    section.add "X-Amz-Credential", valid_591988
  var valid_591989 = header.getOrDefault("X-Amz-Security-Token")
  valid_591989 = validateParameter(valid_591989, JString, required = false,
                                 default = nil)
  if valid_591989 != nil:
    section.add "X-Amz-Security-Token", valid_591989
  var valid_591990 = header.getOrDefault("X-Amz-Algorithm")
  valid_591990 = validateParameter(valid_591990, JString, required = false,
                                 default = nil)
  if valid_591990 != nil:
    section.add "X-Amz-Algorithm", valid_591990
  var valid_591991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591991 = validateParameter(valid_591991, JString, required = false,
                                 default = nil)
  if valid_591991 != nil:
    section.add "X-Amz-SignedHeaders", valid_591991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591993: Call_StopLabelingJob_591981; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ## 
  let valid = call_591993.validator(path, query, header, formData, body)
  let scheme = call_591993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591993.url(scheme.get, call_591993.host, call_591993.base,
                         call_591993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591993, url, valid)

proc call*(call_591994: Call_StopLabelingJob_591981; body: JsonNode): Recallable =
  ## stopLabelingJob
  ## Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
  ##   body: JObject (required)
  var body_591995 = newJObject()
  if body != nil:
    body_591995 = body
  result = call_591994.call(nil, nil, nil, nil, body_591995)

var stopLabelingJob* = Call_StopLabelingJob_591981(name: "stopLabelingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopLabelingJob",
    validator: validate_StopLabelingJob_591982, base: "/", url: url_StopLabelingJob_591983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopNotebookInstance_591996 = ref object of OpenApiRestCall_590364
proc url_StopNotebookInstance_591998(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopNotebookInstance_591997(path: JsonNode; query: JsonNode;
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
  var valid_591999 = header.getOrDefault("X-Amz-Target")
  valid_591999 = validateParameter(valid_591999, JString, required = true, default = newJString(
      "SageMaker.StopNotebookInstance"))
  if valid_591999 != nil:
    section.add "X-Amz-Target", valid_591999
  var valid_592000 = header.getOrDefault("X-Amz-Signature")
  valid_592000 = validateParameter(valid_592000, JString, required = false,
                                 default = nil)
  if valid_592000 != nil:
    section.add "X-Amz-Signature", valid_592000
  var valid_592001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592001 = validateParameter(valid_592001, JString, required = false,
                                 default = nil)
  if valid_592001 != nil:
    section.add "X-Amz-Content-Sha256", valid_592001
  var valid_592002 = header.getOrDefault("X-Amz-Date")
  valid_592002 = validateParameter(valid_592002, JString, required = false,
                                 default = nil)
  if valid_592002 != nil:
    section.add "X-Amz-Date", valid_592002
  var valid_592003 = header.getOrDefault("X-Amz-Credential")
  valid_592003 = validateParameter(valid_592003, JString, required = false,
                                 default = nil)
  if valid_592003 != nil:
    section.add "X-Amz-Credential", valid_592003
  var valid_592004 = header.getOrDefault("X-Amz-Security-Token")
  valid_592004 = validateParameter(valid_592004, JString, required = false,
                                 default = nil)
  if valid_592004 != nil:
    section.add "X-Amz-Security-Token", valid_592004
  var valid_592005 = header.getOrDefault("X-Amz-Algorithm")
  valid_592005 = validateParameter(valid_592005, JString, required = false,
                                 default = nil)
  if valid_592005 != nil:
    section.add "X-Amz-Algorithm", valid_592005
  var valid_592006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592006 = validateParameter(valid_592006, JString, required = false,
                                 default = nil)
  if valid_592006 != nil:
    section.add "X-Amz-SignedHeaders", valid_592006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592008: Call_StopNotebookInstance_591996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ## 
  let valid = call_592008.validator(path, query, header, formData, body)
  let scheme = call_592008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592008.url(scheme.get, call_592008.host, call_592008.base,
                         call_592008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592008, url, valid)

proc call*(call_592009: Call_StopNotebookInstance_591996; body: JsonNode): Recallable =
  ## stopNotebookInstance
  ## <p>Terminates the ML compute instance. Before terminating the instance, Amazon SageMaker disconnects the ML storage volume from it. Amazon SageMaker preserves the ML storage volume. Amazon SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
  ##   body: JObject (required)
  var body_592010 = newJObject()
  if body != nil:
    body_592010 = body
  result = call_592009.call(nil, nil, nil, nil, body_592010)

var stopNotebookInstance* = Call_StopNotebookInstance_591996(
    name: "stopNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopNotebookInstance",
    validator: validate_StopNotebookInstance_591997, base: "/",
    url: url_StopNotebookInstance_591998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrainingJob_592011 = ref object of OpenApiRestCall_590364
proc url_StopTrainingJob_592013(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTrainingJob_592012(path: JsonNode; query: JsonNode;
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
  var valid_592014 = header.getOrDefault("X-Amz-Target")
  valid_592014 = validateParameter(valid_592014, JString, required = true, default = newJString(
      "SageMaker.StopTrainingJob"))
  if valid_592014 != nil:
    section.add "X-Amz-Target", valid_592014
  var valid_592015 = header.getOrDefault("X-Amz-Signature")
  valid_592015 = validateParameter(valid_592015, JString, required = false,
                                 default = nil)
  if valid_592015 != nil:
    section.add "X-Amz-Signature", valid_592015
  var valid_592016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592016 = validateParameter(valid_592016, JString, required = false,
                                 default = nil)
  if valid_592016 != nil:
    section.add "X-Amz-Content-Sha256", valid_592016
  var valid_592017 = header.getOrDefault("X-Amz-Date")
  valid_592017 = validateParameter(valid_592017, JString, required = false,
                                 default = nil)
  if valid_592017 != nil:
    section.add "X-Amz-Date", valid_592017
  var valid_592018 = header.getOrDefault("X-Amz-Credential")
  valid_592018 = validateParameter(valid_592018, JString, required = false,
                                 default = nil)
  if valid_592018 != nil:
    section.add "X-Amz-Credential", valid_592018
  var valid_592019 = header.getOrDefault("X-Amz-Security-Token")
  valid_592019 = validateParameter(valid_592019, JString, required = false,
                                 default = nil)
  if valid_592019 != nil:
    section.add "X-Amz-Security-Token", valid_592019
  var valid_592020 = header.getOrDefault("X-Amz-Algorithm")
  valid_592020 = validateParameter(valid_592020, JString, required = false,
                                 default = nil)
  if valid_592020 != nil:
    section.add "X-Amz-Algorithm", valid_592020
  var valid_592021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592021 = validateParameter(valid_592021, JString, required = false,
                                 default = nil)
  if valid_592021 != nil:
    section.add "X-Amz-SignedHeaders", valid_592021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592023: Call_StopTrainingJob_592011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ## 
  let valid = call_592023.validator(path, query, header, formData, body)
  let scheme = call_592023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592023.url(scheme.get, call_592023.host, call_592023.base,
                         call_592023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592023, url, valid)

proc call*(call_592024: Call_StopTrainingJob_592011; body: JsonNode): Recallable =
  ## stopTrainingJob
  ## <p>Stops a training job. To stop a job, Amazon SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, Amazon SageMaker changes the status of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
  ##   body: JObject (required)
  var body_592025 = newJObject()
  if body != nil:
    body_592025 = body
  result = call_592024.call(nil, nil, nil, nil, body_592025)

var stopTrainingJob* = Call_StopTrainingJob_592011(name: "stopTrainingJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTrainingJob",
    validator: validate_StopTrainingJob_592012, base: "/", url: url_StopTrainingJob_592013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTransformJob_592026 = ref object of OpenApiRestCall_590364
proc url_StopTransformJob_592028(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopTransformJob_592027(path: JsonNode; query: JsonNode;
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
  var valid_592029 = header.getOrDefault("X-Amz-Target")
  valid_592029 = validateParameter(valid_592029, JString, required = true, default = newJString(
      "SageMaker.StopTransformJob"))
  if valid_592029 != nil:
    section.add "X-Amz-Target", valid_592029
  var valid_592030 = header.getOrDefault("X-Amz-Signature")
  valid_592030 = validateParameter(valid_592030, JString, required = false,
                                 default = nil)
  if valid_592030 != nil:
    section.add "X-Amz-Signature", valid_592030
  var valid_592031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592031 = validateParameter(valid_592031, JString, required = false,
                                 default = nil)
  if valid_592031 != nil:
    section.add "X-Amz-Content-Sha256", valid_592031
  var valid_592032 = header.getOrDefault("X-Amz-Date")
  valid_592032 = validateParameter(valid_592032, JString, required = false,
                                 default = nil)
  if valid_592032 != nil:
    section.add "X-Amz-Date", valid_592032
  var valid_592033 = header.getOrDefault("X-Amz-Credential")
  valid_592033 = validateParameter(valid_592033, JString, required = false,
                                 default = nil)
  if valid_592033 != nil:
    section.add "X-Amz-Credential", valid_592033
  var valid_592034 = header.getOrDefault("X-Amz-Security-Token")
  valid_592034 = validateParameter(valid_592034, JString, required = false,
                                 default = nil)
  if valid_592034 != nil:
    section.add "X-Amz-Security-Token", valid_592034
  var valid_592035 = header.getOrDefault("X-Amz-Algorithm")
  valid_592035 = validateParameter(valid_592035, JString, required = false,
                                 default = nil)
  if valid_592035 != nil:
    section.add "X-Amz-Algorithm", valid_592035
  var valid_592036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592036 = validateParameter(valid_592036, JString, required = false,
                                 default = nil)
  if valid_592036 != nil:
    section.add "X-Amz-SignedHeaders", valid_592036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592038: Call_StopTransformJob_592026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ## 
  let valid = call_592038.validator(path, query, header, formData, body)
  let scheme = call_592038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592038.url(scheme.get, call_592038.host, call_592038.base,
                         call_592038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592038, url, valid)

proc call*(call_592039: Call_StopTransformJob_592026; body: JsonNode): Recallable =
  ## stopTransformJob
  ## <p>Stops a transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
  ##   body: JObject (required)
  var body_592040 = newJObject()
  if body != nil:
    body_592040 = body
  result = call_592039.call(nil, nil, nil, nil, body_592040)

var stopTransformJob* = Call_StopTransformJob_592026(name: "stopTransformJob",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.StopTransformJob",
    validator: validate_StopTransformJob_592027, base: "/",
    url: url_StopTransformJob_592028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCodeRepository_592041 = ref object of OpenApiRestCall_590364
proc url_UpdateCodeRepository_592043(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCodeRepository_592042(path: JsonNode; query: JsonNode;
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
  var valid_592044 = header.getOrDefault("X-Amz-Target")
  valid_592044 = validateParameter(valid_592044, JString, required = true, default = newJString(
      "SageMaker.UpdateCodeRepository"))
  if valid_592044 != nil:
    section.add "X-Amz-Target", valid_592044
  var valid_592045 = header.getOrDefault("X-Amz-Signature")
  valid_592045 = validateParameter(valid_592045, JString, required = false,
                                 default = nil)
  if valid_592045 != nil:
    section.add "X-Amz-Signature", valid_592045
  var valid_592046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592046 = validateParameter(valid_592046, JString, required = false,
                                 default = nil)
  if valid_592046 != nil:
    section.add "X-Amz-Content-Sha256", valid_592046
  var valid_592047 = header.getOrDefault("X-Amz-Date")
  valid_592047 = validateParameter(valid_592047, JString, required = false,
                                 default = nil)
  if valid_592047 != nil:
    section.add "X-Amz-Date", valid_592047
  var valid_592048 = header.getOrDefault("X-Amz-Credential")
  valid_592048 = validateParameter(valid_592048, JString, required = false,
                                 default = nil)
  if valid_592048 != nil:
    section.add "X-Amz-Credential", valid_592048
  var valid_592049 = header.getOrDefault("X-Amz-Security-Token")
  valid_592049 = validateParameter(valid_592049, JString, required = false,
                                 default = nil)
  if valid_592049 != nil:
    section.add "X-Amz-Security-Token", valid_592049
  var valid_592050 = header.getOrDefault("X-Amz-Algorithm")
  valid_592050 = validateParameter(valid_592050, JString, required = false,
                                 default = nil)
  if valid_592050 != nil:
    section.add "X-Amz-Algorithm", valid_592050
  var valid_592051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592051 = validateParameter(valid_592051, JString, required = false,
                                 default = nil)
  if valid_592051 != nil:
    section.add "X-Amz-SignedHeaders", valid_592051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592053: Call_UpdateCodeRepository_592041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the specified Git repository with the specified values.
  ## 
  let valid = call_592053.validator(path, query, header, formData, body)
  let scheme = call_592053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592053.url(scheme.get, call_592053.host, call_592053.base,
                         call_592053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592053, url, valid)

proc call*(call_592054: Call_UpdateCodeRepository_592041; body: JsonNode): Recallable =
  ## updateCodeRepository
  ## Updates the specified Git repository with the specified values.
  ##   body: JObject (required)
  var body_592055 = newJObject()
  if body != nil:
    body_592055 = body
  result = call_592054.call(nil, nil, nil, nil, body_592055)

var updateCodeRepository* = Call_UpdateCodeRepository_592041(
    name: "updateCodeRepository", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateCodeRepository",
    validator: validate_UpdateCodeRepository_592042, base: "/",
    url: url_UpdateCodeRepository_592043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpoint_592056 = ref object of OpenApiRestCall_590364
proc url_UpdateEndpoint_592058(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEndpoint_592057(path: JsonNode; query: JsonNode;
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
  var valid_592059 = header.getOrDefault("X-Amz-Target")
  valid_592059 = validateParameter(valid_592059, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpoint"))
  if valid_592059 != nil:
    section.add "X-Amz-Target", valid_592059
  var valid_592060 = header.getOrDefault("X-Amz-Signature")
  valid_592060 = validateParameter(valid_592060, JString, required = false,
                                 default = nil)
  if valid_592060 != nil:
    section.add "X-Amz-Signature", valid_592060
  var valid_592061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592061 = validateParameter(valid_592061, JString, required = false,
                                 default = nil)
  if valid_592061 != nil:
    section.add "X-Amz-Content-Sha256", valid_592061
  var valid_592062 = header.getOrDefault("X-Amz-Date")
  valid_592062 = validateParameter(valid_592062, JString, required = false,
                                 default = nil)
  if valid_592062 != nil:
    section.add "X-Amz-Date", valid_592062
  var valid_592063 = header.getOrDefault("X-Amz-Credential")
  valid_592063 = validateParameter(valid_592063, JString, required = false,
                                 default = nil)
  if valid_592063 != nil:
    section.add "X-Amz-Credential", valid_592063
  var valid_592064 = header.getOrDefault("X-Amz-Security-Token")
  valid_592064 = validateParameter(valid_592064, JString, required = false,
                                 default = nil)
  if valid_592064 != nil:
    section.add "X-Amz-Security-Token", valid_592064
  var valid_592065 = header.getOrDefault("X-Amz-Algorithm")
  valid_592065 = validateParameter(valid_592065, JString, required = false,
                                 default = nil)
  if valid_592065 != nil:
    section.add "X-Amz-Algorithm", valid_592065
  var valid_592066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592066 = validateParameter(valid_592066, JString, required = false,
                                 default = nil)
  if valid_592066 != nil:
    section.add "X-Amz-SignedHeaders", valid_592066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592068: Call_UpdateEndpoint_592056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ## 
  let valid = call_592068.validator(path, query, header, formData, body)
  let scheme = call_592068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592068.url(scheme.get, call_592068.host, call_592068.base,
                         call_592068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592068, url, valid)

proc call*(call_592069: Call_UpdateEndpoint_592056; body: JsonNode): Recallable =
  ## updateEndpoint
  ## <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When Amazon SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note>
  ##   body: JObject (required)
  var body_592070 = newJObject()
  if body != nil:
    body_592070 = body
  result = call_592069.call(nil, nil, nil, nil, body_592070)

var updateEndpoint* = Call_UpdateEndpoint_592056(name: "updateEndpoint",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpoint",
    validator: validate_UpdateEndpoint_592057, base: "/", url: url_UpdateEndpoint_592058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEndpointWeightsAndCapacities_592071 = ref object of OpenApiRestCall_590364
proc url_UpdateEndpointWeightsAndCapacities_592073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEndpointWeightsAndCapacities_592072(path: JsonNode;
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
  var valid_592074 = header.getOrDefault("X-Amz-Target")
  valid_592074 = validateParameter(valid_592074, JString, required = true, default = newJString(
      "SageMaker.UpdateEndpointWeightsAndCapacities"))
  if valid_592074 != nil:
    section.add "X-Amz-Target", valid_592074
  var valid_592075 = header.getOrDefault("X-Amz-Signature")
  valid_592075 = validateParameter(valid_592075, JString, required = false,
                                 default = nil)
  if valid_592075 != nil:
    section.add "X-Amz-Signature", valid_592075
  var valid_592076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592076 = validateParameter(valid_592076, JString, required = false,
                                 default = nil)
  if valid_592076 != nil:
    section.add "X-Amz-Content-Sha256", valid_592076
  var valid_592077 = header.getOrDefault("X-Amz-Date")
  valid_592077 = validateParameter(valid_592077, JString, required = false,
                                 default = nil)
  if valid_592077 != nil:
    section.add "X-Amz-Date", valid_592077
  var valid_592078 = header.getOrDefault("X-Amz-Credential")
  valid_592078 = validateParameter(valid_592078, JString, required = false,
                                 default = nil)
  if valid_592078 != nil:
    section.add "X-Amz-Credential", valid_592078
  var valid_592079 = header.getOrDefault("X-Amz-Security-Token")
  valid_592079 = validateParameter(valid_592079, JString, required = false,
                                 default = nil)
  if valid_592079 != nil:
    section.add "X-Amz-Security-Token", valid_592079
  var valid_592080 = header.getOrDefault("X-Amz-Algorithm")
  valid_592080 = validateParameter(valid_592080, JString, required = false,
                                 default = nil)
  if valid_592080 != nil:
    section.add "X-Amz-Algorithm", valid_592080
  var valid_592081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592081 = validateParameter(valid_592081, JString, required = false,
                                 default = nil)
  if valid_592081 != nil:
    section.add "X-Amz-SignedHeaders", valid_592081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592083: Call_UpdateEndpointWeightsAndCapacities_592071;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ## 
  let valid = call_592083.validator(path, query, header, formData, body)
  let scheme = call_592083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592083.url(scheme.get, call_592083.host, call_592083.base,
                         call_592083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592083, url, valid)

proc call*(call_592084: Call_UpdateEndpointWeightsAndCapacities_592071;
          body: JsonNode): Recallable =
  ## updateEndpointWeightsAndCapacities
  ## Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, Amazon SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
  ##   body: JObject (required)
  var body_592085 = newJObject()
  if body != nil:
    body_592085 = body
  result = call_592084.call(nil, nil, nil, nil, body_592085)

var updateEndpointWeightsAndCapacities* = Call_UpdateEndpointWeightsAndCapacities_592071(
    name: "updateEndpointWeightsAndCapacities", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities",
    validator: validate_UpdateEndpointWeightsAndCapacities_592072, base: "/",
    url: url_UpdateEndpointWeightsAndCapacities_592073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstance_592086 = ref object of OpenApiRestCall_590364
proc url_UpdateNotebookInstance_592088(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNotebookInstance_592087(path: JsonNode; query: JsonNode;
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
  var valid_592089 = header.getOrDefault("X-Amz-Target")
  valid_592089 = validateParameter(valid_592089, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstance"))
  if valid_592089 != nil:
    section.add "X-Amz-Target", valid_592089
  var valid_592090 = header.getOrDefault("X-Amz-Signature")
  valid_592090 = validateParameter(valid_592090, JString, required = false,
                                 default = nil)
  if valid_592090 != nil:
    section.add "X-Amz-Signature", valid_592090
  var valid_592091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592091 = validateParameter(valid_592091, JString, required = false,
                                 default = nil)
  if valid_592091 != nil:
    section.add "X-Amz-Content-Sha256", valid_592091
  var valid_592092 = header.getOrDefault("X-Amz-Date")
  valid_592092 = validateParameter(valid_592092, JString, required = false,
                                 default = nil)
  if valid_592092 != nil:
    section.add "X-Amz-Date", valid_592092
  var valid_592093 = header.getOrDefault("X-Amz-Credential")
  valid_592093 = validateParameter(valid_592093, JString, required = false,
                                 default = nil)
  if valid_592093 != nil:
    section.add "X-Amz-Credential", valid_592093
  var valid_592094 = header.getOrDefault("X-Amz-Security-Token")
  valid_592094 = validateParameter(valid_592094, JString, required = false,
                                 default = nil)
  if valid_592094 != nil:
    section.add "X-Amz-Security-Token", valid_592094
  var valid_592095 = header.getOrDefault("X-Amz-Algorithm")
  valid_592095 = validateParameter(valid_592095, JString, required = false,
                                 default = nil)
  if valid_592095 != nil:
    section.add "X-Amz-Algorithm", valid_592095
  var valid_592096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592096 = validateParameter(valid_592096, JString, required = false,
                                 default = nil)
  if valid_592096 != nil:
    section.add "X-Amz-SignedHeaders", valid_592096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592098: Call_UpdateNotebookInstance_592086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ## 
  let valid = call_592098.validator(path, query, header, formData, body)
  let scheme = call_592098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592098.url(scheme.get, call_592098.host, call_592098.base,
                         call_592098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592098, url, valid)

proc call*(call_592099: Call_UpdateNotebookInstance_592086; body: JsonNode): Recallable =
  ## updateNotebookInstance
  ## Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
  ##   body: JObject (required)
  var body_592100 = newJObject()
  if body != nil:
    body_592100 = body
  result = call_592099.call(nil, nil, nil, nil, body_592100)

var updateNotebookInstance* = Call_UpdateNotebookInstance_592086(
    name: "updateNotebookInstance", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstance",
    validator: validate_UpdateNotebookInstance_592087, base: "/",
    url: url_UpdateNotebookInstance_592088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNotebookInstanceLifecycleConfig_592101 = ref object of OpenApiRestCall_590364
proc url_UpdateNotebookInstanceLifecycleConfig_592103(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateNotebookInstanceLifecycleConfig_592102(path: JsonNode;
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
  var valid_592104 = header.getOrDefault("X-Amz-Target")
  valid_592104 = validateParameter(valid_592104, JString, required = true, default = newJString(
      "SageMaker.UpdateNotebookInstanceLifecycleConfig"))
  if valid_592104 != nil:
    section.add "X-Amz-Target", valid_592104
  var valid_592105 = header.getOrDefault("X-Amz-Signature")
  valid_592105 = validateParameter(valid_592105, JString, required = false,
                                 default = nil)
  if valid_592105 != nil:
    section.add "X-Amz-Signature", valid_592105
  var valid_592106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592106 = validateParameter(valid_592106, JString, required = false,
                                 default = nil)
  if valid_592106 != nil:
    section.add "X-Amz-Content-Sha256", valid_592106
  var valid_592107 = header.getOrDefault("X-Amz-Date")
  valid_592107 = validateParameter(valid_592107, JString, required = false,
                                 default = nil)
  if valid_592107 != nil:
    section.add "X-Amz-Date", valid_592107
  var valid_592108 = header.getOrDefault("X-Amz-Credential")
  valid_592108 = validateParameter(valid_592108, JString, required = false,
                                 default = nil)
  if valid_592108 != nil:
    section.add "X-Amz-Credential", valid_592108
  var valid_592109 = header.getOrDefault("X-Amz-Security-Token")
  valid_592109 = validateParameter(valid_592109, JString, required = false,
                                 default = nil)
  if valid_592109 != nil:
    section.add "X-Amz-Security-Token", valid_592109
  var valid_592110 = header.getOrDefault("X-Amz-Algorithm")
  valid_592110 = validateParameter(valid_592110, JString, required = false,
                                 default = nil)
  if valid_592110 != nil:
    section.add "X-Amz-Algorithm", valid_592110
  var valid_592111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592111 = validateParameter(valid_592111, JString, required = false,
                                 default = nil)
  if valid_592111 != nil:
    section.add "X-Amz-SignedHeaders", valid_592111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592113: Call_UpdateNotebookInstanceLifecycleConfig_592101;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ## 
  let valid = call_592113.validator(path, query, header, formData, body)
  let scheme = call_592113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592113.url(scheme.get, call_592113.host, call_592113.base,
                         call_592113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592113, url, valid)

proc call*(call_592114: Call_UpdateNotebookInstanceLifecycleConfig_592101;
          body: JsonNode): Recallable =
  ## updateNotebookInstanceLifecycleConfig
  ## Updates a notebook instance lifecycle configuration created with the <a>CreateNotebookInstanceLifecycleConfig</a> API.
  ##   body: JObject (required)
  var body_592115 = newJObject()
  if body != nil:
    body_592115 = body
  result = call_592114.call(nil, nil, nil, nil, body_592115)

var updateNotebookInstanceLifecycleConfig* = Call_UpdateNotebookInstanceLifecycleConfig_592101(
    name: "updateNotebookInstanceLifecycleConfig", meth: HttpMethod.HttpPost,
    host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig",
    validator: validate_UpdateNotebookInstanceLifecycleConfig_592102, base: "/",
    url: url_UpdateNotebookInstanceLifecycleConfig_592103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkteam_592116 = ref object of OpenApiRestCall_590364
proc url_UpdateWorkteam_592118(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWorkteam_592117(path: JsonNode; query: JsonNode;
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
  var valid_592119 = header.getOrDefault("X-Amz-Target")
  valid_592119 = validateParameter(valid_592119, JString, required = true, default = newJString(
      "SageMaker.UpdateWorkteam"))
  if valid_592119 != nil:
    section.add "X-Amz-Target", valid_592119
  var valid_592120 = header.getOrDefault("X-Amz-Signature")
  valid_592120 = validateParameter(valid_592120, JString, required = false,
                                 default = nil)
  if valid_592120 != nil:
    section.add "X-Amz-Signature", valid_592120
  var valid_592121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592121 = validateParameter(valid_592121, JString, required = false,
                                 default = nil)
  if valid_592121 != nil:
    section.add "X-Amz-Content-Sha256", valid_592121
  var valid_592122 = header.getOrDefault("X-Amz-Date")
  valid_592122 = validateParameter(valid_592122, JString, required = false,
                                 default = nil)
  if valid_592122 != nil:
    section.add "X-Amz-Date", valid_592122
  var valid_592123 = header.getOrDefault("X-Amz-Credential")
  valid_592123 = validateParameter(valid_592123, JString, required = false,
                                 default = nil)
  if valid_592123 != nil:
    section.add "X-Amz-Credential", valid_592123
  var valid_592124 = header.getOrDefault("X-Amz-Security-Token")
  valid_592124 = validateParameter(valid_592124, JString, required = false,
                                 default = nil)
  if valid_592124 != nil:
    section.add "X-Amz-Security-Token", valid_592124
  var valid_592125 = header.getOrDefault("X-Amz-Algorithm")
  valid_592125 = validateParameter(valid_592125, JString, required = false,
                                 default = nil)
  if valid_592125 != nil:
    section.add "X-Amz-Algorithm", valid_592125
  var valid_592126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592126 = validateParameter(valid_592126, JString, required = false,
                                 default = nil)
  if valid_592126 != nil:
    section.add "X-Amz-SignedHeaders", valid_592126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592128: Call_UpdateWorkteam_592116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing work team with new member definitions or description.
  ## 
  let valid = call_592128.validator(path, query, header, formData, body)
  let scheme = call_592128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592128.url(scheme.get, call_592128.host, call_592128.base,
                         call_592128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592128, url, valid)

proc call*(call_592129: Call_UpdateWorkteam_592116; body: JsonNode): Recallable =
  ## updateWorkteam
  ## Updates an existing work team with new member definitions or description.
  ##   body: JObject (required)
  var body_592130 = newJObject()
  if body != nil:
    body_592130 = body
  result = call_592129.call(nil, nil, nil, nil, body_592130)

var updateWorkteam* = Call_UpdateWorkteam_592116(name: "updateWorkteam",
    meth: HttpMethod.HttpPost, host: "api.sagemaker.amazonaws.com",
    route: "/#X-Amz-Target=SageMaker.UpdateWorkteam",
    validator: validate_UpdateWorkteam_592117, base: "/", url: url_UpdateWorkteam_592118,
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
