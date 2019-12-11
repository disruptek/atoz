
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

  OpenApiRestCall_597380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597380): Option[Scheme] {.used.} =
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
  Call_DescribeHumanLoop_597718 = ref object of OpenApiRestCall_597380
proc url_DescribeHumanLoop_597720(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHumanLoop_597719(path: JsonNode; query: JsonNode;
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
  var valid_597846 = path.getOrDefault("HumanLoopName")
  valid_597846 = validateParameter(valid_597846, JString, required = true,
                                 default = nil)
  if valid_597846 != nil:
    section.add "HumanLoopName", valid_597846
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
  var valid_597847 = header.getOrDefault("X-Amz-Signature")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-Signature", valid_597847
  var valid_597848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597848 = validateParameter(valid_597848, JString, required = false,
                                 default = nil)
  if valid_597848 != nil:
    section.add "X-Amz-Content-Sha256", valid_597848
  var valid_597849 = header.getOrDefault("X-Amz-Date")
  valid_597849 = validateParameter(valid_597849, JString, required = false,
                                 default = nil)
  if valid_597849 != nil:
    section.add "X-Amz-Date", valid_597849
  var valid_597850 = header.getOrDefault("X-Amz-Credential")
  valid_597850 = validateParameter(valid_597850, JString, required = false,
                                 default = nil)
  if valid_597850 != nil:
    section.add "X-Amz-Credential", valid_597850
  var valid_597851 = header.getOrDefault("X-Amz-Security-Token")
  valid_597851 = validateParameter(valid_597851, JString, required = false,
                                 default = nil)
  if valid_597851 != nil:
    section.add "X-Amz-Security-Token", valid_597851
  var valid_597852 = header.getOrDefault("X-Amz-Algorithm")
  valid_597852 = validateParameter(valid_597852, JString, required = false,
                                 default = nil)
  if valid_597852 != nil:
    section.add "X-Amz-Algorithm", valid_597852
  var valid_597853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597853 = validateParameter(valid_597853, JString, required = false,
                                 default = nil)
  if valid_597853 != nil:
    section.add "X-Amz-SignedHeaders", valid_597853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597876: Call_DescribeHumanLoop_597718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified human loop.
  ## 
  let valid = call_597876.validator(path, query, header, formData, body)
  let scheme = call_597876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597876.url(scheme.get, call_597876.host, call_597876.base,
                         call_597876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597876, url, valid)

proc call*(call_597947: Call_DescribeHumanLoop_597718; HumanLoopName: string): Recallable =
  ## describeHumanLoop
  ## Returns information about the specified human loop.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop.
  var path_597948 = newJObject()
  add(path_597948, "HumanLoopName", newJString(HumanLoopName))
  result = call_597947.call(path_597948, nil, nil, nil, nil)

var describeHumanLoop* = Call_DescribeHumanLoop_597718(name: "describeHumanLoop",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DescribeHumanLoop_597719,
    base: "/", url: url_DescribeHumanLoop_597720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHumanLoop_597988 = ref object of OpenApiRestCall_597380
proc url_DeleteHumanLoop_597990(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteHumanLoop_597989(path: JsonNode; query: JsonNode;
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
  var valid_597991 = path.getOrDefault("HumanLoopName")
  valid_597991 = validateParameter(valid_597991, JString, required = true,
                                 default = nil)
  if valid_597991 != nil:
    section.add "HumanLoopName", valid_597991
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
  var valid_597992 = header.getOrDefault("X-Amz-Signature")
  valid_597992 = validateParameter(valid_597992, JString, required = false,
                                 default = nil)
  if valid_597992 != nil:
    section.add "X-Amz-Signature", valid_597992
  var valid_597993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597993 = validateParameter(valid_597993, JString, required = false,
                                 default = nil)
  if valid_597993 != nil:
    section.add "X-Amz-Content-Sha256", valid_597993
  var valid_597994 = header.getOrDefault("X-Amz-Date")
  valid_597994 = validateParameter(valid_597994, JString, required = false,
                                 default = nil)
  if valid_597994 != nil:
    section.add "X-Amz-Date", valid_597994
  var valid_597995 = header.getOrDefault("X-Amz-Credential")
  valid_597995 = validateParameter(valid_597995, JString, required = false,
                                 default = nil)
  if valid_597995 != nil:
    section.add "X-Amz-Credential", valid_597995
  var valid_597996 = header.getOrDefault("X-Amz-Security-Token")
  valid_597996 = validateParameter(valid_597996, JString, required = false,
                                 default = nil)
  if valid_597996 != nil:
    section.add "X-Amz-Security-Token", valid_597996
  var valid_597997 = header.getOrDefault("X-Amz-Algorithm")
  valid_597997 = validateParameter(valid_597997, JString, required = false,
                                 default = nil)
  if valid_597997 != nil:
    section.add "X-Amz-Algorithm", valid_597997
  var valid_597998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597998 = validateParameter(valid_597998, JString, required = false,
                                 default = nil)
  if valid_597998 != nil:
    section.add "X-Amz-SignedHeaders", valid_597998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597999: Call_DeleteHumanLoop_597988; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified human loop for a flow definition.
  ## 
  let valid = call_597999.validator(path, query, header, formData, body)
  let scheme = call_597999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597999.url(scheme.get, call_597999.host, call_597999.base,
                         call_597999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597999, url, valid)

proc call*(call_598000: Call_DeleteHumanLoop_597988; HumanLoopName: string): Recallable =
  ## deleteHumanLoop
  ## Deletes the specified human loop for a flow definition.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop you want to delete.
  var path_598001 = newJObject()
  add(path_598001, "HumanLoopName", newJString(HumanLoopName))
  result = call_598000.call(path_598001, nil, nil, nil, nil)

var deleteHumanLoop* = Call_DeleteHumanLoop_597988(name: "deleteHumanLoop",
    meth: HttpMethod.HttpDelete, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DeleteHumanLoop_597989,
    base: "/", url: url_DeleteHumanLoop_597990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartHumanLoop_598033 = ref object of OpenApiRestCall_597380
proc url_StartHumanLoop_598035(protocol: Scheme; host: string; base: string;
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

proc validate_StartHumanLoop_598034(path: JsonNode; query: JsonNode;
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
  var valid_598036 = header.getOrDefault("X-Amz-Signature")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Signature", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Content-Sha256", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-Date")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Date", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Credential")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Credential", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-Security-Token")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-Security-Token", valid_598040
  var valid_598041 = header.getOrDefault("X-Amz-Algorithm")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Algorithm", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-SignedHeaders", valid_598042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598044: Call_StartHumanLoop_598033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a human loop, provided that at least one activation condition is met.
  ## 
  let valid = call_598044.validator(path, query, header, formData, body)
  let scheme = call_598044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598044.url(scheme.get, call_598044.host, call_598044.base,
                         call_598044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598044, url, valid)

proc call*(call_598045: Call_StartHumanLoop_598033; body: JsonNode): Recallable =
  ## startHumanLoop
  ## Starts a human loop, provided that at least one activation condition is met.
  ##   body: JObject (required)
  var body_598046 = newJObject()
  if body != nil:
    body_598046 = body
  result = call_598045.call(nil, nil, nil, nil, body_598046)

var startHumanLoop* = Call_StartHumanLoop_598033(name: "startHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_StartHumanLoop_598034, base: "/",
    url: url_StartHumanLoop_598035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanLoops_598002 = ref object of OpenApiRestCall_597380
proc url_ListHumanLoops_598004(protocol: Scheme; host: string; base: string;
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

proc validate_ListHumanLoops_598003(path: JsonNode; query: JsonNode;
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
  var valid_598005 = query.getOrDefault("CreationTimeAfter")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "CreationTimeAfter", valid_598005
  var valid_598006 = query.getOrDefault("MaxResults")
  valid_598006 = validateParameter(valid_598006, JInt, required = false, default = nil)
  if valid_598006 != nil:
    section.add "MaxResults", valid_598006
  var valid_598007 = query.getOrDefault("NextToken")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "NextToken", valid_598007
  var valid_598008 = query.getOrDefault("CreationTimeBefore")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "CreationTimeBefore", valid_598008
  var valid_598022 = query.getOrDefault("SortOrder")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = newJString("Ascending"))
  if valid_598022 != nil:
    section.add "SortOrder", valid_598022
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
  var valid_598023 = header.getOrDefault("X-Amz-Signature")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Signature", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Content-Sha256", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Date")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Date", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-Credential")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-Credential", valid_598026
  var valid_598027 = header.getOrDefault("X-Amz-Security-Token")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Security-Token", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-Algorithm")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-Algorithm", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-SignedHeaders", valid_598029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598030: Call_ListHumanLoops_598002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about human loops, given the specified parameters.
  ## 
  let valid = call_598030.validator(path, query, header, formData, body)
  let scheme = call_598030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598030.url(scheme.get, call_598030.host, call_598030.base,
                         call_598030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598030, url, valid)

proc call*(call_598031: Call_ListHumanLoops_598002; CreationTimeAfter: string = "";
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
  var query_598032 = newJObject()
  add(query_598032, "CreationTimeAfter", newJString(CreationTimeAfter))
  add(query_598032, "MaxResults", newJInt(MaxResults))
  add(query_598032, "NextToken", newJString(NextToken))
  add(query_598032, "CreationTimeBefore", newJString(CreationTimeBefore))
  add(query_598032, "SortOrder", newJString(SortOrder))
  result = call_598031.call(nil, query_598032, nil, nil, nil)

var listHumanLoops* = Call_ListHumanLoops_598002(name: "listHumanLoops",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_ListHumanLoops_598003, base: "/",
    url: url_ListHumanLoops_598004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHumanLoop_598047 = ref object of OpenApiRestCall_597380
proc url_StopHumanLoop_598049(protocol: Scheme; host: string; base: string;
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

proc validate_StopHumanLoop_598048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598050 = header.getOrDefault("X-Amz-Signature")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Signature", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Content-Sha256", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-Date")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Date", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Credential")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Credential", valid_598053
  var valid_598054 = header.getOrDefault("X-Amz-Security-Token")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Security-Token", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Algorithm")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Algorithm", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-SignedHeaders", valid_598056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598058: Call_StopHumanLoop_598047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified human loop.
  ## 
  let valid = call_598058.validator(path, query, header, formData, body)
  let scheme = call_598058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598058.url(scheme.get, call_598058.host, call_598058.base,
                         call_598058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598058, url, valid)

proc call*(call_598059: Call_StopHumanLoop_598047; body: JsonNode): Recallable =
  ## stopHumanLoop
  ## Stops the specified human loop.
  ##   body: JObject (required)
  var body_598060 = newJObject()
  if body != nil:
    body_598060 = body
  result = call_598059.call(nil, nil, nil, nil, body_598060)

var stopHumanLoop* = Call_StopHumanLoop_598047(name: "stopHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/stop", validator: validate_StopHumanLoop_598048, base: "/",
    url: url_StopHumanLoop_598049, schemes: {Scheme.Https, Scheme.Http})
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
