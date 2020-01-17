
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Rekognition
## version: 2016-06-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This is the Amazon Rekognition API reference.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/rekognition/
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

  OpenApiRestCall_605590 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605590](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605590): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "rekognition.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rekognition.ap-southeast-1.amazonaws.com",
                           "us-west-2": "rekognition.us-west-2.amazonaws.com",
                           "eu-west-2": "rekognition.eu-west-2.amazonaws.com", "ap-northeast-3": "rekognition.ap-northeast-3.amazonaws.com", "eu-central-1": "rekognition.eu-central-1.amazonaws.com",
                           "us-east-2": "rekognition.us-east-2.amazonaws.com",
                           "us-east-1": "rekognition.us-east-1.amazonaws.com", "cn-northwest-1": "rekognition.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "rekognition.ap-south-1.amazonaws.com", "eu-north-1": "rekognition.eu-north-1.amazonaws.com", "ap-northeast-2": "rekognition.ap-northeast-2.amazonaws.com",
                           "us-west-1": "rekognition.us-west-1.amazonaws.com", "us-gov-east-1": "rekognition.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "rekognition.eu-west-3.amazonaws.com", "cn-north-1": "rekognition.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "rekognition.sa-east-1.amazonaws.com",
                           "eu-west-1": "rekognition.eu-west-1.amazonaws.com", "us-gov-west-1": "rekognition.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rekognition.ap-southeast-2.amazonaws.com", "ca-central-1": "rekognition.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "rekognition.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "rekognition.ap-southeast-1.amazonaws.com",
      "us-west-2": "rekognition.us-west-2.amazonaws.com",
      "eu-west-2": "rekognition.eu-west-2.amazonaws.com",
      "ap-northeast-3": "rekognition.ap-northeast-3.amazonaws.com",
      "eu-central-1": "rekognition.eu-central-1.amazonaws.com",
      "us-east-2": "rekognition.us-east-2.amazonaws.com",
      "us-east-1": "rekognition.us-east-1.amazonaws.com",
      "cn-northwest-1": "rekognition.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "rekognition.ap-south-1.amazonaws.com",
      "eu-north-1": "rekognition.eu-north-1.amazonaws.com",
      "ap-northeast-2": "rekognition.ap-northeast-2.amazonaws.com",
      "us-west-1": "rekognition.us-west-1.amazonaws.com",
      "us-gov-east-1": "rekognition.us-gov-east-1.amazonaws.com",
      "eu-west-3": "rekognition.eu-west-3.amazonaws.com",
      "cn-north-1": "rekognition.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "rekognition.sa-east-1.amazonaws.com",
      "eu-west-1": "rekognition.eu-west-1.amazonaws.com",
      "us-gov-west-1": "rekognition.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "rekognition.ap-southeast-2.amazonaws.com",
      "ca-central-1": "rekognition.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "rekognition"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CompareFaces_605928 = ref object of OpenApiRestCall_605590
proc url_CompareFaces_605930(protocol: Scheme; host: string; base: string;
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

proc validate_CompareFaces_605929(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606055 = header.getOrDefault("X-Amz-Target")
  valid_606055 = validateParameter(valid_606055, JString, required = true, default = newJString(
      "RekognitionService.CompareFaces"))
  if valid_606055 != nil:
    section.add "X-Amz-Target", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_CompareFaces_605928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_CompareFaces_605928; body: JsonNode): Recallable =
  ## compareFaces
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ##   body: JObject (required)
  var body_606158 = newJObject()
  if body != nil:
    body_606158 = body
  result = call_606157.call(nil, nil, nil, nil, body_606158)

var compareFaces* = Call_CompareFaces_605928(name: "compareFaces",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CompareFaces",
    validator: validate_CompareFaces_605929, base: "/", url: url_CompareFaces_605930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCollection_606197 = ref object of OpenApiRestCall_605590
proc url_CreateCollection_606199(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCollection_606198(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606200 = header.getOrDefault("X-Amz-Target")
  valid_606200 = validateParameter(valid_606200, JString, required = true, default = newJString(
      "RekognitionService.CreateCollection"))
  if valid_606200 != nil:
    section.add "X-Amz-Target", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_CreateCollection_606197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_CreateCollection_606197; body: JsonNode): Recallable =
  ## createCollection
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ##   body: JObject (required)
  var body_606211 = newJObject()
  if body != nil:
    body_606211 = body
  result = call_606210.call(nil, nil, nil, nil, body_606211)

var createCollection* = Call_CreateCollection_606197(name: "createCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateCollection",
    validator: validate_CreateCollection_606198, base: "/",
    url: url_CreateCollection_606199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_606212 = ref object of OpenApiRestCall_605590
proc url_CreateProject_606214(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_606213(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606215 = header.getOrDefault("X-Amz-Target")
  valid_606215 = validateParameter(valid_606215, JString, required = true, default = newJString(
      "RekognitionService.CreateProject"))
  if valid_606215 != nil:
    section.add "X-Amz-Target", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Signature")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Signature", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Content-Sha256", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Date")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Date", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Credential")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Credential", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Security-Token")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Security-Token", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Algorithm")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Algorithm", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-SignedHeaders", valid_606222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606224: Call_CreateProject_606212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ## 
  let valid = call_606224.validator(path, query, header, formData, body)
  let scheme = call_606224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606224.url(scheme.get, call_606224.host, call_606224.base,
                         call_606224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606224, url, valid)

proc call*(call_606225: Call_CreateProject_606212; body: JsonNode): Recallable =
  ## createProject
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ##   body: JObject (required)
  var body_606226 = newJObject()
  if body != nil:
    body_606226 = body
  result = call_606225.call(nil, nil, nil, nil, body_606226)

var createProject* = Call_CreateProject_606212(name: "createProject",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProject",
    validator: validate_CreateProject_606213, base: "/", url: url_CreateProject_606214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProjectVersion_606227 = ref object of OpenApiRestCall_605590
proc url_CreateProjectVersion_606229(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProjectVersion_606228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606230 = header.getOrDefault("X-Amz-Target")
  valid_606230 = validateParameter(valid_606230, JString, required = true, default = newJString(
      "RekognitionService.CreateProjectVersion"))
  if valid_606230 != nil:
    section.add "X-Amz-Target", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Signature")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Signature", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Content-Sha256", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Date")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Date", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Credential")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Credential", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Security-Token")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Security-Token", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Algorithm")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Algorithm", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-SignedHeaders", valid_606237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606239: Call_CreateProjectVersion_606227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ## 
  let valid = call_606239.validator(path, query, header, formData, body)
  let scheme = call_606239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606239.url(scheme.get, call_606239.host, call_606239.base,
                         call_606239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606239, url, valid)

proc call*(call_606240: Call_CreateProjectVersion_606227; body: JsonNode): Recallable =
  ## createProjectVersion
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_606241 = newJObject()
  if body != nil:
    body_606241 = body
  result = call_606240.call(nil, nil, nil, nil, body_606241)

