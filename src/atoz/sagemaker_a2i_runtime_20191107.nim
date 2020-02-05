
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeHumanLoop_612987 = ref object of OpenApiRestCall_612649
proc url_DescribeHumanLoop_612989(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeHumanLoop_612988(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_613115 = path.getOrDefault("HumanLoopName")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "HumanLoopName", valid_613115
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
  var valid_613116 = header.getOrDefault("X-Amz-Signature")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Signature", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Content-Sha256", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Date")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Date", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Credential")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Credential", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Security-Token")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Security-Token", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Algorithm")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Algorithm", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-SignedHeaders", valid_613122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_DescribeHumanLoop_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified human loop.
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_DescribeHumanLoop_612987; HumanLoopName: string): Recallable =
  ## describeHumanLoop
  ## Returns information about the specified human loop.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop.
  var path_613217 = newJObject()
  add(path_613217, "HumanLoopName", newJString(HumanLoopName))
  result = call_613216.call(path_613217, nil, nil, nil, nil)

var describeHumanLoop* = Call_DescribeHumanLoop_612987(name: "describeHumanLoop",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DescribeHumanLoop_612988,
    base: "/", url: url_DescribeHumanLoop_612989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHumanLoop_613257 = ref object of OpenApiRestCall_612649
proc url_DeleteHumanLoop_613259(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteHumanLoop_613258(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_613260 = path.getOrDefault("HumanLoopName")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = nil)
  if valid_613260 != nil:
    section.add "HumanLoopName", valid_613260
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
  var valid_613261 = header.getOrDefault("X-Amz-Signature")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Signature", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Content-Sha256", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Date")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Date", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Credential")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Credential", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Security-Token")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Security-Token", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-Algorithm")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Algorithm", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-SignedHeaders", valid_613267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613268: Call_DeleteHumanLoop_613257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified human loop for a flow definition.
  ## 
  let valid = call_613268.validator(path, query, header, formData, body)
  let scheme = call_613268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613268.url(scheme.get, call_613268.host, call_613268.base,
                         call_613268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613268, url, valid)

proc call*(call_613269: Call_DeleteHumanLoop_613257; HumanLoopName: string): Recallable =
  ## deleteHumanLoop
  ## Deletes the specified human loop for a flow definition.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop you want to delete.
  var path_613270 = newJObject()
  add(path_613270, "HumanLoopName", newJString(HumanLoopName))
  result = call_613269.call(path_613270, nil, nil, nil, nil)

var deleteHumanLoop* = Call_DeleteHumanLoop_613257(name: "deleteHumanLoop",
    meth: HttpMethod.HttpDelete, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DeleteHumanLoop_613258,
    base: "/", url: url_DeleteHumanLoop_613259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartHumanLoop_613302 = ref object of OpenApiRestCall_612649
proc url_StartHumanLoop_613304(protocol: Scheme; host: string; base: string;
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

proc validate_StartHumanLoop_613303(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts a human loop, provided that at least one activation condition is met.
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
  var valid_613305 = header.getOrDefault("X-Amz-Signature")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Signature", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Content-Sha256", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Date")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Date", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Credential")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Credential", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Security-Token")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Security-Token", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Algorithm")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Algorithm", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-SignedHeaders", valid_613311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613313: Call_StartHumanLoop_613302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a human loop, provided that at least one activation condition is met.
  ## 
  let valid = call_613313.validator(path, query, header, formData, body)
  let scheme = call_613313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613313.url(scheme.get, call_613313.host, call_613313.base,
                         call_613313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613313, url, valid)

proc call*(call_613314: Call_StartHumanLoop_613302; body: JsonNode): Recallable =
  ## startHumanLoop
  ## Starts a human loop, provided that at least one activation condition is met.
  ##   body: JObject (required)
  var body_613315 = newJObject()
  if body != nil:
    body_613315 = body
  result = call_613314.call(nil, nil, nil, nil, body_613315)

var startHumanLoop* = Call_StartHumanLoop_613302(name: "startHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_StartHumanLoop_613303, base: "/",
    url: url_StartHumanLoop_613304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanLoops_613271 = ref object of OpenApiRestCall_612649
proc url_ListHumanLoops_613273(protocol: Scheme; host: string; base: string;
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

proc validate_ListHumanLoops_613272(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about human loops, given the specified parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CreationTimeAfter: JString
  ##                    : (Optional) The timestamp of the date when you want the human loops to begin. For example, <code>1551000000</code>.
  ##   MaxResults: JInt
  ##             : The total number of items to return. If the total number of available items is more than the value specified in <code>MaxResults</code>, then a <code>NextToken</code> will be provided in the output that you can use to resume pagination.
  ##   NextToken: JString
  ##            : A token to resume pagination.
  ##   CreationTimeBefore: JString
  ##                     : (Optional) The timestamp of the date before which you want the human loops to begin. For example, <code>1550000000</code>.
  ##   SortOrder: JString
  ##            : An optional value that specifies whether you want the results sorted in <code>Ascending</code> or <code>Descending</code> order.
  section = newJObject()
  var valid_613274 = query.getOrDefault("CreationTimeAfter")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "CreationTimeAfter", valid_613274
  var valid_613275 = query.getOrDefault("MaxResults")
  valid_613275 = validateParameter(valid_613275, JInt, required = false, default = nil)
  if valid_613275 != nil:
    section.add "MaxResults", valid_613275
  var valid_613276 = query.getOrDefault("NextToken")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "NextToken", valid_613276
  var valid_613277 = query.getOrDefault("CreationTimeBefore")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "CreationTimeBefore", valid_613277
  var valid_613291 = query.getOrDefault("SortOrder")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = newJString("Ascending"))
  if valid_613291 != nil:
    section.add "SortOrder", valid_613291
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

proc call*(call_613299: Call_ListHumanLoops_613271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about human loops, given the specified parameters.
  ## 
  let valid = call_613299.validator(path, query, header, formData, body)
  let scheme = call_613299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613299.url(scheme.get, call_613299.host, call_613299.base,
                         call_613299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613299, url, valid)

proc call*(call_613300: Call_ListHumanLoops_613271; CreationTimeAfter: string = "";
          MaxResults: int = 0; NextToken: string = ""; CreationTimeBefore: string = "";
          SortOrder: string = "Ascending"): Recallable =
  ## listHumanLoops
  ## Returns information about human loops, given the specified parameters.
  ##   CreationTimeAfter: string
  ##                    : (Optional) The timestamp of the date when you want the human loops to begin. For example, <code>1551000000</code>.
  ##   MaxResults: int
  ##             : The total number of items to return. If the total number of available items is more than the value specified in <code>MaxResults</code>, then a <code>NextToken</code> will be provided in the output that you can use to resume pagination.
  ##   NextToken: string
  ##            : A token to resume pagination.
  ##   CreationTimeBefore: string
  ##                     : (Optional) The timestamp of the date before which you want the human loops to begin. For example, <code>1550000000</code>.
  ##   SortOrder: string
  ##            : An optional value that specifies whether you want the results sorted in <code>Ascending</code> or <code>Descending</code> order.
  var query_613301 = newJObject()
  add(query_613301, "CreationTimeAfter", newJString(CreationTimeAfter))
  add(query_613301, "MaxResults", newJInt(MaxResults))
  add(query_613301, "NextToken", newJString(NextToken))
  add(query_613301, "CreationTimeBefore", newJString(CreationTimeBefore))
  add(query_613301, "SortOrder", newJString(SortOrder))
  result = call_613300.call(nil, query_613301, nil, nil, nil)

var listHumanLoops* = Call_ListHumanLoops_613271(name: "listHumanLoops",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_ListHumanLoops_613272, base: "/",
    url: url_ListHumanLoops_613273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHumanLoop_613316 = ref object of OpenApiRestCall_612649
proc url_StopHumanLoop_613318(protocol: Scheme; host: string; base: string;
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

proc validate_StopHumanLoop_613317(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops the specified human loop.
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
  var valid_613319 = header.getOrDefault("X-Amz-Signature")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Signature", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Content-Sha256", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Date")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Date", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Credential")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Credential", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Security-Token")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Security-Token", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Algorithm")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Algorithm", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-SignedHeaders", valid_613325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613327: Call_StopHumanLoop_613316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified human loop.
  ## 
  let valid = call_613327.validator(path, query, header, formData, body)
  let scheme = call_613327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613327.url(scheme.get, call_613327.host, call_613327.base,
                         call_613327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613327, url, valid)

proc call*(call_613328: Call_StopHumanLoop_613316; body: JsonNode): Recallable =
  ## stopHumanLoop
  ## Stops the specified human loop.
  ##   body: JObject (required)
  var body_613329 = newJObject()
  if body != nil:
    body_613329 = body
  result = call_613328.call(nil, nil, nil, nil, body_613329)

var stopHumanLoop* = Call_StopHumanLoop_613316(name: "stopHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/stop", validator: validate_StopHumanLoop_613317, base: "/",
    url: url_StopHumanLoop_613318, schemes: {Scheme.Https, Scheme.Http})
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
