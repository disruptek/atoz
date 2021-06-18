
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Augmented AI Runtime
## version: 2019-11-07
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Augmented AI (Augmented AI) (Preview) is a service that adds human judgment to any machine learning application. Human reviewers can take over when an AI application can't evaluate data with a high degree of confidence.</p> <p>From fraudulent bank transaction identification to document processing to image analysis, machine learning models can be trained to make decisions as well as or better than a human. Nevertheless, some decisions require contextual interpretation, such as when you need to decide whether an image is appropriate for a given audience. Content moderation guidelines are nuanced and highly dependent on context, and they vary between countries. When trying to apply AI in these situations, you can be forced to choose between "ML only" systems with unacceptably high error rates or "human only" systems that are expensive and difficult to scale, and that slow down decision making.</p> <p>This API reference includes information about API actions and data types you can use to interact with Augmented AI programmatically. </p> <p>You can create a flow definition against the Augmented AI API. Provide the Amazon Resource Name (ARN) of a flow definition to integrate AI service APIs, such as <code>Textract.AnalyzeDocument</code> and <code>Rekognition.DetectModerationLabels</code>. These AI services, in turn, invoke the <a>StartHumanLoop</a> API, which evaluates conditions under which humans will be invoked. If humans are required, Augmented AI creates a human loop. Results of human work are available asynchronously in Amazon Simple Storage Service (Amazon S3). You can use Amazon CloudWatch Events to detect human work results.</p> <p>You can find additional Augmented AI API documentation in the following reference guides: <a href="https://aws.amazon.com/rekognition/latest/dg/API_Reference.html">Amazon Rekognition</a>, <a href="https://aws.amazon.com/sagemaker/latest/dg/API_Reference.html">Amazon SageMaker</a>, and <a href="https://aws.amazon.com/textract/latest/dg/API_Reference.html">Amazon Textract</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sagemaker/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "a2i-runtime.sagemaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "a2i-runtime.sagemaker.ap-southeast-1.amazonaws.com", "us-west-2": "a2i-runtime.sagemaker.us-west-2.amazonaws.com", "eu-west-2": "a2i-runtime.sagemaker.eu-west-2.amazonaws.com", "ap-northeast-3": "a2i-runtime.sagemaker.ap-northeast-3.amazonaws.com", "eu-central-1": "a2i-runtime.sagemaker.eu-central-1.amazonaws.com", "us-east-2": "a2i-runtime.sagemaker.us-east-2.amazonaws.com", "us-east-1": "a2i-runtime.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "a2i-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "a2i-runtime.sagemaker.ap-south-1.amazonaws.com", "eu-north-1": "a2i-runtime.sagemaker.eu-north-1.amazonaws.com", "ap-northeast-2": "a2i-runtime.sagemaker.ap-northeast-2.amazonaws.com", "us-west-1": "a2i-runtime.sagemaker.us-west-1.amazonaws.com", "us-gov-east-1": "a2i-runtime.sagemaker.us-gov-east-1.amazonaws.com", "eu-west-3": "a2i-runtime.sagemaker.eu-west-3.amazonaws.com", "cn-north-1": "a2i-runtime.sagemaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "a2i-runtime.sagemaker.sa-east-1.amazonaws.com", "eu-west-1": "a2i-runtime.sagemaker.eu-west-1.amazonaws.com", "us-gov-west-1": "a2i-runtime.sagemaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "a2i-runtime.sagemaker.ap-southeast-2.amazonaws.com", "ca-central-1": "a2i-runtime.sagemaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "a2i-runtime.sagemaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "a2i-runtime.sagemaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "a2i-runtime.sagemaker.us-west-2.amazonaws.com",
      "eu-west-2": "a2i-runtime.sagemaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "a2i-runtime.sagemaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "a2i-runtime.sagemaker.eu-central-1.amazonaws.com",
      "us-east-2": "a2i-runtime.sagemaker.us-east-2.amazonaws.com",
      "us-east-1": "a2i-runtime.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "a2i-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "a2i-runtime.sagemaker.ap-south-1.amazonaws.com",
      "eu-north-1": "a2i-runtime.sagemaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "a2i-runtime.sagemaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "a2i-runtime.sagemaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "a2i-runtime.sagemaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "a2i-runtime.sagemaker.eu-west-3.amazonaws.com",
      "cn-north-1": "a2i-runtime.sagemaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "a2i-runtime.sagemaker.sa-east-1.amazonaws.com",
      "eu-west-1": "a2i-runtime.sagemaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "a2i-runtime.sagemaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "a2i-runtime.sagemaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "a2i-runtime.sagemaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sagemaker-a2i-runtime"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_DescribeHumanLoop_402656288 = ref object of OpenApiRestCall_402656038