var createProjectVersion* = Call_CreateProjectVersion_606227(
    name: "createProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProjectVersion",
    validator: validate_CreateProjectVersion_606228, base: "/",
    url: url_CreateProjectVersion_606229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamProcessor_606242 = ref object of OpenApiRestCall_605590
proc url_CreateStreamProcessor_606244(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStreamProcessor_606243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606245 = header.getOrDefault("X-Amz-Target")
  valid_606245 = validateParameter(valid_606245, JString, required = true, default = newJString(
      "RekognitionService.CreateStreamProcessor"))
  if valid_606245 != nil:
    section.add "X-Amz-Target", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_CreateStreamProcessor_606242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_CreateStreamProcessor_606242; body: JsonNode): Recallable =
  ## createStreamProcessor
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ##   body: JObject (required)
  var body_606256 = newJObject()
  if body != nil:
    body_606256 = body
  result = call_606255.call(nil, nil, nil, nil, body_606256)

var createStreamProcessor* = Call_CreateStreamProcessor_606242(
    name: "createStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateStreamProcessor",
    validator: validate_CreateStreamProcessor_606243, base: "/",
    url: url_CreateStreamProcessor_606244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCollection_606257 = ref object of OpenApiRestCall_605590
proc url_DeleteCollection_606259(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCollection_606258(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606260 = header.getOrDefault("X-Amz-Target")
  valid_606260 = validateParameter(valid_606260, JString, required = true, default = newJString(
      "RekognitionService.DeleteCollection"))
  if valid_606260 != nil:
    section.add "X-Amz-Target", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606269: Call_DeleteCollection_606257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ## 
  let valid = call_606269.validator(path, query, header, formData, body)
  let scheme = call_606269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606269.url(scheme.get, call_606269.host, call_606269.base,
                         call_606269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606269, url, valid)

proc call*(call_606270: Call_DeleteCollection_606257; body: JsonNode): Recallable =
  ## deleteCollection
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ##   body: JObject (required)
  var body_606271 = newJObject()
  if body != nil:
    body_606271 = body
  result = call_606270.call(nil, nil, nil, nil, body_606271)

var deleteCollection* = Call_DeleteCollection_606257(name: "deleteCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteCollection",
    validator: validate_DeleteCollection_606258, base: "/",
    url: url_DeleteCollection_606259, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFaces_606272 = ref object of OpenApiRestCall_605590
proc url_DeleteFaces_606274(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFaces_606273(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606275 = header.getOrDefault("X-Amz-Target")
  valid_606275 = validateParameter(valid_606275, JString, required = true, default = newJString(
      "RekognitionService.DeleteFaces"))
  if valid_606275 != nil:
    section.add "X-Amz-Target", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Signature")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Signature", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Content-Sha256", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Date")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Date", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Credential")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Credential", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Security-Token")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Security-Token", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Algorithm")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Algorithm", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-SignedHeaders", valid_606282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606284: Call_DeleteFaces_606272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ## 
  let valid = call_606284.validator(path, query, header, formData, body)
  let scheme = call_606284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606284.url(scheme.get, call_606284.host, call_606284.base,
                         call_606284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606284, url, valid)

proc call*(call_606285: Call_DeleteFaces_606272; body: JsonNode): Recallable =
  ## deleteFaces
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ##   body: JObject (required)
  var body_606286 = newJObject()
  if body != nil:
    body_606286 = body
  result = call_606285.call(nil, nil, nil, nil, body_606286)

var deleteFaces* = Call_DeleteFaces_606272(name: "deleteFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DeleteFaces",
                                        validator: validate_DeleteFaces_606273,
                                        base: "/", url: url_DeleteFaces_606274,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamProcessor_606287 = ref object of OpenApiRestCall_605590
proc url_DeleteStreamProcessor_606289(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStreamProcessor_606288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606290 = header.getOrDefault("X-Amz-Target")
  valid_606290 = validateParameter(valid_606290, JString, required = true, default = newJString(
      "RekognitionService.DeleteStreamProcessor"))
  if valid_606290 != nil:
    section.add "X-Amz-Target", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Signature")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Signature", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Content-Sha256", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Date")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Date", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Credential")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Credential", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Security-Token")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Security-Token", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Algorithm")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Algorithm", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-SignedHeaders", valid_606297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606299: Call_DeleteStreamProcessor_606287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ## 
  let valid = call_606299.validator(path, query, header, formData, body)
  let scheme = call_606299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606299.url(scheme.get, call_606299.host, call_606299.base,
                         call_606299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606299, url, valid)

proc call*(call_606300: Call_DeleteStreamProcessor_606287; body: JsonNode): Recallable =
  ## deleteStreamProcessor
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ##   body: JObject (required)
  var body_606301 = newJObject()
  if body != nil:
    body_606301 = body
  result = call_606300.call(nil, nil, nil, nil, body_606301)

var deleteStreamProcessor* = Call_DeleteStreamProcessor_606287(
    name: "deleteStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteStreamProcessor",
    validator: validate_DeleteStreamProcessor_606288, base: "/",
    url: url_DeleteStreamProcessor_606289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCollection_606302 = ref object of OpenApiRestCall_605590
proc url_DescribeCollection_606304(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCollection_606303(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606305 = header.getOrDefault("X-Amz-Target")
  valid_606305 = validateParameter(valid_606305, JString, required = true, default = newJString(
      "RekognitionService.DescribeCollection"))
  if valid_606305 != nil:
    section.add "X-Amz-Target", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Signature")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Signature", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Content-Sha256", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Date")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Date", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Credential")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Credential", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Security-Token")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Security-Token", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Algorithm")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Algorithm", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-SignedHeaders", valid_606312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606314: Call_DescribeCollection_606302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606314.validator(path, query, header, formData, body)
  let scheme = call_606314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606314.url(scheme.get, call_606314.host, call_606314.base,
                         call_606314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606314, url, valid)

proc call*(call_606315: Call_DescribeCollection_606302; body: JsonNode): Recallable =
  ## describeCollection
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_606316 = newJObject()
  if body != nil:
    body_606316 = body
  result = call_606315.call(nil, nil, nil, nil, body_606316)

var describeCollection* = Call_DescribeCollection_606302(
    name: "describeCollection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeCollection",
    validator: validate_DescribeCollection_606303, base: "/",
    url: url_DescribeCollection_606304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjectVersions_606317 = ref object of OpenApiRestCall_605590
proc url_DescribeProjectVersions_606319(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProjectVersions_606318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606320 = query.getOrDefault("MaxResults")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "MaxResults", valid_606320
  var valid_606321 = query.getOrDefault("NextToken")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "NextToken", valid_606321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606322 = header.getOrDefault("X-Amz-Target")
  valid_606322 = validateParameter(valid_606322, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjectVersions"))
  if valid_606322 != nil:
    section.add "X-Amz-Target", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Signature")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Signature", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Content-Sha256", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Date")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Date", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Credential")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Credential", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Security-Token")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Security-Token", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Algorithm")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Algorithm", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-SignedHeaders", valid_606329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606331: Call_DescribeProjectVersions_606317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ## 
  let valid = call_606331.validator(path, query, header, formData, body)
  let scheme = call_606331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606331.url(scheme.get, call_606331.host, call_606331.base,
                         call_606331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606331, url, valid)

