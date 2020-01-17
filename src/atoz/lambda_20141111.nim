
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Lambda
## version: 2014-11-11
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Lambda</fullname> <p><b>Overview</b></p> <p>This is the AWS Lambda API Reference. The AWS Lambda Developer Guide provides additional information. For the service overview, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/welcome.html">What is AWS Lambda</a>, and for information about how the service works, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS LambdaL How it Works</a> in the AWS Lambda Developer Guide.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lambda/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
                           "us-west-2": "lambda.us-west-2.amazonaws.com",
                           "eu-west-2": "lambda.eu-west-2.amazonaws.com", "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "lambda.eu-central-1.amazonaws.com",
                           "us-east-2": "lambda.us-east-2.amazonaws.com",
                           "us-east-1": "lambda.us-east-1.amazonaws.com", "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "lambda.ap-south-1.amazonaws.com",
                           "eu-north-1": "lambda.eu-north-1.amazonaws.com", "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
                           "us-west-1": "lambda.us-west-1.amazonaws.com", "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "lambda.eu-west-3.amazonaws.com",
                           "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "lambda.sa-east-1.amazonaws.com",
                           "eu-west-1": "lambda.eu-west-1.amazonaws.com", "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
      "us-west-2": "lambda.us-west-2.amazonaws.com",
      "eu-west-2": "lambda.eu-west-2.amazonaws.com",
      "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
      "eu-central-1": "lambda.eu-central-1.amazonaws.com",
      "us-east-2": "lambda.us-east-2.amazonaws.com",
      "us-east-1": "lambda.us-east-1.amazonaws.com",
      "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "lambda.ap-south-1.amazonaws.com",
      "eu-north-1": "lambda.eu-north-1.amazonaws.com",
      "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
      "us-west-1": "lambda.us-west-1.amazonaws.com",
      "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
      "eu-west-3": "lambda.eu-west-3.amazonaws.com",
      "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "lambda.sa-east-1.amazonaws.com",
      "eu-west-1": "lambda.eu-west-1.amazonaws.com",
      "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
      "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lambda"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddEventSource_606177 = ref object of OpenApiRestCall_605580
