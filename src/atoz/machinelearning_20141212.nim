
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AddTags_601727 = ref object of OpenApiRestCall_601389
proc url_AddTags_601729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AmazonML_20141212.AddTags"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AddTags_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AddTags_601727; body: JsonNode): Recallable =
  ## addTags
  ## Adds one or more tags to an object, up to a limit of 10. Each tag consists of a key and an optional value. If you add a tag using a key that is already associated with the ML object, <code>AddTags</code> updates the tag's value.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var addTags* = Call_AddTags_601727(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.AddTags",
                                validator: validate_AddTags_601728, base: "/",
                                url: url_AddTags_601729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBatchPrediction_601996 = ref object of OpenApiRestCall_601389
proc url_CreateBatchPrediction_601998(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBatchPrediction_601997(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateBatchPrediction"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CreateBatchPrediction_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreateBatchPrediction_601996; body: JsonNode): Recallable =
  ## createBatchPrediction
  ## <p>Generates predictions for a group of observations. The observations to process exist in one or more data files referenced by a <code>DataSource</code>. This operation creates a new <code>BatchPrediction</code>, and uses an <code>MLModel</code> and the data files referenced by the <code>DataSource</code> as information sources. </p> <p><code>CreateBatchPrediction</code> is an asynchronous operation. In response to <code>CreateBatchPrediction</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>BatchPrediction</code> status to <code>PENDING</code>. After the <code>BatchPrediction</code> completes, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can poll for status updates by using the <a>GetBatchPrediction</a> operation and checking the <code>Status</code> parameter of the result. After the <code>COMPLETED</code> status appears, the results are available in the location specified by the <code>OutputUri</code> parameter.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createBatchPrediction* = Call_CreateBatchPrediction_601996(
    name: "createBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateBatchPrediction",
    validator: validate_CreateBatchPrediction_601997, base: "/",
    url: url_CreateBatchPrediction_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRDS_602011 = ref object of OpenApiRestCall_601389
proc url_CreateDataSourceFromRDS_602013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSourceFromRDS_602012(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRDS"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateDataSourceFromRDS_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateDataSourceFromRDS_602011; body: JsonNode): Recallable =
  ## createDataSourceFromRDS
  ## <p>Creates a <code>DataSource</code> object from an <a href="http://aws.amazon.com/rds/"> Amazon Relational Database Service</a> (Amazon RDS). A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRDS</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRDS</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used only to perform <code>&gt;CreateMLModel</code>&gt;, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML cannot accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createDataSourceFromRDS* = Call_CreateDataSourceFromRDS_602011(
    name: "createDataSourceFromRDS", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRDS",
    validator: validate_CreateDataSourceFromRDS_602012, base: "/",
    url: url_CreateDataSourceFromRDS_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromRedshift_602026 = ref object of OpenApiRestCall_601389
proc url_CreateDataSourceFromRedshift_602028(protocol: Scheme; host: string;
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

proc validate_CreateDataSourceFromRedshift_602027(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromRedshift"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateDataSourceFromRedshift_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateDataSourceFromRedshift_602026; body: JsonNode): Recallable =
  ## createDataSourceFromRedshift
  ## <p>Creates a <code>DataSource</code> from a database hosted on an Amazon Redshift cluster. A <code>DataSource</code> references data that can be used to perform either <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromRedshift</code> is an asynchronous operation. In response to <code>CreateDataSourceFromRedshift</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> is created and ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in <code>COMPLETED</code> or <code>PENDING</code> states can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observations should be contained in the database hosted on an Amazon Redshift cluster and should be specified by a <code>SelectSqlQuery</code> query. Amazon ML executes an <code>Unload</code> command in Amazon Redshift to transfer the result set of the <code>SelectSqlQuery</code> query to <code>S3StagingLocation</code>.</p> <p>After the <code>DataSource</code> has been created, it's ready for use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also requires a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p> <?oxy_insert_start author="laurama" timestamp="20160406T153842-0700"><p>You can't change an existing datasource, but you can copy and modify the settings from an existing Amazon Redshift datasource to create a new datasource. To do so, call <code>GetDataSource</code> for an existing datasource and copy the values to a <code>CreateDataSource</code> call. Change the settings that you want to change and make sure that all required fields have the appropriate values.</p> <?oxy_insert_end>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createDataSourceFromRedshift* = Call_CreateDataSourceFromRedshift_602026(
    name: "createDataSourceFromRedshift", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromRedshift",
    validator: validate_CreateDataSourceFromRedshift_602027, base: "/",
    url: url_CreateDataSourceFromRedshift_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSourceFromS3_602041 = ref object of OpenApiRestCall_601389
proc url_CreateDataSourceFromS3_602043(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSourceFromS3_602042(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateDataSourceFromS3"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_CreateDataSourceFromS3_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateDataSourceFromS3_602041; body: JsonNode): Recallable =
  ## createDataSourceFromS3
  ## <p>Creates a <code>DataSource</code> object. A <code>DataSource</code> references data that can be used to perform <code>CreateMLModel</code>, <code>CreateEvaluation</code>, or <code>CreateBatchPrediction</code> operations.</p> <p><code>CreateDataSourceFromS3</code> is an asynchronous operation. In response to <code>CreateDataSourceFromS3</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>DataSource</code> status to <code>PENDING</code>. After the <code>DataSource</code> has been created and is ready for use, Amazon ML sets the <code>Status</code> parameter to <code>COMPLETED</code>. <code>DataSource</code> in the <code>COMPLETED</code> or <code>PENDING</code> state can be used to perform only <code>CreateMLModel</code>, <code>CreateEvaluation</code> or <code>CreateBatchPrediction</code> operations. </p> <p> If Amazon ML can't accept the input source, it sets the <code>Status</code> parameter to <code>FAILED</code> and includes an error message in the <code>Message</code> attribute of the <code>GetDataSource</code> operation response. </p> <p>The observation data used in a <code>DataSource</code> should be ready to use; that is, it should have a consistent structure, and missing data values should be kept to a minimum. The observation data must reside in one or more .csv files in an Amazon Simple Storage Service (Amazon S3) location, along with a schema that describes the data items by name and type. The same schema must be used for all of the data files referenced by the <code>DataSource</code>. </p> <p>After the <code>DataSource</code> has been created, it's ready to use in evaluations and batch predictions. If you plan to use the <code>DataSource</code> to train an <code>MLModel</code>, the <code>DataSource</code> also needs a recipe. A recipe describes how each input variable will be used in training an <code>MLModel</code>. Will the variable be included or excluded from training? Will the variable be manipulated; for example, will it be combined with another variable or will it be split apart into word combinations? The recipe provides answers to these questions.</p>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createDataSourceFromS3* = Call_CreateDataSourceFromS3_602041(
    name: "createDataSourceFromS3", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateDataSourceFromS3",
    validator: validate_CreateDataSourceFromS3_602042, base: "/",
    url: url_CreateDataSourceFromS3_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEvaluation_602056 = ref object of OpenApiRestCall_601389
proc url_CreateEvaluation_602058(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEvaluation_602057(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateEvaluation"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_CreateEvaluation_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CreateEvaluation_602056; body: JsonNode): Recallable =
  ## createEvaluation
  ## <p>Creates a new <code>Evaluation</code> of an <code>MLModel</code>. An <code>MLModel</code> is evaluated on a set of observations associated to a <code>DataSource</code>. Like a <code>DataSource</code> for an <code>MLModel</code>, the <code>DataSource</code> for an <code>Evaluation</code> contains values for the <code>Target Variable</code>. The <code>Evaluation</code> compares the predicted result for each observation to the actual outcome and provides a summary so that you know how effective the <code>MLModel</code> functions on the test data. Evaluation generates a relevant performance metric, such as BinaryAUC, RegressionRMSE or MulticlassAvgFScore based on the corresponding <code>MLModelType</code>: <code>BINARY</code>, <code>REGRESSION</code> or <code>MULTICLASS</code>. </p> <p><code>CreateEvaluation</code> is an asynchronous operation. In response to <code>CreateEvaluation</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the evaluation status to <code>PENDING</code>. After the <code>Evaluation</code> is created and ready for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetEvaluation</code> operation to check progress of the evaluation during the creation operation.</p>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var createEvaluation* = Call_CreateEvaluation_602056(name: "createEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateEvaluation",
    validator: validate_CreateEvaluation_602057, base: "/",
    url: url_CreateEvaluation_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLModel_602071 = ref object of OpenApiRestCall_601389
proc url_CreateMLModel_602073(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMLModel_602072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateMLModel"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_CreateMLModel_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_CreateMLModel_602071; body: JsonNode): Recallable =
  ## createMLModel
  ## <p>Creates a new <code>MLModel</code> using the <code>DataSource</code> and the recipe as information sources. </p> <p>An <code>MLModel</code> is nearly immutable. Users can update only the <code>MLModelName</code> and the <code>ScoreThreshold</code> in an <code>MLModel</code> without creating a new <code>MLModel</code>. </p> <p><code>CreateMLModel</code> is an asynchronous operation. In response to <code>CreateMLModel</code>, Amazon Machine Learning (Amazon ML) immediately returns and sets the <code>MLModel</code> status to <code>PENDING</code>. After the <code>MLModel</code> has been created and ready is for use, Amazon ML sets the status to <code>COMPLETED</code>. </p> <p>You can use the <code>GetMLModel</code> operation to check the progress of the <code>MLModel</code> during the creation operation.</p> <p> <code>CreateMLModel</code> requires a <code>DataSource</code> with computed statistics, which can be created by setting <code>ComputeStatistics</code> to <code>true</code> in <code>CreateDataSourceFromRDS</code>, <code>CreateDataSourceFromS3</code>, or <code>CreateDataSourceFromRedshift</code> operations. </p>
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var createMLModel* = Call_CreateMLModel_602071(name: "createMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateMLModel",
    validator: validate_CreateMLModel_602072, base: "/", url: url_CreateMLModel_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRealtimeEndpoint_602086 = ref object of OpenApiRestCall_601389
proc url_CreateRealtimeEndpoint_602088(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRealtimeEndpoint_602087(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "AmazonML_20141212.CreateRealtimeEndpoint"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_CreateRealtimeEndpoint_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_CreateRealtimeEndpoint_602086; body: JsonNode): Recallable =
  ## createRealtimeEndpoint
  ## Creates a real-time endpoint for the <code>MLModel</code>. The endpoint contains the URI of the <code>MLModel</code>; that is, the location to send real-time prediction requests for the specified <code>MLModel</code>.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var createRealtimeEndpoint* = Call_CreateRealtimeEndpoint_602086(
    name: "createRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.CreateRealtimeEndpoint",
    validator: validate_CreateRealtimeEndpoint_602087, base: "/",
    url: url_CreateRealtimeEndpoint_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBatchPrediction_602101 = ref object of OpenApiRestCall_601389
proc url_DeleteBatchPrediction_602103(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBatchPrediction_602102(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteBatchPrediction"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_DeleteBatchPrediction_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DeleteBatchPrediction_602101; body: JsonNode): Recallable =
  ## deleteBatchPrediction
  ## <p>Assigns the DELETED status to a <code>BatchPrediction</code>, rendering it unusable.</p> <p>After using the <code>DeleteBatchPrediction</code> operation, you can use the <a>GetBatchPrediction</a> operation to verify that the status of the <code>BatchPrediction</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteBatchPrediction</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var deleteBatchPrediction* = Call_DeleteBatchPrediction_602101(
    name: "deleteBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteBatchPrediction",
    validator: validate_DeleteBatchPrediction_602102, base: "/",
    url: url_DeleteBatchPrediction_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_602116 = ref object of OpenApiRestCall_601389
proc url_DeleteDataSource_602118(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDataSource_602117(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteDataSource"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_DeleteDataSource_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_DeleteDataSource_602116; body: JsonNode): Recallable =
  ## deleteDataSource
  ## <p>Assigns the DELETED status to a <code>DataSource</code>, rendering it unusable.</p> <p>After using the <code>DeleteDataSource</code> operation, you can use the <a>GetDataSource</a> operation to verify that the status of the <code>DataSource</code> changed to DELETED.</p> <p><b>Caution:</b> The results of the <code>DeleteDataSource</code> operation are irreversible.</p>
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var deleteDataSource* = Call_DeleteDataSource_602116(name: "deleteDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteDataSource",
    validator: validate_DeleteDataSource_602117, base: "/",
    url: url_DeleteDataSource_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluation_602131 = ref object of OpenApiRestCall_601389
proc url_DeleteEvaluation_602133(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteEvaluation_602132(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteEvaluation"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_DeleteEvaluation_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_DeleteEvaluation_602131; body: JsonNode): Recallable =
  ## deleteEvaluation
  ## <p>Assigns the <code>DELETED</code> status to an <code>Evaluation</code>, rendering it unusable.</p> <p>After invoking the <code>DeleteEvaluation</code> operation, you can use the <code>GetEvaluation</code> operation to verify that the status of the <code>Evaluation</code> changed to <code>DELETED</code>.</p> <caution><title>Caution</title> <p>The results of the <code>DeleteEvaluation</code> operation are irreversible.</p></caution>
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var deleteEvaluation* = Call_DeleteEvaluation_602131(name: "deleteEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteEvaluation",
    validator: validate_DeleteEvaluation_602132, base: "/",
    url: url_DeleteEvaluation_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLModel_602146 = ref object of OpenApiRestCall_601389
proc url_DeleteMLModel_602148(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMLModel_602147(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteMLModel"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_DeleteMLModel_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_DeleteMLModel_602146; body: JsonNode): Recallable =
  ## deleteMLModel
  ## <p>Assigns the <code>DELETED</code> status to an <code>MLModel</code>, rendering it unusable.</p> <p>After using the <code>DeleteMLModel</code> operation, you can use the <code>GetMLModel</code> operation to verify that the status of the <code>MLModel</code> changed to DELETED.</p> <p><b>Caution:</b> The result of the <code>DeleteMLModel</code> operation is irreversible.</p>
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var deleteMLModel* = Call_DeleteMLModel_602146(name: "deleteMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteMLModel",
    validator: validate_DeleteMLModel_602147, base: "/", url: url_DeleteMLModel_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRealtimeEndpoint_602161 = ref object of OpenApiRestCall_601389
proc url_DeleteRealtimeEndpoint_602163(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRealtimeEndpoint_602162(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteRealtimeEndpoint"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_DeleteRealtimeEndpoint_602161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_DeleteRealtimeEndpoint_602161; body: JsonNode): Recallable =
  ## deleteRealtimeEndpoint
  ## Deletes a real time endpoint of an <code>MLModel</code>.
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var deleteRealtimeEndpoint* = Call_DeleteRealtimeEndpoint_602161(
    name: "deleteRealtimeEndpoint", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DeleteRealtimeEndpoint",
    validator: validate_DeleteRealtimeEndpoint_602162, base: "/",
    url: url_DeleteRealtimeEndpoint_602163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_602176 = ref object of OpenApiRestCall_601389
proc url_DeleteTags_602178(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_602177(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "AmazonML_20141212.DeleteTags"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_DeleteTags_602176; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_DeleteTags_602176; body: JsonNode): Recallable =
  ## deleteTags
  ## <p>Deletes the specified tags associated with an ML object. After this operation is complete, you can't recover deleted tags.</p> <p>If you specify a tag that doesn't exist, Amazon ML ignores it.</p>
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var deleteTags* = Call_DeleteTags_602176(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.DeleteTags",
                                      validator: validate_DeleteTags_602177,
                                      base: "/", url: url_DeleteTags_602178,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeBatchPredictions_602191 = ref object of OpenApiRestCall_601389
proc url_DescribeBatchPredictions_602193(protocol: Scheme; host: string;
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

proc validate_DescribeBatchPredictions_602192(path: JsonNode; query: JsonNode;
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
  var valid_602194 = query.getOrDefault("NextToken")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "NextToken", valid_602194
  var valid_602195 = query.getOrDefault("Limit")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "Limit", valid_602195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602196 = header.getOrDefault("X-Amz-Target")
  valid_602196 = validateParameter(valid_602196, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeBatchPredictions"))
  if valid_602196 != nil:
    section.add "X-Amz-Target", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Date")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Date", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Credential")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Credential", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Security-Token")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Security-Token", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Algorithm")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Algorithm", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-SignedHeaders", valid_602203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602205: Call_DescribeBatchPredictions_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ## 
  let valid = call_602205.validator(path, query, header, formData, body)
  let scheme = call_602205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602205.url(scheme.get, call_602205.host, call_602205.base,
                         call_602205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602205, url, valid)

proc call*(call_602206: Call_DescribeBatchPredictions_602191; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeBatchPredictions
  ## Returns a list of <code>BatchPrediction</code> operations that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602207 = newJObject()
  var body_602208 = newJObject()
  add(query_602207, "NextToken", newJString(NextToken))
  add(query_602207, "Limit", newJString(Limit))
  if body != nil:
    body_602208 = body
  result = call_602206.call(nil, query_602207, nil, nil, body_602208)

var describeBatchPredictions* = Call_DescribeBatchPredictions_602191(
    name: "describeBatchPredictions", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeBatchPredictions",
    validator: validate_DescribeBatchPredictions_602192, base: "/",
    url: url_DescribeBatchPredictions_602193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSources_602210 = ref object of OpenApiRestCall_601389
proc url_DescribeDataSources_602212(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataSources_602211(path: JsonNode; query: JsonNode;
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
  var valid_602213 = query.getOrDefault("NextToken")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "NextToken", valid_602213
  var valid_602214 = query.getOrDefault("Limit")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Limit", valid_602214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602215 = header.getOrDefault("X-Amz-Target")
  valid_602215 = validateParameter(valid_602215, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeDataSources"))
  if valid_602215 != nil:
    section.add "X-Amz-Target", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Signature")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Signature", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Content-Sha256", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Date")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Date", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Credential")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Credential", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Security-Token")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Security-Token", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Algorithm")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Algorithm", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-SignedHeaders", valid_602222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602224: Call_DescribeDataSources_602210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ## 
  let valid = call_602224.validator(path, query, header, formData, body)
  let scheme = call_602224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602224.url(scheme.get, call_602224.host, call_602224.base,
                         call_602224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602224, url, valid)

proc call*(call_602225: Call_DescribeDataSources_602210; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeDataSources
  ## Returns a list of <code>DataSource</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602226 = newJObject()
  var body_602227 = newJObject()
  add(query_602226, "NextToken", newJString(NextToken))
  add(query_602226, "Limit", newJString(Limit))
  if body != nil:
    body_602227 = body
  result = call_602225.call(nil, query_602226, nil, nil, body_602227)

var describeDataSources* = Call_DescribeDataSources_602210(
    name: "describeDataSources", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeDataSources",
    validator: validate_DescribeDataSources_602211, base: "/",
    url: url_DescribeDataSources_602212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEvaluations_602228 = ref object of OpenApiRestCall_601389
proc url_DescribeEvaluations_602230(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEvaluations_602229(path: JsonNode; query: JsonNode;
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
  var valid_602231 = query.getOrDefault("NextToken")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "NextToken", valid_602231
  var valid_602232 = query.getOrDefault("Limit")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "Limit", valid_602232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602233 = header.getOrDefault("X-Amz-Target")
  valid_602233 = validateParameter(valid_602233, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeEvaluations"))
  if valid_602233 != nil:
    section.add "X-Amz-Target", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Content-Sha256", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Date")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Date", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Credential")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Credential", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Security-Token")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Security-Token", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Algorithm")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Algorithm", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-SignedHeaders", valid_602240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602242: Call_DescribeEvaluations_602228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ## 
  let valid = call_602242.validator(path, query, header, formData, body)
  let scheme = call_602242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602242.url(scheme.get, call_602242.host, call_602242.base,
                         call_602242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602242, url, valid)

proc call*(call_602243: Call_DescribeEvaluations_602228; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeEvaluations
  ## Returns a list of <code>DescribeEvaluations</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602244 = newJObject()
  var body_602245 = newJObject()
  add(query_602244, "NextToken", newJString(NextToken))
  add(query_602244, "Limit", newJString(Limit))
  if body != nil:
    body_602245 = body
  result = call_602243.call(nil, query_602244, nil, nil, body_602245)

var describeEvaluations* = Call_DescribeEvaluations_602228(
    name: "describeEvaluations", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeEvaluations",
    validator: validate_DescribeEvaluations_602229, base: "/",
    url: url_DescribeEvaluations_602230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMLModels_602246 = ref object of OpenApiRestCall_601389
proc url_DescribeMLModels_602248(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMLModels_602247(path: JsonNode; query: JsonNode;
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
  var valid_602249 = query.getOrDefault("NextToken")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "NextToken", valid_602249
  var valid_602250 = query.getOrDefault("Limit")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "Limit", valid_602250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602251 = header.getOrDefault("X-Amz-Target")
  valid_602251 = validateParameter(valid_602251, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeMLModels"))
  if valid_602251 != nil:
    section.add "X-Amz-Target", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Signature")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Signature", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Content-Sha256", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Date")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Date", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Credential")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Credential", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Security-Token")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Security-Token", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Algorithm")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Algorithm", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-SignedHeaders", valid_602258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602260: Call_DescribeMLModels_602246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ## 
  let valid = call_602260.validator(path, query, header, formData, body)
  let scheme = call_602260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602260.url(scheme.get, call_602260.host, call_602260.base,
                         call_602260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602260, url, valid)

proc call*(call_602261: Call_DescribeMLModels_602246; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeMLModels
  ## Returns a list of <code>MLModel</code> that match the search criteria in the request.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602262 = newJObject()
  var body_602263 = newJObject()
  add(query_602262, "NextToken", newJString(NextToken))
  add(query_602262, "Limit", newJString(Limit))
  if body != nil:
    body_602263 = body
  result = call_602261.call(nil, query_602262, nil, nil, body_602263)

var describeMLModels* = Call_DescribeMLModels_602246(name: "describeMLModels",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeMLModels",
    validator: validate_DescribeMLModels_602247, base: "/",
    url: url_DescribeMLModels_602248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_602264 = ref object of OpenApiRestCall_601389
proc url_DescribeTags_602266(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_602265(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602267 = header.getOrDefault("X-Amz-Target")
  valid_602267 = validateParameter(valid_602267, JString, required = true, default = newJString(
      "AmazonML_20141212.DescribeTags"))
  if valid_602267 != nil:
    section.add "X-Amz-Target", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Content-Sha256", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Date")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Date", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Credential")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Credential", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Security-Token")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Security-Token", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Algorithm")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Algorithm", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-SignedHeaders", valid_602274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_DescribeTags_602264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of the tags for your Amazon ML object.
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_DescribeTags_602264; body: JsonNode): Recallable =
  ## describeTags
  ## Describes one or more of the tags for your Amazon ML object.
  ##   body: JObject (required)
  var body_602278 = newJObject()
  if body != nil:
    body_602278 = body
  result = call_602277.call(nil, nil, nil, nil, body_602278)

var describeTags* = Call_DescribeTags_602264(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.DescribeTags",
    validator: validate_DescribeTags_602265, base: "/", url: url_DescribeTags_602266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBatchPrediction_602279 = ref object of OpenApiRestCall_601389
proc url_GetBatchPrediction_602281(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBatchPrediction_602280(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602282 = header.getOrDefault("X-Amz-Target")
  valid_602282 = validateParameter(valid_602282, JString, required = true, default = newJString(
      "AmazonML_20141212.GetBatchPrediction"))
  if valid_602282 != nil:
    section.add "X-Amz-Target", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Content-Sha256", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Credential")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Credential", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Security-Token")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Security-Token", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Algorithm")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Algorithm", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-SignedHeaders", valid_602289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602291: Call_GetBatchPrediction_602279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ## 
  let valid = call_602291.validator(path, query, header, formData, body)
  let scheme = call_602291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602291.url(scheme.get, call_602291.host, call_602291.base,
                         call_602291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602291, url, valid)

proc call*(call_602292: Call_GetBatchPrediction_602279; body: JsonNode): Recallable =
  ## getBatchPrediction
  ## Returns a <code>BatchPrediction</code> that includes detailed metadata, status, and data file information for a <code>Batch Prediction</code> request.
  ##   body: JObject (required)
  var body_602293 = newJObject()
  if body != nil:
    body_602293 = body
  result = call_602292.call(nil, nil, nil, nil, body_602293)

var getBatchPrediction* = Call_GetBatchPrediction_602279(
    name: "getBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetBatchPrediction",
    validator: validate_GetBatchPrediction_602280, base: "/",
    url: url_GetBatchPrediction_602281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSource_602294 = ref object of OpenApiRestCall_601389
proc url_GetDataSource_602296(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDataSource_602295(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602297 = header.getOrDefault("X-Amz-Target")
  valid_602297 = validateParameter(valid_602297, JString, required = true, default = newJString(
      "AmazonML_20141212.GetDataSource"))
  if valid_602297 != nil:
    section.add "X-Amz-Target", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-Content-Sha256", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Credential")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Credential", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Security-Token")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Security-Token", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-SignedHeaders", valid_602304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602306: Call_GetDataSource_602294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ## 
  let valid = call_602306.validator(path, query, header, formData, body)
  let scheme = call_602306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602306.url(scheme.get, call_602306.host, call_602306.base,
                         call_602306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602306, url, valid)

proc call*(call_602307: Call_GetDataSource_602294; body: JsonNode): Recallable =
  ## getDataSource
  ## <p>Returns a <code>DataSource</code> that includes metadata and data file information, as well as the current status of the <code>DataSource</code>.</p> <p><code>GetDataSource</code> provides results in normal or verbose format. The verbose format adds the schema description and the list of files pointed to by the DataSource to the normal format.</p>
  ##   body: JObject (required)
  var body_602308 = newJObject()
  if body != nil:
    body_602308 = body
  result = call_602307.call(nil, nil, nil, nil, body_602308)

var getDataSource* = Call_GetDataSource_602294(name: "getDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetDataSource",
    validator: validate_GetDataSource_602295, base: "/", url: url_GetDataSource_602296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEvaluation_602309 = ref object of OpenApiRestCall_601389
proc url_GetEvaluation_602311(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEvaluation_602310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602312 = header.getOrDefault("X-Amz-Target")
  valid_602312 = validateParameter(valid_602312, JString, required = true, default = newJString(
      "AmazonML_20141212.GetEvaluation"))
  if valid_602312 != nil:
    section.add "X-Amz-Target", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Signature")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Signature", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Content-Sha256", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Date")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Date", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Credential")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Credential", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Security-Token")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Security-Token", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Algorithm")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Algorithm", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-SignedHeaders", valid_602319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602321: Call_GetEvaluation_602309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ## 
  let valid = call_602321.validator(path, query, header, formData, body)
  let scheme = call_602321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602321.url(scheme.get, call_602321.host, call_602321.base,
                         call_602321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602321, url, valid)

proc call*(call_602322: Call_GetEvaluation_602309; body: JsonNode): Recallable =
  ## getEvaluation
  ## Returns an <code>Evaluation</code> that includes metadata as well as the current status of the <code>Evaluation</code>.
  ##   body: JObject (required)
  var body_602323 = newJObject()
  if body != nil:
    body_602323 = body
  result = call_602322.call(nil, nil, nil, nil, body_602323)

var getEvaluation* = Call_GetEvaluation_602309(name: "getEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.GetEvaluation",
    validator: validate_GetEvaluation_602310, base: "/", url: url_GetEvaluation_602311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLModel_602324 = ref object of OpenApiRestCall_601389
proc url_GetMLModel_602326(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMLModel_602325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602327 = header.getOrDefault("X-Amz-Target")
  valid_602327 = validateParameter(valid_602327, JString, required = true, default = newJString(
      "AmazonML_20141212.GetMLModel"))
  if valid_602327 != nil:
    section.add "X-Amz-Target", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Signature")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Signature", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Content-Sha256", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Date")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Date", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Credential")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Credential", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Security-Token")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Security-Token", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-SignedHeaders", valid_602334
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602336: Call_GetMLModel_602324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ## 
  let valid = call_602336.validator(path, query, header, formData, body)
  let scheme = call_602336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602336.url(scheme.get, call_602336.host, call_602336.base,
                         call_602336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602336, url, valid)

proc call*(call_602337: Call_GetMLModel_602324; body: JsonNode): Recallable =
  ## getMLModel
  ## <p>Returns an <code>MLModel</code> that includes detailed metadata, data source information, and the current status of the <code>MLModel</code>.</p> <p><code>GetMLModel</code> provides results in normal or verbose format. </p>
  ##   body: JObject (required)
  var body_602338 = newJObject()
  if body != nil:
    body_602338 = body
  result = call_602337.call(nil, nil, nil, nil, body_602338)

var getMLModel* = Call_GetMLModel_602324(name: "getMLModel",
                                      meth: HttpMethod.HttpPost,
                                      host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.GetMLModel",
                                      validator: validate_GetMLModel_602325,
                                      base: "/", url: url_GetMLModel_602326,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_Predict_602339 = ref object of OpenApiRestCall_601389
proc url_Predict_602341(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Predict_602340(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602342 = header.getOrDefault("X-Amz-Target")
  valid_602342 = validateParameter(valid_602342, JString, required = true, default = newJString(
      "AmazonML_20141212.Predict"))
  if valid_602342 != nil:
    section.add "X-Amz-Target", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Signature")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Signature", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Content-Sha256", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Date")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Date", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Credential")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Credential", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Security-Token")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Security-Token", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Algorithm")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Algorithm", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-SignedHeaders", valid_602349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602351: Call_Predict_602339; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ## 
  let valid = call_602351.validator(path, query, header, formData, body)
  let scheme = call_602351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602351.url(scheme.get, call_602351.host, call_602351.base,
                         call_602351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602351, url, valid)

proc call*(call_602352: Call_Predict_602339; body: JsonNode): Recallable =
  ## predict
  ## <p>Generates a prediction for the observation using the specified <code>ML Model</code>.</p> <note><title>Note</title> <p>Not all response parameters will be populated. Whether a response parameter is populated depends on the type of model requested.</p></note>
  ##   body: JObject (required)
  var body_602353 = newJObject()
  if body != nil:
    body_602353 = body
  result = call_602352.call(nil, nil, nil, nil, body_602353)

var predict* = Call_Predict_602339(name: "predict", meth: HttpMethod.HttpPost,
                                host: "machinelearning.amazonaws.com", route: "/#X-Amz-Target=AmazonML_20141212.Predict",
                                validator: validate_Predict_602340, base: "/",
                                url: url_Predict_602341,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateBatchPrediction_602354 = ref object of OpenApiRestCall_601389
proc url_UpdateBatchPrediction_602356(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateBatchPrediction_602355(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602357 = header.getOrDefault("X-Amz-Target")
  valid_602357 = validateParameter(valid_602357, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateBatchPrediction"))
  if valid_602357 != nil:
    section.add "X-Amz-Target", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Signature")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Signature", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Content-Sha256", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Date")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Date", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Credential")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Credential", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Security-Token")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Security-Token", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Algorithm")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Algorithm", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-SignedHeaders", valid_602364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602366: Call_UpdateBatchPrediction_602354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_602366.validator(path, query, header, formData, body)
  let scheme = call_602366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602366.url(scheme.get, call_602366.host, call_602366.base,
                         call_602366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602366, url, valid)

proc call*(call_602367: Call_UpdateBatchPrediction_602354; body: JsonNode): Recallable =
  ## updateBatchPrediction
  ## <p>Updates the <code>BatchPredictionName</code> of a <code>BatchPrediction</code>.</p> <p>You can use the <code>GetBatchPrediction</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_602368 = newJObject()
  if body != nil:
    body_602368 = body
  result = call_602367.call(nil, nil, nil, nil, body_602368)

var updateBatchPrediction* = Call_UpdateBatchPrediction_602354(
    name: "updateBatchPrediction", meth: HttpMethod.HttpPost,
    host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateBatchPrediction",
    validator: validate_UpdateBatchPrediction_602355, base: "/",
    url: url_UpdateBatchPrediction_602356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_602369 = ref object of OpenApiRestCall_601389
proc url_UpdateDataSource_602371(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDataSource_602370(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602372 = header.getOrDefault("X-Amz-Target")
  valid_602372 = validateParameter(valid_602372, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateDataSource"))
  if valid_602372 != nil:
    section.add "X-Amz-Target", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Signature")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Signature", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Content-Sha256", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Date")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Date", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Credential")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Credential", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Security-Token")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Security-Token", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Algorithm")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Algorithm", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-SignedHeaders", valid_602379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602381: Call_UpdateDataSource_602369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_602381.validator(path, query, header, formData, body)
  let scheme = call_602381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602381.url(scheme.get, call_602381.host, call_602381.base,
                         call_602381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602381, url, valid)

proc call*(call_602382: Call_UpdateDataSource_602369; body: JsonNode): Recallable =
  ## updateDataSource
  ## <p>Updates the <code>DataSourceName</code> of a <code>DataSource</code>.</p> <p>You can use the <code>GetDataSource</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_602383 = newJObject()
  if body != nil:
    body_602383 = body
  result = call_602382.call(nil, nil, nil, nil, body_602383)

var updateDataSource* = Call_UpdateDataSource_602369(name: "updateDataSource",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateDataSource",
    validator: validate_UpdateDataSource_602370, base: "/",
    url: url_UpdateDataSource_602371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEvaluation_602384 = ref object of OpenApiRestCall_601389
proc url_UpdateEvaluation_602386(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateEvaluation_602385(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602387 = header.getOrDefault("X-Amz-Target")
  valid_602387 = validateParameter(valid_602387, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateEvaluation"))
  if valid_602387 != nil:
    section.add "X-Amz-Target", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Signature")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Signature", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Content-Sha256", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Date")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Date", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Credential")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Credential", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Security-Token")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Security-Token", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Algorithm")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Algorithm", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-SignedHeaders", valid_602394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602396: Call_UpdateEvaluation_602384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_602396.validator(path, query, header, formData, body)
  let scheme = call_602396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602396.url(scheme.get, call_602396.host, call_602396.base,
                         call_602396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602396, url, valid)

proc call*(call_602397: Call_UpdateEvaluation_602384; body: JsonNode): Recallable =
  ## updateEvaluation
  ## <p>Updates the <code>EvaluationName</code> of an <code>Evaluation</code>.</p> <p>You can use the <code>GetEvaluation</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_602398 = newJObject()
  if body != nil:
    body_602398 = body
  result = call_602397.call(nil, nil, nil, nil, body_602398)

var updateEvaluation* = Call_UpdateEvaluation_602384(name: "updateEvaluation",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateEvaluation",
    validator: validate_UpdateEvaluation_602385, base: "/",
    url: url_UpdateEvaluation_602386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLModel_602399 = ref object of OpenApiRestCall_601389
proc url_UpdateMLModel_602401(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMLModel_602400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602402 = header.getOrDefault("X-Amz-Target")
  valid_602402 = validateParameter(valid_602402, JString, required = true, default = newJString(
      "AmazonML_20141212.UpdateMLModel"))
  if valid_602402 != nil:
    section.add "X-Amz-Target", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Signature")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Signature", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Content-Sha256", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Date")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Date", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Credential")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Credential", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Security-Token")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Security-Token", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Algorithm")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Algorithm", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-SignedHeaders", valid_602409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602411: Call_UpdateMLModel_602399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ## 
  let valid = call_602411.validator(path, query, header, formData, body)
  let scheme = call_602411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602411.url(scheme.get, call_602411.host, call_602411.base,
                         call_602411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602411, url, valid)

proc call*(call_602412: Call_UpdateMLModel_602399; body: JsonNode): Recallable =
  ## updateMLModel
  ## <p>Updates the <code>MLModelName</code> and the <code>ScoreThreshold</code> of an <code>MLModel</code>.</p> <p>You can use the <code>GetMLModel</code> operation to view the contents of the updated data element.</p>
  ##   body: JObject (required)
  var body_602413 = newJObject()
  if body != nil:
    body_602413 = body
  result = call_602412.call(nil, nil, nil, nil, body_602413)

var updateMLModel* = Call_UpdateMLModel_602399(name: "updateMLModel",
    meth: HttpMethod.HttpPost, host: "machinelearning.amazonaws.com",
    route: "/#X-Amz-Target=AmazonML_20141212.UpdateMLModel",
    validator: validate_UpdateMLModel_602400, base: "/", url: url_UpdateMLModel_602401,
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