proc call*(call_606332: Call_DescribeProjectVersions_606317; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjectVersions
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606333 = newJObject()
  var body_606334 = newJObject()
  add(query_606333, "MaxResults", newJString(MaxResults))
  add(query_606333, "NextToken", newJString(NextToken))
  if body != nil:
    body_606334 = body
  result = call_606332.call(nil, query_606333, nil, nil, body_606334)

var describeProjectVersions* = Call_DescribeProjectVersions_606317(
    name: "describeProjectVersions", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjectVersions",
    validator: validate_DescribeProjectVersions_606318, base: "/",
    url: url_DescribeProjectVersions_606319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjects_606336 = ref object of OpenApiRestCall_605590
proc url_DescribeProjects_606338(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProjects_606337(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606339 = query.getOrDefault("MaxResults")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "MaxResults", valid_606339
  var valid_606340 = query.getOrDefault("NextToken")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "NextToken", valid_606340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606341 = header.getOrDefault("X-Amz-Target")
  valid_606341 = validateParameter(valid_606341, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjects"))
  if valid_606341 != nil:
    section.add "X-Amz-Target", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Signature")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Signature", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Content-Sha256", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Date")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Date", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Credential")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Credential", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Security-Token")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Security-Token", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Algorithm")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Algorithm", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-SignedHeaders", valid_606348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_DescribeProjects_606336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_DescribeProjects_606336; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjects
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606352 = newJObject()
  var body_606353 = newJObject()
  add(query_606352, "MaxResults", newJString(MaxResults))
  add(query_606352, "NextToken", newJString(NextToken))
  if body != nil:
    body_606353 = body
  result = call_606351.call(nil, query_606352, nil, nil, body_606353)

var describeProjects* = Call_DescribeProjects_606336(name: "describeProjects",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjects",
    validator: validate_DescribeProjects_606337, base: "/",
    url: url_DescribeProjects_606338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStreamProcessor_606354 = ref object of OpenApiRestCall_605590
proc url_DescribeStreamProcessor_606356(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStreamProcessor_606355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606357 = header.getOrDefault("X-Amz-Target")
  valid_606357 = validateParameter(valid_606357, JString, required = true, default = newJString(
      "RekognitionService.DescribeStreamProcessor"))
  if valid_606357 != nil:
    section.add "X-Amz-Target", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606366: Call_DescribeStreamProcessor_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ## 
  let valid = call_606366.validator(path, query, header, formData, body)
  let scheme = call_606366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606366.url(scheme.get, call_606366.host, call_606366.base,
                         call_606366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606366, url, valid)

proc call*(call_606367: Call_DescribeStreamProcessor_606354; body: JsonNode): Recallable =
  ## describeStreamProcessor
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ##   body: JObject (required)
  var body_606368 = newJObject()
  if body != nil:
    body_606368 = body
  result = call_606367.call(nil, nil, nil, nil, body_606368)

var describeStreamProcessor* = Call_DescribeStreamProcessor_606354(
    name: "describeStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeStreamProcessor",
    validator: validate_DescribeStreamProcessor_606355, base: "/",
    url: url_DescribeStreamProcessor_606356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectCustomLabels_606369 = ref object of OpenApiRestCall_605590
proc url_DetectCustomLabels_606371(protocol: Scheme; host: string; base: string;
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

proc validate_DetectCustomLabels_606370(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606372 = header.getOrDefault("X-Amz-Target")
  valid_606372 = validateParameter(valid_606372, JString, required = true, default = newJString(
      "RekognitionService.DetectCustomLabels"))
  if valid_606372 != nil:
    section.add "X-Amz-Target", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Signature")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Signature", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Content-Sha256", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Date")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Date", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Credential")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Credential", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Security-Token")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Security-Token", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Algorithm")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Algorithm", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-SignedHeaders", valid_606379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606381: Call_DetectCustomLabels_606369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ## 
  let valid = call_606381.validator(path, query, header, formData, body)
  let scheme = call_606381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606381.url(scheme.get, call_606381.host, call_606381.base,
                         call_606381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606381, url, valid)

proc call*(call_606382: Call_DetectCustomLabels_606369; body: JsonNode): Recallable =
  ## detectCustomLabels
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ##   body: JObject (required)
  var body_606383 = newJObject()
  if body != nil:
    body_606383 = body
  result = call_606382.call(nil, nil, nil, nil, body_606383)

var detectCustomLabels* = Call_DetectCustomLabels_606369(
    name: "detectCustomLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectCustomLabels",
    validator: validate_DetectCustomLabels_606370, base: "/",
    url: url_DetectCustomLabels_606371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectFaces_606384 = ref object of OpenApiRestCall_605590
proc url_DetectFaces_606386(protocol: Scheme; host: string; base: string;
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

proc validate_DetectFaces_606385(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606387 = header.getOrDefault("X-Amz-Target")
  valid_606387 = validateParameter(valid_606387, JString, required = true, default = newJString(
      "RekognitionService.DetectFaces"))
  if valid_606387 != nil:
    section.add "X-Amz-Target", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_DetectFaces_606384; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_DetectFaces_606384; body: JsonNode): Recallable =
  ## detectFaces
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ##   body: JObject (required)
  var body_606398 = newJObject()
  if body != nil:
    body_606398 = body
  result = call_606397.call(nil, nil, nil, nil, body_606398)

var detectFaces* = Call_DetectFaces_606384(name: "detectFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectFaces",
                                        validator: validate_DetectFaces_606385,
                                        base: "/", url: url_DetectFaces_606386,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectLabels_606399 = ref object of OpenApiRestCall_605590
proc url_DetectLabels_606401(protocol: Scheme; host: string; base: string;
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

proc validate_DetectLabels_606400(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606402 = header.getOrDefault("X-Amz-Target")
  valid_606402 = validateParameter(valid_606402, JString, required = true, default = newJString(
      "RekognitionService.DetectLabels"))
  if valid_606402 != nil:
    section.add "X-Amz-Target", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Signature")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Signature", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Content-Sha256", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Date")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Date", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Credential")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Credential", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Security-Token")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Security-Token", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Algorithm")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Algorithm", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-SignedHeaders", valid_606409
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606411: Call_DetectLabels_606399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ## 
  let valid = call_606411.validator(path, query, header, formData, body)
  let scheme = call_606411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606411.url(scheme.get, call_606411.host, call_606411.base,
                         call_606411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606411, url, valid)

proc call*(call_606412: Call_DetectLabels_606399; body: JsonNode): Recallable =
  ## detectLabels
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ##   body: JObject (required)
  var body_606413 = newJObject()
  if body != nil:
    body_606413 = body
  result = call_606412.call(nil, nil, nil, nil, body_606413)

var detectLabels* = Call_DetectLabels_606399(name: "detectLabels",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectLabels",
    validator: validate_DetectLabels_606400, base: "/", url: url_DetectLabels_606401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectModerationLabels_606414 = ref object of OpenApiRestCall_605590
proc url_DetectModerationLabels_606416(protocol: Scheme; host: string; base: string;
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

proc validate_DetectModerationLabels_606415(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606417 = header.getOrDefault("X-Amz-Target")
  valid_606417 = validateParameter(valid_606417, JString, required = true, default = newJString(
      "RekognitionService.DetectModerationLabels"))
  if valid_606417 != nil:
    section.add "X-Amz-Target", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Signature")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Signature", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Content-Sha256", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Date")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Date", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Credential")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Credential", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Security-Token")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Security-Token", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Algorithm")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Algorithm", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-SignedHeaders", valid_606424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606426: Call_DetectModerationLabels_606414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ## 
  let valid = call_606426.validator(path, query, header, formData, body)
  let scheme = call_606426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606426.url(scheme.get, call_606426.host, call_606426.base,
                         call_606426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606426, url, valid)

proc call*(call_606427: Call_DetectModerationLabels_606414; body: JsonNode): Recallable =
  ## detectModerationLabels
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ##   body: JObject (required)
  var body_606428 = newJObject()
  if body != nil:
    body_606428 = body
  result = call_606427.call(nil, nil, nil, nil, body_606428)

var detectModerationLabels* = Call_DetectModerationLabels_606414(
    name: "detectModerationLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectModerationLabels",
    validator: validate_DetectModerationLabels_606415, base: "/",
    url: url_DetectModerationLabels_606416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectText_606429 = ref object of OpenApiRestCall_605590
proc url_DetectText_606431(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DetectText_606430(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606432 = header.getOrDefault("X-Amz-Target")
  valid_606432 = validateParameter(valid_606432, JString, required = true, default = newJString(
      "RekognitionService.DetectText"))
  if valid_606432 != nil:
    section.add "X-Amz-Target", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Signature")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Signature", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Content-Sha256", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Date")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Date", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Credential")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Credential", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Security-Token")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Security-Token", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Algorithm")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Algorithm", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-SignedHeaders", valid_606439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606441: Call_DetectText_606429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606441.validator(path, query, header, formData, body)
  let scheme = call_606441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606441.url(scheme.get, call_606441.host, call_606441.base,
                         call_606441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606441, url, valid)

proc call*(call_606442: Call_DetectText_606429; body: JsonNode): Recallable =
  ## detectText
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_606443 = newJObject()
  if body != nil:
    body_606443 = body
  result = call_606442.call(nil, nil, nil, nil, body_606443)

var detectText* = Call_DetectText_606429(name: "detectText",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectText",
                                      validator: validate_DetectText_606430,
                                      base: "/", url: url_DetectText_606431,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityInfo_606444 = ref object of OpenApiRestCall_605590
proc url_GetCelebrityInfo_606446(protocol: Scheme; host: string; base: string;
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

proc validate_GetCelebrityInfo_606445(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606447 = header.getOrDefault("X-Amz-Target")
  valid_606447 = validateParameter(valid_606447, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityInfo"))
  if valid_606447 != nil:
    section.add "X-Amz-Target", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Signature")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Signature", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Content-Sha256", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Date")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Date", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-Credential")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-Credential", valid_606451
  var valid_606452 = header.getOrDefault("X-Amz-Security-Token")
  valid_606452 = validateParameter(valid_606452, JString, required = false,
                                 default = nil)
  if valid_606452 != nil:
    section.add "X-Amz-Security-Token", valid_606452
  var valid_606453 = header.getOrDefault("X-Amz-Algorithm")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Algorithm", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-SignedHeaders", valid_606454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606456: Call_GetCelebrityInfo_606444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ## 
  let valid = call_606456.validator(path, query, header, formData, body)
  let scheme = call_606456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606456.url(scheme.get, call_606456.host, call_606456.base,
                         call_606456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606456, url, valid)

proc call*(call_606457: Call_GetCelebrityInfo_606444; body: JsonNode): Recallable =
  ## getCelebrityInfo
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ##   body: JObject (required)
  var body_606458 = newJObject()
  if body != nil:
    body_606458 = body
  result = call_606457.call(nil, nil, nil, nil, body_606458)

var getCelebrityInfo* = Call_GetCelebrityInfo_606444(name: "getCelebrityInfo",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityInfo",
    validator: validate_GetCelebrityInfo_606445, base: "/",
    url: url_GetCelebrityInfo_606446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityRecognition_606459 = ref object of OpenApiRestCall_605590
proc url_GetCelebrityRecognition_606461(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCelebrityRecognition_606460(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606462 = query.getOrDefault("MaxResults")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "MaxResults", valid_606462
  var valid_606463 = query.getOrDefault("NextToken")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "NextToken", valid_606463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606464 = header.getOrDefault("X-Amz-Target")
  valid_606464 = validateParameter(valid_606464, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityRecognition"))
  if valid_606464 != nil:
    section.add "X-Amz-Target", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Signature")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Signature", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Content-Sha256", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Date")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Date", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Credential")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Credential", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Security-Token")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Security-Token", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Algorithm")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Algorithm", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-SignedHeaders", valid_606471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606473: Call_GetCelebrityRecognition_606459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ## 
  let valid = call_606473.validator(path, query, header, formData, body)
  let scheme = call_606473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606473.url(scheme.get, call_606473.host, call_606473.base,
                         call_606473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606473, url, valid)

proc call*(call_606474: Call_GetCelebrityRecognition_606459; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCelebrityRecognition
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606475 = newJObject()
  var body_606476 = newJObject()
  add(query_606475, "MaxResults", newJString(MaxResults))
  add(query_606475, "NextToken", newJString(NextToken))
  if body != nil:
    body_606476 = body
  result = call_606474.call(nil, query_606475, nil, nil, body_606476)

var getCelebrityRecognition* = Call_GetCelebrityRecognition_606459(
    name: "getCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityRecognition",
    validator: validate_GetCelebrityRecognition_606460, base: "/",
    url: url_GetCelebrityRecognition_606461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContentModeration_606477 = ref object of OpenApiRestCall_605590
proc url_GetContentModeration_606479(protocol: Scheme; host: string; base: string;
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

proc validate_GetContentModeration_606478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606480 = query.getOrDefault("MaxResults")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "MaxResults", valid_606480
  var valid_606481 = query.getOrDefault("NextToken")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "NextToken", valid_606481
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606482 = header.getOrDefault("X-Amz-Target")
  valid_606482 = validateParameter(valid_606482, JString, required = true, default = newJString(
      "RekognitionService.GetContentModeration"))
  if valid_606482 != nil:
    section.add "X-Amz-Target", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Security-Token")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Security-Token", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Algorithm")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Algorithm", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-SignedHeaders", valid_606489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_GetContentModeration_606477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_GetContentModeration_606477; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getContentModeration
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606493 = newJObject()
  var body_606494 = newJObject()
  add(query_606493, "MaxResults", newJString(MaxResults))
  add(query_606493, "NextToken", newJString(NextToken))
  if body != nil:
    body_606494 = body
  result = call_606492.call(nil, query_606493, nil, nil, body_606494)

var getContentModeration* = Call_GetContentModeration_606477(
    name: "getContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetContentModeration",
    validator: validate_GetContentModeration_606478, base: "/",
    url: url_GetContentModeration_606479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceDetection_606495 = ref object of OpenApiRestCall_605590
proc url_GetFaceDetection_606497(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceDetection_606496(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606498 = query.getOrDefault("MaxResults")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "MaxResults", valid_606498
  var valid_606499 = query.getOrDefault("NextToken")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "NextToken", valid_606499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606500 = header.getOrDefault("X-Amz-Target")
  valid_606500 = validateParameter(valid_606500, JString, required = true, default = newJString(
      "RekognitionService.GetFaceDetection"))
  if valid_606500 != nil:
    section.add "X-Amz-Target", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Signature")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Signature", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Content-Sha256", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Date")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Date", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Credential")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Credential", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Security-Token")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Security-Token", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Algorithm")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Algorithm", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-SignedHeaders", valid_606507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606509: Call_GetFaceDetection_606495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ## 
  let valid = call_606509.validator(path, query, header, formData, body)
  let scheme = call_606509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606509.url(scheme.get, call_606509.host, call_606509.base,
                         call_606509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606509, url, valid)

proc call*(call_606510: Call_GetFaceDetection_606495; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceDetection
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606511 = newJObject()
  var body_606512 = newJObject()
  add(query_606511, "MaxResults", newJString(MaxResults))
  add(query_606511, "NextToken", newJString(NextToken))
  if body != nil:
    body_606512 = body
  result = call_606510.call(nil, query_606511, nil, nil, body_606512)

var getFaceDetection* = Call_GetFaceDetection_606495(name: "getFaceDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceDetection",
    validator: validate_GetFaceDetection_606496, base: "/",
    url: url_GetFaceDetection_606497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceSearch_606513 = ref object of OpenApiRestCall_605590
proc url_GetFaceSearch_606515(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceSearch_606514(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606516 = query.getOrDefault("MaxResults")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "MaxResults", valid_606516
  var valid_606517 = query.getOrDefault("NextToken")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "NextToken", valid_606517
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606518 = header.getOrDefault("X-Amz-Target")
  valid_606518 = validateParameter(valid_606518, JString, required = true, default = newJString(
      "RekognitionService.GetFaceSearch"))
  if valid_606518 != nil:
    section.add "X-Amz-Target", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Signature")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Signature", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Content-Sha256", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Date")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Date", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Credential")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Credential", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Security-Token")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Security-Token", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Algorithm")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Algorithm", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-SignedHeaders", valid_606525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606527: Call_GetFaceSearch_606513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ## 
  let valid = call_606527.validator(path, query, header, formData, body)
  let scheme = call_606527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606527.url(scheme.get, call_606527.host, call_606527.base,
                         call_606527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606527, url, valid)

proc call*(call_606528: Call_GetFaceSearch_606513; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceSearch
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606529 = newJObject()
  var body_606530 = newJObject()
  add(query_606529, "MaxResults", newJString(MaxResults))
  add(query_606529, "NextToken", newJString(NextToken))
  if body != nil:
    body_606530 = body
  result = call_606528.call(nil, query_606529, nil, nil, body_606530)

var getFaceSearch* = Call_GetFaceSearch_606513(name: "getFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceSearch",
    validator: validate_GetFaceSearch_606514, base: "/", url: url_GetFaceSearch_606515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLabelDetection_606531 = ref object of OpenApiRestCall_605590
proc url_GetLabelDetection_606533(protocol: Scheme; host: string; base: string;
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

proc validate_GetLabelDetection_606532(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606534 = query.getOrDefault("MaxResults")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "MaxResults", valid_606534
  var valid_606535 = query.getOrDefault("NextToken")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "NextToken", valid_606535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606536 = header.getOrDefault("X-Amz-Target")
  valid_606536 = validateParameter(valid_606536, JString, required = true, default = newJString(
      "RekognitionService.GetLabelDetection"))
  if valid_606536 != nil:
    section.add "X-Amz-Target", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Signature")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Signature", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Content-Sha256", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Date")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Date", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Credential")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Credential", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Security-Token")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Security-Token", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Algorithm")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Algorithm", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-SignedHeaders", valid_606543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606545: Call_GetLabelDetection_606531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ## 
  let valid = call_606545.validator(path, query, header, formData, body)
  let scheme = call_606545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606545.url(scheme.get, call_606545.host, call_606545.base,
                         call_606545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606545, url, valid)

proc call*(call_606546: Call_GetLabelDetection_606531; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getLabelDetection
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606547 = newJObject()
  var body_606548 = newJObject()
  add(query_606547, "MaxResults", newJString(MaxResults))
  add(query_606547, "NextToken", newJString(NextToken))
  if body != nil:
    body_606548 = body
  result = call_606546.call(nil, query_606547, nil, nil, body_606548)

var getLabelDetection* = Call_GetLabelDetection_606531(name: "getLabelDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetLabelDetection",
    validator: validate_GetLabelDetection_606532, base: "/",
    url: url_GetLabelDetection_606533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPersonTracking_606549 = ref object of OpenApiRestCall_605590
proc url_GetPersonTracking_606551(protocol: Scheme; host: string; base: string;
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

proc validate_GetPersonTracking_606550(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606552 = query.getOrDefault("MaxResults")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "MaxResults", valid_606552
  var valid_606553 = query.getOrDefault("NextToken")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "NextToken", valid_606553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606554 = header.getOrDefault("X-Amz-Target")
  valid_606554 = validateParameter(valid_606554, JString, required = true, default = newJString(
      "RekognitionService.GetPersonTracking"))
  if valid_606554 != nil:
    section.add "X-Amz-Target", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Signature")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Signature", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Content-Sha256", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Date")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Date", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Credential")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Credential", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Security-Token")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Security-Token", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Algorithm")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Algorithm", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-SignedHeaders", valid_606561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606563: Call_GetPersonTracking_606549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ## 
  let valid = call_606563.validator(path, query, header, formData, body)
  let scheme = call_606563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606563.url(scheme.get, call_606563.host, call_606563.base,
                         call_606563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606563, url, valid)

proc call*(call_606564: Call_GetPersonTracking_606549; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPersonTracking
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606565 = newJObject()
  var body_606566 = newJObject()
  add(query_606565, "MaxResults", newJString(MaxResults))
  add(query_606565, "NextToken", newJString(NextToken))
  if body != nil:
    body_606566 = body
  result = call_606564.call(nil, query_606565, nil, nil, body_606566)

var getPersonTracking* = Call_GetPersonTracking_606549(name: "getPersonTracking",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetPersonTracking",
    validator: validate_GetPersonTracking_606550, base: "/",
    url: url_GetPersonTracking_606551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IndexFaces_606567 = ref object of OpenApiRestCall_605590
proc url_IndexFaces_606569(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_IndexFaces_606568(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606570 = header.getOrDefault("X-Amz-Target")
  valid_606570 = validateParameter(valid_606570, JString, required = true, default = newJString(
      "RekognitionService.IndexFaces"))
  if valid_606570 != nil:
    section.add "X-Amz-Target", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Signature")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Signature", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Content-Sha256", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Date")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Date", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Credential")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Credential", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Security-Token")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Security-Token", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Algorithm")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Algorithm", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-SignedHeaders", valid_606577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606579: Call_IndexFaces_606567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ## 
  let valid = call_606579.validator(path, query, header, formData, body)
  let scheme = call_606579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606579.url(scheme.get, call_606579.host, call_606579.base,
                         call_606579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606579, url, valid)

proc call*(call_606580: Call_IndexFaces_606567; body: JsonNode): Recallable =
  ## indexFaces
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ##   body: JObject (required)
  var body_606581 = newJObject()
  if body != nil:
    body_606581 = body
  result = call_606580.call(nil, nil, nil, nil, body_606581)

var indexFaces* = Call_IndexFaces_606567(name: "indexFaces",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.IndexFaces",
                                      validator: validate_IndexFaces_606568,
                                      base: "/", url: url_IndexFaces_606569,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCollections_606582 = ref object of OpenApiRestCall_605590
proc url_ListCollections_606584(protocol: Scheme; host: string; base: string;
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

proc validate_ListCollections_606583(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606585 = query.getOrDefault("MaxResults")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "MaxResults", valid_606585
  var valid_606586 = query.getOrDefault("NextToken")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "NextToken", valid_606586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606587 = header.getOrDefault("X-Amz-Target")
  valid_606587 = validateParameter(valid_606587, JString, required = true, default = newJString(
      "RekognitionService.ListCollections"))
  if valid_606587 != nil:
    section.add "X-Amz-Target", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Signature")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Signature", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Content-Sha256", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Date")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Date", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Credential")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Credential", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Security-Token")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Security-Token", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Algorithm")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Algorithm", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-SignedHeaders", valid_606594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606596: Call_ListCollections_606582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ## 
  let valid = call_606596.validator(path, query, header, formData, body)
  let scheme = call_606596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606596.url(scheme.get, call_606596.host, call_606596.base,
                         call_606596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606596, url, valid)

proc call*(call_606597: Call_ListCollections_606582; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCollections
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606598 = newJObject()
  var body_606599 = newJObject()
  add(query_606598, "MaxResults", newJString(MaxResults))
  add(query_606598, "NextToken", newJString(NextToken))
  if body != nil:
    body_606599 = body
  result = call_606597.call(nil, query_606598, nil, nil, body_606599)

var listCollections* = Call_ListCollections_606582(name: "listCollections",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListCollections",
    validator: validate_ListCollections_606583, base: "/", url: url_ListCollections_606584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFaces_606600 = ref object of OpenApiRestCall_605590
proc url_ListFaces_606602(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFaces_606601(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606603 = query.getOrDefault("MaxResults")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "MaxResults", valid_606603
  var valid_606604 = query.getOrDefault("NextToken")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "NextToken", valid_606604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606605 = header.getOrDefault("X-Amz-Target")
  valid_606605 = validateParameter(valid_606605, JString, required = true, default = newJString(
      "RekognitionService.ListFaces"))
  if valid_606605 != nil:
    section.add "X-Amz-Target", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Signature")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Signature", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Content-Sha256", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Date")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Date", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Credential")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Credential", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Security-Token")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Security-Token", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Algorithm")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Algorithm", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-SignedHeaders", valid_606612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606614: Call_ListFaces_606600; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ## 
  let valid = call_606614.validator(path, query, header, formData, body)
  let scheme = call_606614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606614.url(scheme.get, call_606614.host, call_606614.base,
                         call_606614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606614, url, valid)

proc call*(call_606615: Call_ListFaces_606600; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFaces
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606616 = newJObject()
  var body_606617 = newJObject()
  add(query_606616, "MaxResults", newJString(MaxResults))
  add(query_606616, "NextToken", newJString(NextToken))
  if body != nil:
    body_606617 = body
  result = call_606615.call(nil, query_606616, nil, nil, body_606617)

var listFaces* = Call_ListFaces_606600(name: "listFaces", meth: HttpMethod.HttpPost,
                                    host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.ListFaces",
                                    validator: validate_ListFaces_606601,
                                    base: "/", url: url_ListFaces_606602,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamProcessors_606618 = ref object of OpenApiRestCall_605590
proc url_ListStreamProcessors_606620(protocol: Scheme; host: string; base: string;
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

proc validate_ListStreamProcessors_606619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606621 = query.getOrDefault("MaxResults")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "MaxResults", valid_606621
  var valid_606622 = query.getOrDefault("NextToken")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "NextToken", valid_606622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606623 = header.getOrDefault("X-Amz-Target")
  valid_606623 = validateParameter(valid_606623, JString, required = true, default = newJString(
      "RekognitionService.ListStreamProcessors"))
  if valid_606623 != nil:
    section.add "X-Amz-Target", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Signature")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Signature", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Content-Sha256", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Date")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Date", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Credential")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Credential", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Security-Token")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Security-Token", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Algorithm")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Algorithm", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-SignedHeaders", valid_606630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606632: Call_ListStreamProcessors_606618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ## 
  let valid = call_606632.validator(path, query, header, formData, body)
  let scheme = call_606632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606632.url(scheme.get, call_606632.host, call_606632.base,
                         call_606632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606632, url, valid)

proc call*(call_606633: Call_ListStreamProcessors_606618; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreamProcessors
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606634 = newJObject()
  var body_606635 = newJObject()
  add(query_606634, "MaxResults", newJString(MaxResults))
  add(query_606634, "NextToken", newJString(NextToken))
  if body != nil:
    body_606635 = body
  result = call_606633.call(nil, query_606634, nil, nil, body_606635)

var listStreamProcessors* = Call_ListStreamProcessors_606618(
    name: "listStreamProcessors", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListStreamProcessors",
    validator: validate_ListStreamProcessors_606619, base: "/",
    url: url_ListStreamProcessors_606620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RecognizeCelebrities_606636 = ref object of OpenApiRestCall_605590
proc url_RecognizeCelebrities_606638(protocol: Scheme; host: string; base: string;
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

proc validate_RecognizeCelebrities_606637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606639 = header.getOrDefault("X-Amz-Target")
  valid_606639 = validateParameter(valid_606639, JString, required = true, default = newJString(
      "RekognitionService.RecognizeCelebrities"))
  if valid_606639 != nil:
    section.add "X-Amz-Target", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Signature")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Signature", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Content-Sha256", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Date")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Date", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Credential")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Credential", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Security-Token")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Security-Token", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Algorithm")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Algorithm", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-SignedHeaders", valid_606646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606648: Call_RecognizeCelebrities_606636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ## 
  let valid = call_606648.validator(path, query, header, formData, body)
  let scheme = call_606648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606648.url(scheme.get, call_606648.host, call_606648.base,
                         call_606648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606648, url, valid)

proc call*(call_606649: Call_RecognizeCelebrities_606636; body: JsonNode): Recallable =
  ## recognizeCelebrities
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ##   body: JObject (required)
  var body_606650 = newJObject()
  if body != nil:
    body_606650 = body
  result = call_606649.call(nil, nil, nil, nil, body_606650)

var recognizeCelebrities* = Call_RecognizeCelebrities_606636(
    name: "recognizeCelebrities", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.RecognizeCelebrities",
    validator: validate_RecognizeCelebrities_606637, base: "/",
    url: url_RecognizeCelebrities_606638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFaces_606651 = ref object of OpenApiRestCall_605590
proc url_SearchFaces_606653(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFaces_606652(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606654 = header.getOrDefault("X-Amz-Target")
  valid_606654 = validateParameter(valid_606654, JString, required = true, default = newJString(
      "RekognitionService.SearchFaces"))
  if valid_606654 != nil:
    section.add "X-Amz-Target", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Signature")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Signature", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Content-Sha256", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Date")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Date", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Credential")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Credential", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Security-Token")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Security-Token", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Algorithm")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Algorithm", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-SignedHeaders", valid_606661
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606663: Call_SearchFaces_606651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ## 
  let valid = call_606663.validator(path, query, header, formData, body)
  let scheme = call_606663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606663.url(scheme.get, call_606663.host, call_606663.base,
                         call_606663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606663, url, valid)

proc call*(call_606664: Call_SearchFaces_606651; body: JsonNode): Recallable =
  ## searchFaces
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ##   body: JObject (required)
  var body_606665 = newJObject()
  if body != nil:
    body_606665 = body
  result = call_606664.call(nil, nil, nil, nil, body_606665)

var searchFaces* = Call_SearchFaces_606651(name: "searchFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.SearchFaces",
                                        validator: validate_SearchFaces_606652,
                                        base: "/", url: url_SearchFaces_606653,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFacesByImage_606666 = ref object of OpenApiRestCall_605590
proc url_SearchFacesByImage_606668(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFacesByImage_606667(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606669 = header.getOrDefault("X-Amz-Target")
  valid_606669 = validateParameter(valid_606669, JString, required = true, default = newJString(
      "RekognitionService.SearchFacesByImage"))
  if valid_606669 != nil:
    section.add "X-Amz-Target", valid_606669
  var valid_606670 = header.getOrDefault("X-Amz-Signature")
  valid_606670 = validateParameter(valid_606670, JString, required = false,
                                 default = nil)
  if valid_606670 != nil:
    section.add "X-Amz-Signature", valid_606670
  var valid_606671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Content-Sha256", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Date")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Date", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Credential")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Credential", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Security-Token")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Security-Token", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Algorithm")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Algorithm", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-SignedHeaders", valid_606676
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606678: Call_SearchFacesByImage_606666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ## 
  let valid = call_606678.validator(path, query, header, formData, body)
  let scheme = call_606678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606678.url(scheme.get, call_606678.host, call_606678.base,
                         call_606678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606678, url, valid)

