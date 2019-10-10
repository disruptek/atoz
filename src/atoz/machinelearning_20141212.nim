
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Machine Learning
## version: 2014-12-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Definition of the public APIs exposed by Amazon Machine Learning
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/machinelearning/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "machinelearning.ap-northeast-1.amazonaws.com", "ap-southeast-1": "machinelearning.ap-southeast-1.amazonaws.com", "us-west-2": "machinelearning.us-west-2.amazonaws.com", "eu-west-2": "machinelearning.eu-west-2.amazonaws.com", "ap-northeast-3": "machinelearning.ap-northeast-3.amazonaws.com", "eu-central-1": "machinelearning.eu-central-1.amazonaws.com", "us-east-2": "machinelearning.us-east-2.amazonaws.com", "us-east-1": "machinelearning.us-east-1.amazonaws.com", "cn-northwest-1": "machinelearning.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "machinelearning.ap-south-1.amazonaws.com", "eu-north-1": "machinelearning.eu-north-1.amazonaws.com", "ap-northeast-2": "machinelearning.ap-northeast-2.amazonaws.com", "us-west-1": "machinelearning.us-west-1.amazonaws.com", "us-gov-east-1": "machinelearning.us-gov-east-1.amazonaws.com", "eu-west-3": "machinelearning.eu-west-3.amazonaws.com", "cn-north-1": "machinelearning.cn-north-1.amazonaws.com.cn", "sa-east-1": "machinelearning.sa-east-1.amazonaws.com", "eu-west-1": "machinelearning.eu-west-1.amazonaws.com", "us-gov-west-1": "machinelearning.us-gov-west-1.amazonaws.com", "ap-southeast-2": "machinelearning.ap-southeast-2.amazonaws.com", "ca-central-1": "machinelearning.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "machinelearning.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "machinelearning.ap-southeast-1.amazonaws.com",
      "us-west-2": "machinelearning.us-west-2.amazonaws.com",
      "eu-west-2": "machinelearning.eu-west-2.amazonaws.com",
      "ap-northeast-3": "machinelearning.ap-northeast-3.amazonaws.com",
      "eu-central-1": "machinelearning.eu-central-1.amazonaws.com",
      "us-east-2": "machinelearning.us-east-2.amazonaws.com",
      "us-east-1": "machinelearning.us-east-1.amazonaws.com",
      "cn-northwest-1": "machinelearning.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "machinelearning.ap-south-1.amazonaws.com",
      "eu-north-1": "machinelearning.eu-north-1.amazonaws.com",
      "ap-northeast-2": "machinelearning.ap-northeast-2.amazonaws.com",
      "us-west-1": "machinelearning.us-west-1.amazonaws.com",
      "us-gov-east-1": "machinelearning.us-gov-east-1.amazonaws.com",
      "eu-west-3": "machinelearning.eu-west-3.amazonaws.com",
      "cn-north-1": "machinelearning.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "machinelearning.sa-east-1.amazonaws.com",
      "eu-west-1": "machinelearning.eu-west-1.amazonaws.com",
      "us-gov-west-1": "machinelearning.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "machinelearning.ap-southeast-2.amazonaws.com",
      "ca-central-1": "machinelearning.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "machinelearning"
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
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
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
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AmazonML_20141212.AddTags"))
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
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
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
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var addTags* = Call_AddTags_602803(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.AddTags",
                                validator: validate_AddTags_602804, base: "/",
                                url: url_AddTags_602805,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBatchPrediction_603072 = ref object of OpenApiRestCall_602466
proc url_CreateBatchPrediction_603074(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBatchPrediction_603073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
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
      "AmazonML_20141212.CreateBatchPrediction"))
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

