
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "a2i-runtime.sagemaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "a2i-runtime.sagemaker.ap-southeast-1.amazonaws.com", "us-west-2": "a2i-runtime.sagemaker.us-west-2.amazonaws.com", "eu-west-2": "a2i-runtime.sagemaker.eu-west-2.amazonaws.com", "ap-northeast-3": "a2i-runtime.sagemaker.ap-northeast-3.amazonaws.com", "eu-central-1": "a2i-runtime.sagemaker.eu-central-1.amazonaws.com", "us-east-2": "a2i-runtime.sagemaker.us-east-2.amazonaws.com", "us-east-1": "a2i-runtime.sagemaker.us-east-1.amazonaws.com", "cn-northwest-1": "a2i-runtime.sagemaker.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "a2i-runtime.sagemaker.ap-south-1.amazonaws.com", "eu-north-1": "a2i-runtime.sagemaker.eu-north-1.amazonaws.com", "ap-northeast-2": "a2i-runtime.sagemaker.ap-northeast-2.amazonaws.com", "us-west-1": "a2i-runtime.sagemaker.us-west-1.amazonaws.com", "us-gov-east-1": "a2i-runtime.sagemaker.us-gov-east-1.amazonaws.com", "eu-west-3": "a2i-runtime.sagemaker.eu-west-3.amazonaws.com", "cn-north-1": "a2i-runtime.sagemaker.cn-north-1.amazonaws.com.cn", "sa-east-1": "a2i-runtime.sagemaker.sa-east-1.amazonaws.com", "eu-west-1": "a2i-runtime.sagemaker.eu-west-1.amazonaws.com", "us-gov-west-1": "a2i-runtime.sagemaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "a2i-runtime.sagemaker.ap-southeast-2.amazonaws.com", "ca-central-1": "a2i-runtime.sagemaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_DescribeHumanLoop_21625770 = ref object of OpenApiRestCall_21625426
proc url_DescribeHumanLoop_21625772(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DescribeHumanLoop_21625771(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21625886 = path.getOrDefault("HumanLoopName")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "HumanLoopName", valid_21625886
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
  var valid_21625887 = header.getOrDefault("X-Amz-Date")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Date", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Security-Token", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Algorithm", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-Signature")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-Signature", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625892
  var valid_21625893 = header.getOrDefault("X-Amz-Credential")
  valid_21625893 = validateParameter(valid_21625893, JString, required = false,
                                   default = nil)
  if valid_21625893 != nil:
    section.add "X-Amz-Credential", valid_21625893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625918: Call_DescribeHumanLoop_21625770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the specified human loop.
  ## 
  let valid = call_21625918.validator(path, query, header, formData, body, _)
  let scheme = call_21625918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625918.makeUrl(scheme.get, call_21625918.host, call_21625918.base,
                               call_21625918.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625918, uri, valid, _)

proc call*(call_21625981: Call_DescribeHumanLoop_21625770; HumanLoopName: string): Recallable =
  ## describeHumanLoop
  ## Returns information about the specified human loop.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop.
  var path_21625983 = newJObject()
  add(path_21625983, "HumanLoopName", newJString(HumanLoopName))
  result = call_21625981.call(path_21625983, nil, nil, nil, nil)

var describeHumanLoop* = Call_DescribeHumanLoop_21625770(name: "describeHumanLoop",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DescribeHumanLoop_21625771,
    base: "/", makeUrl: url_DescribeHumanLoop_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHumanLoop_21626021 = ref object of OpenApiRestCall_21625426
proc url_DeleteHumanLoop_21626023(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteHumanLoop_21626022(path: JsonNode; query: JsonNode;
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
  var valid_21626024 = path.getOrDefault("HumanLoopName")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "HumanLoopName", valid_21626024
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
  var valid_21626025 = header.getOrDefault("X-Amz-Date")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Date", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Security-Token", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Algorithm", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Signature")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Signature", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626030
  var valid_21626031 = header.getOrDefault("X-Amz-Credential")
  valid_21626031 = validateParameter(valid_21626031, JString, required = false,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "X-Amz-Credential", valid_21626031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626032: Call_DeleteHumanLoop_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified human loop for a flow definition.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_DeleteHumanLoop_21626021; HumanLoopName: string): Recallable =
  ## deleteHumanLoop
  ## Deletes the specified human loop for a flow definition.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop you want to delete.
  var path_21626034 = newJObject()
  add(path_21626034, "HumanLoopName", newJString(HumanLoopName))
  result = call_21626033.call(path_21626034, nil, nil, nil, nil)

var deleteHumanLoop* = Call_DeleteHumanLoop_21626021(name: "deleteHumanLoop",
    meth: HttpMethod.HttpDelete, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DeleteHumanLoop_21626022,
    base: "/", makeUrl: url_DeleteHumanLoop_21626023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartHumanLoop_21626069 = ref object of OpenApiRestCall_21625426
proc url_StartHumanLoop_21626071(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartHumanLoop_21626070(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626072 = header.getOrDefault("X-Amz-Date")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Date", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Security-Token", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Algorithm", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Signature")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Signature", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Credential")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Credential", valid_21626078
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

proc call*(call_21626080: Call_StartHumanLoop_21626069; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a human loop, provided that at least one activation condition is met.
  ## 
  let valid = call_21626080.validator(path, query, header, formData, body, _)
  let scheme = call_21626080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626080.makeUrl(scheme.get, call_21626080.host, call_21626080.base,
                               call_21626080.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626080, uri, valid, _)

proc call*(call_21626081: Call_StartHumanLoop_21626069; body: JsonNode): Recallable =
  ## startHumanLoop
  ## Starts a human loop, provided that at least one activation condition is met.
  ##   body: JObject (required)
  var body_21626082 = newJObject()
  if body != nil:
    body_21626082 = body
  result = call_21626081.call(nil, nil, nil, nil, body_21626082)

var startHumanLoop* = Call_StartHumanLoop_21626069(name: "startHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_StartHumanLoop_21626070, base: "/",
    makeUrl: url_StartHumanLoop_21626071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanLoops_21626035 = ref object of OpenApiRestCall_21625426
proc url_ListHumanLoops_21626037(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHumanLoops_21626036(path: JsonNode; query: JsonNode;
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
  ##   SortOrder: JString
  ##            : An optional value that specifies whether you want the results sorted in <code>Ascending</code> or <code>Descending</code> order.
  ##   CreationTimeAfter: JString
  ##                    : (Optional) The timestamp of the date when you want the human loops to begin. For example, <code>1551000000</code>.
  ##   NextToken: JString
  ##            : A token to resume pagination.
  ##   CreationTimeBefore: JString
  ##                     : (Optional) The timestamp of the date before which you want the human loops to begin. For example, <code>1550000000</code>.
  ##   MaxResults: JInt
  ##             : The total number of items to return. If the total number of available items is more than the value specified in <code>MaxResults</code>, then a <code>NextToken</code> will be provided in the output that you can use to resume pagination.
  section = newJObject()
  var valid_21626052 = query.getOrDefault("SortOrder")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = newJString("Ascending"))
  if valid_21626052 != nil:
    section.add "SortOrder", valid_21626052
  var valid_21626053 = query.getOrDefault("CreationTimeAfter")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "CreationTimeAfter", valid_21626053
  var valid_21626054 = query.getOrDefault("NextToken")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "NextToken", valid_21626054
  var valid_21626055 = query.getOrDefault("CreationTimeBefore")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "CreationTimeBefore", valid_21626055
  var valid_21626056 = query.getOrDefault("MaxResults")
  valid_21626056 = validateParameter(valid_21626056, JInt, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "MaxResults", valid_21626056
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
  var valid_21626057 = header.getOrDefault("X-Amz-Date")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Date", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Security-Token", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Algorithm", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Signature")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Signature", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Credential")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Credential", valid_21626063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626064: Call_ListHumanLoops_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about human loops, given the specified parameters.
  ## 
  let valid = call_21626064.validator(path, query, header, formData, body, _)
  let scheme = call_21626064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626064.makeUrl(scheme.get, call_21626064.host, call_21626064.base,
                               call_21626064.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626064, uri, valid, _)

proc call*(call_21626065: Call_ListHumanLoops_21626035;
          SortOrder: string = "Ascending"; CreationTimeAfter: string = "";
          NextToken: string = ""; CreationTimeBefore: string = ""; MaxResults: int = 0): Recallable =
  ## listHumanLoops
  ## Returns information about human loops, given the specified parameters.
  ##   SortOrder: string
  ##            : An optional value that specifies whether you want the results sorted in <code>Ascending</code> or <code>Descending</code> order.
  ##   CreationTimeAfter: string
  ##                    : (Optional) The timestamp of the date when you want the human loops to begin. For example, <code>1551000000</code>.
  ##   NextToken: string
  ##            : A token to resume pagination.
  ##   CreationTimeBefore: string
  ##                     : (Optional) The timestamp of the date before which you want the human loops to begin. For example, <code>1550000000</code>.
  ##   MaxResults: int
  ##             : The total number of items to return. If the total number of available items is more than the value specified in <code>MaxResults</code>, then a <code>NextToken</code> will be provided in the output that you can use to resume pagination.
  var query_21626066 = newJObject()
  add(query_21626066, "SortOrder", newJString(SortOrder))
  add(query_21626066, "CreationTimeAfter", newJString(CreationTimeAfter))
  add(query_21626066, "NextToken", newJString(NextToken))
  add(query_21626066, "CreationTimeBefore", newJString(CreationTimeBefore))
  add(query_21626066, "MaxResults", newJInt(MaxResults))
  result = call_21626065.call(nil, query_21626066, nil, nil, nil)

var listHumanLoops* = Call_ListHumanLoops_21626035(name: "listHumanLoops",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_ListHumanLoops_21626036, base: "/",
    makeUrl: url_ListHumanLoops_21626037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHumanLoop_21626083 = ref object of OpenApiRestCall_21625426
proc url_StopHumanLoop_21626085(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopHumanLoop_21626084(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Stops the specified human loop.
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
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
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

proc call*(call_21626094: Call_StopHumanLoop_21626083; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops the specified human loop.
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_StopHumanLoop_21626083; body: JsonNode): Recallable =
  ## stopHumanLoop
  ## Stops the specified human loop.
  ##   body: JObject (required)
  var body_21626096 = newJObject()
  if body != nil:
    body_21626096 = body
  result = call_21626095.call(nil, nil, nil, nil, body_21626096)

var stopHumanLoop* = Call_StopHumanLoop_21626083(name: "stopHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/stop", validator: validate_StopHumanLoop_21626084,
    base: "/", makeUrl: url_StopHumanLoop_21626085,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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