proc call*(call_606679: Call_SearchFacesByImage_606666; body: JsonNode): Recallable =
  ## searchFacesByImage
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ##   body: JObject (required)
  var body_606680 = newJObject()
  if body != nil:
    body_606680 = body
  result = call_606679.call(nil, nil, nil, nil, body_606680)

var searchFacesByImage* = Call_SearchFacesByImage_606666(
    name: "searchFacesByImage", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.SearchFacesByImage",
    validator: validate_SearchFacesByImage_606667, base: "/",
    url: url_SearchFacesByImage_606668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCelebrityRecognition_606681 = ref object of OpenApiRestCall_605590
proc url_StartCelebrityRecognition_606683(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartCelebrityRecognition_606682(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606684 = header.getOrDefault("X-Amz-Target")
  valid_606684 = validateParameter(valid_606684, JString, required = true, default = newJString(
      "RekognitionService.StartCelebrityRecognition"))
  if valid_606684 != nil:
    section.add "X-Amz-Target", valid_606684
  var valid_606685 = header.getOrDefault("X-Amz-Signature")
  valid_606685 = validateParameter(valid_606685, JString, required = false,
                                 default = nil)
  if valid_606685 != nil:
    section.add "X-Amz-Signature", valid_606685
  var valid_606686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Content-Sha256", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Date")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Date", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Credential")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Credential", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Security-Token")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Security-Token", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Algorithm")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Algorithm", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-SignedHeaders", valid_606691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606693: Call_StartCelebrityRecognition_606681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606693.validator(path, query, header, formData, body)
  let scheme = call_606693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606693.url(scheme.get, call_606693.host, call_606693.base,
                         call_606693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606693, url, valid)

