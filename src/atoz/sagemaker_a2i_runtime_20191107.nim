
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
  Call_DescribeHumanLoop_605918 = ref object of OpenApiRestCall_605580
proc url_DescribeHumanLoop_605920(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHumanLoop_605919(path: JsonNode; query: JsonNode;
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
  var valid_606046 = path.getOrDefault("HumanLoopName")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "HumanLoopName", valid_606046
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
  var valid_606047 = header.getOrDefault("X-Amz-Signature")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Signature", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Content-Sha256", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Date")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Date", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Credential")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Credential", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Security-Token")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Security-Token", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Algorithm")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Algorithm", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-SignedHeaders", valid_606053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606076: Call_DescribeHumanLoop_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the specified human loop.
  ## 
  let valid = call_606076.validator(path, query, header, formData, body)
  let scheme = call_606076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606076.url(scheme.get, call_606076.host, call_606076.base,
                         call_606076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606076, url, valid)

proc call*(call_606147: Call_DescribeHumanLoop_605918; HumanLoopName: string): Recallable =
  ## describeHumanLoop
  ## Returns information about the specified human loop.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop.
  var path_606148 = newJObject()
  add(path_606148, "HumanLoopName", newJString(HumanLoopName))
  result = call_606147.call(path_606148, nil, nil, nil, nil)

var describeHumanLoop* = Call_DescribeHumanLoop_605918(name: "describeHumanLoop",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DescribeHumanLoop_605919,
    base: "/", url: url_DescribeHumanLoop_605920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteHumanLoop_606188 = ref object of OpenApiRestCall_605580
proc url_DeleteHumanLoop_606190(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteHumanLoop_606189(path: JsonNode; query: JsonNode;
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
  var valid_606191 = path.getOrDefault("HumanLoopName")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = nil)
  if valid_606191 != nil:
    section.add "HumanLoopName", valid_606191
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
  var valid_606192 = header.getOrDefault("X-Amz-Signature")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Signature", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Content-Sha256", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Date")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Date", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-Credential")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-Credential", valid_606195
  var valid_606196 = header.getOrDefault("X-Amz-Security-Token")
  valid_606196 = validateParameter(valid_606196, JString, required = false,
                                 default = nil)
  if valid_606196 != nil:
    section.add "X-Amz-Security-Token", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-Algorithm")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Algorithm", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-SignedHeaders", valid_606198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606199: Call_DeleteHumanLoop_606188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified human loop for a flow definition.
  ## 
  let valid = call_606199.validator(path, query, header, formData, body)
  let scheme = call_606199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606199.url(scheme.get, call_606199.host, call_606199.base,
                         call_606199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606199, url, valid)

proc call*(call_606200: Call_DeleteHumanLoop_606188; HumanLoopName: string): Recallable =
  ## deleteHumanLoop
  ## Deletes the specified human loop for a flow definition.
  ##   HumanLoopName: string (required)
  ##                : The name of the human loop you want to delete.
  var path_606201 = newJObject()
  add(path_606201, "HumanLoopName", newJString(HumanLoopName))
  result = call_606200.call(path_606201, nil, nil, nil, nil)

var deleteHumanLoop* = Call_DeleteHumanLoop_606188(name: "deleteHumanLoop",
    meth: HttpMethod.HttpDelete, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/{HumanLoopName}", validator: validate_DeleteHumanLoop_606189,
    base: "/", url: url_DeleteHumanLoop_606190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartHumanLoop_606233 = ref object of OpenApiRestCall_605580
proc url_StartHumanLoop_606235(protocol: Scheme; host: string; base: string;
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

proc validate_StartHumanLoop_606234(path: JsonNode; query: JsonNode;
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
  var valid_606236 = header.getOrDefault("X-Amz-Signature")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Signature", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Content-Sha256", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Date")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Date", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Credential")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Credential", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Security-Token")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Security-Token", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Algorithm")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Algorithm", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-SignedHeaders", valid_606242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606244: Call_StartHumanLoop_606233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a human loop, provided that at least one activation condition is met.
  ## 
  let valid = call_606244.validator(path, query, header, formData, body)
  let scheme = call_606244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606244.url(scheme.get, call_606244.host, call_606244.base,
                         call_606244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606244, url, valid)

proc call*(call_606245: Call_StartHumanLoop_606233; body: JsonNode): Recallable =
  ## startHumanLoop
  ## Starts a human loop, provided that at least one activation condition is met.
  ##   body: JObject (required)
  var body_606246 = newJObject()
  if body != nil:
    body_606246 = body
  result = call_606245.call(nil, nil, nil, nil, body_606246)

var startHumanLoop* = Call_StartHumanLoop_606233(name: "startHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_StartHumanLoop_606234, base: "/",
    url: url_StartHumanLoop_606235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHumanLoops_606202 = ref object of OpenApiRestCall_605580
proc url_ListHumanLoops_606204(protocol: Scheme; host: string; base: string;
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

proc validate_ListHumanLoops_606203(path: JsonNode; query: JsonNode;
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
  var valid_606205 = query.getOrDefault("CreationTimeAfter")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "CreationTimeAfter", valid_606205
  var valid_606206 = query.getOrDefault("MaxResults")
  valid_606206 = validateParameter(valid_606206, JInt, required = false, default = nil)
  if valid_606206 != nil:
    section.add "MaxResults", valid_606206
  var valid_606207 = query.getOrDefault("NextToken")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "NextToken", valid_606207
  var valid_606208 = query.getOrDefault("CreationTimeBefore")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "CreationTimeBefore", valid_606208
  var valid_606222 = query.getOrDefault("SortOrder")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = newJString("Ascending"))
  if valid_606222 != nil:
    section.add "SortOrder", valid_606222
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

proc call*(call_606230: Call_ListHumanLoops_606202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about human loops, given the specified parameters.
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_ListHumanLoops_606202; CreationTimeAfter: string = "";
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
  var query_606232 = newJObject()
  add(query_606232, "CreationTimeAfter", newJString(CreationTimeAfter))
  add(query_606232, "MaxResults", newJInt(MaxResults))
  add(query_606232, "NextToken", newJString(NextToken))
  add(query_606232, "CreationTimeBefore", newJString(CreationTimeBefore))
  add(query_606232, "SortOrder", newJString(SortOrder))
  result = call_606231.call(nil, query_606232, nil, nil, nil)

var listHumanLoops* = Call_ListHumanLoops_606202(name: "listHumanLoops",
    meth: HttpMethod.HttpGet, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops", validator: validate_ListHumanLoops_606203, base: "/",
    url: url_ListHumanLoops_606204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopHumanLoop_606247 = ref object of OpenApiRestCall_605580
proc url_StopHumanLoop_606249(protocol: Scheme; host: string; base: string;
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

proc validate_StopHumanLoop_606248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606250 = header.getOrDefault("X-Amz-Signature")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Signature", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Content-Sha256", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Date")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Date", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Credential")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Credential", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Security-Token")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Security-Token", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Algorithm")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Algorithm", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-SignedHeaders", valid_606256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606258: Call_StopHumanLoop_606247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the specified human loop.
  ## 
  let valid = call_606258.validator(path, query, header, formData, body)
  let scheme = call_606258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606258.url(scheme.get, call_606258.host, call_606258.base,
                         call_606258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606258, url, valid)

proc call*(call_606259: Call_StopHumanLoop_606247; body: JsonNode): Recallable =
  ## stopHumanLoop
  ## Stops the specified human loop.
  ##   body: JObject (required)
  var body_606260 = newJObject()
  if body != nil:
    body_606260 = body
  result = call_606259.call(nil, nil, nil, nil, body_606260)

var stopHumanLoop* = Call_StopHumanLoop_606247(name: "stopHumanLoop",
    meth: HttpMethod.HttpPost, host: "a2i-runtime.sagemaker.amazonaws.com",
    route: "/human-loops/stop", validator: validate_StopHumanLoop_606248, base: "/",
    url: url_StopHumanLoop_606249, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
