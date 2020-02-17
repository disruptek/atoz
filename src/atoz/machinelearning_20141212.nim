
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_610996 = ref object of OpenApiRestCall_610658
proc url_AddTags_610998(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_610997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AmazonML_20141212.AddTags"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AddTags_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AddTags_610996; body: JsonNode): Recallable =
  ## addTags
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var addTags* = Call_AddTags_610996(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.AddTags",
                                validator: validate_AddTags_610997, base: "/",
                                url: url_AddTags_610998,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBatchPrediction_611265 = ref object of OpenApiRestCall_610658
proc url_CreateBatchPrediction_611267(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBatchPrediction_611266(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateBatchPrediction"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_CreateBatchPrediction_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CreateBatchPrediction_611265; body: JsonNode): Recallable =
  ## createBatchPrediction
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var createBatchPrediction* = Call_CreateBatchPrediction_611265(
    name: "createBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateBatchPrediction",
    validator: validate_CreateBatchPrediction_611266, base: "/",
    url: url_CreateBatchPrediction_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRDS_611280 = ref object of OpenApiRestCall_610658
proc url_CreateDataSourceFromRDS_611282(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSourceFromRDS_611281(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRDS"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CreateDataSourceFromRDS_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CreateDataSourceFromRDS_611280; body: JsonNode): Recallable =
  ## createDataSourceFromRDS
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var createDataSourceFromRDS* = Call_CreateDataSourceFromRDS_611280(
    name: "createDataSourceFromRDS", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRDS",
    validator: validate_CreateDataSourceFromRDS_611281, base: "/",
    url: url_CreateDataSourceFromRDS_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRedshift_611295 = ref object of OpenApiRestCall_610658
proc url_CreateDataSourceFromRedshift_611297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSourceFromRedshift_611296(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRedshift"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_CreateDataSourceFromRedshift_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CreateDataSourceFromRedshift_611295; body: JsonNode): Recallable =
  ## createDataSourceFromRedshift
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var createDataSourceFromRedshift* = Call_CreateDataSourceFromRedshift_611295(
    name: "createDataSourceFromRedshift", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRedshift",
    validator: validate_CreateDataSourceFromRedshift_611296, base: "/",
    url: url_CreateDataSourceFromRedshift_611297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromS3_611310 = ref object of OpenApiRestCall_610658
proc url_CreateDataSourceFromS3_611312(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSourceFromS3_611311(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromS3"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_CreateDataSourceFromS3_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_CreateDataSourceFromS3_611310; body: JsonNode): Recallable =
  ## createDataSourceFromS3
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var createDataSourceFromS3* = Call_CreateDataSourceFromS3_611310(
    name: "createDataSourceFromS3", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromS3",
    validator: validate_CreateDataSourceFromS3_611311, base: "/",
    url: url_CreateDataSourceFromS3_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEvaluation_611325 = ref object of OpenApiRestCall_610658
proc url_CreateEvaluation_611327(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEvaluation_611326(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateEvaluation"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_CreateEvaluation_611325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_CreateEvaluation_611325; body: JsonNode): Recallable =
  ## createEvaluation
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var createEvaluation* = Call_CreateEvaluation_611325(name: "createEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateEvaluation",
    validator: validate_CreateEvaluation_611326, base: "/",
    url: url_CreateEvaluation_611327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLModel_611340 = ref object of OpenApiRestCall_610658
proc url_CreateMLModel_611342(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMLModel_611341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateMLModel"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_CreateMLModel_611340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_CreateMLModel_611340; body: JsonNode): Recallable =
  ## createMLModel
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var createMLModel* = Call_CreateMLModel_611340(name: "createMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateMLModel",
    validator: validate_CreateMLModel_611341, base: "/", url: url_CreateMLModel_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRealtimeEndpoint_611355 = ref object of OpenApiRestCall_610658
proc url_CreateRealtimeEndpoint_611357(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRealtimeEndpoint_611356(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateRealtimeEndpoint"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_CreateRealtimeEndpoint_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_CreateRealtimeEndpoint_611355; body: JsonNode): Recallable =
  ## createRealtimeEndpoint
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var createRealtimeEndpoint* = Call_CreateRealtimeEndpoint_611355(
    name: "createRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateRealtimeEndpoint",
    validator: validate_CreateRealtimeEndpoint_611356, base: "/",
    url: url_CreateRealtimeEndpoint_611357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBatchPrediction_611370 = ref object of OpenApiRestCall_610658
proc url_DeleteBatchPrediction_611372(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBatchPrediction_611371(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611373 = header.getOrDefault("X-Amz-Target")
  valid_611373 = validateParameter(valid_611373, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteBatchPrediction"))
  if valid_611373 != nil:
    section.add "X-Amz-Target", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Signature")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Signature", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Content-Sha256", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Date")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Date", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Credential")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Credential", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Security-Token")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Security-Token", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Algorithm")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Algorithm", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-SignedHeaders", valid_611380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611382: Call_DeleteBatchPrediction_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ## 
  let valid = call_611382.validator(path, query, header, formData, body)
  let scheme = call_611382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611382.url(scheme.get, call_611382.host, call_611382.base,
                         call_611382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611382, url, valid)

proc call*(call_611383: Call_DeleteBatchPrediction_611370; body: JsonNode): Recallable =
  ## deleteBatchPrediction
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_611384 = newJObject()
  if body != nil:
    body_611384 = body
  result = call_611383.call(nil, nil, nil, nil, body_611384)

var deleteBatchPrediction* = Call_DeleteBatchPrediction_611370(
    name: "deleteBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteBatchPrediction",
    validator: validate_DeleteBatchPrediction_611371, base: "/",
    url: url_DeleteBatchPrediction_611372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_611385 = ref object of OpenApiRestCall_610658
proc url_DeleteDataSource_611387(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDataSource_611386(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611388 = header.getOrDefault("X-Amz-Target")
  valid_611388 = validateParameter(valid_611388, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteDataSource"))
  if valid_611388 != nil:
    section.add "X-Amz-Target", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Signature")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Signature", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Content-Sha256", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Date")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Date", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Credential")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Credential", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Security-Token")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Security-Token", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Algorithm")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Algorithm", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-SignedHeaders", valid_611395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611397: Call_DeleteDataSource_611385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ## 
  let valid = call_611397.validator(path, query, header, formData, body)
  let scheme = call_611397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611397.url(scheme.get, call_611397.host, call_611397.base,
                         call_611397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611397, url, valid)

proc call*(call_611398: Call_DeleteDataSource_611385; body: JsonNode): Recallable =
  ## deleteDataSource
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ##   body: JObject (required)
  var body_611399 = newJObject()
  if body != nil:
    body_611399 = body
  result = call_611398.call(nil, nil, nil, nil, body_611399)

var deleteDataSource* = Call_DeleteDataSource_611385(name: "deleteDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteDataSource",
    validator: validate_DeleteDataSource_611386, base: "/",
    url: url_DeleteDataSource_611387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluation_611400 = ref object of OpenApiRestCall_610658
proc url_DeleteEvaluation_611402(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvaluation_611401(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611403 = header.getOrDefault("X-Amz-Target")
  valid_611403 = validateParameter(valid_611403, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteEvaluation"))
  if valid_611403 != nil:
    section.add "X-Amz-Target", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611412: Call_DeleteEvaluation_611400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ## 
  let valid = call_611412.validator(path, query, header, formData, body)
  let scheme = call_611412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611412.url(scheme.get, call_611412.host, call_611412.base,
                         call_611412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611412, url, valid)

proc call*(call_611413: Call_DeleteEvaluation_611400; body: JsonNode): Recallable =
  ## deleteEvaluation
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ##   body: JObject (required)
  var body_611414 = newJObject()
  if body != nil:
    body_611414 = body
  result = call_611413.call(nil, nil, nil, nil, body_611414)

var deleteEvaluation* = Call_DeleteEvaluation_611400(name: "deleteEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteEvaluation",
    validator: validate_DeleteEvaluation_611401, base: "/",
    url: url_DeleteEvaluation_611402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLModel_611415 = ref object of OpenApiRestCall_610658
proc url_DeleteMLModel_611417(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMLModel_611416(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611418 = header.getOrDefault("X-Amz-Target")
  valid_611418 = validateParameter(valid_611418, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteMLModel"))
  if valid_611418 != nil:
    section.add "X-Amz-Target", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611427: Call_DeleteMLModel_611415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ## 
  let valid = call_611427.validator(path, query, header, formData, body)
  let scheme = call_611427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611427.url(scheme.get, call_611427.host, call_611427.base,
                         call_611427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611427, url, valid)

proc call*(call_611428: Call_DeleteMLModel_611415; body: JsonNode): Recallable =
  ## deleteMLModel
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_611429 = newJObject()
  if body != nil:
    body_611429 = body
  result = call_611428.call(nil, nil, nil, nil, body_611429)

var deleteMLModel* = Call_DeleteMLModel_611415(name: "deleteMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteMLModel",
    validator: validate_DeleteMLModel_611416, base: "/", url: url_DeleteMLModel_611417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRealtimeEndpoint_611430 = ref object of OpenApiRestCall_610658
proc url_DeleteRealtimeEndpoint_611432(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRealtimeEndpoint_611431(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611433 = header.getOrDefault("X-Amz-Target")
  valid_611433 = validateParameter(valid_611433, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteRealtimeEndpoint"))
  if valid_611433 != nil:
    section.add "X-Amz-Target", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Signature")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Signature", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Content-Sha256", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Date")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Date", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Credential")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Credential", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Security-Token")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Security-Token", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Algorithm")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Algorithm", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-SignedHeaders", valid_611440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611442: Call_DeleteRealtimeEndpoint_611430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ## 
  let valid = call_611442.validator(path, query, header, formData, body)
  let scheme = call_611442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611442.url(scheme.get, call_611442.host, call_611442.base,
                         call_611442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611442, url, valid)

proc call*(call_611443: Call_DeleteRealtimeEndpoint_611430; body: JsonNode): Recallable =
  ## deleteRealtimeEndpoint
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ##   body: JObject (required)
  var body_611444 = newJObject()
  if body != nil:
    body_611444 = body
  result = call_611443.call(nil, nil, nil, nil, body_611444)

var deleteRealtimeEndpoint* = Call_DeleteRealtimeEndpoint_611430(
    name: "deleteRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteRealtimeEndpoint",
    validator: validate_DeleteRealtimeEndpoint_611431, base: "/",
    url: url_DeleteRealtimeEndpoint_611432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_611445 = ref object of OpenApiRestCall_610658
proc url_DeleteTags_611447(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_611446(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Target")
  valid_611448 = validateParameter(valid_611448, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteTags"))
  if valid_611448 != nil:
    section.add "X-Amz-Target", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Signature")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Signature", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Content-Sha256", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Date")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Date", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Credential")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Credential", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Security-Token")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Security-Token", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Algorithm")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Algorithm", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-SignedHeaders", valid_611455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611457: Call_DeleteTags_611445; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ## 
  let valid = call_611457.validator(path, query, header, formData, body)
  let scheme = call_611457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611457.url(scheme.get, call_611457.host, call_611457.base,
                         call_611457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611457, url, valid)

proc call*(call_611458: Call_DeleteTags_611445; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ##   body: JObject (required)
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  result = call_611458.call(nil, nil, nil, nil, body_611459)

var deleteTags* = Call_DeleteTags_611445(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.DeleteTags",
                                      validator: validate_DeleteTags_611446,
                                      base: "/", url: url_DeleteTags_611447,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBatchPredictions_611460 = ref object of OpenApiRestCall_610658
proc url_DescribeBatchPredictions_611462(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeBatchPredictions_611461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_611463 = query.getOrDefault("NextToken")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "NextToken", valid_611463
  var valid_611464 = query.getOrDefault("Limit")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "Limit", valid_611464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611465 = header.getOrDefault("X-Amz-Target")
  valid_611465 = validateParameter(valid_611465, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeBatchPredictions"))
  if valid_611465 != nil:
    section.add "X-Amz-Target", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Signature")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Signature", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Content-Sha256", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Date")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Date", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Credential")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Credential", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Security-Token")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Security-Token", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Algorithm")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Algorithm", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-SignedHeaders", valid_611472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611474: Call_DescribeBatchPredictions_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  let valid = call_611474.validator(path, query, header, formData, body)
  let scheme = call_611474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611474.url(scheme.get, call_611474.host, call_611474.base,
                         call_611474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611474, url, valid)

proc call*(call_611475: Call_DescribeBatchPredictions_611460; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeBatchPredictions
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_611476 = newJObject()
  var body_611477 = newJObject()
  add(query_611476, "NextToken", newJString(NextToken))
  add(query_611476, "Limit", newJString(Limit))
  if body != nil:
    body_611477 = body
  result = call_611475.call(nil, query_611476, nil, nil, body_611477)

var describeBatchPredictions* = Call_DescribeBatchPredictions_611460(
    name: "describeBatchPredictions", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeBatchPredictions",
    validator: validate_DescribeBatchPredictions_611461, base: "/",
    url: url_DescribeBatchPredictions_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSources_611479 = ref object of OpenApiRestCall_610658
proc url_DescribeDataSources_611481(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataSources_611480(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_611482 = query.getOrDefault("NextToken")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "NextToken", valid_611482
  var valid_611483 = query.getOrDefault("Limit")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "Limit", valid_611483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611484 = header.getOrDefault("X-Amz-Target")
  valid_611484 = validateParameter(valid_611484, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeDataSources"))
  if valid_611484 != nil:
    section.add "X-Amz-Target", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Signature")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Signature", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Content-Sha256", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Date")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Date", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Credential")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Credential", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Security-Token")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Security-Token", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Algorithm")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Algorithm", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-SignedHeaders", valid_611491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611493: Call_DescribeDataSources_611479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  let valid = call_611493.validator(path, query, header, formData, body)
  let scheme = call_611493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611493.url(scheme.get, call_611493.host, call_611493.base,
                         call_611493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611493, url, valid)

proc call*(call_611494: Call_DescribeDataSources_611479; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeDataSources
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_611495 = newJObject()
  var body_611496 = newJObject()
  add(query_611495, "NextToken", newJString(NextToken))
  add(query_611495, "Limit", newJString(Limit))
  if body != nil:
    body_611496 = body
  result = call_611494.call(nil, query_611495, nil, nil, body_611496)

var describeDataSources* = Call_DescribeDataSources_611479(
    name: "describeDataSources", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeDataSources",
    validator: validate_DescribeDataSources_611480, base: "/",
    url: url_DescribeDataSources_611481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvaluations_611497 = ref object of OpenApiRestCall_610658
proc url_DescribeEvaluations_611499(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvaluations_611498(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_611500 = query.getOrDefault("NextToken")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "NextToken", valid_611500
  var valid_611501 = query.getOrDefault("Limit")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "Limit", valid_611501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611502 = header.getOrDefault("X-Amz-Target")
  valid_611502 = validateParameter(valid_611502, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeEvaluations"))
  if valid_611502 != nil:
    section.add "X-Amz-Target", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Signature")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Signature", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Content-Sha256", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Date")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Date", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Credential")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Credential", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Security-Token")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Security-Token", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Algorithm")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Algorithm", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-SignedHeaders", valid_611509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611511: Call_DescribeEvaluations_611497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  let valid = call_611511.validator(path, query, header, formData, body)
  let scheme = call_611511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611511.url(scheme.get, call_611511.host, call_611511.base,
                         call_611511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611511, url, valid)

proc call*(call_611512: Call_DescribeEvaluations_611497; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeEvaluations
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_611513 = newJObject()
  var body_611514 = newJObject()
  add(query_611513, "NextToken", newJString(NextToken))
  add(query_611513, "Limit", newJString(Limit))
  if body != nil:
    body_611514 = body
  result = call_611512.call(nil, query_611513, nil, nil, body_611514)

var describeEvaluations* = Call_DescribeEvaluations_611497(
    name: "describeEvaluations", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeEvaluations",
    validator: validate_DescribeEvaluations_611498, base: "/",
    url: url_DescribeEvaluations_611499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMLModels_611515 = ref object of OpenApiRestCall_610658
proc url_DescribeMLModels_611517(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMLModels_611516(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_611518 = query.getOrDefault("NextToken")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "NextToken", valid_611518
  var valid_611519 = query.getOrDefault("Limit")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "Limit", valid_611519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611520 = header.getOrDefault("X-Amz-Target")
  valid_611520 = validateParameter(valid_611520, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeMLModels"))
  if valid_611520 != nil:
    section.add "X-Amz-Target", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Signature")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Signature", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Content-Sha256", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Date")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Date", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Credential")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Credential", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Security-Token")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Security-Token", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Algorithm")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Algorithm", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-SignedHeaders", valid_611527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611529: Call_DescribeMLModels_611515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  let valid = call_611529.validator(path, query, header, formData, body)
  let scheme = call_611529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611529.url(scheme.get, call_611529.host, call_611529.base,
                         call_611529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611529, url, valid)

proc call*(call_611530: Call_DescribeMLModels_611515; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeMLModels
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_611531 = newJObject()
  var body_611532 = newJObject()
  add(query_611531, "NextToken", newJString(NextToken))
  add(query_611531, "Limit", newJString(Limit))
  if body != nil:
    body_611532 = body
  result = call_611530.call(nil, query_611531, nil, nil, body_611532)

var describeMLModels* = Call_DescribeMLModels_611515(name: "describeMLModels",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeMLModels",
    validator: validate_DescribeMLModels_611516, base: "/",
    url: url_DescribeMLModels_611517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_611533 = ref object of OpenApiRestCall_610658
proc url_DescribeTags_611535(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_611534(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611536 = header.getOrDefault("X-Amz-Target")
  valid_611536 = validateParameter(valid_611536, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeTags"))
  if valid_611536 != nil:
    section.add "X-Amz-Target", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Signature")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Signature", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Content-Sha256", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Date")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Date", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Credential")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Credential", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Security-Token")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Security-Token", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Algorithm")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Algorithm", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-SignedHeaders", valid_611543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611545: Call_DescribeTags_611533; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of the tags for your Amazon ML object.
  ## 
  let valid = call_611545.validator(path, query, header, formData, body)
  let scheme = call_611545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611545.url(scheme.get, call_611545.host, call_611545.base,
                         call_611545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611545, url, valid)

proc call*(call_611546: Call_DescribeTags_611533; body: JsonNode): Recallable =
  ## describeTags
  ## Describes one or more of the tags for your Amazon ML object.
  ##   body: JObject (required)
  var body_611547 = newJObject()
  if body != nil:
    body_611547 = body
  result = call_611546.call(nil, nil, nil, nil, body_611547)

var describeTags* = Call_DescribeTags_611533(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeTags",
    validator: validate_DescribeTags_611534, base: "/", url: url_DescribeTags_611535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPrediction_611548 = ref object of OpenApiRestCall_610658
proc url_GetBatchPrediction_611550(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPrediction_611549(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611551 = header.getOrDefault("X-Amz-Target")
  valid_611551 = validateParameter(valid_611551, JString, required = true, default = newJString(
      "AmazonML_20141212.GetBatchPrediction"))
  if valid_611551 != nil:
    section.add "X-Amz-Target", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Signature")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Signature", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Content-Sha256", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Date")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Date", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Credential")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Credential", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Security-Token")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Security-Token", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Algorithm")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Algorithm", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-SignedHeaders", valid_611558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_GetBatchPrediction_611548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_GetBatchPrediction_611548; body: JsonNode): Recallable =
  ## getBatchPrediction
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ##   body: JObject (required)
  var body_611562 = newJObject()
  if body != nil:
    body_611562 = body
  result = call_611561.call(nil, nil, nil, nil, body_611562)

var getBatchPrediction* = Call_GetBatchPrediction_611548(
    name: "getBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetBatchPrediction",
    validator: validate_GetBatchPrediction_611549, base: "/",
    url: url_GetBatchPrediction_611550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_611563 = ref object of OpenApiRestCall_610658
proc url_GetDataSource_611565(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataSource_611564(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611566 = header.getOrDefault("X-Amz-Target")
  valid_611566 = validateParameter(valid_611566, JString, required = true, default = newJString(
      "AmazonML_20141212.GetDataSource"))
  if valid_611566 != nil:
    section.add "X-Amz-Target", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Signature")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Signature", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Content-Sha256", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Date")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Date", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Credential")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Credential", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Security-Token")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Security-Token", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Algorithm")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Algorithm", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-SignedHeaders", valid_611573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611575: Call_GetDataSource_611563; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ## 
  let valid = call_611575.validator(path, query, header, formData, body)
  let scheme = call_611575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611575.url(scheme.get, call_611575.host, call_611575.base,
                         call_611575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611575, url, valid)

proc call*(call_611576: Call_GetDataSource_611563; body: JsonNode): Recallable =
  ## getDataSource
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ##   body: JObject (required)
  var body_611577 = newJObject()
  if body != nil:
    body_611577 = body
  result = call_611576.call(nil, nil, nil, nil, body_611577)

var getDataSource* = Call_GetDataSource_611563(name: "getDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetDataSource",
    validator: validate_GetDataSource_611564, base: "/", url: url_GetDataSource_611565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEvaluation_611578 = ref object of OpenApiRestCall_610658
proc url_GetEvaluation_611580(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEvaluation_611579(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611581 = header.getOrDefault("X-Amz-Target")
  valid_611581 = validateParameter(valid_611581, JString, required = true, default = newJString(
      "AmazonML_20141212.GetEvaluation"))
  if valid_611581 != nil:
    section.add "X-Amz-Target", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Signature")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Signature", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Content-Sha256", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Date")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Date", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Credential")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Credential", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Security-Token")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Security-Token", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Algorithm")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Algorithm", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-SignedHeaders", valid_611588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611590: Call_GetEvaluation_611578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ## 
  let valid = call_611590.validator(path, query, header, formData, body)
  let scheme = call_611590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611590.url(scheme.get, call_611590.host, call_611590.base,
                         call_611590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611590, url, valid)

proc call*(call_611591: Call_GetEvaluation_611578; body: JsonNode): Recallable =
  ## getEvaluation
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ##   body: JObject (required)
  var body_611592 = newJObject()
  if body != nil:
    body_611592 = body
  result = call_611591.call(nil, nil, nil, nil, body_611592)

var getEvaluation* = Call_GetEvaluation_611578(name: "getEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetEvaluation",
    validator: validate_GetEvaluation_611579, base: "/", url: url_GetEvaluation_611580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLModel_611593 = ref object of OpenApiRestCall_610658
proc url_GetMLModel_611595(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMLModel_611594(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611596 = header.getOrDefault("X-Amz-Target")
  valid_611596 = validateParameter(valid_611596, JString, required = true, default = newJString(
      "AmazonML_20141212.GetMLModel"))
  if valid_611596 != nil:
    section.add "X-Amz-Target", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Signature")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Signature", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Content-Sha256", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Date")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Date", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Credential")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Credential", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Security-Token")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Security-Token", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Algorithm")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Algorithm", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-SignedHeaders", valid_611603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611605: Call_GetMLModel_611593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ## 
  let valid = call_611605.validator(path, query, header, formData, body)
  let scheme = call_611605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611605.url(scheme.get, call_611605.host, call_611605.base,
                         call_611605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611605, url, valid)

proc call*(call_611606: Call_GetMLModel_611593; body: JsonNode): Recallable =
  ## getMLModel
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ##   body: JObject (required)
  var body_611607 = newJObject()
  if body != nil:
    body_611607 = body
  result = call_611606.call(nil, nil, nil, nil, body_611607)

var getMLModel* = Call_GetMLModel_611593(name: "getMLModel",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.GetMLModel",
                                      validator: validate_GetMLModel_611594,
                                      base: "/", url: url_GetMLModel_611595,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Predict_611608 = ref object of OpenApiRestCall_610658
proc url_Predict_611610(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_Predict_611609(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611611 = header.getOrDefault("X-Amz-Target")
  valid_611611 = validateParameter(valid_611611, JString, required = true, default = newJString(
      "AmazonML_20141212.Predict"))
  if valid_611611 != nil:
    section.add "X-Amz-Target", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Signature")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Signature", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Content-Sha256", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Date")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Date", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Credential")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Credential", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Security-Token")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Security-Token", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Algorithm")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Algorithm", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-SignedHeaders", valid_611618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611620: Call_Predict_611608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ## 
  let valid = call_611620.validator(path, query, header, formData, body)
  let scheme = call_611620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611620.url(scheme.get, call_611620.host, call_611620.base,
                         call_611620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611620, url, valid)

proc call*(call_611621: Call_Predict_611608; body: JsonNode): Recallable =
  ## predict
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ##   body: JObject (required)
  var body_611622 = newJObject()
  if body != nil:
    body_611622 = body
  result = call_611621.call(nil, nil, nil, nil, body_611622)

var predict* = Call_Predict_611608(name: "predict", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.Predict",
                                validator: validate_Predict_611609, base: "/",
                                url: url_Predict_611610,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBatchPrediction_611623 = ref object of OpenApiRestCall_610658
proc url_UpdateBatchPrediction_611625(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateBatchPrediction_611624(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611626 = header.getOrDefault("X-Amz-Target")
  valid_611626 = validateParameter(valid_611626, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateBatchPrediction"))
  if valid_611626 != nil:
    section.add "X-Amz-Target", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Signature")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Signature", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Content-Sha256", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Date")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Date", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Credential")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Credential", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Security-Token")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Security-Token", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Algorithm")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Algorithm", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-SignedHeaders", valid_611633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611635: Call_UpdateBatchPrediction_611623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_611635.validator(path, query, header, formData, body)
  let scheme = call_611635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611635.url(scheme.get, call_611635.host, call_611635.base,
                         call_611635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611635, url, valid)

proc call*(call_611636: Call_UpdateBatchPrediction_611623; body: JsonNode): Recallable =
  ## updateBatchPrediction
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_611637 = newJObject()
  if body != nil:
    body_611637 = body
  result = call_611636.call(nil, nil, nil, nil, body_611637)

var updateBatchPrediction* = Call_UpdateBatchPrediction_611623(
    name: "updateBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateBatchPrediction",
    validator: validate_UpdateBatchPrediction_611624, base: "/",
    url: url_UpdateBatchPrediction_611625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_611638 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSource_611640(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDataSource_611639(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611641 = header.getOrDefault("X-Amz-Target")
  valid_611641 = validateParameter(valid_611641, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateDataSource"))
  if valid_611641 != nil:
    section.add "X-Amz-Target", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Signature")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Signature", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Content-Sha256", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Date")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Date", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Credential")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Credential", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Security-Token")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Security-Token", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Algorithm")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Algorithm", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-SignedHeaders", valid_611648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611650: Call_UpdateDataSource_611638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_611650.validator(path, query, header, formData, body)
  let scheme = call_611650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611650.url(scheme.get, call_611650.host, call_611650.base,
                         call_611650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611650, url, valid)

proc call*(call_611651: Call_UpdateDataSource_611638; body: JsonNode): Recallable =
  ## updateDataSource
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_611652 = newJObject()
  if body != nil:
    body_611652 = body
  result = call_611651.call(nil, nil, nil, nil, body_611652)

var updateDataSource* = Call_UpdateDataSource_611638(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateDataSource",
    validator: validate_UpdateDataSource_611639, base: "/",
    url: url_UpdateDataSource_611640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEvaluation_611653 = ref object of OpenApiRestCall_610658
proc url_UpdateEvaluation_611655(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEvaluation_611654(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611656 = header.getOrDefault("X-Amz-Target")
  valid_611656 = validateParameter(valid_611656, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateEvaluation"))
  if valid_611656 != nil:
    section.add "X-Amz-Target", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Signature")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Signature", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Content-Sha256", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Date")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Date", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Credential")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Credential", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Security-Token")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Security-Token", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Algorithm")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Algorithm", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-SignedHeaders", valid_611663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611665: Call_UpdateEvaluation_611653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_611665.validator(path, query, header, formData, body)
  let scheme = call_611665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611665.url(scheme.get, call_611665.host, call_611665.base,
                         call_611665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611665, url, valid)

proc call*(call_611666: Call_UpdateEvaluation_611653; body: JsonNode): Recallable =
  ## updateEvaluation
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_611667 = newJObject()
  if body != nil:
    body_611667 = body
  result = call_611666.call(nil, nil, nil, nil, body_611667)

var updateEvaluation* = Call_UpdateEvaluation_611653(name: "updateEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateEvaluation",
    validator: validate_UpdateEvaluation_611654, base: "/",
    url: url_UpdateEvaluation_611655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLModel_611668 = ref object of OpenApiRestCall_610658
proc url_UpdateMLModel_611670(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMLModel_611669(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611671 = header.getOrDefault("X-Amz-Target")
  valid_611671 = validateParameter(valid_611671, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateMLModel"))
  if valid_611671 != nil:
    section.add "X-Amz-Target", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Signature")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Signature", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Content-Sha256", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Date")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Date", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Credential")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Credential", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Security-Token")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Security-Token", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Algorithm")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Algorithm", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-SignedHeaders", valid_611678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611680: Call_UpdateMLModel_611668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_611680.validator(path, query, header, formData, body)
  let scheme = call_611680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611680.url(scheme.get, call_611680.host, call_611680.base,
                         call_611680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611680, url, valid)

proc call*(call_611681: Call_UpdateMLModel_611668; body: JsonNode): Recallable =
  ## updateMLModel
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_611682 = newJObject()
  if body != nil:
    body_611682 = body
  result = call_611681.call(nil, nil, nil, nil, body_611682)

var updateMLModel* = Call_UpdateMLModel_611668(name: "updateMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateMLModel",
    validator: validate_UpdateMLModel_611669, base: "/", url: url_UpdateMLModel_611670,
    schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