proc call*(call_606694: Call_StartCelebrityRecognition_606681; body: JsonNode): Recallable =
  ## startCelebrityRecognition
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_606695 = newJObject()
  if body != nil:
    body_606695 = body
  result = call_606694.call(nil, nil, nil, nil, body_606695)

var startCelebrityRecognition* = Call_StartCelebrityRecognition_606681(
    name: "startCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartCelebrityRecognition",
    validator: validate_StartCelebrityRecognition_606682, base: "/",
    url: url_StartCelebrityRecognition_606683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContentModeration_606696 = ref object of OpenApiRestCall_605590
proc url_StartContentModeration_606698(protocol: Scheme; host: string; base: string;
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

proc validate_StartContentModeration_606697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606699 = header.getOrDefault("X-Amz-Target")
  valid_606699 = validateParameter(valid_606699, JString, required = true, default = newJString(
      "RekognitionService.StartContentModeration"))
  if valid_606699 != nil:
    section.add "X-Amz-Target", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Signature")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Signature", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Content-Sha256", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Date")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Date", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Credential")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Credential", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Security-Token")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Security-Token", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Algorithm")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Algorithm", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-SignedHeaders", valid_606706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606708: Call_StartContentModeration_606696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606708.validator(path, query, header, formData, body)
  let scheme = call_606708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606708.url(scheme.get, call_606708.host, call_606708.base,
                         call_606708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606708, url, valid)

