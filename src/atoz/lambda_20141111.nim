
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602457 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602457](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602457): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddEventSource_603053 = ref object of OpenApiRestCall_602457
proc url_AddEventSource_603055(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddEventSource_603054(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603056 = header.getOrDefault("X-Amz-Date")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Date", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Security-Token")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Security-Token", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Content-Sha256", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Algorithm")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Algorithm", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Signature")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Signature", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-SignedHeaders", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Credential")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Credential", valid_603062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603064: Call_AddEventSource_603053; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ## 
  let valid = call_603064.validator(path, query, header, formData, body)
  let scheme = call_603064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603064.url(scheme.get, call_603064.host, call_603064.base,
                         call_603064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603064, url, valid)

proc call*(call_603065: Call_AddEventSource_603053; body: JsonNode): Recallable =
  ## addEventSource
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ##   body: JObject (required)
  var body_603066 = newJObject()
  if body != nil:
    body_603066 = body
  result = call_603065.call(nil, nil, nil, nil, body_603066)

var addEventSource* = Call_AddEventSource_603053(name: "addEventSource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_AddEventSource_603054, base: "/", url: url_AddEventSource_603055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_602794 = ref object of OpenApiRestCall_602457
proc url_ListEventSources_602796(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventSources_602795(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionName: JString
  ##               : The name of the AWS Lambda function.
  ##   Marker: JString
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListEventSources</code> operation. If present, specifies to continue the list from where the returning call left off. 
  ##   MaxItems: JInt
  ##           : Optional integer. Specifies the maximum number of event sources to return in response. This value must be greater than 0.
  ##   EventSource: JString
  ##              : The Amazon Resource Name (ARN) of the Amazon Kinesis stream.
  section = newJObject()
  var valid_602908 = query.getOrDefault("FunctionName")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "FunctionName", valid_602908
  var valid_602909 = query.getOrDefault("Marker")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "Marker", valid_602909
  var valid_602910 = query.getOrDefault("MaxItems")
  valid_602910 = validateParameter(valid_602910, JInt, required = false, default = nil)
  if valid_602910 != nil:
    section.add "MaxItems", valid_602910
  var valid_602911 = query.getOrDefault("EventSource")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "EventSource", valid_602911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602912 = header.getOrDefault("X-Amz-Date")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Date", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Security-Token")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Security-Token", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Content-Sha256", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Algorithm")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Algorithm", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Signature")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Signature", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-SignedHeaders", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Credential")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Credential", valid_602918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602941: Call_ListEventSources_602794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  let valid = call_602941.validator(path, query, header, formData, body)
  let scheme = call_602941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602941.url(scheme.get, call_602941.host, call_602941.base,
                         call_602941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602941, url, valid)

proc call*(call_603012: Call_ListEventSources_602794; FunctionName: string = "";
          Marker: string = ""; MaxItems: int = 0; EventSource: string = ""): Recallable =
  ## listEventSources
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ##   FunctionName: string
  ##               : The name of the AWS Lambda function.
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListEventSources</code> operation. If present, specifies to continue the list from where the returning call left off. 
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of event sources to return in response. This value must be greater than 0.
  ##   EventSource: string
  ##              : The Amazon Resource Name (ARN) of the Amazon Kinesis stream.
  var query_603013 = newJObject()
  add(query_603013, "FunctionName", newJString(FunctionName))
  add(query_603013, "Marker", newJString(Marker))
  add(query_603013, "MaxItems", newJInt(MaxItems))
  add(query_603013, "EventSource", newJString(EventSource))
  result = call_603012.call(nil, query_603013, nil, nil, nil)

var listEventSources* = Call_ListEventSources_602794(name: "listEventSources",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_ListEventSources_602795, base: "/",
    url: url_ListEventSources_602796, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_603067 = ref object of OpenApiRestCall_602457
proc url_GetFunction_603069(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetFunction_603068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603084 = path.getOrDefault("FunctionName")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = nil)
  if valid_603084 != nil:
    section.add "FunctionName", valid_603084
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Security-Token")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Security-Token", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Signature")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Signature", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-SignedHeaders", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Credential")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Credential", valid_603091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603092: Call_GetFunction_603067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ## 
  let valid = call_603092.validator(path, query, header, formData, body)
  let scheme = call_603092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603092.url(scheme.get, call_603092.host, call_603092.base,
                         call_603092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603092, url, valid)

proc call*(call_603093: Call_GetFunction_603067; FunctionName: string): Recallable =
  ## getFunction
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  var path_603094 = newJObject()
  add(path_603094, "FunctionName", newJString(FunctionName))
  result = call_603093.call(path_603094, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_603067(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}",
                                        validator: validate_GetFunction_603068,
                                        base: "/", url: url_GetFunction_603069,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_603095 = ref object of OpenApiRestCall_602457
proc url_DeleteFunction_603097(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteFunction_603096(path: JsonNode; query: JsonNode;
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
  var valid_603098 = path.getOrDefault("FunctionName")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = nil)
  if valid_603098 != nil:
    section.add "FunctionName", valid_603098
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Security-Token")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Security-Token", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603106: Call_DeleteFunction_603095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ## 
  let valid = call_603106.validator(path, query, header, formData, body)
  let scheme = call_603106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603106.url(scheme.get, call_603106.host, call_603106.base,
                         call_603106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603106, url, valid)

proc call*(call_603107: Call_DeleteFunction_603095; FunctionName: string): Recallable =
  ## deleteFunction
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function to delete.
  var path_603108 = newJObject()
  add(path_603108, "FunctionName", newJString(FunctionName))
  result = call_603107.call(path_603108, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_603095(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_DeleteFunction_603096, base: "/", url: url_DeleteFunction_603097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSource_603109 = ref object of OpenApiRestCall_602457
proc url_GetEventSource_603111(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetEventSource_603110(path: JsonNode; query: JsonNode;
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
  var valid_603112 = path.getOrDefault("UUID")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "UUID", valid_603112
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Algorithm")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Algorithm", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-SignedHeaders", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_GetEventSource_603109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ## 
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603120, url, valid)

proc call*(call_603121: Call_GetEventSource_603109; UUID: string): Recallable =
  ## getEventSource
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The AWS Lambda assigned ID of the event source mapping.
  var path_603122 = newJObject()
  add(path_603122, "UUID", newJString(UUID))
  result = call_603121.call(path_603122, nil, nil, nil, nil)

var getEventSource* = Call_GetEventSource_603109(name: "getEventSource",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_GetEventSource_603110, base: "/", url: url_GetEventSource_603111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveEventSource_603123 = ref object of OpenApiRestCall_602457
proc url_RemoveEventSource_603125(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_RemoveEventSource_603124(path: JsonNode; query: JsonNode;
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
  var valid_603126 = path.getOrDefault("UUID")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "UUID", valid_603126
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_RemoveEventSource_603123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_RemoveEventSource_603123; UUID: string): Recallable =
  ## removeEventSource
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The event source mapping ID.
  var path_603136 = newJObject()
  add(path_603136, "UUID", newJString(UUID))
  result = call_603135.call(path_603136, nil, nil, nil, nil)

var removeEventSource* = Call_RemoveEventSource_603123(name: "removeEventSource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_RemoveEventSource_603124, base: "/",
    url: url_RemoveEventSource_603125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_603151 = ref object of OpenApiRestCall_602457
proc url_UpdateFunctionConfiguration_603153(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_603152(path: JsonNode; query: JsonNode;
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
  var valid_603154 = path.getOrDefault("FunctionName")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = nil)
  if valid_603154 != nil:
    section.add "FunctionName", valid_603154
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString
  ##              : A short user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   Timeout: JInt
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Handler: JString
  ##          : The function that Lambda calls to begin executing your function. For Node.js, it is the <i>module-name.export</i> value in your function. 
  ##   Role: JString
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda will assume when it executes your function. 
  ##   MemorySize: JInt
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  section = newJObject()
  var valid_603155 = query.getOrDefault("Description")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "Description", valid_603155
  var valid_603156 = query.getOrDefault("Timeout")
  valid_603156 = validateParameter(valid_603156, JInt, required = false, default = nil)
  if valid_603156 != nil:
    section.add "Timeout", valid_603156
  var valid_603157 = query.getOrDefault("Handler")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "Handler", valid_603157
  var valid_603158 = query.getOrDefault("Role")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "Role", valid_603158
  var valid_603159 = query.getOrDefault("MemorySize")
  valid_603159 = validateParameter(valid_603159, JInt, required = false, default = nil)
  if valid_603159 != nil:
    section.add "MemorySize", valid_603159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603160 = header.getOrDefault("X-Amz-Date")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Date", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Security-Token")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Security-Token", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Content-Sha256", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Algorithm")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Algorithm", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Signature")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Signature", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-SignedHeaders", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_UpdateFunctionConfiguration_603151; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ## 
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_UpdateFunctionConfiguration_603151;
          FunctionName: string; Description: string = ""; Timeout: int = 0;
          Handler: string = ""; Role: string = ""; MemorySize: int = 0): Recallable =
  ## updateFunctionConfiguration
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ##   Description: string
  ##              : A short user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function.
  ##   Timeout: int
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Handler: string
  ##          : The function that Lambda calls to begin executing your function. For Node.js, it is the <i>module-name.export</i> value in your function. 
  ##   Role: string
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda will assume when it executes your function. 
  ##   MemorySize: int
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  var path_603169 = newJObject()
  var query_603170 = newJObject()
  add(query_603170, "Description", newJString(Description))
  add(path_603169, "FunctionName", newJString(FunctionName))
  add(query_603170, "Timeout", newJInt(Timeout))
  add(query_603170, "Handler", newJString(Handler))
  add(query_603170, "Role", newJString(Role))
  add(query_603170, "MemorySize", newJInt(MemorySize))
  result = call_603168.call(path_603169, query_603170, nil, nil, nil)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_603151(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_603152, base: "/",
    url: url_UpdateFunctionConfiguration_603153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_603137 = ref object of OpenApiRestCall_602457
proc url_GetFunctionConfiguration_603139(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_603138(path: JsonNode; query: JsonNode;
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
  var valid_603140 = path.getOrDefault("FunctionName")
  valid_603140 = validateParameter(valid_603140, JString, required = true,
                                 default = nil)
  if valid_603140 != nil:
    section.add "FunctionName", valid_603140
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603141 = header.getOrDefault("X-Amz-Date")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Date", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Security-Token")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Security-Token", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Content-Sha256", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Algorithm")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Algorithm", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Signature")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Signature", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-SignedHeaders", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Credential")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Credential", valid_603147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603148: Call_GetFunctionConfiguration_603137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ## 
  let valid = call_603148.validator(path, query, header, formData, body)
  let scheme = call_603148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603148.url(scheme.get, call_603148.host, call_603148.base,
                         call_603148.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603148, url, valid)

proc call*(call_603149: Call_GetFunctionConfiguration_603137; FunctionName: string): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function for which you want to retrieve the configuration information.
  var path_603150 = newJObject()
  add(path_603150, "FunctionName", newJString(FunctionName))
  result = call_603149.call(path_603150, nil, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_603137(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_603138, base: "/",
    url: url_GetFunctionConfiguration_603139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_603171 = ref object of OpenApiRestCall_602457
proc url_InvokeAsync_603173(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_InvokeAsync_603172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603174 = path.getOrDefault("FunctionName")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "FunctionName", valid_603174
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603183: Call_InvokeAsync_603171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ## 
  let valid = call_603183.validator(path, query, header, formData, body)
  let scheme = call_603183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603183.url(scheme.get, call_603183.host, call_603183.base,
                         call_603183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603183, url, valid)

proc call*(call_603184: Call_InvokeAsync_603171; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  ##   body: JObject (required)
  var path_603185 = newJObject()
  var body_603186 = newJObject()
  add(path_603185, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_603186 = body
  result = call_603184.call(path_603185, nil, nil, nil, body_603186)

var invokeAsync* = Call_InvokeAsync_603171(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_603172,
                                        base: "/", url: url_InvokeAsync_603173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_603187 = ref object of OpenApiRestCall_602457
proc url_ListFunctions_603189(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctions_603188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603190 = query.getOrDefault("Marker")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Marker", valid_603190
  var valid_603191 = query.getOrDefault("MaxItems")
  valid_603191 = validateParameter(valid_603191, JInt, required = false, default = nil)
  if valid_603191 != nil:
    section.add "MaxItems", valid_603191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_603194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Content-Sha256", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Algorithm")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Algorithm", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Signature")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Signature", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-SignedHeaders", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Credential")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Credential", valid_603198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603199: Call_ListFunctions_603187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ## 
  let valid = call_603199.validator(path, query, header, formData, body)
  let scheme = call_603199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603199.url(scheme.get, call_603199.host, call_603199.base,
                         call_603199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603199, url, valid)

proc call*(call_603200: Call_ListFunctions_603187; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.
  var query_603201 = newJObject()
  add(query_603201, "Marker", newJString(Marker))
  add(query_603201, "MaxItems", newJInt(MaxItems))
  result = call_603200.call(nil, query_603201, nil, nil, nil)

var listFunctions* = Call_ListFunctions_603187(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/", validator: validate_ListFunctions_603188,
    base: "/", url: url_ListFunctions_603189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadFunction_603202 = ref object of OpenApiRestCall_602457
proc url_UploadFunction_603204(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UploadFunction_603203(path: JsonNode; query: JsonNode;
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
  var valid_603205 = path.getOrDefault("FunctionName")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "FunctionName", valid_603205
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString
  ##              : A short, user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   Runtime: JString (required)
  ##          : The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.
  ##   Timeout: JInt
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Handler: JString (required)
  ##          : The function that Lambda calls to begin execution. For Node.js, it is the <i>module-name</i>.<i>export</i> value in your function. 
  ##   Role: JString (required)
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. 
  ##   Mode: JString (required)
  ##       : How the Lambda function will be invoked. Lambda supports only the "event" mode. 
  ##   MemorySize: JInt
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, database operation might need less memory compared to image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  section = newJObject()
  var valid_603206 = query.getOrDefault("Description")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Description", valid_603206
  assert query != nil, "query argument is necessary due to required `Runtime` field"
  var valid_603220 = query.getOrDefault("Runtime")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = newJString("nodejs"))
  if valid_603220 != nil:
    section.add "Runtime", valid_603220
  var valid_603221 = query.getOrDefault("Timeout")
  valid_603221 = validateParameter(valid_603221, JInt, required = false, default = nil)
  if valid_603221 != nil:
    section.add "Timeout", valid_603221
  var valid_603222 = query.getOrDefault("Handler")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Handler", valid_603222
  var valid_603223 = query.getOrDefault("Role")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Role", valid_603223
  var valid_603224 = query.getOrDefault("Mode")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = newJString("event"))
  if valid_603224 != nil:
    section.add "Mode", valid_603224
  var valid_603225 = query.getOrDefault("MemorySize")
  valid_603225 = validateParameter(valid_603225, JInt, required = false, default = nil)
  if valid_603225 != nil:
    section.add "MemorySize", valid_603225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603226 = header.getOrDefault("X-Amz-Date")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Date", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Security-Token")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Security-Token", valid_603227
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

proc call*(call_603234: Call_UploadFunction_603202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_UploadFunction_603202; FunctionName: string;
          Handler: string; Role: string; body: JsonNode; Description: string = "";
          Runtime: string = "nodejs"; Timeout: int = 0; Mode: string = "event";
          MemorySize: int = 0): Recallable =
  ## uploadFunction
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ##   Description: string
  ##              : A short, user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.
  ##   FunctionName: string (required)
  ##               : The name you want to assign to the function you are uploading. The function names appear in the console and are returned in the <a>ListFunctions</a> API. Function names are used to specify functions to other AWS Lambda APIs, such as <a>InvokeAsync</a>. 
  ##   Runtime: string (required)
  ##          : The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.
  ##   Timeout: int
  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   Handler: string (required)
  ##          : The function that Lambda calls to begin execution. For Node.js, it is the <i>module-name</i>.<i>export</i> value in your function. 
  ##   Role: string (required)
  ##       : The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. 
  ##   Mode: string (required)
  ##       : How the Lambda function will be invoked. Lambda supports only the "event" mode. 
  ##   MemorySize: int
  ##             : The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, database operation might need less memory compared to image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.
  ##   body: JObject (required)
  var path_603236 = newJObject()
  var query_603237 = newJObject()
  var body_603238 = newJObject()
  add(query_603237, "Description", newJString(Description))
  add(path_603236, "FunctionName", newJString(FunctionName))
  add(query_603237, "Runtime", newJString(Runtime))
  add(query_603237, "Timeout", newJInt(Timeout))
  add(query_603237, "Handler", newJString(Handler))
  add(query_603237, "Role", newJString(Role))
  add(query_603237, "Mode", newJString(Mode))
  add(query_603237, "MemorySize", newJInt(MemorySize))
  if body != nil:
    body_603238 = body
  result = call_603235.call(path_603236, query_603237, nil, nil, body_603238)

var uploadFunction* = Call_UploadFunction_603202(name: "uploadFunction",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}#Runtime&Role&Handler&Mode",
    validator: validate_UploadFunction_603203, base: "/", url: url_UploadFunction_603204,
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