proc url_DescribeHumanLoop_402656290(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HumanLoopName" in path, "`HumanLoopName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/human-loops/"),
                 (kind: VariableSegment, value: "HumanLoopName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeHumanLoop_402656289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about the specified human loop.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HumanLoopName: JString (required)
                                 ##                : The name of the human loop.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `HumanLoopName` field"
  var valid_402656380 = path.getOrDefault("HumanLoopName")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "HumanLoopName", valid_402656380
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
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_DescribeHumanLoop_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified human loop.
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_DescribeHumanLoop_402656288;
           HumanLoopName: string): Recallable =
  ## describeHumanLoop
  ## Returns information about the specified human loop.
  ##   HumanLoopName: string (required)
                                                        ##                : The name of the human loop.
  var path_402656451 = newJObject()
  add(path_402656451, "HumanLoopName", newJString(HumanLoopName))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var describeHumanLoop* = Call_DescribeHumanLoop_402656288(
    name: "describeHumanLoop", meth: HttpMethod.HttpGet,
    host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}",
    validator: validate_DescribeHumanLoop_402656289, base: "/",
    makeUrl: url_DescribeHumanLoop_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHumanLoop_402656481 = ref object of OpenApiRestCall_402656038
proc url_DeleteHumanLoop_402656483(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "HumanLoopName" in path, "`HumanLoopName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/human-loops/"),
                 (kind: VariableSegment, value: "HumanLoopName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHumanLoop_402656482(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified human loop for a flow definition.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   HumanLoopName: JString (required)
                                 ##                : The name of the human loop you want to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `HumanLoopName` field"
  var valid_402656484 = path.getOrDefault("HumanLoopName")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "HumanLoopName", valid_402656484
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
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656492: Call_DeleteHumanLoop_402656481; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified human loop for a flow definition.
                                                                                         ## 
  let valid = call_402656492.validator(path, query, header, formData, body, _)
  let scheme = call_402656492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656492.makeUrl(scheme.get, call_402656492.host, call_402656492.base,
                                   call_402656492.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656492, uri, valid, _)

proc call*(call_402656493: Call_DeleteHumanLoop_402656481; HumanLoopName: string): Recallable =
  ## deleteHumanLoop
  ## Deletes the specified human loop for a flow definition.
  ##   HumanLoopName: string (required)
                                                            ##                : The name of the human loop you want to delete.
  var path_402656494 = newJObject()
  add(path_402656494, "HumanLoopName", newJString(HumanLoopName))
  result = call_402656493.call(path_402656494, nil, nil, nil, nil)

var deleteHumanLoop* = Call_DeleteHumanLoop_402656481(name: "deleteHumanLoop",
    meth: HttpMethod.HttpDelete, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DeleteHumanLoop_402656482,
    base: "/", makeUrl: url_DeleteHumanLoop_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartHumanLoop_402656525 = ref object of OpenApiRestCall_402656038
proc url_StartHumanLoop_402656527(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartHumanLoop_402656526(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a human loop, provided that at least one activation condition is met.
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
  var valid_402656528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Security-Token", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Signature")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Signature", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Algorithm", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Date")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Date", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Credential")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Credential", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656534
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

proc call*(call_402656536: Call_StartHumanLoop_402656525; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a human loop, provided that at least one activation condition is met.
                                                                                         ## 
  let valid = call_402656536.validator(path, query, header, formData, body, _)
  let scheme = call_402656536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656536.makeUrl(scheme.get, call_402656536.host, call_402656536.base,
                                   call_402656536.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656536, uri, valid, _)

proc call*(call_402656537: Call_StartHumanLoop_402656525; body: JsonNode): Recallable =
  ## startHumanLoop
  ## Starts a human loop, provided that at least one activation condition is met.
  ##   
                                                                                 ## body: JObject (required)
  var body_402656538 = newJObject()
  if body != nil:
    body_402656538 = body
  result = call_402656537.call(nil, nil, nil, nil, body_402656538)

var startHumanLoop* = Call_StartHumanLoop_402656525(name: "startHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_StartHumanLoop_402656526,
    base: "/", makeUrl: url_StartHumanLoop_402656527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanLoops_402656495 = ref object of OpenApiRestCall_402656038
proc url_ListHumanLoops_402656497(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanLoops_402656496(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about human loops, given the specified parameters.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CreationTimeBefore: JString
                                  ##                     : (Optional) The timestamp of the date before which you want the human loops to begin. For example, <code>1550000000</code>.
  ##   
                                                                                                                                                                                     ## MaxResults: JInt
                                                                                                                                                                                     ##             
                                                                                                                                                                                     ## : 
                                                                                                                                                                                     ## The 
                                                                                                                                                                                     ## total 
                                                                                                                                                                                     ## number 
                                                                                                                                                                                     ## of 
                                                                                                                                                                                     ## items 
                                                                                                                                                                                     ## to 
                                                                                                                                                                                     ## return. 
                                                                                                                                                                                     ## If 
                                                                                                                                                                                     ## the 
                                                                                                                                                                                     ## total 
                                                                                                                                                                                     ## number 
                                                                                                                                                                                     ## of 
                                                                                                                                                                                     ## available 
                                                                                                                                                                                     ## items 
                                                                                                                                                                                     ## is 
                                                                                                                                                                                     ## more 
                                                                                                                                                                                     ## than 
                                                                                                                                                                                     ## the 
                                                                                                                                                                                     ## value 
                                                                                                                                                                                     ## specified 
                                                                                                                                                                                     ## in 
                                                                                                                                                                                     ## <code>MaxResults</code>, 
                                                                                                                                                                                     ## then 
                                                                                                                                                                                     ## a 
                                                                                                                                                                                     ## <code>NextToken</code> 
                                                                                                                                                                                     ## will 
                                                                                                                                                                                     ## be 
                                                                                                                                                                                     ## provided 
                                                                                                                                                                                     ## in 
                                                                                                                                                                                     ## the 
                                                                                                                                                                                     ## output 
                                                                                                                                                                                     ## that 
                                                                                                                                                                                     ## you 
                                                                                                                                                                                     ## can 
                                                                                                                                                                                     ## use 
                                                                                                                                                                                     ## to 
                                                                                                                                                                                     ## resume 
                                                                                                                                                                                     ## pagination.
  ##   
                                                                                                                                                                                                   ## CreationTimeAfter: JString
                                                                                                                                                                                                   ##                    
                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                   ## (Optional) 
                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                   ## timestamp 
                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## date 
                                                                                                                                                                                                   ## when 
                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                   ## human 
                                                                                                                                                                                                   ## loops 
                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                   ## begin. 
                                                                                                                                                                                                   ## For 
                                                                                                                                                                                                   ## example, 
                                                                                                                                                                                                   ## <code>1551000000</code>.
  ##   
                                                                                                                                                                                                                              ## NextToken: JString
                                                                                                                                                                                                                              ##            
                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                              ## A 
                                                                                                                                                                                                                              ## token 
                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                              ## resume 
                                                                                                                                                                                                                              ## pagination.
  ##   
                                                                                                                                                                                                                                            ## SortOrder: JString
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## An 
                                                                                                                                                                                                                                            ## optional 
                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                            ## specifies 
                                                                                                                                                                                                                                            ## whether 
                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                            ## sorted 
                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                            ## <code>Ascending</code> 
                                                                                                                                                                                                                                            ## or 
                                                                                                                                                                                                                                            ## <code>Descending</code> 
                                                                                                                                                                                                                                            ## order.
  section = newJObject()
  var valid_402656498 = query.getOrDefault("CreationTimeBefore")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "CreationTimeBefore", valid_402656498
  var valid_402656499 = query.getOrDefault("MaxResults")
  valid_402656499 = validateParameter(valid_402656499, JInt, required = false,
                                      default = nil)
  if valid_402656499 != nil:
    section.add "MaxResults", valid_402656499
  var valid_402656500 = query.getOrDefault("CreationTimeAfter")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "CreationTimeAfter", valid_402656500
  var valid_402656501 = query.getOrDefault("NextToken")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "NextToken", valid_402656501
  var valid_402656514 = query.getOrDefault("SortOrder")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false,
                                      default = newJString("Ascending"))
  if valid_402656514 != nil:
    section.add "SortOrder", valid_402656514
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
  var valid_402656515 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Security-Token", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Signature")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Signature", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Algorithm", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Date")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Date", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Credential")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Credential", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656522: Call_ListHumanLoops_402656495; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about human loops, given the specified parameters.
                                                                                         ## 
  let valid = call_402656522.validator(path, query, header, formData, body, _)
  let scheme = call_402656522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656522.makeUrl(scheme.get, call_402656522.host, call_402656522.base,
                                   call_402656522.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656522, uri, valid, _)

proc call*(call_402656523: Call_ListHumanLoops_402656495;
           CreationTimeBefore: string = ""; MaxResults: int = 0;
           CreationTimeAfter: string = ""; NextToken: string = "";
           SortOrder: string = "Ascending"): Recallable =
  ## listHumanLoops
  ## Returns information about human loops, given the specified parameters.
  ##   
                                                                           ## CreationTimeBefore: string
                                                                           ##                     
                                                                           ## : 
                                                                           ## (Optional) 
                                                                           ## The 
                                                                           ## timestamp 
                                                                           ## of 
                                                                           ## the 
                                                                           ## date 
                                                                           ## before 
                                                                           ## which 
                                                                           ## you 
                                                                           ## want 
                                                                           ## the 
                                                                           ## human 
                                                                           ## loops 
                                                                           ## to 
                                                                           ## begin. 
                                                                           ## For 
                                                                           ## example, 
                                                                           ## <code>1550000000</code>.
  ##   
                                                                                                      ## MaxResults: int
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## total 
                                                                                                      ## number 
                                                                                                      ## of 
                                                                                                      ## items 
                                                                                                      ## to 
                                                                                                      ## return. 
                                                                                                      ## If 
                                                                                                      ## the 
                                                                                                      ## total 
                                                                                                      ## number 
                                                                                                      ## of 
                                                                                                      ## available 
                                                                                                      ## items 
                                                                                                      ## is 
                                                                                                      ## more 
                                                                                                      ## than 
                                                                                                      ## the 
                                                                                                      ## value 
                                                                                                      ## specified 
                                                                                                      ## in 
                                                                                                      ## <code>MaxResults</code>, 
                                                                                                      ## then 
                                                                                                      ## a 
                                                                                                      ## <code>NextToken</code> 
                                                                                                      ## will 
                                                                                                      ## be 
                                                                                                      ## provided 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## output 
                                                                                                      ## that 
                                                                                                      ## you 
                                                                                                      ## can 
                                                                                                      ## use 
                                                                                                      ## to 
                                                                                                      ## resume 
                                                                                                      ## pagination.
  ##   
                                                                                                                    ## CreationTimeAfter: string
                                                                                                                    ##                    
                                                                                                                    ## : 
                                                                                                                    ## (Optional) 
                                                                                                                    ## The 
                                                                                                                    ## timestamp 
                                                                                                                    ## of 
                                                                                                                    ## the 
                                                                                                                    ## date 
                                                                                                                    ## when 
                                                                                                                    ## you 
                                                                                                                    ## want 
                                                                                                                    ## the 
                                                                                                                    ## human 
                                                                                                                    ## loops 
                                                                                                                    ## to 
                                                                                                                    ## begin. 
                                                                                                                    ## For 
                                                                                                                    ## example, 
                                                                                                                    ## <code>1551000000</code>.
  ##   
                                                                                                                                               ## NextToken: string
                                                                                                                                               ##            
                                                                                                                                               ## : 
                                                                                                                                               ## A 
                                                                                                                                               ## token 
                                                                                                                                               ## to 
                                                                                                                                               ## resume 
                                                                                                                                               ## pagination.
  ##   
                                                                                                                                                             ## SortOrder: string
                                                                                                                                                             ##            
                                                                                                                                                             ## : 
                                                                                                                                                             ## An 
                                                                                                                                                             ## optional 
                                                                                                                                                             ## value 
                                                                                                                                                             ## that 
                                                                                                                                                             ## specifies 
                                                                                                                                                             ## whether 
                                                                                                                                                             ## you 
                                                                                                                                                             ## want 
                                                                                                                                                             ## the 
                                                                                                                                                             ## results 
                                                                                                                                                             ## sorted 
                                                                                                                                                             ## in 
                                                                                                                                                             ## <code>Ascending</code> 
                                                                                                                                                             ## or 
                                                                                                                                                             ## <code>Descending</code> 
                                                                                                                                                             ## order.
  var query_402656524 = newJObject()
  add(query_402656524, "CreationTimeBefore", newJString(CreationTimeBefore))
  add(query_402656524, "MaxResults", newJInt(MaxResults))
  add(query_402656524, "CreationTimeAfter", newJString(CreationTimeAfter))
  add(query_402656524, "NextToken", newJString(NextToken))
  add(query_402656524, "SortOrder", newJString(SortOrder))
  result = call_402656523.call(nil, query_402656524, nil, nil, nil)

var listHumanLoops* = Call_ListHumanLoops_402656495(name: "listHumanLoops",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_ListHumanLoops_402656496,
    base: "/", makeUrl: url_ListHumanLoops_402656497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHumanLoop_402656539 = ref object of OpenApiRestCall_402656038
proc url_StopHumanLoop_402656541(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopHumanLoop_402656540(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops the specified human loop.
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
  var valid_402656542 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Security-Token", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Signature")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Signature", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Algorithm", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Date")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Date", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Credential")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Credential", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656548
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

proc call*(call_402656550: Call_StopHumanLoop_402656539; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the specified human loop.
                                                                                         ## 
  let valid = call_402656550.validator(path, query, header, formData, body, _)
  let scheme = call_402656550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656550.makeUrl(scheme.get, call_402656550.host, call_402656550.base,
                                   call_402656550.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656550, uri, valid, _)

proc call*(call_402656551: Call_StopHumanLoop_402656539; body: JsonNode): Recallable =
  ## stopHumanLoop
  ## Stops the specified human loop.
  ##   body: JObject (required)
  var body_402656552 = newJObject()
  if body != nil:
    body_402656552 = body
  result = call_402656551.call(nil, nil, nil, nil, body_402656552)

var stopHumanLoop* = Call_StopHumanLoop_402656539(name: "stopHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/stop", validator: validate_StopHumanLoop_402656540,
    base: "/", makeUrl: url_StopHumanLoop_402656541,
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