proc call*(call_606709: Call_StartContentModeration_606696; body: JsonNode): Recallable =
  ## startContentModeration
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_606710 = newJObject()
  if body != nil:
    body_606710 = body
  result = call_606709.call(nil, nil, nil, nil, body_606710)

var startContentModeration* = Call_StartContentModeration_606696(
    name: "startContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartContentModeration",
    validator: validate_StartContentModeration_606697, base: "/",
    url: url_StartContentModeration_606698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceDetection_606711 = ref object of OpenApiRestCall_605590
proc url_StartFaceDetection_606713(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceDetection_606712(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606714 = header.getOrDefault("X-Amz-Target")
  valid_606714 = validateParameter(valid_606714, JString, required = true, default = newJString(
      "RekognitionService.StartFaceDetection"))
  if valid_606714 != nil:
    section.add "X-Amz-Target", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Signature")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Signature", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-Content-Sha256", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Date")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Date", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Credential")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Credential", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Security-Token")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Security-Token", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Algorithm")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Algorithm", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-SignedHeaders", valid_606721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606723: Call_StartFaceDetection_606711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_606723.validator(path, query, header, formData, body)
  let scheme = call_606723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606723.url(scheme.get, call_606723.host, call_606723.base,
                         call_606723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606723, url, valid)

