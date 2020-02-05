
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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
  Call_AddEventSource_613246 = ref object of OpenApiRestCall_612649
proc url_AddEventSource_613248(protocol: Scheme; host: string; base: string;
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

proc validate_AddEventSource_613247(path: JsonNode; query: JsonNode;
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
  var valid_613249 = header.getOrDefault("X-Amz-Signature")
  valid_613249 = validateParameter(valid_613249, JString, required = false,
                                 default = nil)
  if valid_613249 != nil:
    section.add "X-Amz-Signature", valid_613249
  var valid_613250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613250 = validateParameter(valid_613250, JString, required = false,
                                 default = nil)
  if valid_613250 != nil:
    section.add "X-Amz-Content-Sha256", valid_613250
  var valid_613251 = header.getOrDefault("X-Amz-Date")
  valid_613251 = validateParameter(valid_613251, JString, required = false,
                                 default = nil)
  if valid_613251 != nil:
    section.add "X-Amz-Date", valid_613251
  var valid_613252 = header.getOrDefault("X-Amz-Credential")
  valid_613252 = validateParameter(valid_613252, JString, required = false,
                                 default = nil)
  if valid_613252 != nil:
    section.add "X-Amz-Credential", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-Security-Token")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Security-Token", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Algorithm")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Algorithm", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-SignedHeaders", valid_613255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613257: Call_AddEventSource_613246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ## 
  let valid = call_613257.validator(path, query, header, formData, body)
  let scheme = call_613257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613257.url(scheme.get, call_613257.host, call_613257.base,
                         call_613257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613257, url, valid)

proc call*(call_613258: Call_AddEventSource_613246; body: JsonNode): Recallable =
  ## addEventSource
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ##   body: JObject (required)
  var body_613259 = newJObject()
  if body != nil:
    body_613259 = body
  result = call_613258.call(nil, nil, nil, nil, body_613259)

var addEventSource* = Call_AddEventSource_613246(name: "addEventSource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_AddEventSource_613247, base: "/", url: url_AddEventSource_613248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_612987 = ref object of OpenApiRestCall_612649
proc url_ListEventSources_612989(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSources_612988(path: JsonNode; query: JsonNode;
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
  var valid_613101 = query.getOrDefault("Marker")
  valid_613101 = validateParameter(valid_613101, JString, required = false,
                                 default = nil)
  if valid_613101 != nil:
    section.add "Marker", valid_613101
  var valid_613102 = query.getOrDefault("EventSource")
  valid_613102 = validateParameter(valid_613102, JString, required = false,
                                 default = nil)
  if valid_613102 != nil:
    section.add "EventSource", valid_613102
  var valid_613103 = query.getOrDefault("FunctionName")
  valid_613103 = validateParameter(valid_613103, JString, required = false,
                                 default = nil)
  if valid_613103 != nil:
    section.add "FunctionName", valid_613103
  var valid_613104 = query.getOrDefault("MaxItems")
  valid_613104 = validateParameter(valid_613104, JInt, required = false, default = nil)
  if valid_613104 != nil:
    section.add "MaxItems", valid_613104
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
  var valid_613105 = header.getOrDefault("X-Amz-Signature")
  valid_613105 = validateParameter(valid_613105, JString, required = false,
                                 default = nil)
  if valid_613105 != nil:
    section.add "X-Amz-Signature", valid_613105
  var valid_613106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613106 = validateParameter(valid_613106, JString, required = false,
                                 default = nil)
  if valid_613106 != nil:
    section.add "X-Amz-Content-Sha256", valid_613106
  var valid_613107 = header.getOrDefault("X-Amz-Date")
  valid_613107 = validateParameter(valid_613107, JString, required = false,
                                 default = nil)
  if valid_613107 != nil:
    section.add "X-Amz-Date", valid_613107
  var valid_613108 = header.getOrDefault("X-Amz-Credential")
  valid_613108 = validateParameter(valid_613108, JString, required = false,
                                 default = nil)
  if valid_613108 != nil:
    section.add "X-Amz-Credential", valid_613108
  var valid_613109 = header.getOrDefault("X-Amz-Security-Token")
  valid_613109 = validateParameter(valid_613109, JString, required = false,
                                 default = nil)
  if valid_613109 != nil:
    section.add "X-Amz-Security-Token", valid_613109
  var valid_613110 = header.getOrDefault("X-Amz-Algorithm")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Algorithm", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-SignedHeaders", valid_613111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613134: Call_ListEventSources_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ## 
  let valid = call_613134.validator(path, query, header, formData, body)
  let scheme = call_613134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613134.url(scheme.get, call_613134.host, call_613134.base,
                         call_613134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613134, url, valid)

proc call*(call_613205: Call_ListEventSources_612987; Marker: string = "";
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
  var query_613206 = newJObject()
  add(query_613206, "Marker", newJString(Marker))
  add(query_613206, "EventSource", newJString(EventSource))
  add(query_613206, "FunctionName", newJString(FunctionName))
  add(query_613206, "MaxItems", newJInt(MaxItems))
  result = call_613205.call(nil, query_613206, nil, nil, nil)

var listEventSources* = Call_ListEventSources_612987(name: "listEventSources",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_ListEventSources_612988, base: "/",
    url: url_ListEventSources_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_613260 = ref object of OpenApiRestCall_612649
proc url_GetFunction_613262(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_613261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613277 = path.getOrDefault("FunctionName")
  valid_613277 = validateParameter(valid_613277, JString, required = true,
                                 default = nil)
  if valid_613277 != nil:
    section.add "FunctionName", valid_613277
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
  var valid_613278 = header.getOrDefault("X-Amz-Signature")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Signature", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Content-Sha256", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Date")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Date", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Credential")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Credential", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Security-Token")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Security-Token", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Algorithm")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Algorithm", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-SignedHeaders", valid_613284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613285: Call_GetFunction_613260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ## 
  let valid = call_613285.validator(path, query, header, formData, body)
  let scheme = call_613285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613285.url(scheme.get, call_613285.host, call_613285.base,
                         call_613285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613285, url, valid)

proc call*(call_613286: Call_GetFunction_613260; FunctionName: string): Recallable =
  ## getFunction
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  var path_613287 = newJObject()
  add(path_613287, "FunctionName", newJString(FunctionName))
  result = call_613286.call(path_613287, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_613260(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}",
                                        validator: validate_GetFunction_613261,
                                        base: "/", url: url_GetFunction_613262,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_613288 = ref object of OpenApiRestCall_612649
proc url_DeleteFunction_613290(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_613289(path: JsonNode; query: JsonNode;
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
  var valid_613291 = path.getOrDefault("FunctionName")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "FunctionName", valid_613291
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
  var valid_613292 = header.getOrDefault("X-Amz-Signature")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Signature", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Content-Sha256", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Date")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Date", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Credential")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Credential", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Security-Token")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Security-Token", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Algorithm")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Algorithm", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-SignedHeaders", valid_613298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613299: Call_DeleteFunction_613288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ## 
  let valid = call_613299.validator(path, query, header, formData, body)
  let scheme = call_613299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613299.url(scheme.get, call_613299.host, call_613299.base,
                         call_613299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613299, url, valid)

proc call*(call_613300: Call_DeleteFunction_613288; FunctionName: string): Recallable =
  ## deleteFunction
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function to delete.
  var path_613301 = newJObject()
  add(path_613301, "FunctionName", newJString(FunctionName))
  result = call_613300.call(path_613301, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_613288(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_DeleteFunction_613289, base: "/", url: url_DeleteFunction_613290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSource_613302 = ref object of OpenApiRestCall_612649
proc url_GetEventSource_613304(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventSource_613303(path: JsonNode; query: JsonNode;
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
  var valid_613305 = path.getOrDefault("UUID")
  valid_613305 = validateParameter(valid_613305, JString, required = true,
                                 default = nil)
  if valid_613305 != nil:
    section.add "UUID", valid_613305
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
  var valid_613306 = header.getOrDefault("X-Amz-Signature")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Signature", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Content-Sha256", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Date")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Date", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Credential")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Credential", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Security-Token")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Security-Token", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Algorithm")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Algorithm", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-SignedHeaders", valid_613312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613313: Call_GetEventSource_613302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ## 
  let valid = call_613313.validator(path, query, header, formData, body)
  let scheme = call_613313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613313.url(scheme.get, call_613313.host, call_613313.base,
                         call_613313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613313, url, valid)

proc call*(call_613314: Call_GetEventSource_613302; UUID: string): Recallable =
  ## getEventSource
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The AWS Lambda assigned ID of the event source mapping.
  var path_613315 = newJObject()
  add(path_613315, "UUID", newJString(UUID))
  result = call_613314.call(path_613315, nil, nil, nil, nil)

var getEventSource* = Call_GetEventSource_613302(name: "getEventSource",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_GetEventSource_613303, base: "/", url: url_GetEventSource_613304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveEventSource_613316 = ref object of OpenApiRestCall_612649
proc url_RemoveEventSource_613318(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveEventSource_613317(path: JsonNode; query: JsonNode;
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
  var valid_613319 = path.getOrDefault("UUID")
  valid_613319 = validateParameter(valid_613319, JString, required = true,
                                 default = nil)
  if valid_613319 != nil:
    section.add "UUID", valid_613319
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
  var valid_613320 = header.getOrDefault("X-Amz-Signature")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Signature", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Content-Sha256", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Date")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Date", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Credential")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Credential", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Security-Token")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Security-Token", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Algorithm")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Algorithm", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-SignedHeaders", valid_613326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613327: Call_RemoveEventSource_613316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ## 
  let valid = call_613327.validator(path, query, header, formData, body)
  let scheme = call_613327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613327.url(scheme.get, call_613327.host, call_613327.base,
                         call_613327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613327, url, valid)

proc call*(call_613328: Call_RemoveEventSource_613316; UUID: string): Recallable =
  ## removeEventSource
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ##   UUID: string (required)
  ##       : The event source mapping ID.
  var path_613329 = newJObject()
  add(path_613329, "UUID", newJString(UUID))
  result = call_613328.call(path_613329, nil, nil, nil, nil)

var removeEventSource* = Call_RemoveEventSource_613316(name: "removeEventSource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_RemoveEventSource_613317, base: "/",
    url: url_RemoveEventSource_613318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_613344 = ref object of OpenApiRestCall_612649
proc url_UpdateFunctionConfiguration_613346(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionConfiguration_613345(path: JsonNode; query: JsonNode;
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
  var valid_613347 = path.getOrDefault("FunctionName")
  valid_613347 = validateParameter(valid_613347, JString, required = true,
                                 default = nil)
  if valid_613347 != nil:
    section.add "FunctionName", valid_613347
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
  var valid_613348 = query.getOrDefault("Timeout")
  valid_613348 = validateParameter(valid_613348, JInt, required = false, default = nil)
  if valid_613348 != nil:
    section.add "Timeout", valid_613348
  var valid_613349 = query.getOrDefault("Role")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "Role", valid_613349
  var valid_613350 = query.getOrDefault("Description")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "Description", valid_613350
  var valid_613351 = query.getOrDefault("Handler")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "Handler", valid_613351
  var valid_613352 = query.getOrDefault("MemorySize")
  valid_613352 = validateParameter(valid_613352, JInt, required = false, default = nil)
  if valid_613352 != nil:
    section.add "MemorySize", valid_613352
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
  var valid_613353 = header.getOrDefault("X-Amz-Signature")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Signature", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Content-Sha256", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Date")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Date", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Credential")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Credential", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Security-Token")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Security-Token", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Algorithm")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Algorithm", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-SignedHeaders", valid_613359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_UpdateFunctionConfiguration_613344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_UpdateFunctionConfiguration_613344;
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
  var path_613362 = newJObject()
  var query_613363 = newJObject()
  add(path_613362, "FunctionName", newJString(FunctionName))
  add(query_613363, "Timeout", newJInt(Timeout))
  add(query_613363, "Role", newJString(Role))
  add(query_613363, "Description", newJString(Description))
  add(query_613363, "Handler", newJString(Handler))
  add(query_613363, "MemorySize", newJInt(MemorySize))
  result = call_613361.call(path_613362, query_613363, nil, nil, nil)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_613344(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_613345, base: "/",
    url: url_UpdateFunctionConfiguration_613346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_613330 = ref object of OpenApiRestCall_612649
proc url_GetFunctionConfiguration_613332(protocol: Scheme; host: string;
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

proc validate_GetFunctionConfiguration_613331(path: JsonNode; query: JsonNode;
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
  var valid_613333 = path.getOrDefault("FunctionName")
  valid_613333 = validateParameter(valid_613333, JString, required = true,
                                 default = nil)
  if valid_613333 != nil:
    section.add "FunctionName", valid_613333
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
  var valid_613334 = header.getOrDefault("X-Amz-Signature")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Signature", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Content-Sha256", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Date")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Date", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Credential")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Credential", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Security-Token")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Security-Token", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Algorithm")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Algorithm", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-SignedHeaders", valid_613340
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613341: Call_GetFunctionConfiguration_613330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ## 
  let valid = call_613341.validator(path, query, header, formData, body)
  let scheme = call_613341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613341.url(scheme.get, call_613341.host, call_613341.base,
                         call_613341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613341, url, valid)

proc call*(call_613342: Call_GetFunctionConfiguration_613330; FunctionName: string): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ##   FunctionName: string (required)
  ##               : The name of the Lambda function for which you want to retrieve the configuration information.
  var path_613343 = newJObject()
  add(path_613343, "FunctionName", newJString(FunctionName))
  result = call_613342.call(path_613343, nil, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_613330(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_613331, base: "/",
    url: url_GetFunctionConfiguration_613332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_613364 = ref object of OpenApiRestCall_612649
proc url_InvokeAsync_613366(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeAsync_613365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613367 = path.getOrDefault("FunctionName")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = nil)
  if valid_613367 != nil:
    section.add "FunctionName", valid_613367
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
  var valid_613368 = header.getOrDefault("X-Amz-Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Signature", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Content-Sha256", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Date")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Date", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Credential")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Credential", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Security-Token")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Security-Token", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Algorithm")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Algorithm", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-SignedHeaders", valid_613374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613376: Call_InvokeAsync_613364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ## 
  let valid = call_613376.validator(path, query, header, formData, body)
  let scheme = call_613376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613376.url(scheme.get, call_613376.host, call_613376.base,
                         call_613376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613376, url, valid)

proc call*(call_613377: Call_InvokeAsync_613364; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ##   FunctionName: string (required)
  ##               : The Lambda function name.
  ##   body: JObject (required)
  var path_613378 = newJObject()
  var body_613379 = newJObject()
  add(path_613378, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_613379 = body
  result = call_613377.call(path_613378, nil, nil, nil, body_613379)

var invokeAsync* = Call_InvokeAsync_613364(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_613365,
                                        base: "/", url: url_InvokeAsync_613366,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_613380 = ref object of OpenApiRestCall_612649
proc url_ListFunctions_613382(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_613381(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613383 = query.getOrDefault("Marker")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "Marker", valid_613383
  var valid_613384 = query.getOrDefault("MaxItems")
  valid_613384 = validateParameter(valid_613384, JInt, required = false, default = nil)
  if valid_613384 != nil:
    section.add "MaxItems", valid_613384
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
  var valid_613385 = header.getOrDefault("X-Amz-Signature")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Signature", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Content-Sha256", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Date")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Date", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Credential")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Credential", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Security-Token")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Security-Token", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Algorithm")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Algorithm", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-SignedHeaders", valid_613391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613392: Call_ListFunctions_613380; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ## 
  let valid = call_613392.validator(path, query, header, formData, body)
  let scheme = call_613392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613392.url(scheme.get, call_613392.host, call_613392.base,
                         call_613392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613392, url, valid)

proc call*(call_613393: Call_ListFunctions_613380; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ##   Marker: string
  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   MaxItems: int
  ##           : Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.
  var query_613394 = newJObject()
  add(query_613394, "Marker", newJString(Marker))
  add(query_613394, "MaxItems", newJInt(MaxItems))
  result = call_613393.call(nil, query_613394, nil, nil, nil)

var listFunctions* = Call_ListFunctions_613380(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/", validator: validate_ListFunctions_613381,
    base: "/", url: url_ListFunctions_613382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadFunction_613395 = ref object of OpenApiRestCall_612649
proc url_UploadFunction_613397(protocol: Scheme; host: string; base: string;
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

proc validate_UploadFunction_613396(path: JsonNode; query: JsonNode;
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
  var valid_613398 = path.getOrDefault("FunctionName")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "FunctionName", valid_613398
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
  var valid_613399 = query.getOrDefault("Timeout")
  valid_613399 = validateParameter(valid_613399, JInt, required = false, default = nil)
  if valid_613399 != nil:
    section.add "Timeout", valid_613399
  assert query != nil, "query argument is necessary due to required `Role` field"
  var valid_613400 = query.getOrDefault("Role")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "Role", valid_613400
  var valid_613414 = query.getOrDefault("Mode")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = newJString("event"))
  if valid_613414 != nil:
    section.add "Mode", valid_613414
  var valid_613415 = query.getOrDefault("Description")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "Description", valid_613415
  var valid_613416 = query.getOrDefault("Handler")
  valid_613416 = validateParameter(valid_613416, JString, required = true,
                                 default = nil)
  if valid_613416 != nil:
    section.add "Handler", valid_613416
  var valid_613417 = query.getOrDefault("MemorySize")
  valid_613417 = validateParameter(valid_613417, JInt, required = false, default = nil)
  if valid_613417 != nil:
    section.add "MemorySize", valid_613417
  var valid_613418 = query.getOrDefault("Runtime")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = newJString("nodejs"))
  if valid_613418 != nil:
    section.add "Runtime", valid_613418
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
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613427: Call_UploadFunction_613395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ## 
  let valid = call_613427.validator(path, query, header, formData, body)
  let scheme = call_613427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613427.url(scheme.get, call_613427.host, call_613427.base,
                         call_613427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613427, url, valid)

proc call*(call_613428: Call_UploadFunction_613395; FunctionName: string;
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
  var path_613429 = newJObject()
  var query_613430 = newJObject()
  var body_613431 = newJObject()
  add(path_613429, "FunctionName", newJString(FunctionName))
  add(query_613430, "Timeout", newJInt(Timeout))
  add(query_613430, "Role", newJString(Role))
  add(query_613430, "Mode", newJString(Mode))
  add(query_613430, "Description", newJString(Description))
  if body != nil:
    body_613431 = body
  add(query_613430, "Handler", newJString(Handler))
  add(query_613430, "MemorySize", newJInt(MemorySize))
  add(query_613430, "Runtime", newJString(Runtime))
  result = call_613428.call(path_613429, query_613430, nil, nil, body_613431)

var uploadFunction* = Call_UploadFunction_613395(name: "uploadFunction",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}#Runtime&Role&Handler&Mode",
    validator: validate_UploadFunction_613396, base: "/", url: url_UploadFunction_613397,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