proc url_AddEventSource_606179(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddEventSource_606178(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606180 = header.getOrDefault("X-Amz-Signature")
  valid_606180 = validateParameter(valid_606180, JString, required = false,
                                 default = nil)
  if valid_606180 != nil:
    section.add "X-Amz-Signature", valid_606180
  var valid_606181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606181 = validateParameter(valid_606181, JString, required = false,
                                 default = nil)
  if valid_606181 != nil:
    section.add "X-Amz-Content-Sha256", valid_606181
  var valid_606182 = header.getOrDefault("X-Amz-Date")
  valid_606182 = validateParameter(valid_606182, JString, required = false,
                                 default = nil)
  if valid_606182 != nil:
    section.add "X-Amz-Date", valid_606182
  var valid_606183 = header.getOrDefault("X-Amz-Credential")
  valid_606183 = validateParameter(valid_606183, JString, required = false,
                                 default = nil)
  if valid_606183 != nil:
    section.add "X-Amz-Credential", valid_606183
  var valid_606184 = header.getOrDefault("X-Amz-Security-Token")
  valid_606184 = validateParameter(valid_606184, JString, required = false,
                                 default = nil)
  if valid_606184 != nil:
    section.add "X-Amz-Security-Token", valid_606184
  var valid_606185 = header.getOrDefault("X-Amz-Algorithm")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Algorithm", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-SignedHeaders", valid_606186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606188: Call_AddEventSource_606177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ## 
  let valid = call_606188.validator(path, query, header, formData, body)
  let scheme = call_606188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606188.url(scheme.get, call_606188.host, call_606188.base,
                         call_606188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606188, url, valid)

proc call*(call_606189: Call_AddEventSource_606177; body: JsonNode): Recallable =
  ## addEventSource
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ##   body: JObject (required)
  var body_606190 = newJObject()
  if body != nil:
    body_606190 = body
  result = call_606189.call(nil, nil, nil, nil, body_606190)

var addEventSource* = Call_AddEventSource_606177(name: "addEventSource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_AddEventSource_606178, base: "/", url: url_AddEventSource_606179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_605918 = ref object of OpenApiRestCall_605580
proc url_ListEventSources_605920(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSources_605919(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListEventSources</code> operation. If present, specifies to continue the list from where the returning call left off. 
  ##   EventSource: JString
  ##              : The Amazon Resource Name (ARN) of the Amazon Kinesis stream.
  ##   FunctionName: JString
  ##               : The name of the AWS Lambda function.
  ##   MaxItems: JInt
  ##           : Optional integer. Specifies the maximum number of event sources to return in response. This value must be greater than 0.
  section = newJObject()
  var valid_606032 = query.getOrDefault("Marker")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "Marker", valid_606032
  var valid_606033 = query.getOrDefault("EventSource")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "EventSource", valid_606033
  var valid_606034 = query.getOrDefault("FunctionName")
  valid_606034 = validateParameter(valid_606034, JString, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "FunctionName", valid_606034
  var valid_606035 = query.getOrDefault("MaxItems")
  valid_606035 = validateParameter(valid_606035, JInt, required = false, default = nil)
  if valid_606035 != nil:
    section.add "MaxItems", valid_606035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606036 = header.getOrDefault("X-Amz-Signature")
  valid_606036 = validateParameter(valid_606036, JString, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "X-Amz-Signature", valid_606036
  var valid_606037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606037 = validateParameter(valid_606037, JString, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "X-Amz-Content-Sha256", valid_606037
  var valid_606038 = header.getOrDefault("X-Amz-Date")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-Date", valid_606038
  var valid_606039 = header.getOrDefault("X-Amz-Credential")
  valid_606039 = validateParameter(valid_606039, JString, required = false,
                                 default = nil)
  if valid_606039 != nil:
    section.add "X-Amz-Credential", valid_606039
  var valid_606040 = header.getOrDefault("X-Amz-Security-Token")
  valid_606040 = validateParameter(valid_606040, JString, required = false,
                                 default = nil)
  if valid_606040 != nil:
    section.add "X-Amz-Security-Token", valid_606040
  var valid_606041 = header.getOrDefault("X-Amz-Algorithm")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Algorithm", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-SignedHeaders", valid_606042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606065: Call_ListEventSources_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  let valid = call_606065.validator(path, query, header, formData, body)
  let scheme = call_606065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606065.url(scheme.get, call_606065.host, call_606065.base,
                         call_606065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606065, url, valid)

proc call*(call_606136: Call_ListEventSources_605918; Marker: string = "";
          EventSource: string = ""; FunctionName: string = ""; MaxItems: int = 0): Recallable =
  ## listEventSources
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListEventSources</code> operation. If present, specifies to continue the list from where the returning call left off. 
  ##   EventSource: string
  ##              : The Amazon Resource Name (ARN) of the Amazon Kinesis stream.
  ##   FunctionName: string
  ##               : The name of the AWS Lambda function.
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of event sources to return in response. This value must be greater than 0.
  var query_606137 = newJObject()
  add(query_606137, "Marker", newJString(Marker))
  add(query_606137, "EventSource", newJString(EventSource))
  add(query_606137, "FunctionName", newJString(FunctionName))
  add(query_606137, "MaxItems", newJInt(MaxItems))
  result = call_606136.call(nil, query_606137, nil, nil, nil)

var listEventSources* = Call_ListEventSources_605918(name: "listEventSources",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_ListEventSources_605919, base: "/",
    url: url_ListEventSources_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_606191 = ref object of OpenApiRestCall_605580
proc url_GetFunction_606193(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_606192(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The Lambda function name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606208 = path.getOrDefault("FunctionName")
  valid_606208 = validateParameter(valid_606208, JString, required = true,
                                 default = nil)
  if valid_606208 != nil:
    section.add "FunctionName", valid_606208
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606209 = header.getOrDefault("X-Amz-Signature")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Signature", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Content-Sha256", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Date")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Date", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Credential")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Credential", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Security-Token")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Security-Token", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Algorithm")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Algorithm", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-SignedHeaders", valid_606215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606216: Call_GetFunction_606191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ## 
  let valid = call_606216.validator(path, query, header, formData, body)
  let scheme = call_606216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606216.url(scheme.get, call_606216.host, call_606216.base,
                         call_606216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606216, url, valid)

proc call*(call_606217: Call_GetFunction_606191; FunctionName: string): Recallable =
  ## getFunction
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  var path_606218 = newJObject()
  add(path_606218, "FunctionName", newJString(FunctionName))
  result = call_606217.call(path_606218, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_606191(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}",
                                        validator: validate_GetFunction_606192,
                                        base: "/", url: url_GetFunction_606193,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_606219 = ref object of OpenApiRestCall_605580
proc url_DeleteFunction_606221(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_606220(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The Lambda function to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606222 = path.getOrDefault("FunctionName")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "FunctionName", valid_606222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606223 = header.getOrDefault("X-Amz-Signature")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Signature", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Content-Sha256", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Date")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Date", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Credential")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Credential", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Security-Token")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Security-Token", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Algorithm")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Algorithm", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-SignedHeaders", valid_606229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606230: Call_DeleteFunction_606219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_DeleteFunction_606219; FunctionName: string): Recallable =
  ## deleteFunction
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function to delete.
  var path_606232 = newJObject()
  add(path_606232, "FunctionName", newJString(FunctionName))
  result = call_606231.call(path_606232, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_606219(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_DeleteFunction_606220, base: "/", url: url_DeleteFunction_606221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSource_606233 = ref object of OpenApiRestCall_605580
proc url_GetEventSource_606235(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventSource_606234(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The AWS Lambda assigned ID of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_606236 = path.getOrDefault("UUID")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "UUID", valid_606236
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606237 = header.getOrDefault("X-Amz-Signature")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Signature", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Content-Sha256", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Date")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Date", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Credential")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Credential", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Security-Token")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Security-Token", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Algorithm")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Algorithm", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-SignedHeaders", valid_606243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606244: Call_GetEventSource_606233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ## 
  let valid = call_606244.validator(path, query, header, formData, body)
  let scheme = call_606244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606244.url(scheme.get, call_606244.host, call_606244.base,
                         call_606244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606244, url, valid)

proc call*(call_606245: Call_GetEventSource_606233; UUID: string): Recallable =
  ## getEventSource
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The AWS Lambda assigned ID of the event source mapping.
  var path_606246 = newJObject()
  add(path_606246, "UUID", newJString(UUID))
  result = call_606245.call(path_606246, nil, nil, nil, nil)

var getEventSource* = Call_GetEventSource_606233(name: "getEventSource",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_GetEventSource_606234, base: "/", url: url_GetEventSource_606235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveEventSource_606247 = ref object of OpenApiRestCall_605580
proc url_RemoveEventSource_606249(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveEventSource_606248(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The event source mapping ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_606250 = path.getOrDefault("UUID")
  valid_606250 = validateParameter(valid_606250, JString, required = true,
                                 default = nil)
  if valid_606250 != nil:
    section.add "UUID", valid_606250
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606251 = header.getOrDefault("X-Amz-Signature")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Signature", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Content-Sha256", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Date")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Date", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Credential")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Credential", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Security-Token")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Security-Token", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Algorithm")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Algorithm", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-SignedHeaders", valid_606257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606258: Call_RemoveEventSource_606247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ## 
  let valid = call_606258.validator(path, query, header, formData, body)
  let scheme = call_606258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606258.url(scheme.get, call_606258.host, call_606258.base,
                         call_606258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606258, url, valid)

proc call*(call_606259: Call_RemoveEventSource_606247; UUID: string): Recallable =
  ## removeEventSource
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The event source mapping ID.
  var path_606260 = newJObject()
  add(path_606260, "UUID", newJString(UUID))
  result = call_606259.call(path_606260, nil, nil, nil, nil)

var removeEventSource* = Call_RemoveEventSource_606247(name: "removeEventSource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_RemoveEventSource_606248, base: "/",
    url: url_RemoveEventSource_606249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_606275 = ref object of OpenApiRestCall_605580
proc url_UpdateFunctionConfiguration_606277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_606276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The name of the Lambda function.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606278 = path.getOrDefault("FunctionName")
  valid_606278 = validateParameter(valid_606278, JString, required = true,
                                 default = nil)
  if valid_606278 != nil:
    section.add "FunctionName", valid_606278
  result.add "path", section
  ## parameters in `query` object:
  ##   Timeout: JInt
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Role: JString
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda will assume when it executes your function. 
  ##   Description: JString
  ##              : A short user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   Handler: JString
  ##          : The function that Lambda calls to begin executing your function. For Node.js, it is the <i>module-name.export</i> value in your function. 
  ##   MemorySize: JInt
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  section = newJObject()
  var valid_606279 = query.getOrDefault("Timeout")
  valid_606279 = validateParameter(valid_606279, JInt, required = false, default = nil)
  if valid_606279 != nil:
    section.add "Timeout", valid_606279
  var valid_606280 = query.getOrDefault("Role")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "Role", valid_606280
  var valid_606281 = query.getOrDefault("Description")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "Description", valid_606281
  var valid_606282 = query.getOrDefault("Handler")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "Handler", valid_606282
  var valid_606283 = query.getOrDefault("MemorySize")
  valid_606283 = validateParameter(valid_606283, JInt, required = false, default = nil)
  if valid_606283 != nil:
    section.add "MemorySize", valid_606283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606284 = header.getOrDefault("X-Amz-Signature")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Signature", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Content-Sha256", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Date")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Date", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Credential")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Credential", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Security-Token")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Security-Token", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Algorithm")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Algorithm", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-SignedHeaders", valid_606290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_UpdateFunctionConfiguration_606275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_UpdateFunctionConfiguration_606275;
          FunctionName: string; Timeout: int = 0; Role: string = "";
          Description: string = ""; Handler: string = ""; MemorySize: int = 0): Recallable =
  ## updateFunctionConfiguration
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function.
  ##   Timeout: int
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Role: string
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda will assume when it executes your function. 
  ##   Description: string
  ##              : A short user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   Handler: string
  ##          : The function that Lambda calls to begin executing your function. For Node.js, it is the <i>module-name.export</i> value in your function. 
  ##   MemorySize: int
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  var path_606293 = newJObject()
  var query_606294 = newJObject()
  add(path_606293, "FunctionName", newJString(FunctionName))
  add(query_606294, "Timeout", newJInt(Timeout))
  add(query_606294, "Role", newJString(Role))
  add(query_606294, "Description", newJString(Description))
  add(query_606294, "Handler", newJString(Handler))
  add(query_606294, "MemorySize", newJInt(MemorySize))
  result = call_606292.call(path_606293, query_606294, nil, nil, nil)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_606275(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_606276, base: "/",
    url: url_UpdateFunctionConfiguration_606277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_606261 = ref object of OpenApiRestCall_605580
proc url_GetFunctionConfiguration_606263(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_606262(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The name of the Lambda function for which you want to retrieve the configuration information.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606264 = path.getOrDefault("FunctionName")
  valid_606264 = validateParameter(valid_606264, JString, required = true,
                                 default = nil)
  if valid_606264 != nil:
    section.add "FunctionName", valid_606264
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606265 = header.getOrDefault("X-Amz-Signature")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Signature", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Content-Sha256", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Date")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Date", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Credential")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Credential", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Security-Token")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Security-Token", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Algorithm")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Algorithm", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-SignedHeaders", valid_606271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606272: Call_GetFunctionConfiguration_606261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ## 
  let valid = call_606272.validator(path, query, header, formData, body)
  let scheme = call_606272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606272.url(scheme.get, call_606272.host, call_606272.base,
                         call_606272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606272, url, valid)

proc call*(call_606273: Call_GetFunctionConfiguration_606261; FunctionName: string): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function for which you want to retrieve the configuration information.
  var path_606274 = newJObject()
  add(path_606274, "FunctionName", newJString(FunctionName))
  result = call_606273.call(path_606274, nil, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_606261(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_606262, base: "/",
    url: url_GetFunctionConfiguration_606263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_606295 = ref object of OpenApiRestCall_605580
proc url_InvokeAsync_606297(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/invoke-async/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeAsync_606296(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The Lambda function name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606298 = path.getOrDefault("FunctionName")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = nil)
  if valid_606298 != nil:
    section.add "FunctionName", valid_606298
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606299 = header.getOrDefault("X-Amz-Signature")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Signature", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Content-Sha256", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Date")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Date", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Credential")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Credential", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Security-Token")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Security-Token", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Algorithm")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Algorithm", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-SignedHeaders", valid_606305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606307: Call_InvokeAsync_606295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ## 
  let valid = call_606307.validator(path, query, header, formData, body)
  let scheme = call_606307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606307.url(scheme.get, call_606307.host, call_606307.base,
                         call_606307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606307, url, valid)

proc call*(call_606308: Call_InvokeAsync_606295; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  ##   body: JObject (required)
  var path_606309 = newJObject()
  var body_606310 = newJObject()
  add(path_606309, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606310 = body
  result = call_606308.call(path_606309, nil, nil, nil, body_606310)

var invokeAsync* = Call_InvokeAsync_606295(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_606296,
                                        base: "/", url: url_InvokeAsync_606297,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_606311 = ref object of OpenApiRestCall_605580
proc url_ListFunctions_606313(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctions_606312(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   MaxItems: JInt
  ##           : Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.
  section = newJObject()
  var valid_606314 = query.getOrDefault("Marker")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "Marker", valid_606314
  var valid_606315 = query.getOrDefault("MaxItems")
  valid_606315 = validateParameter(valid_606315, JInt, required = false, default = nil)
  if valid_606315 != nil:
    section.add "MaxItems", valid_606315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606316 = header.getOrDefault("X-Amz-Signature")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Signature", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Content-Sha256", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Date")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Date", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Credential")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Credential", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Security-Token")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Security-Token", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Algorithm")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Algorithm", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-SignedHeaders", valid_606322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606323: Call_ListFunctions_606311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ## 
  let valid = call_606323.validator(path, query, header, formData, body)
  let scheme = call_606323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606323.url(scheme.get, call_606323.host, call_606323.base,
                         call_606323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606323, url, valid)

proc call*(call_606324: Call_ListFunctions_606311; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.
  var query_606325 = newJObject()
  add(query_606325, "Marker", newJString(Marker))
  add(query_606325, "MaxItems", newJInt(MaxItems))
  result = call_606324.call(nil, query_606325, nil, nil, nil)

var listFunctions* = Call_ListFunctions_606311(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/", validator: validate_ListFunctions_606312,
    base: "/", url: url_ListFunctions_606313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadFunction_606326 = ref object of OpenApiRestCall_605580
proc url_UploadFunction_606328(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "#Runtime&Role&Handler&Mode")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UploadFunction_606327(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : The name you want to assign to the function you are uploading. The function names appear in the console and are returned in the <a>ListFunctions</a> API. Function names are used to specify functions to other AWS Lambda APIs, such as <a>InvokeAsync</a>. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606329 = path.getOrDefault("FunctionName")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = nil)
  if valid_606329 != nil:
    section.add "FunctionName", valid_606329
  result.add "path", section
  ## parameters in `query` object:
  ##   Timeout: JInt
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Role: JString (required)
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. 
  ##   Mode: JString (required)
  ##       : How the Lambda function will be invoked. Lambda supports only the "event" mode. 
  ##   Description: JString
  ##              : A short, user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   Handler: JString (required)
  ##          : The function that Lambda calls to begin execution. For Node.js, it is the <i>module-name</i>.<i>export</i> value in your function. 
  ##   MemorySize: JInt
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, database operation might need less memory compared to image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  ##   Runtime: JString (required)
  ##          : The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.
  section = newJObject()
  var valid_606330 = query.getOrDefault("Timeout")
  valid_606330 = validateParameter(valid_606330, JInt, required = false, default = nil)
  if valid_606330 != nil:
    section.add "Timeout", valid_606330
  assert query != nil, "query argument is necessary due to required `Role` field"
  var valid_606331 = query.getOrDefault("Role")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "Role", valid_606331
  var valid_606345 = query.getOrDefault("Mode")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = newJString("event"))
  if valid_606345 != nil:
    section.add "Mode", valid_606345
  var valid_606346 = query.getOrDefault("Description")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "Description", valid_606346
  var valid_606347 = query.getOrDefault("Handler")
  valid_606347 = validateParameter(valid_606347, JString, required = true,
                                 default = nil)
  if valid_606347 != nil:
    section.add "Handler", valid_606347
  var valid_606348 = query.getOrDefault("MemorySize")
  valid_606348 = validateParameter(valid_606348, JInt, required = false, default = nil)
  if valid_606348 != nil:
    section.add "MemorySize", valid_606348
  var valid_606349 = query.getOrDefault("Runtime")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = newJString("nodejs"))
  if valid_606349 != nil:
    section.add "Runtime", valid_606349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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

proc call*(call_606358: Call_UploadFunction_606326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_UploadFunction_606326; FunctionName: string;
          Role: string; body: JsonNode; Handler: string; Timeout: int = 0;
          Mode: string = "event"; Description: string = ""; MemorySize: int = 0;
          Runtime: string = "nodejs"): Recallable =
  ## uploadFunction
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The name you want to assign to the function you are uploading. The function names appear in the console and are returned in the <a>ListFunctions</a> API. Function names are used to specify functions to other AWS Lambda APIs, such as <a>InvokeAsync</a>. 
  ##   Timeout: int
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Role: string (required)
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. 
  ##   Mode: string (required)
  ##       : How the Lambda function will be invoked. Lambda supports only the "event" mode. 
  ##   Description: string
  ##              : A short, user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   body: JObject (required)
  ##   Handler: string (required)
  ##          : The function that Lambda calls to begin execution. For Node.js, it is the <i>module-name</i>.<i>export</i> value in your function. 
  ##   MemorySize: int
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, database operation might need less memory compared to image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  ##   Runtime: string (required)
  ##          : The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.
  var path_606360 = newJObject()
  var query_606361 = newJObject()
  var body_606362 = newJObject()
  add(path_606360, "FunctionName", newJString(FunctionName))
  add(query_606361, "Timeout", newJInt(Timeout))
  add(query_606361, "Role", newJString(Role))
  add(query_606361, "Mode", newJString(Mode))
  add(query_606361, "Description", newJString(Description))
  if body != nil:
    body_606362 = body
  add(query_606361, "Handler", newJString(Handler))
  add(query_606361, "MemorySize", newJInt(MemorySize))
  add(query_606361, "Runtime", newJString(Runtime))
  result = call_606359.call(path_606360, query_606361, nil, nil, body_606362)

var uploadFunction* = Call_UploadFunction_606326(name: "uploadFunction",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}#Runtime&Role&Handler&Mode",
    validator: validate_UploadFunction_606327, base: "/", url: url_UploadFunction_606328,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
