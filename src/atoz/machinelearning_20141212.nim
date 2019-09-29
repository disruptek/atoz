
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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
  Call_AddTags_593774 = ref object of OpenApiRestCall_593437
proc url_AddTags_593776(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddTags_593775(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "AmazonML_20141212.AddTags"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AddTags_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AddTags_593774; body: JsonNode): Recallable =
  ## addTags
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var addTags* = Call_AddTags_593774(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.AddTags",
                                validator: validate_AddTags_593775, base: "/",
                                url: url_AddTags_593776,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBatchPrediction_594043 = ref object of OpenApiRestCall_593437
proc url_CreateBatchPrediction_594045(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBatchPrediction_594044(path: JsonNode; query: JsonNode;
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateBatchPrediction"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CreateBatchPrediction_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CreateBatchPrediction_594043; body: JsonNode): Recallable =
  ## createBatchPrediction
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var createBatchPrediction* = Call_CreateBatchPrediction_594043(
    name: "createBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateBatchPrediction",
    validator: validate_CreateBatchPrediction_594044, base: "/",
    url: url_CreateBatchPrediction_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRDS_594058 = ref object of OpenApiRestCall_593437
proc url_CreateDataSourceFromRDS_594060(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromRDS_594059(path: JsonNode; query: JsonNode;
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRDS"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CreateDataSourceFromRDS_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CreateDataSourceFromRDS_594058; body: JsonNode): Recallable =
  ## createDataSourceFromRDS
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var createDataSourceFromRDS* = Call_CreateDataSourceFromRDS_594058(
    name: "createDataSourceFromRDS", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRDS",
    validator: validate_CreateDataSourceFromRDS_594059, base: "/",
    url: url_CreateDataSourceFromRDS_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRedshift_594073 = ref object of OpenApiRestCall_593437
proc url_CreateDataSourceFromRedshift_594075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromRedshift_594074(path: JsonNode; query: JsonNode;
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRedshift"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateDataSourceFromRedshift_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateDataSourceFromRedshift_594073; body: JsonNode): Recallable =
  ## createDataSourceFromRedshift
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createDataSourceFromRedshift* = Call_CreateDataSourceFromRedshift_594073(
    name: "createDataSourceFromRedshift", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRedshift",
    validator: validate_CreateDataSourceFromRedshift_594074, base: "/",
    url: url_CreateDataSourceFromRedshift_594075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromS3_594088 = ref object of OpenApiRestCall_593437
proc url_CreateDataSourceFromS3_594090(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDataSourceFromS3_594089(path: JsonNode; query: JsonNode;
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromS3"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateDataSourceFromS3_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateDataSourceFromS3_594088; body: JsonNode): Recallable =
  ## createDataSourceFromS3
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createDataSourceFromS3* = Call_CreateDataSourceFromS3_594088(
    name: "createDataSourceFromS3", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromS3",
    validator: validate_CreateDataSourceFromS3_594089, base: "/",
    url: url_CreateDataSourceFromS3_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEvaluation_594103 = ref object of OpenApiRestCall_593437
proc url_CreateEvaluation_594105(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEvaluation_594104(path: JsonNode; query: JsonNode;
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateEvaluation"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateEvaluation_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateEvaluation_594103; body: JsonNode): Recallable =
  ## createEvaluation
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createEvaluation* = Call_CreateEvaluation_594103(name: "createEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateEvaluation",
    validator: validate_CreateEvaluation_594104, base: "/",
    url: url_CreateEvaluation_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLModel_594118 = ref object of OpenApiRestCall_593437
proc url_CreateMLModel_594120(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateMLModel_594119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateMLModel"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateMLModel_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateMLModel_594118; body: JsonNode): Recallable =
  ## createMLModel
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createMLModel* = Call_CreateMLModel_594118(name: "createMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateMLModel",
    validator: validate_CreateMLModel_594119, base: "/", url: url_CreateMLModel_594120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRealtimeEndpoint_594133 = ref object of OpenApiRestCall_593437
proc url_CreateRealtimeEndpoint_594135(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRealtimeEndpoint_594134(path: JsonNode; query: JsonNode;
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateRealtimeEndpoint"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateRealtimeEndpoint_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateRealtimeEndpoint_594133; body: JsonNode): Recallable =
  ## createRealtimeEndpoint
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createRealtimeEndpoint* = Call_CreateRealtimeEndpoint_594133(
    name: "createRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateRealtimeEndpoint",
    validator: validate_CreateRealtimeEndpoint_594134, base: "/",
    url: url_CreateRealtimeEndpoint_594135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBatchPrediction_594148 = ref object of OpenApiRestCall_593437
proc url_DeleteBatchPrediction_594150(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBatchPrediction_594149(path: JsonNode; query: JsonNode;
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteBatchPrediction"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_DeleteBatchPrediction_594148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_DeleteBatchPrediction_594148; body: JsonNode): Recallable =
  ## deleteBatchPrediction
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var deleteBatchPrediction* = Call_DeleteBatchPrediction_594148(
    name: "deleteBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteBatchPrediction",
    validator: validate_DeleteBatchPrediction_594149, base: "/",
    url: url_DeleteBatchPrediction_594150, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_594163 = ref object of OpenApiRestCall_593437
proc url_DeleteDataSource_594165(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDataSource_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteDataSource"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_DeleteDataSource_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_DeleteDataSource_594163; body: JsonNode): Recallable =
  ## deleteDataSource
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var deleteDataSource* = Call_DeleteDataSource_594163(name: "deleteDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteDataSource",
    validator: validate_DeleteDataSource_594164, base: "/",
    url: url_DeleteDataSource_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluation_594178 = ref object of OpenApiRestCall_593437
proc url_DeleteEvaluation_594180(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEvaluation_594179(path: JsonNode; query: JsonNode;
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteEvaluation"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_DeleteEvaluation_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_DeleteEvaluation_594178; body: JsonNode): Recallable =
  ## deleteEvaluation
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var deleteEvaluation* = Call_DeleteEvaluation_594178(name: "deleteEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteEvaluation",
    validator: validate_DeleteEvaluation_594179, base: "/",
    url: url_DeleteEvaluation_594180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLModel_594193 = ref object of OpenApiRestCall_593437
proc url_DeleteMLModel_594195(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteMLModel_594194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteMLModel"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_DeleteMLModel_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_DeleteMLModel_594193; body: JsonNode): Recallable =
  ## deleteMLModel
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var deleteMLModel* = Call_DeleteMLModel_594193(name: "deleteMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteMLModel",
    validator: validate_DeleteMLModel_594194, base: "/", url: url_DeleteMLModel_594195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRealtimeEndpoint_594208 = ref object of OpenApiRestCall_593437
proc url_DeleteRealtimeEndpoint_594210(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRealtimeEndpoint_594209(path: JsonNode; query: JsonNode;
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteRealtimeEndpoint"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_DeleteRealtimeEndpoint_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_DeleteRealtimeEndpoint_594208; body: JsonNode): Recallable =
  ## deleteRealtimeEndpoint
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var deleteRealtimeEndpoint* = Call_DeleteRealtimeEndpoint_594208(
    name: "deleteRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteRealtimeEndpoint",
    validator: validate_DeleteRealtimeEndpoint_594209, base: "/",
    url: url_DeleteRealtimeEndpoint_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_594223 = ref object of OpenApiRestCall_593437
proc url_DeleteTags_594225(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTags_594224(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteTags"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DeleteTags_594223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DeleteTags_594223; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var deleteTags* = Call_DeleteTags_594223(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.DeleteTags",
                                      validator: validate_DeleteTags_594224,
                                      base: "/", url: url_DeleteTags_594225,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBatchPredictions_594238 = ref object of OpenApiRestCall_593437
proc url_DescribeBatchPredictions_594240(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeBatchPredictions_594239(path: JsonNode; query: JsonNode;
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
  var valid_594241 = query.getOrDefault("Limit")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "Limit", valid_594241
  var valid_594242 = query.getOrDefault("NextToken")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "NextToken", valid_594242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594243 = header.getOrDefault("X-Amz-Date")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Date", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Security-Token")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Security-Token", valid_594244
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594245 = header.getOrDefault("X-Amz-Target")
  valid_594245 = validateParameter(valid_594245, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeBatchPredictions"))
  if valid_594245 != nil:
    section.add "X-Amz-Target", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Content-Sha256", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-Algorithm")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-Algorithm", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Signature")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Signature", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-SignedHeaders", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Credential")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Credential", valid_594250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594252: Call_DescribeBatchPredictions_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  let valid = call_594252.validator(path, query, header, formData, body)
  let scheme = call_594252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594252.url(scheme.get, call_594252.host, call_594252.base,
                         call_594252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594252, url, valid)

proc call*(call_594253: Call_DescribeBatchPredictions_594238; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeBatchPredictions
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594254 = newJObject()
  var body_594255 = newJObject()
  add(query_594254, "Limit", newJString(Limit))
  add(query_594254, "NextToken", newJString(NextToken))
  if body != nil:
    body_594255 = body
  result = call_594253.call(nil, query_594254, nil, nil, body_594255)

var describeBatchPredictions* = Call_DescribeBatchPredictions_594238(
    name: "describeBatchPredictions", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeBatchPredictions",
    validator: validate_DescribeBatchPredictions_594239, base: "/",
    url: url_DescribeBatchPredictions_594240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSources_594257 = ref object of OpenApiRestCall_593437
proc url_DescribeDataSources_594259(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDataSources_594258(path: JsonNode; query: JsonNode;
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
  var valid_594260 = query.getOrDefault("Limit")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "Limit", valid_594260
  var valid_594261 = query.getOrDefault("NextToken")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "NextToken", valid_594261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594262 = header.getOrDefault("X-Amz-Date")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-Date", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Security-Token")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Security-Token", valid_594263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594264 = header.getOrDefault("X-Amz-Target")
  valid_594264 = validateParameter(valid_594264, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeDataSources"))
  if valid_594264 != nil:
    section.add "X-Amz-Target", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Content-Sha256", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Signature")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Signature", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-SignedHeaders", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Credential")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Credential", valid_594269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594271: Call_DescribeDataSources_594257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  let valid = call_594271.validator(path, query, header, formData, body)
  let scheme = call_594271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594271.url(scheme.get, call_594271.host, call_594271.base,
                         call_594271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594271, url, valid)

proc call*(call_594272: Call_DescribeDataSources_594257; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeDataSources
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594273 = newJObject()
  var body_594274 = newJObject()
  add(query_594273, "Limit", newJString(Limit))
  add(query_594273, "NextToken", newJString(NextToken))
  if body != nil:
    body_594274 = body
  result = call_594272.call(nil, query_594273, nil, nil, body_594274)

var describeDataSources* = Call_DescribeDataSources_594257(
    name: "describeDataSources", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeDataSources",
    validator: validate_DescribeDataSources_594258, base: "/",
    url: url_DescribeDataSources_594259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvaluations_594275 = ref object of OpenApiRestCall_593437
proc url_DescribeEvaluations_594277(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeEvaluations_594276(path: JsonNode; query: JsonNode;
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
  var valid_594278 = query.getOrDefault("Limit")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "Limit", valid_594278
  var valid_594279 = query.getOrDefault("NextToken")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "NextToken", valid_594279
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594280 = header.getOrDefault("X-Amz-Date")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Date", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Security-Token")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Security-Token", valid_594281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594282 = header.getOrDefault("X-Amz-Target")
  valid_594282 = validateParameter(valid_594282, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeEvaluations"))
  if valid_594282 != nil:
    section.add "X-Amz-Target", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Content-Sha256", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Algorithm")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Algorithm", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Signature")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Signature", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-SignedHeaders", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Credential")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Credential", valid_594287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594289: Call_DescribeEvaluations_594275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  let valid = call_594289.validator(path, query, header, formData, body)
  let scheme = call_594289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594289.url(scheme.get, call_594289.host, call_594289.base,
                         call_594289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594289, url, valid)

proc call*(call_594290: Call_DescribeEvaluations_594275; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeEvaluations
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594291 = newJObject()
  var body_594292 = newJObject()
  add(query_594291, "Limit", newJString(Limit))
  add(query_594291, "NextToken", newJString(NextToken))
  if body != nil:
    body_594292 = body
  result = call_594290.call(nil, query_594291, nil, nil, body_594292)

var describeEvaluations* = Call_DescribeEvaluations_594275(
    name: "describeEvaluations", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeEvaluations",
    validator: validate_DescribeEvaluations_594276, base: "/",
    url: url_DescribeEvaluations_594277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMLModels_594293 = ref object of OpenApiRestCall_593437
proc url_DescribeMLModels_594295(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMLModels_594294(path: JsonNode; query: JsonNode;
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
  var valid_594296 = query.getOrDefault("Limit")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "Limit", valid_594296
  var valid_594297 = query.getOrDefault("NextToken")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "NextToken", valid_594297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594298 = header.getOrDefault("X-Amz-Date")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Date", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Security-Token")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Security-Token", valid_594299
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594300 = header.getOrDefault("X-Amz-Target")
  valid_594300 = validateParameter(valid_594300, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeMLModels"))
  if valid_594300 != nil:
    section.add "X-Amz-Target", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Content-Sha256", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Algorithm")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Algorithm", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Signature")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Signature", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-SignedHeaders", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Credential")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Credential", valid_594305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594307: Call_DescribeMLModels_594293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  let valid = call_594307.validator(path, query, header, formData, body)
  let scheme = call_594307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594307.url(scheme.get, call_594307.host, call_594307.base,
                         call_594307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594307, url, valid)

proc call*(call_594308: Call_DescribeMLModels_594293; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeMLModels
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594309 = newJObject()
  var body_594310 = newJObject()
  add(query_594309, "Limit", newJString(Limit))
  add(query_594309, "NextToken", newJString(NextToken))
  if body != nil:
    body_594310 = body
  result = call_594308.call(nil, query_594309, nil, nil, body_594310)

var describeMLModels* = Call_DescribeMLModels_594293(name: "describeMLModels",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeMLModels",
    validator: validate_DescribeMLModels_594294, base: "/",
    url: url_DescribeMLModels_594295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_594311 = ref object of OpenApiRestCall_593437
proc url_DescribeTags_594313(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTags_594312(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594314 = header.getOrDefault("X-Amz-Date")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Date", valid_594314
  var valid_594315 = header.getOrDefault("X-Amz-Security-Token")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "X-Amz-Security-Token", valid_594315
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594316 = header.getOrDefault("X-Amz-Target")
  valid_594316 = validateParameter(valid_594316, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeTags"))
  if valid_594316 != nil:
    section.add "X-Amz-Target", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Content-Sha256", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Algorithm")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Algorithm", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Signature")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Signature", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-SignedHeaders", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Credential")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Credential", valid_594321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_DescribeTags_594311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of the tags for your Amazon ML object.
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_DescribeTags_594311; body: JsonNode): Recallable =
  ## describeTags
  ## Describes one or more of the tags for your Amazon ML object.
  ##   body: JObject (required)
  var body_594325 = newJObject()
  if body != nil:
    body_594325 = body
  result = call_594324.call(nil, nil, nil, nil, body_594325)

var describeTags* = Call_DescribeTags_594311(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeTags",
    validator: validate_DescribeTags_594312, base: "/", url: url_DescribeTags_594313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPrediction_594326 = ref object of OpenApiRestCall_593437
proc url_GetBatchPrediction_594328(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBatchPrediction_594327(path: JsonNode; query: JsonNode;
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
  var valid_594329 = header.getOrDefault("X-Amz-Date")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Date", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Security-Token")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Security-Token", valid_594330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594331 = header.getOrDefault("X-Amz-Target")
  valid_594331 = validateParameter(valid_594331, JString, required = true, default = newJString(
      "AmazonML_20141212.GetBatchPrediction"))
  if valid_594331 != nil:
    section.add "X-Amz-Target", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Algorithm")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Algorithm", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Signature")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Signature", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-SignedHeaders", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Credential")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Credential", valid_594336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_GetBatchPrediction_594326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_GetBatchPrediction_594326; body: JsonNode): Recallable =
  ## getBatchPrediction
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ##   body: JObject (required)
  var body_594340 = newJObject()
  if body != nil:
    body_594340 = body
  result = call_594339.call(nil, nil, nil, nil, body_594340)

var getBatchPrediction* = Call_GetBatchPrediction_594326(
    name: "getBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetBatchPrediction",
    validator: validate_GetBatchPrediction_594327, base: "/",
    url: url_GetBatchPrediction_594328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_594341 = ref object of OpenApiRestCall_593437
proc url_GetDataSource_594343(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDataSource_594342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594344 = header.getOrDefault("X-Amz-Date")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Date", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-Security-Token")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-Security-Token", valid_594345
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594346 = header.getOrDefault("X-Amz-Target")
  valid_594346 = validateParameter(valid_594346, JString, required = true, default = newJString(
      "AmazonML_20141212.GetDataSource"))
  if valid_594346 != nil:
    section.add "X-Amz-Target", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Content-Sha256", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Algorithm")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Algorithm", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Signature")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Signature", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-SignedHeaders", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Credential")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Credential", valid_594351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594353: Call_GetDataSource_594341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ## 
  let valid = call_594353.validator(path, query, header, formData, body)
  let scheme = call_594353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594353.url(scheme.get, call_594353.host, call_594353.base,
                         call_594353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594353, url, valid)

proc call*(call_594354: Call_GetDataSource_594341; body: JsonNode): Recallable =
  ## getDataSource
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ##   body: JObject (required)
  var body_594355 = newJObject()
  if body != nil:
    body_594355 = body
  result = call_594354.call(nil, nil, nil, nil, body_594355)

var getDataSource* = Call_GetDataSource_594341(name: "getDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetDataSource",
    validator: validate_GetDataSource_594342, base: "/", url: url_GetDataSource_594343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEvaluation_594356 = ref object of OpenApiRestCall_593437
proc url_GetEvaluation_594358(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetEvaluation_594357(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594359 = header.getOrDefault("X-Amz-Date")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "X-Amz-Date", valid_594359
  var valid_594360 = header.getOrDefault("X-Amz-Security-Token")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "X-Amz-Security-Token", valid_594360
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594361 = header.getOrDefault("X-Amz-Target")
  valid_594361 = validateParameter(valid_594361, JString, required = true, default = newJString(
      "AmazonML_20141212.GetEvaluation"))
  if valid_594361 != nil:
    section.add "X-Amz-Target", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Content-Sha256", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Algorithm")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Algorithm", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Signature")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Signature", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-SignedHeaders", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Credential")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Credential", valid_594366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594368: Call_GetEvaluation_594356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ## 
  let valid = call_594368.validator(path, query, header, formData, body)
  let scheme = call_594368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594368.url(scheme.get, call_594368.host, call_594368.base,
                         call_594368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594368, url, valid)

proc call*(call_594369: Call_GetEvaluation_594356; body: JsonNode): Recallable =
  ## getEvaluation
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ##   body: JObject (required)
  var body_594370 = newJObject()
  if body != nil:
    body_594370 = body
  result = call_594369.call(nil, nil, nil, nil, body_594370)

var getEvaluation* = Call_GetEvaluation_594356(name: "getEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetEvaluation",
    validator: validate_GetEvaluation_594357, base: "/", url: url_GetEvaluation_594358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLModel_594371 = ref object of OpenApiRestCall_593437
proc url_GetMLModel_594373(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMLModel_594372(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594374 = header.getOrDefault("X-Amz-Date")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Date", valid_594374
  var valid_594375 = header.getOrDefault("X-Amz-Security-Token")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "X-Amz-Security-Token", valid_594375
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594376 = header.getOrDefault("X-Amz-Target")
  valid_594376 = validateParameter(valid_594376, JString, required = true, default = newJString(
      "AmazonML_20141212.GetMLModel"))
  if valid_594376 != nil:
    section.add "X-Amz-Target", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Content-Sha256", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Algorithm")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Algorithm", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Signature")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Signature", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-SignedHeaders", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Credential")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Credential", valid_594381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594383: Call_GetMLModel_594371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ## 
  let valid = call_594383.validator(path, query, header, formData, body)
  let scheme = call_594383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594383.url(scheme.get, call_594383.host, call_594383.base,
                         call_594383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594383, url, valid)

proc call*(call_594384: Call_GetMLModel_594371; body: JsonNode): Recallable =
  ## getMLModel
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ##   body: JObject (required)
  var body_594385 = newJObject()
  if body != nil:
    body_594385 = body
  result = call_594384.call(nil, nil, nil, nil, body_594385)

var getMLModel* = Call_GetMLModel_594371(name: "getMLModel",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.GetMLModel",
                                      validator: validate_GetMLModel_594372,
                                      base: "/", url: url_GetMLModel_594373,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Predict_594386 = ref object of OpenApiRestCall_593437
proc url_Predict_594388(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_Predict_594387(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594389 = header.getOrDefault("X-Amz-Date")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Date", valid_594389
  var valid_594390 = header.getOrDefault("X-Amz-Security-Token")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = nil)
  if valid_594390 != nil:
    section.add "X-Amz-Security-Token", valid_594390
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594391 = header.getOrDefault("X-Amz-Target")
  valid_594391 = validateParameter(valid_594391, JString, required = true, default = newJString(
      "AmazonML_20141212.Predict"))
  if valid_594391 != nil:
    section.add "X-Amz-Target", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Content-Sha256", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Algorithm")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Algorithm", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Signature")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Signature", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-SignedHeaders", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Credential")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Credential", valid_594396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594398: Call_Predict_594386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ## 
  let valid = call_594398.validator(path, query, header, formData, body)
  let scheme = call_594398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594398.url(scheme.get, call_594398.host, call_594398.base,
                         call_594398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594398, url, valid)

proc call*(call_594399: Call_Predict_594386; body: JsonNode): Recallable =
  ## predict
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ##   body: JObject (required)
  var body_594400 = newJObject()
  if body != nil:
    body_594400 = body
  result = call_594399.call(nil, nil, nil, nil, body_594400)

var predict* = Call_Predict_594386(name: "predict", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.Predict",
                                validator: validate_Predict_594387, base: "/",
                                url: url_Predict_594388,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBatchPrediction_594401 = ref object of OpenApiRestCall_593437
proc url_UpdateBatchPrediction_594403(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateBatchPrediction_594402(path: JsonNode; query: JsonNode;
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
  var valid_594404 = header.getOrDefault("X-Amz-Date")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Date", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Security-Token")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Security-Token", valid_594405
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594406 = header.getOrDefault("X-Amz-Target")
  valid_594406 = validateParameter(valid_594406, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateBatchPrediction"))
  if valid_594406 != nil:
    section.add "X-Amz-Target", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Content-Sha256", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Algorithm")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Algorithm", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Signature")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Signature", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-SignedHeaders", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Credential")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Credential", valid_594411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594413: Call_UpdateBatchPrediction_594401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_594413.validator(path, query, header, formData, body)
  let scheme = call_594413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594413.url(scheme.get, call_594413.host, call_594413.base,
                         call_594413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594413, url, valid)

proc call*(call_594414: Call_UpdateBatchPrediction_594401; body: JsonNode): Recallable =
  ## updateBatchPrediction
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_594415 = newJObject()
  if body != nil:
    body_594415 = body
  result = call_594414.call(nil, nil, nil, nil, body_594415)

var updateBatchPrediction* = Call_UpdateBatchPrediction_594401(
    name: "updateBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateBatchPrediction",
    validator: validate_UpdateBatchPrediction_594402, base: "/",
    url: url_UpdateBatchPrediction_594403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_594416 = ref object of OpenApiRestCall_593437
proc url_UpdateDataSource_594418(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDataSource_594417(path: JsonNode; query: JsonNode;
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
  var valid_594419 = header.getOrDefault("X-Amz-Date")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Date", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Security-Token")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Security-Token", valid_594420
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594421 = header.getOrDefault("X-Amz-Target")
  valid_594421 = validateParameter(valid_594421, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateDataSource"))
  if valid_594421 != nil:
    section.add "X-Amz-Target", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Content-Sha256", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Algorithm")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Algorithm", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Signature")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Signature", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-SignedHeaders", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Credential")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Credential", valid_594426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594428: Call_UpdateDataSource_594416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_594428.validator(path, query, header, formData, body)
  let scheme = call_594428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594428.url(scheme.get, call_594428.host, call_594428.base,
                         call_594428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594428, url, valid)

proc call*(call_594429: Call_UpdateDataSource_594416; body: JsonNode): Recallable =
  ## updateDataSource
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_594430 = newJObject()
  if body != nil:
    body_594430 = body
  result = call_594429.call(nil, nil, nil, nil, body_594430)

var updateDataSource* = Call_UpdateDataSource_594416(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateDataSource",
    validator: validate_UpdateDataSource_594417, base: "/",
    url: url_UpdateDataSource_594418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEvaluation_594431 = ref object of OpenApiRestCall_593437
proc url_UpdateEvaluation_594433(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateEvaluation_594432(path: JsonNode; query: JsonNode;
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
  var valid_594434 = header.getOrDefault("X-Amz-Date")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Date", valid_594434
  var valid_594435 = header.getOrDefault("X-Amz-Security-Token")
  valid_594435 = validateParameter(valid_594435, JString, required = false,
                                 default = nil)
  if valid_594435 != nil:
    section.add "X-Amz-Security-Token", valid_594435
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594436 = header.getOrDefault("X-Amz-Target")
  valid_594436 = validateParameter(valid_594436, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateEvaluation"))
  if valid_594436 != nil:
    section.add "X-Amz-Target", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Content-Sha256", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Algorithm")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Algorithm", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Signature")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Signature", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-SignedHeaders", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Credential")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Credential", valid_594441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594443: Call_UpdateEvaluation_594431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_594443.validator(path, query, header, formData, body)
  let scheme = call_594443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594443.url(scheme.get, call_594443.host, call_594443.base,
                         call_594443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594443, url, valid)

proc call*(call_594444: Call_UpdateEvaluation_594431; body: JsonNode): Recallable =
  ## updateEvaluation
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_594445 = newJObject()
  if body != nil:
    body_594445 = body
  result = call_594444.call(nil, nil, nil, nil, body_594445)

var updateEvaluation* = Call_UpdateEvaluation_594431(name: "updateEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateEvaluation",
    validator: validate_UpdateEvaluation_594432, base: "/",
    url: url_UpdateEvaluation_594433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLModel_594446 = ref object of OpenApiRestCall_593437
proc url_UpdateMLModel_594448(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateMLModel_594447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594449 = header.getOrDefault("X-Amz-Date")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Date", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Security-Token")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Security-Token", valid_594450
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594451 = header.getOrDefault("X-Amz-Target")
  valid_594451 = validateParameter(valid_594451, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateMLModel"))
  if valid_594451 != nil:
    section.add "X-Amz-Target", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Content-Sha256", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Algorithm")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Algorithm", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Signature")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Signature", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-SignedHeaders", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Credential")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Credential", valid_594456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594458: Call_UpdateMLModel_594446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_594458.validator(path, query, header, formData, body)
  let scheme = call_594458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594458.url(scheme.get, call_594458.host, call_594458.base,
                         call_594458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594458, url, valid)

proc call*(call_594459: Call_UpdateMLModel_594446; body: JsonNode): Recallable =
  ## updateMLModel
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_594460 = newJObject()
  if body != nil:
    body_594460 = body
  result = call_594459.call(nil, nil, nil, nil, body_594460)

var updateMLModel* = Call_UpdateMLModel_594446(name: "updateMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateMLModel",
    validator: validate_UpdateMLModel_594447, base: "/", url: url_UpdateMLModel_594448,
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
