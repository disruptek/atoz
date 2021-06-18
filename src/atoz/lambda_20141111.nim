
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
                               "us-west-2": "lambda.us-west-2.amazonaws.com",
                               "eu-west-2": "lambda.eu-west-2.amazonaws.com", "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com", "eu-central-1": "lambda.eu-central-1.amazonaws.com",
                               "us-east-2": "lambda.us-east-2.amazonaws.com",
                               "us-east-1": "lambda.us-east-1.amazonaws.com", "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "lambda.ap-south-1.amazonaws.com",
                               "eu-north-1": "lambda.eu-north-1.amazonaws.com", "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
                               "us-west-1": "lambda.us-west-1.amazonaws.com", "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "lambda.eu-west-3.amazonaws.com", "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "lambda.sa-east-1.amazonaws.com",
                               "eu-west-1": "lambda.eu-west-1.amazonaws.com", "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com", "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddEventSource_402656473 = ref object of OpenApiRestCall_402656038
proc url_AddEventSource_402656475(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddEventSource_402656474(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Security-Token", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Signature")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Signature", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Algorithm", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Date")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Date", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Credential")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Credential", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656484: Call_AddEventSource_402656473; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
                                                                                         ## 
  let valid = call_402656484.validator(path, query, header, formData, body, _)
  let scheme = call_402656484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656484.makeUrl(scheme.get, call_402656484.host, call_402656484.base,
                                   call_402656484.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656484, uri, valid, _)

proc call*(call_402656485: Call_AddEventSource_402656473; body: JsonNode): Recallable =
  ## addEventSource
  ## <p>Identifies a stream as an event source for an AWS Lambda function. It can be either an Amazon Kinesis stream or a Amazon DynamoDB stream. AWS Lambda invokes the specified function when records are posted to the stream.</p> <p>This is the pull model, where AWS Lambda invokes the function. For more information, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the AWS Lambda Developer Guide.</p> <p>This association between an Amazon Kinesis stream and an AWS Lambda function is called the event source mapping. You provide the configuration information (for example, which stream to read from and which AWS Lambda function to invoke) for the event source mapping in the request body.</p> <p> Each event source, such as a Kinesis stream, can only be associated with one AWS Lambda function. If you call <a>AddEventSource</a> for an event source that is already mapped to another AWS Lambda function, the existing mapping is updated to call the new function instead of the old one. </p> <p>This operation requires permission for the <code>iam:PassRole</code> action for the IAM role. It also requires permission for the <code>lambda:AddEventSource</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656486 = newJObject()
  if body != nil:
    body_402656486 = body
  result = call_402656485.call(nil, nil, nil, nil, body_402656486)

var addEventSource* = Call_AddEventSource_402656473(name: "addEventSource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/",
    validator: validate_AddEventSource_402656474, base: "/",
    makeUrl: url_AddEventSource_402656475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSources_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListEventSources_402656290(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSources_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionName: JString
                                  ##               : The name of the AWS Lambda function.
  ##   
                                                                                         ## Marker: JString
                                                                                         ##         
                                                                                         ## : 
                                                                                         ## Optional 
                                                                                         ## string. 
                                                                                         ## An 
                                                                                         ## opaque 
                                                                                         ## pagination 
                                                                                         ## token 
                                                                                         ## returned 
                                                                                         ## from 
                                                                                         ## a 
                                                                                         ## previous 
                                                                                         ## <code>ListEventSources</code> 
                                                                                         ## operation. 
                                                                                         ## If 
                                                                                         ## present, 
                                                                                         ## specifies 
                                                                                         ## to 
                                                                                         ## continue 
                                                                                         ## the 
                                                                                         ## list 
                                                                                         ## from 
                                                                                         ## where 
                                                                                         ## the 
                                                                                         ## returning 
                                                                                         ## call 
                                                                                         ## left 
                                                                                         ## off. 
  ##   
                                                                                                 ## EventSource: JString
                                                                                                 ##              
                                                                                                 ## : 
                                                                                                 ## The 
                                                                                                 ## Amazon 
                                                                                                 ## Resource 
                                                                                                 ## Name 
                                                                                                 ## (ARN) 
                                                                                                 ## of 
                                                                                                 ## the 
                                                                                                 ## Amazon 
                                                                                                 ## Kinesis 
                                                                                                 ## stream.
  ##   
                                                                                                           ## MaxItems: JInt
                                                                                                           ##           
                                                                                                           ## : 
                                                                                                           ## Optional 
                                                                                                           ## integer. 
                                                                                                           ## Specifies 
                                                                                                           ## the 
                                                                                                           ## maximum 
                                                                                                           ## number 
                                                                                                           ## of 
                                                                                                           ## event 
                                                                                                           ## sources 
                                                                                                           ## to 
                                                                                                           ## return 
                                                                                                           ## in 
                                                                                                           ## response. 
                                                                                                           ## This 
                                                                                                           ## value 
                                                                                                           ## must 
                                                                                                           ## be 
                                                                                                           ## greater 
                                                                                                           ## than 
                                                                                                           ## 0.
  section = newJObject()
  var valid_402656369 = query.getOrDefault("FunctionName")
  valid_402656369 = validateParameter(valid_402656369, JString,
                                      required = false, default = nil)
  if valid_402656369 != nil:
    section.add "FunctionName", valid_402656369
  var valid_402656370 = query.getOrDefault("Marker")
  valid_402656370 = validateParameter(valid_402656370, JString,
                                      required = false, default = nil)
  if valid_402656370 != nil:
    section.add "Marker", valid_402656370
  var valid_402656371 = query.getOrDefault("EventSource")
  valid_402656371 = validateParameter(valid_402656371, JString,
                                      required = false, default = nil)
  if valid_402656371 != nil:
    section.add "EventSource", valid_402656371
  var valid_402656372 = query.getOrDefault("MaxItems")
  valid_402656372 = validateParameter(valid_402656372, JInt, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "MaxItems", valid_402656372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656373 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Security-Token", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Signature")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Signature", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Algorithm", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-Date")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Date", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Credential")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Credential", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656393: Call_ListEventSources_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
                                                                                         ## 
  let valid = call_402656393.validator(path, query, header, formData, body, _)
  let scheme = call_402656393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656393.makeUrl(scheme.get, call_402656393.host, call_402656393.base,
                                   call_402656393.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656393, uri, valid, _)

proc call*(call_402656442: Call_ListEventSources_402656288;
           FunctionName: string = ""; Marker: string = "";
           EventSource: string = ""; MaxItems: int = 0): Recallable =
  ## listEventSources
  ## <p>Returns a list of event source mappings you created using the <code>AddEventSource</code> (see <a>AddEventSource</a>), where you identify a stream as event source. This list does not include Amazon S3 event sources. </p> <p>For each mapping, the API returns configuration information. You can optionally specify filters to retrieve specific event source mappings.</p> <p>This operation requires permission for the <code>lambda:ListEventSources</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## FunctionName: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## AWS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## function.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Marker: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Optional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## string. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## An 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## opaque 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## <code>ListEventSources</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## operation. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## present, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## continue 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## returning 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## left 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## off. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## EventSource: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Kinesis 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## stream.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## MaxItems: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Optional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## integer. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## sources 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## This 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## greater 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## 0.
  var query_402656443 = newJObject()
  add(query_402656443, "FunctionName", newJString(FunctionName))
  add(query_402656443, "Marker", newJString(Marker))
  add(query_402656443, "EventSource", newJString(EventSource))
  add(query_402656443, "MaxItems", newJInt(MaxItems))
  result = call_402656442.call(nil, query_402656443, nil, nil, nil)

var listEventSources* = Call_ListEventSources_402656288(
    name: "listEventSources", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2014-11-13/event-source-mappings/",
    validator: validate_ListEventSources_402656289, base: "/",
    makeUrl: url_ListEventSources_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_402656487 = ref object of OpenApiRestCall_402656038
proc url_GetFunction_402656489(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_402656488(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656501 = path.getOrDefault("FunctionName")
  valid_402656501 = validateParameter(valid_402656501, JString, required = true,
                                      default = nil)
  if valid_402656501 != nil:
    section.add "FunctionName", valid_402656501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Security-Token", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Signature")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Signature", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Algorithm", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Date")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Date", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Credential")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Credential", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656509: Call_GetFunction_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
                                                                                         ## 
  let valid = call_402656509.validator(path, query, header, formData, body, _)
  let scheme = call_402656509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656509.makeUrl(scheme.get, call_402656509.host, call_402656509.base,
                                   call_402656509.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656509, uri, valid, _)

proc call*(call_402656510: Call_GetFunction_402656487; FunctionName: string): Recallable =
  ## getFunction
  ## <p>Returns the configuration information of the Lambda function and a presigned URL link to the .zip file you uploaded with <a>UploadFunction</a> so you can download the .zip file. Note that the URL is valid for up to 10 minutes. The configuration information is the same information you provided as parameters when uploading the function.</p> <p>This operation requires permission for the <code>lambda:GetFunction</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## FunctionName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name.
  var path_402656511 = newJObject()
  add(path_402656511, "FunctionName", newJString(FunctionName))
  result = call_402656510.call(path_402656511, nil, nil, nil, nil)

var getFunction* = Call_GetFunction_402656487(name: "getFunction",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_GetFunction_402656488, base: "/",
    makeUrl: url_GetFunction_402656489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_402656512 = ref object of OpenApiRestCall_402656038
proc url_DeleteFunction_402656514(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_402656513(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656515 = path.getOrDefault("FunctionName")
  valid_402656515 = validateParameter(valid_402656515, JString, required = true,
                                      default = nil)
  if valid_402656515 != nil:
    section.add "FunctionName", valid_402656515
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656516 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Security-Token", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Signature")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Signature", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Algorithm", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Date")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Date", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Credential")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Credential", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656523: Call_DeleteFunction_402656512; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
                                                                                         ## 
  let valid = call_402656523.validator(path, query, header, formData, body, _)
  let scheme = call_402656523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656523.makeUrl(scheme.get, call_402656523.host, call_402656523.base,
                                   call_402656523.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656523, uri, valid, _)

proc call*(call_402656524: Call_DeleteFunction_402656512; FunctionName: string): Recallable =
  ## deleteFunction
  ## <p>Deletes the specified Lambda function code and configuration.</p> <p>This operation requires permission for the <code>lambda:DeleteFunction</code> action.</p>
  ##   
                                                                                                                                                                      ## FunctionName: string (required)
                                                                                                                                                                      ##               
                                                                                                                                                                      ## : 
                                                                                                                                                                      ## The 
                                                                                                                                                                      ## Lambda 
                                                                                                                                                                      ## function 
                                                                                                                                                                      ## to 
                                                                                                                                                                      ## delete.
  var path_402656525 = newJObject()
  add(path_402656525, "FunctionName", newJString(FunctionName))
  result = call_402656524.call(path_402656525, nil, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_402656512(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}",
    validator: validate_DeleteFunction_402656513, base: "/",
    makeUrl: url_DeleteFunction_402656514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSource_402656526 = ref object of OpenApiRestCall_402656038
proc url_GetEventSource_402656528(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2014-11-13/event-source-mappings/"),
                 (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventSource_402656527(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
                                 ##       : The AWS Lambda assigned ID of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_402656529 = path.getOrDefault("UUID")
  valid_402656529 = validateParameter(valid_402656529, JString, required = true,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "UUID", valid_402656529
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656530 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Security-Token", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Signature")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Signature", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Algorithm", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Date")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Date", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Credential")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Credential", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656537: Call_GetEventSource_402656526; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
                                                                                         ## 
  let valid = call_402656537.validator(path, query, header, formData, body, _)
  let scheme = call_402656537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656537.makeUrl(scheme.get, call_402656537.host, call_402656537.base,
                                   call_402656537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656537, uri, valid, _)

proc call*(call_402656538: Call_GetEventSource_402656526; UUID: string): Recallable =
  ## getEventSource
  ## <p>Returns configuration information for the specified event source mapping (see <a>AddEventSource</a>).</p> <p>This operation requires permission for the <code>lambda:GetEventSource</code> action.</p>
  ##   
                                                                                                                                                                                                              ## UUID: string (required)
                                                                                                                                                                                                              ##       
                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                              ## AWS 
                                                                                                                                                                                                              ## Lambda 
                                                                                                                                                                                                              ## assigned 
                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                              ## event 
                                                                                                                                                                                                              ## source 
                                                                                                                                                                                                              ## mapping.
  var path_402656539 = newJObject()
  add(path_402656539, "UUID", newJString(UUID))
  result = call_402656538.call(path_402656539, nil, nil, nil, nil)

var getEventSource* = Call_GetEventSource_402656526(name: "getEventSource",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_GetEventSource_402656527, base: "/",
    makeUrl: url_GetEventSource_402656528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveEventSource_402656540 = ref object of OpenApiRestCall_402656038
proc url_RemoveEventSource_402656542(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2014-11-13/event-source-mappings/"),
                 (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveEventSource_402656541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
                                 ##       : The event source mapping ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_402656543 = path.getOrDefault("UUID")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true,
                                      default = nil)
  if valid_402656543 != nil:
    section.add "UUID", valid_402656543
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656551: Call_RemoveEventSource_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_RemoveEventSource_402656540; UUID: string): Recallable =
  ## removeEventSource
  ## <p>Removes an event source mapping. This means AWS Lambda will no longer invoke the function for events in the associated source.</p> <p>This operation requires permission for the <code>lambda:RemoveEventSource</code> action.</p>
  ##   
                                                                                                                                                                                                                                          ## UUID: string (required)
                                                                                                                                                                                                                                          ##       
                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                          ## event 
                                                                                                                                                                                                                                          ## source 
                                                                                                                                                                                                                                          ## mapping 
                                                                                                                                                                                                                                          ## ID.
  var path_402656553 = newJObject()
  add(path_402656553, "UUID", newJString(UUID))
  result = call_402656552.call(path_402656553, nil, nil, nil, nil)

var removeEventSource* = Call_RemoveEventSource_402656540(
    name: "removeEventSource", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/event-source-mappings/{UUID}",
    validator: validate_RemoveEventSource_402656541, base: "/",
    makeUrl: url_RemoveEventSource_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_402656568 = ref object of OpenApiRestCall_402656038
proc url_UpdateFunctionConfiguration_402656570(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_402656569(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656571 = path.getOrDefault("FunctionName")
  valid_402656571 = validateParameter(valid_402656571, JString, required = true,
                                      default = nil)
  if valid_402656571 != nil:
    section.add "FunctionName", valid_402656571
  result.add "path", section
  ## parameters in `query` object:
  ##   Timeout: JInt
                                  ##          : The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. 
  ##   
                                                                                                                                                                                                                                                                              ## Description: JString
                                                                                                                                                                                                                                                                              ##              
                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                              ## A 
                                                                                                                                                                                                                                                                              ## short 
                                                                                                                                                                                                                                                                              ## user-defined 
                                                                                                                                                                                                                                                                              ## function 
                                                                                                                                                                                                                                                                              ## description. 
                                                                                                                                                                                                                                                                              ## Lambda 
                                                                                                                                                                                                                                                                              ## does 
                                                                                                                                                                                                                                                                              ## not 
                                                                                                                                                                                                                                                                              ## use 
                                                                                                                                                                                                                                                                              ## this 
                                                                                                                                                                                                                                                                              ## value. 
                                                                                                                                                                                                                                                                              ## Assign 
                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                              ## meaningful 
                                                                                                                                                                                                                                                                              ## description 
                                                                                                                                                                                                                                                                              ## as 
                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                              ## see 
                                                                                                                                                                                                                                                                              ## fit.
  ##   
                                                                                                                                                                                                                                                                                     ## Handler: JString
                                                                                                                                                                                                                                                                                     ##          
                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                     ## function 
                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                     ## Lambda 
                                                                                                                                                                                                                                                                                     ## calls 
                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                     ## begin 
                                                                                                                                                                                                                                                                                     ## executing 
                                                                                                                                                                                                                                                                                     ## your 
                                                                                                                                                                                                                                                                                     ## function. 
                                                                                                                                                                                                                                                                                     ## For 
                                                                                                                                                                                                                                                                                     ## Node.js, 
                                                                                                                                                                                                                                                                                     ## it 
                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                     ## <i>module-name.export</i> 
                                                                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                     ## your 
                                                                                                                                                                                                                                                                                     ## function. 
  ##   
                                                                                                                                                                                                                                                                                                  ## MemorySize: JInt
                                                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                  ## amount 
                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                  ## memory, 
                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                  ## MB, 
                                                                                                                                                                                                                                                                                                  ## your 
                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                  ## function 
                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                  ## given. 
                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                  ## uses 
                                                                                                                                                                                                                                                                                                  ## this 
                                                                                                                                                                                                                                                                                                  ## memory 
                                                                                                                                                                                                                                                                                                  ## size 
                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                  ## infer 
                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                  ## amount 
                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                  ## CPU 
                                                                                                                                                                                                                                                                                                  ## allocated 
                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                  ## your 
                                                                                                                                                                                                                                                                                                  ## function. 
                                                                                                                                                                                                                                                                                                  ## Your 
                                                                                                                                                                                                                                                                                                  ## function 
                                                                                                                                                                                                                                                                                                  ## use-case 
                                                                                                                                                                                                                                                                                                  ## determines 
                                                                                                                                                                                                                                                                                                  ## your 
                                                                                                                                                                                                                                                                                                  ## CPU 
                                                                                                                                                                                                                                                                                                  ## and 
                                                                                                                                                                                                                                                                                                  ## memory 
                                                                                                                                                                                                                                                                                                  ## requirements. 
                                                                                                                                                                                                                                                                                                  ## For 
                                                                                                                                                                                                                                                                                                  ## example, 
                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                  ## database 
                                                                                                                                                                                                                                                                                                  ## operation 
                                                                                                                                                                                                                                                                                                  ## might 
                                                                                                                                                                                                                                                                                                  ## need 
                                                                                                                                                                                                                                                                                                  ## less 
                                                                                                                                                                                                                                                                                                  ## memory 
                                                                                                                                                                                                                                                                                                  ## compared 
                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                  ## an 
                                                                                                                                                                                                                                                                                                  ## image 
                                                                                                                                                                                                                                                                                                  ## processing 
                                                                                                                                                                                                                                                                                                  ## function. 
                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                  ## default 
                                                                                                                                                                                                                                                                                                  ## value 
                                                                                                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                                                                                                  ## 128 
                                                                                                                                                                                                                                                                                                  ## MB. 
                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                  ## value 
                                                                                                                                                                                                                                                                                                  ## must 
                                                                                                                                                                                                                                                                                                  ## be 
                                                                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                                                                  ## multiple 
                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                  ## 64 
                                                                                                                                                                                                                                                                                                  ## MB.
  ##   
                                                                                                                                                                                                                                                                                                        ## Role: JString
                                                                                                                                                                                                                                                                                                        ##       
                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                                                                                                                                        ## Resource 
                                                                                                                                                                                                                                                                                                        ## Name 
                                                                                                                                                                                                                                                                                                        ## (ARN) 
                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                        ## IAM 
                                                                                                                                                                                                                                                                                                        ## role 
                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                        ## Lambda 
                                                                                                                                                                                                                                                                                                        ## will 
                                                                                                                                                                                                                                                                                                        ## assume 
                                                                                                                                                                                                                                                                                                        ## when 
                                                                                                                                                                                                                                                                                                        ## it 
                                                                                                                                                                                                                                                                                                        ## executes 
                                                                                                                                                                                                                                                                                                        ## your 
                                                                                                                                                                                                                                                                                                        ## function. 
  section = newJObject()
  var valid_402656572 = query.getOrDefault("Timeout")
  valid_402656572 = validateParameter(valid_402656572, JInt, required = false,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "Timeout", valid_402656572
  var valid_402656573 = query.getOrDefault("Description")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "Description", valid_402656573
  var valid_402656574 = query.getOrDefault("Handler")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "Handler", valid_402656574
  var valid_402656575 = query.getOrDefault("MemorySize")
  valid_402656575 = validateParameter(valid_402656575, JInt, required = false,
                                      default = nil)
  if valid_402656575 != nil:
    section.add "MemorySize", valid_402656575
  var valid_402656576 = query.getOrDefault("Role")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "Role", valid_402656576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656584: Call_UpdateFunctionConfiguration_402656568;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
                                                                                         ## 
  let valid = call_402656584.validator(path, query, header, formData, body, _)
  let scheme = call_402656584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656584.makeUrl(scheme.get, call_402656584.host, call_402656584.base,
                                   call_402656584.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656584, uri, valid, _)

proc call*(call_402656585: Call_UpdateFunctionConfiguration_402656568;
           FunctionName: string; Timeout: int = 0; Description: string = "";
           Handler: string = ""; MemorySize: int = 0; Role: string = ""): Recallable =
  ## updateFunctionConfiguration
  ## <p>Updates the configuration parameters for the specified Lambda function by using the values provided in the request. You provide only the parameters you want to change. This operation must only be used on an existing Lambda function and cannot be used to update the function's code. </p> <p>This operation requires permission for the <code>lambda:UpdateFunctionConfiguration</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## Timeout: int
                                                                                                                                                                                                                                                                                                                                                                                                                ##          
                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                ## should 
                                                                                                                                                                                                                                                                                                                                                                                                                ## terminate 
                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                ## Because 
                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                ## has 
                                                                                                                                                                                                                                                                                                                                                                                                                ## cost 
                                                                                                                                                                                                                                                                                                                                                                                                                ## implications, 
                                                                                                                                                                                                                                                                                                                                                                                                                ## we 
                                                                                                                                                                                                                                                                                                                                                                                                                ## recommend 
                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                ## based 
                                                                                                                                                                                                                                                                                                                                                                                                                ## on 
                                                                                                                                                                                                                                                                                                                                                                                                                ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                ## expected 
                                                                                                                                                                                                                                                                                                                                                                                                                ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                ## time. 
                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                ## 3 
                                                                                                                                                                                                                                                                                                                                                                                                                ## seconds. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## Description: string
                                                                                                                                                                                                                                                                                                                                                                                                                            ##              
                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## short 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## user-defined 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## description. 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## does 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## value. 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## Assign 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## meaningful 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## description 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## see 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## fit.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Handler: string
                                                                                                                                                                                                                                                                                                                                                                                                                                   ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## calls 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## begin 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## executing 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Node.js, 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <i>module-name.export</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                   ## function. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## FunctionName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                ## function.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## MemorySize: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## amount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## memory, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## MB, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## given. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## uses 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## size 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## infer 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## amount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## CPU 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## allocated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## use-case 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## determines 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## CPU 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## requirements. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## database 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## operation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## might 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## need 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## less 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## compared 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## image 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## processing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## MB. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## multiple 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## 64 
                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## MB.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Role: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## IAM 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## role 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## will 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## assume 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## executes 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## function. 
  var path_402656586 = newJObject()
  var query_402656587 = newJObject()
  add(query_402656587, "Timeout", newJInt(Timeout))
  add(query_402656587, "Description", newJString(Description))
  add(query_402656587, "Handler", newJString(Handler))
  add(path_402656586, "FunctionName", newJString(FunctionName))
  add(query_402656587, "MemorySize", newJInt(MemorySize))
  add(query_402656587, "Role", newJString(Role))
  result = call_402656585.call(path_402656586, query_402656587, nil, nil, nil)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_402656568(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_402656569, base: "/",
    makeUrl: url_UpdateFunctionConfiguration_402656570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_402656554 = ref object of OpenApiRestCall_402656038
proc url_GetFunctionConfiguration_402656556(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_402656555(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656557 = path.getOrDefault("FunctionName")
  valid_402656557 = validateParameter(valid_402656557, JString, required = true,
                                      default = nil)
  if valid_402656557 != nil:
    section.add "FunctionName", valid_402656557
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656565: Call_GetFunctionConfiguration_402656554;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_GetFunctionConfiguration_402656554;
           FunctionName: string): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the configuration information of the Lambda function. This the same information you provided as parameters when uploading the function by using <a>UploadFunction</a>.</p> <p>This operation requires permission for the <code>lambda:GetFunctionConfiguration</code> operation.</p>
  ##   
                                                                                                                                                                                                                                                                                                    ## FunctionName: string (required)
                                                                                                                                                                                                                                                                                                    ##               
                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                    ## name 
                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                    ## Lambda 
                                                                                                                                                                                                                                                                                                    ## function 
                                                                                                                                                                                                                                                                                                    ## for 
                                                                                                                                                                                                                                                                                                    ## which 
                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                    ## want 
                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                    ## retrieve 
                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                    ## configuration 
                                                                                                                                                                                                                                                                                                    ## information.
  var path_402656567 = newJObject()
  add(path_402656567, "FunctionName", newJString(FunctionName))
  result = call_402656566.call(path_402656567, nil, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_402656554(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_402656555, base: "/",
    makeUrl: url_GetFunctionConfiguration_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_402656588 = ref object of OpenApiRestCall_402656038
proc url_InvokeAsync_402656590(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeAsync_402656589(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656591 = path.getOrDefault("FunctionName")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "FunctionName", valid_402656591
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Security-Token", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Signature")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Signature", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Algorithm", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Date")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Date", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Credential")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Credential", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656600: Call_InvokeAsync_402656588; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_InvokeAsync_402656588; FunctionName: string;
           body: JsonNode): Recallable =
  ## invokeAsync
  ## <p>Submits an invocation request to AWS Lambda. Upon receiving the request, Lambda executes the specified function asynchronously. To see the logs generated by the Lambda function execution, see the CloudWatch logs console.</p> <p>This operation requires permission for the <code>lambda:InvokeAsync</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                  ## FunctionName: string (required)
                                                                                                                                                                                                                                                                                                                                  ##               
                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                                                  ## function 
                                                                                                                                                                                                                                                                                                                                  ## name.
  ##   
                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var path_402656602 = newJObject()
  var body_402656603 = newJObject()
  add(path_402656602, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_402656603 = body
  result = call_402656601.call(path_402656602, nil, nil, nil, body_402656603)

var invokeAsync* = Call_InvokeAsync_402656588(name: "invokeAsync",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
    validator: validate_InvokeAsync_402656589, base: "/",
    makeUrl: url_InvokeAsync_402656590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_402656604 = ref object of OpenApiRestCall_402656038
proc url_ListFunctions_402656606(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctions_402656605(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. 
  ##   
                                                                                                                                                                                                               ## MaxItems: JInt
                                                                                                                                                                                                               ##           
                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                               ## Optional 
                                                                                                                                                                                                               ## integer. 
                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                               ## maximum 
                                                                                                                                                                                                               ## number 
                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                               ## AWS 
                                                                                                                                                                                                               ## Lambda 
                                                                                                                                                                                                               ## functions 
                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                               ## return 
                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                               ## response. 
                                                                                                                                                                                                               ## This 
                                                                                                                                                                                                               ## parameter 
                                                                                                                                                                                                               ## value 
                                                                                                                                                                                                               ## must 
                                                                                                                                                                                                               ## be 
                                                                                                                                                                                                               ## greater 
                                                                                                                                                                                                               ## than 
                                                                                                                                                                                                               ## 0.
  section = newJObject()
  var valid_402656607 = query.getOrDefault("Marker")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "Marker", valid_402656607
  var valid_402656608 = query.getOrDefault("MaxItems")
  valid_402656608 = validateParameter(valid_402656608, JInt, required = false,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "MaxItems", valid_402656608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Security-Token", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Signature")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Signature", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Algorithm", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Date")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Date", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Credential")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Credential", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656616: Call_ListFunctions_402656604; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
                                                                                         ## 
  let valid = call_402656616.validator(path, query, header, formData, body, _)
  let scheme = call_402656616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656616.makeUrl(scheme.get, call_402656616.host, call_402656616.base,
                                   call_402656616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656616, uri, valid, _)

proc call*(call_402656617: Call_ListFunctions_402656604; Marker: string = "";
           MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of your Lambda functions. For each function, the response includes the function configuration information. You must use <a>GetFunction</a> to retrieve the code for your function.</p> <p>This operation requires permission for the <code>lambda:ListFunctions</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                         ## Marker: string
                                                                                                                                                                                                                                                                                                         ##         
                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                         ## Optional 
                                                                                                                                                                                                                                                                                                         ## string. 
                                                                                                                                                                                                                                                                                                         ## An 
                                                                                                                                                                                                                                                                                                         ## opaque 
                                                                                                                                                                                                                                                                                                         ## pagination 
                                                                                                                                                                                                                                                                                                         ## token 
                                                                                                                                                                                                                                                                                                         ## returned 
                                                                                                                                                                                                                                                                                                         ## from 
                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                         ## previous 
                                                                                                                                                                                                                                                                                                         ## <code>ListFunctions</code> 
                                                                                                                                                                                                                                                                                                         ## operation. 
                                                                                                                                                                                                                                                                                                         ## If 
                                                                                                                                                                                                                                                                                                         ## present, 
                                                                                                                                                                                                                                                                                                         ## indicates 
                                                                                                                                                                                                                                                                                                         ## where 
                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                         ## continue 
                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                         ## listing. 
  ##   
                                                                                                                                                                                                                                                                                                                     ## MaxItems: int
                                                                                                                                                                                                                                                                                                                     ##           
                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                     ## Optional 
                                                                                                                                                                                                                                                                                                                     ## integer. 
                                                                                                                                                                                                                                                                                                                     ## Specifies 
                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                     ## maximum 
                                                                                                                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                     ## AWS 
                                                                                                                                                                                                                                                                                                                     ## Lambda 
                                                                                                                                                                                                                                                                                                                     ## functions 
                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                     ## return 
                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                     ## response. 
                                                                                                                                                                                                                                                                                                                     ## This 
                                                                                                                                                                                                                                                                                                                     ## parameter 
                                                                                                                                                                                                                                                                                                                     ## value 
                                                                                                                                                                                                                                                                                                                     ## must 
                                                                                                                                                                                                                                                                                                                     ## be 
                                                                                                                                                                                                                                                                                                                     ## greater 
                                                                                                                                                                                                                                                                                                                     ## than 
                                                                                                                                                                                                                                                                                                                     ## 0.
  var query_402656618 = newJObject()
  add(query_402656618, "Marker", newJString(Marker))
  add(query_402656618, "MaxItems", newJInt(MaxItems))
  result = call_402656617.call(nil, query_402656618, nil, nil, nil)

var listFunctions* = Call_ListFunctions_402656604(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/", validator: validate_ListFunctions_402656605,
    base: "/", makeUrl: url_ListFunctions_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadFunction_402656619 = ref object of OpenApiRestCall_402656038
proc url_UploadFunction_402656621(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UploadFunction_402656620(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656622 = path.getOrDefault("FunctionName")
  valid_402656622 = validateParameter(valid_402656622, JString, required = true,
                                      default = nil)
  if valid_402656622 != nil:
    section.add "FunctionName", valid_402656622
  result.add "path", section
  ## parameters in `query` object:
  ##   Runtime: JString (required)
                                  ##          : The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.
  ##   
                                                                                                                                                                           ## Timeout: JInt
                                                                                                                                                                           ##          
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## function 
                                                                                                                                                                           ## execution 
                                                                                                                                                                           ## time 
                                                                                                                                                                           ## at 
                                                                                                                                                                           ## which 
                                                                                                                                                                           ## Lambda 
                                                                                                                                                                           ## should 
                                                                                                                                                                           ## terminate 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## function. 
                                                                                                                                                                           ## Because 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## execution 
                                                                                                                                                                           ## time 
                                                                                                                                                                           ## has 
                                                                                                                                                                           ## cost 
                                                                                                                                                                           ## implications, 
                                                                                                                                                                           ## we 
                                                                                                                                                                           ## recommend 
                                                                                                                                                                           ## you 
                                                                                                                                                                           ## set 
                                                                                                                                                                           ## this 
                                                                                                                                                                           ## value 
                                                                                                                                                                           ## based 
                                                                                                                                                                           ## on 
                                                                                                                                                                           ## your 
                                                                                                                                                                           ## expected 
                                                                                                                                                                           ## execution 
                                                                                                                                                                           ## time. 
                                                                                                                                                                           ## The 
                                                                                                                                                                           ## default 
                                                                                                                                                                           ## is 
                                                                                                                                                                           ## 3 
                                                                                                                                                                           ## seconds. 
  ##   
                                                                                                                                                                                       ## Description: JString
                                                                                                                                                                                       ##              
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## A 
                                                                                                                                                                                       ## short, 
                                                                                                                                                                                       ## user-defined 
                                                                                                                                                                                       ## function 
                                                                                                                                                                                       ## description. 
                                                                                                                                                                                       ## Lambda 
                                                                                                                                                                                       ## does 
                                                                                                                                                                                       ## not 
                                                                                                                                                                                       ## use 
                                                                                                                                                                                       ## this 
                                                                                                                                                                                       ## value. 
                                                                                                                                                                                       ## Assign 
                                                                                                                                                                                       ## a 
                                                                                                                                                                                       ## meaningful 
                                                                                                                                                                                       ## description 
                                                                                                                                                                                       ## as 
                                                                                                                                                                                       ## you 
                                                                                                                                                                                       ## see 
                                                                                                                                                                                       ## fit.
  ##   
                                                                                                                                                                                              ## Handler: JString (required)
                                                                                                                                                                                              ##          
                                                                                                                                                                                              ## : 
                                                                                                                                                                                              ## The 
                                                                                                                                                                                              ## function 
                                                                                                                                                                                              ## that 
                                                                                                                                                                                              ## Lambda 
                                                                                                                                                                                              ## calls 
                                                                                                                                                                                              ## to 
                                                                                                                                                                                              ## begin 
                                                                                                                                                                                              ## execution. 
                                                                                                                                                                                              ## For 
                                                                                                                                                                                              ## Node.js, 
                                                                                                                                                                                              ## it 
                                                                                                                                                                                              ## is 
                                                                                                                                                                                              ## the 
                                                                                                                                                                                              ## <i>module-name</i>.<i>export</i> 
                                                                                                                                                                                              ## value 
                                                                                                                                                                                              ## in 
                                                                                                                                                                                              ## your 
                                                                                                                                                                                              ## function. 
  ##   
                                                                                                                                                                                                           ## MemorySize: JInt
                                                                                                                                                                                                           ##             
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                           ## amount 
                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                           ## memory, 
                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                           ## MB, 
                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                           ## Lambda 
                                                                                                                                                                                                           ## function 
                                                                                                                                                                                                           ## is 
                                                                                                                                                                                                           ## given. 
                                                                                                                                                                                                           ## Lambda 
                                                                                                                                                                                                           ## uses 
                                                                                                                                                                                                           ## this 
                                                                                                                                                                                                           ## memory 
                                                                                                                                                                                                           ## size 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## infer 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## amount 
                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                           ## CPU 
                                                                                                                                                                                                           ## allocated 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                           ## function. 
                                                                                                                                                                                                           ## Your 
                                                                                                                                                                                                           ## function 
                                                                                                                                                                                                           ## use-case 
                                                                                                                                                                                                           ## determines 
                                                                                                                                                                                                           ## your 
                                                                                                                                                                                                           ## CPU 
                                                                                                                                                                                                           ## and 
                                                                                                                                                                                                           ## memory 
                                                                                                                                                                                                           ## requirements. 
                                                                                                                                                                                                           ## For 
                                                                                                                                                                                                           ## example, 
                                                                                                                                                                                                           ## database 
                                                                                                                                                                                                           ## operation 
                                                                                                                                                                                                           ## might 
                                                                                                                                                                                                           ## need 
                                                                                                                                                                                                           ## less 
                                                                                                                                                                                                           ## memory 
                                                                                                                                                                                                           ## compared 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## image 
                                                                                                                                                                                                           ## processing 
                                                                                                                                                                                                           ## function. 
                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                           ## default 
                                                                                                                                                                                                           ## value 
                                                                                                                                                                                                           ## is 
                                                                                                                                                                                                           ## 128 
                                                                                                                                                                                                           ## MB. 
                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                           ## value 
                                                                                                                                                                                                           ## must 
                                                                                                                                                                                                           ## be 
                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                           ## multiple 
                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                           ## 64 
                                                                                                                                                                                                           ## MB.
  ##   
                                                                                                                                                                                                                 ## Role: JString (required)
                                                                                                                                                                                                                 ##       
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                                                 ## Resource 
                                                                                                                                                                                                                 ## Name 
                                                                                                                                                                                                                 ## (ARN) 
                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## IAM 
                                                                                                                                                                                                                 ## role 
                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                 ## Lambda 
                                                                                                                                                                                                                 ## assumes 
                                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                                 ## it 
                                                                                                                                                                                                                 ## executes 
                                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                                 ## function 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## access 
                                                                                                                                                                                                                 ## any 
                                                                                                                                                                                                                 ## other 
                                                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                                                 ## Web 
                                                                                                                                                                                                                 ## Services 
                                                                                                                                                                                                                 ## (AWS) 
                                                                                                                                                                                                                 ## resources. 
  ##   
                                                                                                                                                                                                                               ## Mode: JString (required)
                                                                                                                                                                                                                               ##       
                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                               ## How 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## Lambda 
                                                                                                                                                                                                                               ## function 
                                                                                                                                                                                                                               ## will 
                                                                                                                                                                                                                               ## be 
                                                                                                                                                                                                                               ## invoked. 
                                                                                                                                                                                                                               ## Lambda 
                                                                                                                                                                                                                               ## supports 
                                                                                                                                                                                                                               ## only 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## "event" 
                                                                                                                                                                                                                               ## mode. 
  section = newJObject()
  var valid_402656635 = query.getOrDefault("Runtime")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = newJString("nodejs"))
  if valid_402656635 != nil:
    section.add "Runtime", valid_402656635
  var valid_402656636 = query.getOrDefault("Timeout")
  valid_402656636 = validateParameter(valid_402656636, JInt, required = false,
                                      default = nil)
  if valid_402656636 != nil:
    section.add "Timeout", valid_402656636
  var valid_402656637 = query.getOrDefault("Description")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "Description", valid_402656637
  var valid_402656638 = query.getOrDefault("Handler")
  valid_402656638 = validateParameter(valid_402656638, JString, required = true,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "Handler", valid_402656638
  var valid_402656639 = query.getOrDefault("MemorySize")
  valid_402656639 = validateParameter(valid_402656639, JInt, required = false,
                                      default = nil)
  if valid_402656639 != nil:
    section.add "MemorySize", valid_402656639
  var valid_402656640 = query.getOrDefault("Role")
  valid_402656640 = validateParameter(valid_402656640, JString, required = true,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "Role", valid_402656640
  var valid_402656641 = query.getOrDefault("Mode")
  valid_402656641 = validateParameter(valid_402656641, JString, required = true,
                                      default = newJString("event"))
  if valid_402656641 != nil:
    section.add "Mode", valid_402656641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Security-Token", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Signature")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Signature", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Algorithm", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Date")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Date", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Credential")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Credential", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656650: Call_UploadFunction_402656619; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
                                                                                         ## 
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_UploadFunction_402656619; Handler: string;
           FunctionName: string; body: JsonNode; Role: string;
           Runtime: string = "nodejs"; Timeout: int = 0;
           Description: string = ""; MemorySize: int = 0; Mode: string = "event"): Recallable =
  ## uploadFunction
  ## <p>Creates a new Lambda function or updates an existing function. The function metadata is created from the request parameters, and the code for the function is provided by a .zip file in the request body. If the function name already exists, the existing Lambda function is updated with the new code and metadata. </p> <p>This operation requires permission for the <code>lambda:UploadFunction</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Runtime: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                 ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## runtime 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## environment 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## uploading. 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Currently, 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## supports 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## only 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## "nodejs" 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                 ## runtime.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Timeout: int
                                                                                                                                                                                                                                                                                                                                                                                                                                            ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## should 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## terminate 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Because 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## has 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## cost 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## implications, 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## we 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## recommend 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## based 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## on 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## expected 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## execution 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## time. 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## 3 
                                                                                                                                                                                                                                                                                                                                                                                                                                            ## seconds. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Description: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## short, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## user-defined 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## description. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## does 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## value. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Assign 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## meaningful 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## description 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## see 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## fit.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Handler: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## calls 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## begin 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## execution. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Node.js, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## <i>module-name</i>.<i>export</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## function. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## FunctionName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## assign 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## uploading. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## names 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## appear 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## console 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <a>ListFunctions</a> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## API. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## names 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## functions 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## other 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## AWS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## APIs, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## such 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <a>InvokeAsync</a>. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MemorySize: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## amount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## memory, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MB, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## given. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## uses 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## size 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## infer 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## amount 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## CPU 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## allocated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## Your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## use-case 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## determines 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## CPU 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## requirements. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## database 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## operation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## might 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## need 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## less 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## memory 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## compared 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## image 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## processing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## function. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 128 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MB. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## multiple 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 64 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MB.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Role: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## IAM 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## role 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## assumes 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## it 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## executes 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## your 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## any 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## other 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Web 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Services 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## (AWS) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## resources. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Mode: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## How 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## function 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## will 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## invoked. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Lambda 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## supports 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## only 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## "event" 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## mode. 
  var path_402656652 = newJObject()
  var query_402656653 = newJObject()
  var body_402656654 = newJObject()
  add(query_402656653, "Runtime", newJString(Runtime))
  add(query_402656653, "Timeout", newJInt(Timeout))
  add(query_402656653, "Description", newJString(Description))
  add(query_402656653, "Handler", newJString(Handler))
  add(path_402656652, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_402656654 = body
  add(query_402656653, "MemorySize", newJInt(MemorySize))
  add(query_402656653, "Role", newJString(Role))
  add(query_402656653, "Mode", newJString(Mode))
  result = call_402656651.call(path_402656652, query_402656653, nil, nil, body_402656654)

var uploadFunction* = Call_UploadFunction_402656619(name: "uploadFunction",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}#Runtime&Role&Handler&Mode",
    validator: validate_UploadFunction_402656620, base: "/",
    makeUrl: url_UploadFunction_402656621, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}