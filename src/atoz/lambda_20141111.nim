
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

  OpenApiRestCall_592355 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592355](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592355): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddEventSource_592953 = ref object of OpenApiRestCall_592355
proc url_AddEventSource_592955(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AddEventSource_592954(path: JsonNode; query: JsonNode;
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
  var valid_592956 = header.getOrDefault("X-Amz-Signature")
  valid_592956 = validateParameter(valid_592956, JString, required = false,
                                 default = nil)
  if valid_592956 != nil:
    section.add "X-Amz-Signature", valid_592956
  var valid_592957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592957 = validateParameter(valid_592957, JString, required = false,
                                 default = nil)
  if valid_592957 != nil:
    section.add "X-Amz-Content-Sha256", valid_592957
  var valid_592958 = header.getOrDefault("X-Amz-Date")
  valid_592958 = validateParameter(valid_592958, JString, required = false,
                                 default = nil)
  if valid_592958 != nil:
    section.add "X-Amz-Date", valid_592958
  var valid_592959 = header.getOrDefault("X-Amz-Credential")
  valid_592959 = validateParameter(valid_592959, JString, required = false,
                                 default = nil)
  if valid_592959 != nil:
    section.add "X-Amz-Credential", valid_592959
  var valid_592960 = header.getOrDefault("X-Amz-Security-Token")
  valid_592960 = validateParameter(valid_592960, JString, required = false,
                                 default = nil)
  if valid_592960 != nil:
    section.add "X-Amz-Security-Token", valid_592960
  var valid_592961 = header.getOrDefault("X-Amz-Algorithm")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Algorithm", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-SignedHeaders", valid_592962
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592964: Call_AddEventSource_592953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ## 
  let valid = call_592964.validator(path, query, header, formData, body)
  let scheme = call_592964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592964.url(scheme.get, call_592964.host, call_592964.base,
                         call_592964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592964, url, valid)

proc call*(call_592965: Call_AddEventSource_592953; body: JsonNode): Recallable =
  ## addEventSource
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ##   body: JObject (required)
  var body_592966 = newJObject()
  if body != nil:
    body_592966 = body
  result = call_592965.call(nil, nil, nil, nil, body_592966)

var addEventSource* = Call_AddEventSource_592953(name: "addEventSource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_AddEventSource_592954, base: "/", url: url_AddEventSource_592955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_592694 = ref object of OpenApiRestCall_592355
proc url_ListEventSources_592696(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEventSources_592695(path: JsonNode; query: JsonNode;
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
  var valid_592808 = query.getOrDefault("Marker")
  valid_592808 = validateParameter(valid_592808, JString, required = false,
                                 default = nil)
  if valid_592808 != nil:
    section.add "Marker", valid_592808
  var valid_592809 = query.getOrDefault("EventSource")
  valid_592809 = validateParameter(valid_592809, JString, required = false,
                                 default = nil)
  if valid_592809 != nil:
    section.add "EventSource", valid_592809
  var valid_592810 = query.getOrDefault("FunctionName")
  valid_592810 = validateParameter(valid_592810, JString, required = false,
                                 default = nil)
  if valid_592810 != nil:
    section.add "FunctionName", valid_592810
  var valid_592811 = query.getOrDefault("MaxItems")
  valid_592811 = validateParameter(valid_592811, JInt, required = false, default = nil)
  if valid_592811 != nil:
    section.add "MaxItems", valid_592811
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
  var valid_592812 = header.getOrDefault("X-Amz-Signature")
  valid_592812 = validateParameter(valid_592812, JString, required = false,
                                 default = nil)
  if valid_592812 != nil:
    section.add "X-Amz-Signature", valid_592812
  var valid_592813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592813 = validateParameter(valid_592813, JString, required = false,
                                 default = nil)
  if valid_592813 != nil:
    section.add "X-Amz-Content-Sha256", valid_592813
  var valid_592814 = header.getOrDefault("X-Amz-Date")
  valid_592814 = validateParameter(valid_592814, JString, required = false,
                                 default = nil)
  if valid_592814 != nil:
    section.add "X-Amz-Date", valid_592814
  var valid_592815 = header.getOrDefault("X-Amz-Credential")
  valid_592815 = validateParameter(valid_592815, JString, required = false,
                                 default = nil)
  if valid_592815 != nil:
    section.add "X-Amz-Credential", valid_592815
  var valid_592816 = header.getOrDefault("X-Amz-Security-Token")
  valid_592816 = validateParameter(valid_592816, JString, required = false,
                                 default = nil)
  if valid_592816 != nil:
    section.add "X-Amz-Security-Token", valid_592816
  var valid_592817 = header.getOrDefault("X-Amz-Algorithm")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Algorithm", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-SignedHeaders", valid_592818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592841: Call_ListEventSources_592694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  let valid = call_592841.validator(path, query, header, formData, body)
  let scheme = call_592841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592841.url(scheme.get, call_592841.host, call_592841.base,
                         call_592841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592841, url, valid)

proc call*(call_592912: Call_ListEventSources_592694; Marker: string = "";
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
  var query_592913 = newJObject()
  add(query_592913, "Marker", newJString(Marker))
  add(query_592913, "EventSource", newJString(EventSource))
  add(query_592913, "FunctionName", newJString(FunctionName))
  add(query_592913, "MaxItems", newJInt(MaxItems))
  result = call_592912.call(nil, query_592913, nil, nil, nil)

var listEventSources* = Call_ListEventSources_592694(name: "listEventSources",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_ListEventSources_592695, base: "/",
    url: url_ListEventSources_592696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_592967 = ref object of OpenApiRestCall_592355
proc url_GetFunction_592969(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_592968(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592984 = path.getOrDefault("FunctionName")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = nil)
  if valid_592984 != nil:
    section.add "FunctionName", valid_592984
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
  var valid_592985 = header.getOrDefault("X-Amz-Signature")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Signature", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Content-Sha256", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Date")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Date", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Credential")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Credential", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Security-Token")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Security-Token", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Algorithm")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Algorithm", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-SignedHeaders", valid_592991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592992: Call_GetFunction_592967; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ## 
  let valid = call_592992.validator(path, query, header, formData, body)
  let scheme = call_592992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592992.url(scheme.get, call_592992.host, call_592992.base,
                         call_592992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592992, url, valid)

proc call*(call_592993: Call_GetFunction_592967; FunctionName: string): Recallable =
  ## getFunction
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  var path_592994 = newJObject()
  add(path_592994, "FunctionName", newJString(FunctionName))
  result = call_592993.call(path_592994, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_592967(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}",
                                        validator: validate_GetFunction_592968,
                                        base: "/", url: url_GetFunction_592969,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_592995 = ref object of OpenApiRestCall_592355
proc url_DeleteFunction_592997(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_592996(path: JsonNode; query: JsonNode;
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
  var valid_592998 = path.getOrDefault("FunctionName")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "FunctionName", valid_592998
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
  var valid_592999 = header.getOrDefault("X-Amz-Signature")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Signature", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Content-Sha256", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Date")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Date", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Credential")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Credential", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Security-Token")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Security-Token", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Algorithm")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Algorithm", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-SignedHeaders", valid_593005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_DeleteFunction_592995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_DeleteFunction_592995; FunctionName: string): Recallable =
  ## deleteFunction
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function to delete.
  var path_593008 = newJObject()
  add(path_593008, "FunctionName", newJString(FunctionName))
  result = call_593007.call(path_593008, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_592995(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_DeleteFunction_592996, base: "/", url: url_DeleteFunction_592997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSource_593009 = ref object of OpenApiRestCall_592355
proc url_GetEventSource_593011(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventSource_593010(path: JsonNode; query: JsonNode;
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
  var valid_593012 = path.getOrDefault("UUID")
  valid_593012 = validateParameter(valid_593012, JString, required = true,
                                 default = nil)
  if valid_593012 != nil:
    section.add "UUID", valid_593012
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
  var valid_593013 = header.getOrDefault("X-Amz-Signature")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "X-Amz-Signature", valid_593013
  var valid_593014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "X-Amz-Content-Sha256", valid_593014
  var valid_593015 = header.getOrDefault("X-Amz-Date")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "X-Amz-Date", valid_593015
  var valid_593016 = header.getOrDefault("X-Amz-Credential")
  valid_593016 = validateParameter(valid_593016, JString, required = false,
                                 default = nil)
  if valid_593016 != nil:
    section.add "X-Amz-Credential", valid_593016
  var valid_593017 = header.getOrDefault("X-Amz-Security-Token")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Security-Token", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Algorithm")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Algorithm", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-SignedHeaders", valid_593019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593020: Call_GetEventSource_593009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ## 
  let valid = call_593020.validator(path, query, header, formData, body)
  let scheme = call_593020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593020.url(scheme.get, call_593020.host, call_593020.base,
                         call_593020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593020, url, valid)

proc call*(call_593021: Call_GetEventSource_593009; UUID: string): Recallable =
  ## getEventSource
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The AWS Lambda assigned ID of the event source mapping.
  var path_593022 = newJObject()
  add(path_593022, "UUID", newJString(UUID))
  result = call_593021.call(path_593022, nil, nil, nil, nil)

var getEventSource* = Call_GetEventSource_593009(name: "getEventSource",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_GetEventSource_593010, base: "/", url: url_GetEventSource_593011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveEventSource_593023 = ref object of OpenApiRestCall_592355
proc url_RemoveEventSource_593025(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveEventSource_593024(path: JsonNode; query: JsonNode;
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
  var valid_593026 = path.getOrDefault("UUID")
  valid_593026 = validateParameter(valid_593026, JString, required = true,
                                 default = nil)
  if valid_593026 != nil:
    section.add "UUID", valid_593026
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
  var valid_593027 = header.getOrDefault("X-Amz-Signature")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "X-Amz-Signature", valid_593027
  var valid_593028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593028 = validateParameter(valid_593028, JString, required = false,
                                 default = nil)
  if valid_593028 != nil:
    section.add "X-Amz-Content-Sha256", valid_593028
  var valid_593029 = header.getOrDefault("X-Amz-Date")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "X-Amz-Date", valid_593029
  var valid_593030 = header.getOrDefault("X-Amz-Credential")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Credential", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Security-Token")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Security-Token", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Algorithm")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Algorithm", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-SignedHeaders", valid_593033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593034: Call_RemoveEventSource_593023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ## 
  let valid = call_593034.validator(path, query, header, formData, body)
  let scheme = call_593034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593034.url(scheme.get, call_593034.host, call_593034.base,
                         call_593034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593034, url, valid)

proc call*(call_593035: Call_RemoveEventSource_593023; UUID: string): Recallable =
  ## removeEventSource
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The event source mapping ID.
  var path_593036 = newJObject()
  add(path_593036, "UUID", newJString(UUID))
  result = call_593035.call(path_593036, nil, nil, nil, nil)

var removeEventSource* = Call_RemoveEventSource_593023(name: "removeEventSource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_RemoveEventSource_593024, base: "/",
    url: url_RemoveEventSource_593025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_593051 = ref object of OpenApiRestCall_592355
proc url_UpdateFunctionConfiguration_593053(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionConfiguration_593052(path: JsonNode; query: JsonNode;
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
  var valid_593054 = path.getOrDefault("FunctionName")
  valid_593054 = validateParameter(valid_593054, JString, required = true,
                                 default = nil)
  if valid_593054 != nil:
    section.add "FunctionName", valid_593054
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
  var valid_593055 = query.getOrDefault("Timeout")
  valid_593055 = validateParameter(valid_593055, JInt, required = false, default = nil)
  if valid_593055 != nil:
    section.add "Timeout", valid_593055
  var valid_593056 = query.getOrDefault("Role")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "Role", valid_593056
  var valid_593057 = query.getOrDefault("Description")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "Description", valid_593057
  var valid_593058 = query.getOrDefault("Handler")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "Handler", valid_593058
  var valid_593059 = query.getOrDefault("MemorySize")
  valid_593059 = validateParameter(valid_593059, JInt, required = false, default = nil)
  if valid_593059 != nil:
    section.add "MemorySize", valid_593059
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
  var valid_593060 = header.getOrDefault("X-Amz-Signature")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Signature", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Content-Sha256", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Date")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Date", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Credential")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Credential", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Security-Token")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Security-Token", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-Algorithm")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-Algorithm", valid_593065
  var valid_593066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "X-Amz-SignedHeaders", valid_593066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_UpdateFunctionConfiguration_593051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_UpdateFunctionConfiguration_593051;
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
  var path_593069 = newJObject()
  var query_593070 = newJObject()
  add(path_593069, "FunctionName", newJString(FunctionName))
  add(query_593070, "Timeout", newJInt(Timeout))
  add(query_593070, "Role", newJString(Role))
  add(query_593070, "Description", newJString(Description))
  add(query_593070, "Handler", newJString(Handler))
  add(query_593070, "MemorySize", newJInt(MemorySize))
  result = call_593068.call(path_593069, query_593070, nil, nil, nil)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_593051(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_593052, base: "/",
    url: url_UpdateFunctionConfiguration_593053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_593037 = ref object of OpenApiRestCall_592355
proc url_GetFunctionConfiguration_593039(protocol: Scheme; host: string;
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

proc validate_GetFunctionConfiguration_593038(path: JsonNode; query: JsonNode;
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
  var valid_593040 = path.getOrDefault("FunctionName")
  valid_593040 = validateParameter(valid_593040, JString, required = true,
                                 default = nil)
  if valid_593040 != nil:
    section.add "FunctionName", valid_593040
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
  var valid_593041 = header.getOrDefault("X-Amz-Signature")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Signature", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Content-Sha256", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Date")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Date", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-Credential")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Credential", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Security-Token")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Security-Token", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Algorithm")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Algorithm", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-SignedHeaders", valid_593047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593048: Call_GetFunctionConfiguration_593037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ## 
  let valid = call_593048.validator(path, query, header, formData, body)
  let scheme = call_593048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593048.url(scheme.get, call_593048.host, call_593048.base,
                         call_593048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593048, url, valid)

proc call*(call_593049: Call_GetFunctionConfiguration_593037; FunctionName: string): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function for which you want to retrieve the configuration information.
  var path_593050 = newJObject()
  add(path_593050, "FunctionName", newJString(FunctionName))
  result = call_593049.call(path_593050, nil, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_593037(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_593038, base: "/",
    url: url_GetFunctionConfiguration_593039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_593071 = ref object of OpenApiRestCall_592355
proc url_InvokeAsync_593073(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeAsync_593072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593074 = path.getOrDefault("FunctionName")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = nil)
  if valid_593074 != nil:
    section.add "FunctionName", valid_593074
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
  var valid_593075 = header.getOrDefault("X-Amz-Signature")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Signature", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Content-Sha256", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Date")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Date", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Credential")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Credential", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-Security-Token")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Security-Token", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Algorithm")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Algorithm", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-SignedHeaders", valid_593081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593083: Call_InvokeAsync_593071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ## 
  let valid = call_593083.validator(path, query, header, formData, body)
  let scheme = call_593083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593083.url(scheme.get, call_593083.host, call_593083.base,
                         call_593083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593083, url, valid)

proc call*(call_593084: Call_InvokeAsync_593071; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  ##   body: JObject (required)
  var path_593085 = newJObject()
  var body_593086 = newJObject()
  add(path_593085, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_593086 = body
  result = call_593084.call(path_593085, nil, nil, nil, body_593086)

var invokeAsync* = Call_InvokeAsync_593071(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_593072,
                                        base: "/", url: url_InvokeAsync_593073,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_593087 = ref object of OpenApiRestCall_592355
proc url_ListFunctions_593089(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFunctions_593088(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593090 = query.getOrDefault("Marker")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "Marker", valid_593090
  var valid_593091 = query.getOrDefault("MaxItems")
  valid_593091 = validateParameter(valid_593091, JInt, required = false, default = nil)
  if valid_593091 != nil:
    section.add "MaxItems", valid_593091
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
  var valid_593092 = header.getOrDefault("X-Amz-Signature")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Signature", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Content-Sha256", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Date")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Date", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Credential")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Credential", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Security-Token")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Security-Token", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Algorithm")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Algorithm", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-SignedHeaders", valid_593098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593099: Call_ListFunctions_593087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ## 
  let valid = call_593099.validator(path, query, header, formData, body)
  let scheme = call_593099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593099.url(scheme.get, call_593099.host, call_593099.base,
                         call_593099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593099, url, valid)

proc call*(call_593100: Call_ListFunctions_593087; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.
  var query_593101 = newJObject()
  add(query_593101, "Marker", newJString(Marker))
  add(query_593101, "MaxItems", newJInt(MaxItems))
  result = call_593100.call(nil, query_593101, nil, nil, nil)

var listFunctions* = Call_ListFunctions_593087(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/", validator: validate_ListFunctions_593088,
    base: "/", url: url_ListFunctions_593089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadFunction_593102 = ref object of OpenApiRestCall_592355
proc url_UploadFunction_593104(protocol: Scheme; host: string; base: string;
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

proc validate_UploadFunction_593103(path: JsonNode; query: JsonNode;
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
  var valid_593105 = path.getOrDefault("FunctionName")
  valid_593105 = validateParameter(valid_593105, JString, required = true,
                                 default = nil)
  if valid_593105 != nil:
    section.add "FunctionName", valid_593105
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
  var valid_593106 = query.getOrDefault("Timeout")
  valid_593106 = validateParameter(valid_593106, JInt, required = false, default = nil)
  if valid_593106 != nil:
    section.add "Timeout", valid_593106
  assert query != nil, "query argument is necessary due to required `Role` field"
  var valid_593107 = query.getOrDefault("Role")
  valid_593107 = validateParameter(valid_593107, JString, required = true,
                                 default = nil)
  if valid_593107 != nil:
    section.add "Role", valid_593107
  var valid_593121 = query.getOrDefault("Mode")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = newJString("event"))
  if valid_593121 != nil:
    section.add "Mode", valid_593121
  var valid_593122 = query.getOrDefault("Description")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "Description", valid_593122
  var valid_593123 = query.getOrDefault("Handler")
  valid_593123 = validateParameter(valid_593123, JString, required = true,
                                 default = nil)
  if valid_593123 != nil:
    section.add "Handler", valid_593123
  var valid_593124 = query.getOrDefault("MemorySize")
  valid_593124 = validateParameter(valid_593124, JInt, required = false, default = nil)
  if valid_593124 != nil:
    section.add "MemorySize", valid_593124
  var valid_593125 = query.getOrDefault("Runtime")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = newJString("nodejs"))
  if valid_593125 != nil:
    section.add "Runtime", valid_593125
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
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593134: Call_UploadFunction_593102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ## 
  let valid = call_593134.validator(path, query, header, formData, body)
  let scheme = call_593134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593134.url(scheme.get, call_593134.host, call_593134.base,
                         call_593134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593134, url, valid)

proc call*(call_593135: Call_UploadFunction_593102; FunctionName: string;
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
  var path_593136 = newJObject()
  var query_593137 = newJObject()
  var body_593138 = newJObject()
  add(path_593136, "FunctionName", newJString(FunctionName))
  add(query_593137, "Timeout", newJInt(Timeout))
  add(query_593137, "Role", newJString(Role))
  add(query_593137, "Mode", newJString(Mode))
  add(query_593137, "Description", newJString(Description))
  if body != nil:
    body_593138 = body
  add(query_593137, "Handler", newJString(Handler))
  add(query_593137, "MemorySize", newJInt(MemorySize))
  add(query_593137, "Runtime", newJString(Runtime))
  result = call_593135.call(path_593136, query_593137, nil, nil, body_593138)

var uploadFunction* = Call_UploadFunction_593102(name: "uploadFunction",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}#Runtime&Role&Handler&Mode",
    validator: validate_UploadFunction_593103, base: "/", url: url_UploadFunction_593104,
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