proc call*(call_603084: Call_CreateBatchPrediction_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CreateBatchPrediction_603072; body: JsonNode): Recallable =
  ## createBatchPrediction
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var createBatchPrediction* = Call_CreateBatchPrediction_603072(
    name: "createBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateBatchPrediction",
    validator: validate_CreateBatchPrediction_603073, base: "/",
    url: url_CreateBatchPrediction_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRDS_603087 = ref object of OpenApiRestCall_602466
proc url_CreateDataSourceFromRDS_603089(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromRDS_603088(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
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
      "AmazonML_20141212.CreateDataSourceFromRDS"))
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

proc call*(call_603099: Call_CreateDataSourceFromRDS_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateDataSourceFromRDS_603087; body: JsonNode): Recallable =
  ## createDataSourceFromRDS
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createDataSourceFromRDS* = Call_CreateDataSourceFromRDS_603087(
    name: "createDataSourceFromRDS", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRDS",
    validator: validate_CreateDataSourceFromRDS_603088, base: "/",
    url: url_CreateDataSourceFromRDS_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRedshift_603102 = ref object of OpenApiRestCall_602466
proc url_CreateDataSourceFromRedshift_603104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromRedshift_603103(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
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
      "AmazonML_20141212.CreateDataSourceFromRedshift"))
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

proc call*(call_603114: Call_CreateDataSourceFromRedshift_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateDataSourceFromRedshift_603102; body: JsonNode): Recallable =
  ## createDataSourceFromRedshift
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createDataSourceFromRedshift* = Call_CreateDataSourceFromRedshift_603102(
    name: "createDataSourceFromRedshift", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRedshift",
    validator: validate_CreateDataSourceFromRedshift_603103, base: "/",
    url: url_CreateDataSourceFromRedshift_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromS3_603117 = ref object of OpenApiRestCall_602466
proc url_CreateDataSourceFromS3_603119(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromS3_603118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
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
      "AmazonML_20141212.CreateDataSourceFromS3"))
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

proc call*(call_603129: Call_CreateDataSourceFromS3_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateDataSourceFromS3_603117; body: JsonNode): Recallable =
  ## createDataSourceFromS3
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createDataSourceFromS3* = Call_CreateDataSourceFromS3_603117(
    name: "createDataSourceFromS3", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromS3",
    validator: validate_CreateDataSourceFromS3_603118, base: "/",
    url: url_CreateDataSourceFromS3_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEvaluation_603132 = ref object of OpenApiRestCall_602466
proc url_CreateEvaluation_603134(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEvaluation_603133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
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
      "AmazonML_20141212.CreateEvaluation"))
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

proc call*(call_603144: Call_CreateEvaluation_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateEvaluation_603132; body: JsonNode): Recallable =
  ## createEvaluation
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createEvaluation* = Call_CreateEvaluation_603132(name: "createEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateEvaluation",
    validator: validate_CreateEvaluation_603133, base: "/",
    url: url_CreateEvaluation_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLModel_603147 = ref object of OpenApiRestCall_602466
proc url_CreateMLModel_603149(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLModel_603148(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
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
      "AmazonML_20141212.CreateMLModel"))
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

proc call*(call_603159: Call_CreateMLModel_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateMLModel_603147; body: JsonNode): Recallable =
  ## createMLModel
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createMLModel* = Call_CreateMLModel_603147(name: "createMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateMLModel",
    validator: validate_CreateMLModel_603148, base: "/", url: url_CreateMLModel_603149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRealtimeEndpoint_603162 = ref object of OpenApiRestCall_602466
proc url_CreateRealtimeEndpoint_603164(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRealtimeEndpoint_603163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
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
      "AmazonML_20141212.CreateRealtimeEndpoint"))
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

proc call*(call_603174: Call_CreateRealtimeEndpoint_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateRealtimeEndpoint_603162; body: JsonNode): Recallable =
  ## createRealtimeEndpoint
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createRealtimeEndpoint* = Call_CreateRealtimeEndpoint_603162(
    name: "createRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateRealtimeEndpoint",
    validator: validate_CreateRealtimeEndpoint_603163, base: "/",
    url: url_CreateRealtimeEndpoint_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBatchPrediction_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteBatchPrediction_603179(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBatchPrediction_603178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
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
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteBatchPrediction"))
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

proc call*(call_603189: Call_DeleteBatchPrediction_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteBatchPrediction_603177; body: JsonNode): Recallable =
  ## deleteBatchPrediction
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteBatchPrediction* = Call_DeleteBatchPrediction_603177(
    name: "deleteBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteBatchPrediction",
    validator: validate_DeleteBatchPrediction_603178, base: "/",
    url: url_DeleteBatchPrediction_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteDataSource_603194(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDataSource_603193(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
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
      "AmazonML_20141212.DeleteDataSource"))
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

proc call*(call_603204: Call_DeleteDataSource_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteDataSource_603192; body: JsonNode): Recallable =
  ## deleteDataSource
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteDataSource* = Call_DeleteDataSource_603192(name: "deleteDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteDataSource",
    validator: validate_DeleteDataSource_603193, base: "/",
    url: url_DeleteDataSource_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluation_603207 = ref object of OpenApiRestCall_602466
proc url_DeleteEvaluation_603209(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEvaluation_603208(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
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
      "AmazonML_20141212.DeleteEvaluation"))
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

proc call*(call_603219: Call_DeleteEvaluation_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DeleteEvaluation_603207; body: JsonNode): Recallable =
  ## deleteEvaluation
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var deleteEvaluation* = Call_DeleteEvaluation_603207(name: "deleteEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteEvaluation",
    validator: validate_DeleteEvaluation_603208, base: "/",
    url: url_DeleteEvaluation_603209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLModel_603222 = ref object of OpenApiRestCall_602466
proc url_DeleteMLModel_603224(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLModel_603223(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
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
      "AmazonML_20141212.DeleteMLModel"))
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

proc call*(call_603234: Call_DeleteMLModel_603222; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteMLModel_603222; body: JsonNode): Recallable =
  ## deleteMLModel
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var deleteMLModel* = Call_DeleteMLModel_603222(name: "deleteMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteMLModel",
    validator: validate_DeleteMLModel_603223, base: "/", url: url_DeleteMLModel_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRealtimeEndpoint_603237 = ref object of OpenApiRestCall_602466
proc url_DeleteRealtimeEndpoint_603239(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRealtimeEndpoint_603238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a real time endpoint of an <code>MLModel</code>.
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
      "AmazonML_20141212.DeleteRealtimeEndpoint"))
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

proc call*(call_603249: Call_DeleteRealtimeEndpoint_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DeleteRealtimeEndpoint_603237; body: JsonNode): Recallable =
  ## deleteRealtimeEndpoint
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var deleteRealtimeEndpoint* = Call_DeleteRealtimeEndpoint_603237(
    name: "deleteRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteRealtimeEndpoint",
    validator: validate_DeleteRealtimeEndpoint_603238, base: "/",
    url: url_DeleteRealtimeEndpoint_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_603252 = ref object of OpenApiRestCall_602466
proc url_DeleteTags_603254(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_603253(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
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
      "AmazonML_20141212.DeleteTags"))
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

proc call*(call_603264: Call_DeleteTags_603252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DeleteTags_603252; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var deleteTags* = Call_DeleteTags_603252(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.DeleteTags",
                                      validator: validate_DeleteTags_603253,
                                      base: "/", url: url_DeleteTags_603254,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBatchPredictions_603267 = ref object of OpenApiRestCall_602466
proc url_DescribeBatchPredictions_603269(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBatchPredictions_603268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603270 = query.getOrDefault("Limit")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "Limit", valid_603270
  var valid_603271 = query.getOrDefault("NextToken")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "NextToken", valid_603271
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603272 = header.getOrDefault("X-Amz-Date")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Date", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Security-Token")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Security-Token", valid_603273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603274 = header.getOrDefault("X-Amz-Target")
  valid_603274 = validateParameter(valid_603274, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeBatchPredictions"))
  if valid_603274 != nil:
    section.add "X-Amz-Target", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Content-Sha256", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Algorithm")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Algorithm", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Signature")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Signature", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-SignedHeaders", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Credential")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Credential", valid_603279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603281: Call_DescribeBatchPredictions_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  let valid = call_603281.validator(path, query, header, formData, body)
  let scheme = call_603281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603281.url(scheme.get, call_603281.host, call_603281.base,
                         call_603281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603281, url, valid)

proc call*(call_603282: Call_DescribeBatchPredictions_603267; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeBatchPredictions
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603283 = newJObject()
  var body_603284 = newJObject()
  add(query_603283, "Limit", newJString(Limit))
  add(query_603283, "NextToken", newJString(NextToken))
  if body != nil:
    body_603284 = body
  result = call_603282.call(nil, query_603283, nil, nil, body_603284)

var describeBatchPredictions* = Call_DescribeBatchPredictions_603267(
    name: "describeBatchPredictions", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeBatchPredictions",
    validator: validate_DescribeBatchPredictions_603268, base: "/",
    url: url_DescribeBatchPredictions_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSources_603286 = ref object of OpenApiRestCall_602466
proc url_DescribeDataSources_603288(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDataSources_603287(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603289 = query.getOrDefault("Limit")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "Limit", valid_603289
  var valid_603290 = query.getOrDefault("NextToken")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "NextToken", valid_603290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603293 = header.getOrDefault("X-Amz-Target")
  valid_603293 = validateParameter(valid_603293, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeDataSources"))
  if valid_603293 != nil:
    section.add "X-Amz-Target", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Content-Sha256", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-SignedHeaders", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Credential")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Credential", valid_603298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603300: Call_DescribeDataSources_603286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  let valid = call_603300.validator(path, query, header, formData, body)
  let scheme = call_603300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603300.url(scheme.get, call_603300.host, call_603300.base,
                         call_603300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603300, url, valid)

proc call*(call_603301: Call_DescribeDataSources_603286; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeDataSources
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603302 = newJObject()
  var body_603303 = newJObject()
  add(query_603302, "Limit", newJString(Limit))
  add(query_603302, "NextToken", newJString(NextToken))
  if body != nil:
    body_603303 = body
  result = call_603301.call(nil, query_603302, nil, nil, body_603303)

var describeDataSources* = Call_DescribeDataSources_603286(
    name: "describeDataSources", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeDataSources",
    validator: validate_DescribeDataSources_603287, base: "/",
    url: url_DescribeDataSources_603288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvaluations_603304 = ref object of OpenApiRestCall_602466
proc url_DescribeEvaluations_603306(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvaluations_603305(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603307 = query.getOrDefault("Limit")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "Limit", valid_603307
  var valid_603308 = query.getOrDefault("NextToken")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "NextToken", valid_603308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603309 = header.getOrDefault("X-Amz-Date")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Date", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Security-Token")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Security-Token", valid_603310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603311 = header.getOrDefault("X-Amz-Target")
  valid_603311 = validateParameter(valid_603311, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeEvaluations"))
  if valid_603311 != nil:
    section.add "X-Amz-Target", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Content-Sha256", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Algorithm")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Algorithm", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Signature")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Signature", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-SignedHeaders", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Credential")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Credential", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_DescribeEvaluations_603304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_DescribeEvaluations_603304; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeEvaluations
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603320 = newJObject()
  var body_603321 = newJObject()
  add(query_603320, "Limit", newJString(Limit))
  add(query_603320, "NextToken", newJString(NextToken))
  if body != nil:
    body_603321 = body
  result = call_603319.call(nil, query_603320, nil, nil, body_603321)

var describeEvaluations* = Call_DescribeEvaluations_603304(
    name: "describeEvaluations", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeEvaluations",
    validator: validate_DescribeEvaluations_603305, base: "/",
    url: url_DescribeEvaluations_603306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMLModels_603322 = ref object of OpenApiRestCall_602466
proc url_DescribeMLModels_603324(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMLModels_603323(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603325 = query.getOrDefault("Limit")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "Limit", valid_603325
  var valid_603326 = query.getOrDefault("NextToken")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "NextToken", valid_603326
  result.add "query", section
  ## parameters in `header` object:
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
  valid_603329 = validateParameter(valid_603329, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeMLModels"))
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

proc call*(call_603336: Call_DescribeMLModels_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  let valid = call_603336.validator(path, query, header, formData, body)
  let scheme = call_603336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603336.url(scheme.get, call_603336.host, call_603336.base,
                         call_603336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603336, url, valid)

proc call*(call_603337: Call_DescribeMLModels_603322; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeMLModels
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603338 = newJObject()
  var body_603339 = newJObject()
  add(query_603338, "Limit", newJString(Limit))
  add(query_603338, "NextToken", newJString(NextToken))
  if body != nil:
    body_603339 = body
  result = call_603337.call(nil, query_603338, nil, nil, body_603339)

var describeMLModels* = Call_DescribeMLModels_603322(name: "describeMLModels",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeMLModels",
    validator: validate_DescribeMLModels_603323, base: "/",
    url: url_DescribeMLModels_603324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_603340 = ref object of OpenApiRestCall_602466
proc url_DescribeTags_603342(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTags_603341(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of the tags for your Amazon ML object.
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
  var valid_603343 = header.getOrDefault("X-Amz-Date")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Date", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Security-Token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Security-Token", valid_603344
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603345 = header.getOrDefault("X-Amz-Target")
  valid_603345 = validateParameter(valid_603345, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeTags"))
  if valid_603345 != nil:
    section.add "X-Amz-Target", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Content-Sha256", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Algorithm")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Algorithm", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Signature")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Signature", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-SignedHeaders", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Credential")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Credential", valid_603350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_DescribeTags_603340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of the tags for your Amazon ML object.
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_DescribeTags_603340; body: JsonNode): Recallable =
  ## describeTags
  ## Describes one or more of the tags for your Amazon ML object.
  ##   body: JObject (required)
  var body_603354 = newJObject()
  if body != nil:
    body_603354 = body
  result = call_603353.call(nil, nil, nil, nil, body_603354)

var describeTags* = Call_DescribeTags_603340(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeTags",
    validator: validate_DescribeTags_603341, base: "/", url: url_DescribeTags_603342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPrediction_603355 = ref object of OpenApiRestCall_602466
proc url_GetBatchPrediction_603357(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchPrediction_603356(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603360 = header.getOrDefault("X-Amz-Target")
  valid_603360 = validateParameter(valid_603360, JString, required = true, default = newJString(
      "AmazonML_20141212.GetBatchPrediction"))
  if valid_603360 != nil:
    section.add "X-Amz-Target", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_GetBatchPrediction_603355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_GetBatchPrediction_603355; body: JsonNode): Recallable =
  ## getBatchPrediction
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ##   body: JObject (required)
  var body_603369 = newJObject()
  if body != nil:
    body_603369 = body
  result = call_603368.call(nil, nil, nil, nil, body_603369)

var getBatchPrediction* = Call_GetBatchPrediction_603355(
    name: "getBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetBatchPrediction",
    validator: validate_GetBatchPrediction_603356, base: "/",
    url: url_GetBatchPrediction_603357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_603370 = ref object of OpenApiRestCall_602466
proc url_GetDataSource_603372(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataSource_603371(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
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
  var valid_603373 = header.getOrDefault("X-Amz-Date")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Date", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Security-Token")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Security-Token", valid_603374
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603375 = header.getOrDefault("X-Amz-Target")
  valid_603375 = validateParameter(valid_603375, JString, required = true, default = newJString(
      "AmazonML_20141212.GetDataSource"))
  if valid_603375 != nil:
    section.add "X-Amz-Target", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Content-Sha256", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Algorithm")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Algorithm", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Signature")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Signature", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-SignedHeaders", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Credential")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Credential", valid_603380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603382: Call_GetDataSource_603370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ## 
  let valid = call_603382.validator(path, query, header, formData, body)
  let scheme = call_603382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603382.url(scheme.get, call_603382.host, call_603382.base,
                         call_603382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603382, url, valid)

proc call*(call_603383: Call_GetDataSource_603370; body: JsonNode): Recallable =
  ## getDataSource
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ##   body: JObject (required)
  var body_603384 = newJObject()
  if body != nil:
    body_603384 = body
  result = call_603383.call(nil, nil, nil, nil, body_603384)

var getDataSource* = Call_GetDataSource_603370(name: "getDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetDataSource",
    validator: validate_GetDataSource_603371, base: "/", url: url_GetDataSource_603372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEvaluation_603385 = ref object of OpenApiRestCall_602466
proc url_GetEvaluation_603387(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEvaluation_603386(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
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
  var valid_603388 = header.getOrDefault("X-Amz-Date")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Date", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Security-Token")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Security-Token", valid_603389
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603390 = header.getOrDefault("X-Amz-Target")
  valid_603390 = validateParameter(valid_603390, JString, required = true, default = newJString(
      "AmazonML_20141212.GetEvaluation"))
  if valid_603390 != nil:
    section.add "X-Amz-Target", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Content-Sha256", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Signature")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Signature", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-SignedHeaders", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Credential")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Credential", valid_603395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603397: Call_GetEvaluation_603385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ## 
  let valid = call_603397.validator(path, query, header, formData, body)
  let scheme = call_603397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603397.url(scheme.get, call_603397.host, call_603397.base,
                         call_603397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603397, url, valid)

proc call*(call_603398: Call_GetEvaluation_603385; body: JsonNode): Recallable =
  ## getEvaluation
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ##   body: JObject (required)
  var body_603399 = newJObject()
  if body != nil:
    body_603399 = body
  result = call_603398.call(nil, nil, nil, nil, body_603399)

var getEvaluation* = Call_GetEvaluation_603385(name: "getEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetEvaluation",
    validator: validate_GetEvaluation_603386, base: "/", url: url_GetEvaluation_603387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLModel_603400 = ref object of OpenApiRestCall_602466
proc url_GetMLModel_603402(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLModel_603401(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
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
  var valid_603403 = header.getOrDefault("X-Amz-Date")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Date", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Security-Token")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Security-Token", valid_603404
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603405 = header.getOrDefault("X-Amz-Target")
  valid_603405 = validateParameter(valid_603405, JString, required = true, default = newJString(
      "AmazonML_20141212.GetMLModel"))
  if valid_603405 != nil:
    section.add "X-Amz-Target", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Content-Sha256", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Algorithm")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Algorithm", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Signature")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Signature", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-SignedHeaders", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Credential")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Credential", valid_603410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_GetMLModel_603400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ## 
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_GetMLModel_603400; body: JsonNode): Recallable =
  ## getMLModel
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ##   body: JObject (required)
  var body_603414 = newJObject()
  if body != nil:
    body_603414 = body
  result = call_603413.call(nil, nil, nil, nil, body_603414)

var getMLModel* = Call_GetMLModel_603400(name: "getMLModel",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.GetMLModel",
                                      validator: validate_GetMLModel_603401,
                                      base: "/", url: url_GetMLModel_603402,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Predict_603415 = ref object of OpenApiRestCall_602466
proc url_Predict_603417(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Predict_603416(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
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
  var valid_603418 = header.getOrDefault("X-Amz-Date")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Date", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Security-Token")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Security-Token", valid_603419
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603420 = header.getOrDefault("X-Amz-Target")
  valid_603420 = validateParameter(valid_603420, JString, required = true, default = newJString(
      "AmazonML_20141212.Predict"))
  if valid_603420 != nil:
    section.add "X-Amz-Target", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Content-Sha256", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Algorithm")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Algorithm", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Signature")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Signature", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-SignedHeaders", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Credential")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Credential", valid_603425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603427: Call_Predict_603415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ## 
  let valid = call_603427.validator(path, query, header, formData, body)
  let scheme = call_603427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603427.url(scheme.get, call_603427.host, call_603427.base,
                         call_603427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603427, url, valid)

proc call*(call_603428: Call_Predict_603415; body: JsonNode): Recallable =
  ## predict
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ##   body: JObject (required)
  var body_603429 = newJObject()
  if body != nil:
    body_603429 = body
  result = call_603428.call(nil, nil, nil, nil, body_603429)

var predict* = Call_Predict_603415(name: "predict", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.Predict",
                                validator: validate_Predict_603416, base: "/",
                                url: url_Predict_603417,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBatchPrediction_603430 = ref object of OpenApiRestCall_602466
proc url_UpdateBatchPrediction_603432(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBatchPrediction_603431(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
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
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603435 = header.getOrDefault("X-Amz-Target")
  valid_603435 = validateParameter(valid_603435, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateBatchPrediction"))
  if valid_603435 != nil:
    section.add "X-Amz-Target", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603442: Call_UpdateBatchPrediction_603430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_603442.validator(path, query, header, formData, body)
  let scheme = call_603442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603442.url(scheme.get, call_603442.host, call_603442.base,
                         call_603442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603442, url, valid)

proc call*(call_603443: Call_UpdateBatchPrediction_603430; body: JsonNode): Recallable =
  ## updateBatchPrediction
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_603444 = newJObject()
  if body != nil:
    body_603444 = body
  result = call_603443.call(nil, nil, nil, nil, body_603444)

var updateBatchPrediction* = Call_UpdateBatchPrediction_603430(
    name: "updateBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateBatchPrediction",
    validator: validate_UpdateBatchPrediction_603431, base: "/",
    url: url_UpdateBatchPrediction_603432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_603445 = ref object of OpenApiRestCall_602466
proc url_UpdateDataSource_603447(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDataSource_603446(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
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
  var valid_603448 = header.getOrDefault("X-Amz-Date")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Date", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Security-Token")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Security-Token", valid_603449
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603450 = header.getOrDefault("X-Amz-Target")
  valid_603450 = validateParameter(valid_603450, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateDataSource"))
  if valid_603450 != nil:
    section.add "X-Amz-Target", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Content-Sha256", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Signature")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Signature", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-SignedHeaders", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Credential")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Credential", valid_603455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603457: Call_UpdateDataSource_603445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_603457.validator(path, query, header, formData, body)
  let scheme = call_603457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603457.url(scheme.get, call_603457.host, call_603457.base,
                         call_603457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603457, url, valid)

proc call*(call_603458: Call_UpdateDataSource_603445; body: JsonNode): Recallable =
  ## updateDataSource
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_603459 = newJObject()
  if body != nil:
    body_603459 = body
  result = call_603458.call(nil, nil, nil, nil, body_603459)

var updateDataSource* = Call_UpdateDataSource_603445(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateDataSource",
    validator: validate_UpdateDataSource_603446, base: "/",
    url: url_UpdateDataSource_603447, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEvaluation_603460 = ref object of OpenApiRestCall_602466
proc url_UpdateEvaluation_603462(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEvaluation_603461(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
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
  var valid_603463 = header.getOrDefault("X-Amz-Date")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Date", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Security-Token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Security-Token", valid_603464
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603465 = header.getOrDefault("X-Amz-Target")
  valid_603465 = validateParameter(valid_603465, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateEvaluation"))
  if valid_603465 != nil:
    section.add "X-Amz-Target", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Content-Sha256", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Algorithm")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Algorithm", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Signature")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Signature", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-SignedHeaders", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Credential")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Credential", valid_603470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603472: Call_UpdateEvaluation_603460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_603472.validator(path, query, header, formData, body)
  let scheme = call_603472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603472.url(scheme.get, call_603472.host, call_603472.base,
                         call_603472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603472, url, valid)

proc call*(call_603473: Call_UpdateEvaluation_603460; body: JsonNode): Recallable =
  ## updateEvaluation
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_603474 = newJObject()
  if body != nil:
    body_603474 = body
  result = call_603473.call(nil, nil, nil, nil, body_603474)

var updateEvaluation* = Call_UpdateEvaluation_603460(name: "updateEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateEvaluation",
    validator: validate_UpdateEvaluation_603461, base: "/",
    url: url_UpdateEvaluation_603462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLModel_603475 = ref object of OpenApiRestCall_602466
proc url_UpdateMLModel_603477(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLModel_603476(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
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
  var valid_603478 = header.getOrDefault("X-Amz-Date")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Date", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Security-Token")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Security-Token", valid_603479
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603480 = header.getOrDefault("X-Amz-Target")
  valid_603480 = validateParameter(valid_603480, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateMLModel"))
  if valid_603480 != nil:
    section.add "X-Amz-Target", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Content-Sha256", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Algorithm")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Algorithm", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Signature")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Signature", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-SignedHeaders", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Credential")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Credential", valid_603485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603487: Call_UpdateMLModel_603475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_603487.validator(path, query, header, formData, body)
  let scheme = call_603487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603487.url(scheme.get, call_603487.host, call_603487.base,
                         call_603487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603487, url, valid)

proc call*(call_603488: Call_UpdateMLModel_603475; body: JsonNode): Recallable =
  ## updateMLModel
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_603489 = newJObject()
  if body != nil:
    body_603489 = body
  result = call_603488.call(nil, nil, nil, nil, body_603489)

var updateMLModel* = Call_UpdateMLModel_603475(name: "updateMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateMLModel",
    validator: validate_UpdateMLModel_603476, base: "/", url: url_UpdateMLModel_603477,
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