proc call*(call_606724: Call_StartFaceDetection_606711; body: JsonNode): Recallable =
  ## startFaceDetection
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_606725 = newJObject()
  if body != nil:
    body_606725 = body
  result = call_606724.call(nil, nil, nil, nil, body_606725)

var startFaceDetection* = Call_StartFaceDetection_606711(
    name: "startFaceDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceDetection",
    validator: validate_StartFaceDetection_606712, base: "/",
    url: url_StartFaceDetection_606713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceSearch_606726 = ref object of OpenApiRestCall_605590
proc url_StartFaceSearch_606728(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceSearch_606727(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606729 = header.getOrDefault("X-Amz-Target")
  valid_606729 = validateParameter(valid_606729, JString, required = true, default = newJString(
      "RekognitionService.StartFaceSearch"))
  if valid_606729 != nil:
    section.add "X-Amz-Target", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Signature")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Signature", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Content-Sha256", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Date")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Date", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Credential")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Credential", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Security-Token")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Security-Token", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Algorithm")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Algorithm", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-SignedHeaders", valid_606736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606738: Call_StartFaceSearch_606726; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ## 
  let valid = call_606738.validator(path, query, header, formData, body)
  let scheme = call_606738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606738.url(scheme.get, call_606738.host, call_606738.base,
                         call_606738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606738, url, valid)

proc call*(call_606739: Call_StartFaceSearch_606726; body: JsonNode): Recallable =
  ## startFaceSearch
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ##   body: JObject (required)
  var body_606740 = newJObject()
  if body != nil:
    body_606740 = body
  result = call_606739.call(nil, nil, nil, nil, body_606740)

var startFaceSearch* = Call_StartFaceSearch_606726(name: "startFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceSearch",
    validator: validate_StartFaceSearch_606727, base: "/", url: url_StartFaceSearch_606728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLabelDetection_606741 = ref object of OpenApiRestCall_605590
proc url_StartLabelDetection_606743(protocol: Scheme; host: string; base: string;
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

proc validate_StartLabelDetection_606742(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606744 = header.getOrDefault("X-Amz-Target")
  valid_606744 = validateParameter(valid_606744, JString, required = true, default = newJString(
      "RekognitionService.StartLabelDetection"))
  if valid_606744 != nil:
    section.add "X-Amz-Target", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Signature")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Signature", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Content-Sha256", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Date")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Date", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Credential")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Credential", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Security-Token")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Security-Token", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Algorithm")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Algorithm", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-SignedHeaders", valid_606751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606753: Call_StartLabelDetection_606741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ## 
  let valid = call_606753.validator(path, query, header, formData, body)
  let scheme = call_606753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606753.url(scheme.get, call_606753.host, call_606753.base,
                         call_606753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606753, url, valid)

proc call*(call_606754: Call_StartLabelDetection_606741; body: JsonNode): Recallable =
  ## startLabelDetection
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ##   body: JObject (required)
  var body_606755 = newJObject()
  if body != nil:
    body_606755 = body
  result = call_606754.call(nil, nil, nil, nil, body_606755)

var startLabelDetection* = Call_StartLabelDetection_606741(
    name: "startLabelDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartLabelDetection",
    validator: validate_StartLabelDetection_606742, base: "/",
    url: url_StartLabelDetection_606743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPersonTracking_606756 = ref object of OpenApiRestCall_605590
proc url_StartPersonTracking_606758(protocol: Scheme; host: string; base: string;
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

proc validate_StartPersonTracking_606757(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606759 = header.getOrDefault("X-Amz-Target")
  valid_606759 = validateParameter(valid_606759, JString, required = true, default = newJString(
      "RekognitionService.StartPersonTracking"))
  if valid_606759 != nil:
    section.add "X-Amz-Target", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Signature")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Signature", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Content-Sha256", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Date")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Date", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Credential")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Credential", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Security-Token")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Security-Token", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Algorithm")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Algorithm", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-SignedHeaders", valid_606766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606768: Call_StartPersonTracking_606756; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ## 
  let valid = call_606768.validator(path, query, header, formData, body)
  let scheme = call_606768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606768.url(scheme.get, call_606768.host, call_606768.base,
                         call_606768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606768, url, valid)

proc call*(call_606769: Call_StartPersonTracking_606756; body: JsonNode): Recallable =
  ## startPersonTracking
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ##   body: JObject (required)
  var body_606770 = newJObject()
  if body != nil:
    body_606770 = body
  result = call_606769.call(nil, nil, nil, nil, body_606770)

var startPersonTracking* = Call_StartPersonTracking_606756(
    name: "startPersonTracking", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartPersonTracking",
    validator: validate_StartPersonTracking_606757, base: "/",
    url: url_StartPersonTracking_606758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartProjectVersion_606771 = ref object of OpenApiRestCall_605590
proc url_StartProjectVersion_606773(protocol: Scheme; host: string; base: string;
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

proc validate_StartProjectVersion_606772(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606774 = header.getOrDefault("X-Amz-Target")
  valid_606774 = validateParameter(valid_606774, JString, required = true, default = newJString(
      "RekognitionService.StartProjectVersion"))
  if valid_606774 != nil:
    section.add "X-Amz-Target", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Signature")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Signature", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Content-Sha256", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Date")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Date", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Credential")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Credential", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Security-Token")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Security-Token", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Algorithm")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Algorithm", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-SignedHeaders", valid_606781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606783: Call_StartProjectVersion_606771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ## 
  let valid = call_606783.validator(path, query, header, formData, body)
  let scheme = call_606783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606783.url(scheme.get, call_606783.host, call_606783.base,
                         call_606783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606783, url, valid)

proc call*(call_606784: Call_StartProjectVersion_606771; body: JsonNode): Recallable =
  ## startProjectVersion
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_606785 = newJObject()
  if body != nil:
    body_606785 = body
  result = call_606784.call(nil, nil, nil, nil, body_606785)

var startProjectVersion* = Call_StartProjectVersion_606771(
    name: "startProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartProjectVersion",
    validator: validate_StartProjectVersion_606772, base: "/",
    url: url_StartProjectVersion_606773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartStreamProcessor_606786 = ref object of OpenApiRestCall_605590
proc url_StartStreamProcessor_606788(protocol: Scheme; host: string; base: string;
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

proc validate_StartStreamProcessor_606787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606789 = header.getOrDefault("X-Amz-Target")
  valid_606789 = validateParameter(valid_606789, JString, required = true, default = newJString(
      "RekognitionService.StartStreamProcessor"))
  if valid_606789 != nil:
    section.add "X-Amz-Target", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Signature")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Signature", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Content-Sha256", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Date")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Date", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Credential")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Credential", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Security-Token")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Security-Token", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Algorithm")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Algorithm", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-SignedHeaders", valid_606796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606798: Call_StartStreamProcessor_606786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ## 
  let valid = call_606798.validator(path, query, header, formData, body)
  let scheme = call_606798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606798.url(scheme.get, call_606798.host, call_606798.base,
                         call_606798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606798, url, valid)

proc call*(call_606799: Call_StartStreamProcessor_606786; body: JsonNode): Recallable =
  ## startStreamProcessor
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ##   body: JObject (required)
  var body_606800 = newJObject()
  if body != nil:
    body_606800 = body
  result = call_606799.call(nil, nil, nil, nil, body_606800)

var startStreamProcessor* = Call_StartStreamProcessor_606786(
    name: "startStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartStreamProcessor",
    validator: validate_StartStreamProcessor_606787, base: "/",
    url: url_StartStreamProcessor_606788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProjectVersion_606801 = ref object of OpenApiRestCall_605590
proc url_StopProjectVersion_606803(protocol: Scheme; host: string; base: string;
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

proc validate_StopProjectVersion_606802(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606804 = header.getOrDefault("X-Amz-Target")
  valid_606804 = validateParameter(valid_606804, JString, required = true, default = newJString(
      "RekognitionService.StopProjectVersion"))
  if valid_606804 != nil:
    section.add "X-Amz-Target", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Signature")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Signature", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Content-Sha256", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Date")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Date", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Credential")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Credential", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Security-Token")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Security-Token", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Algorithm")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Algorithm", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-SignedHeaders", valid_606811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606813: Call_StopProjectVersion_606801; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ## 
  let valid = call_606813.validator(path, query, header, formData, body)
  let scheme = call_606813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606813.url(scheme.get, call_606813.host, call_606813.base,
                         call_606813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606813, url, valid)

proc call*(call_606814: Call_StopProjectVersion_606801; body: JsonNode): Recallable =
  ## stopProjectVersion
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ##   body: JObject (required)
  var body_606815 = newJObject()
  if body != nil:
    body_606815 = body
  result = call_606814.call(nil, nil, nil, nil, body_606815)

var stopProjectVersion* = Call_StopProjectVersion_606801(
    name: "stopProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopProjectVersion",
    validator: validate_StopProjectVersion_606802, base: "/",
    url: url_StopProjectVersion_606803, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopStreamProcessor_606816 = ref object of OpenApiRestCall_605590
proc url_StopStreamProcessor_606818(protocol: Scheme; host: string; base: string;
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

proc validate_StopStreamProcessor_606817(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606819 = header.getOrDefault("X-Amz-Target")
  valid_606819 = validateParameter(valid_606819, JString, required = true, default = newJString(
      "RekognitionService.StopStreamProcessor"))
  if valid_606819 != nil:
    section.add "X-Amz-Target", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Signature")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Signature", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-Content-Sha256", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Date")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Date", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Credential")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Credential", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Security-Token")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Security-Token", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Algorithm")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Algorithm", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-SignedHeaders", valid_606826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606828: Call_StopStreamProcessor_606816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ## 
  let valid = call_606828.validator(path, query, header, formData, body)
  let scheme = call_606828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606828.url(scheme.get, call_606828.host, call_606828.base,
                         call_606828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606828, url, valid)

proc call*(call_606829: Call_StopStreamProcessor_606816; body: JsonNode): Recallable =
  ## stopStreamProcessor
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ##   body: JObject (required)
  var body_606830 = newJObject()
  if body != nil:
    body_606830 = body
  result = call_606829.call(nil, nil, nil, nil, body_606830)

var stopStreamProcessor* = Call_StopStreamProcessor_606816(
    name: "stopStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopStreamProcessor",
    validator: validate_StopStreamProcessor_606817, base: "/",
    url: url_StopStreamProcessor_606818, schemes: {Scheme.Https, Scheme.Http})
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
