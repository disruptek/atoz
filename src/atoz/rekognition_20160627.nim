
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

  OpenApiRestCall_612659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612659): Option[Scheme] {.used.} =
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
  Call_CompareFaces_612997 = ref object of OpenApiRestCall_612659
proc url_CompareFaces_612999(protocol: Scheme; host: string; base: string;
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

proc validate_CompareFaces_612998(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613124 = header.getOrDefault("X-Amz-Target")
  valid_613124 = validateParameter(valid_613124, JString, required = true, default = newJString(
      "RekognitionService.CompareFaces"))
  if valid_613124 != nil:
    section.add "X-Amz-Target", valid_613124
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613155: Call_CompareFaces_612997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ## 
  let valid = call_613155.validator(path, query, header, formData, body)
  let scheme = call_613155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613155.url(scheme.get, call_613155.host, call_613155.base,
                         call_613155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613155, url, valid)

proc call*(call_613226: Call_CompareFaces_612997; body: JsonNode): Recallable =
  ## compareFaces
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ##   body: JObject (required)
  var body_613227 = newJObject()
  if body != nil:
    body_613227 = body
  result = call_613226.call(nil, nil, nil, nil, body_613227)

var compareFaces* = Call_CompareFaces_612997(name: "compareFaces",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CompareFaces",
    validator: validate_CompareFaces_612998, base: "/", url: url_CompareFaces_612999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCollection_613266 = ref object of OpenApiRestCall_612659
proc url_CreateCollection_613268(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCollection_613267(path: JsonNode; query: JsonNode;
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
  var valid_613269 = header.getOrDefault("X-Amz-Target")
  valid_613269 = validateParameter(valid_613269, JString, required = true, default = newJString(
      "RekognitionService.CreateCollection"))
  if valid_613269 != nil:
    section.add "X-Amz-Target", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_CreateCollection_613266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_CreateCollection_613266; body: JsonNode): Recallable =
  ## createCollection
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ##   body: JObject (required)
  var body_613280 = newJObject()
  if body != nil:
    body_613280 = body
  result = call_613279.call(nil, nil, nil, nil, body_613280)

var createCollection* = Call_CreateCollection_613266(name: "createCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateCollection",
    validator: validate_CreateCollection_613267, base: "/",
    url: url_CreateCollection_613268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_613281 = ref object of OpenApiRestCall_612659
proc url_CreateProject_613283(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_613282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613284 = header.getOrDefault("X-Amz-Target")
  valid_613284 = validateParameter(valid_613284, JString, required = true, default = newJString(
      "RekognitionService.CreateProject"))
  if valid_613284 != nil:
    section.add "X-Amz-Target", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_CreateProject_613281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_CreateProject_613281; body: JsonNode): Recallable =
  ## createProject
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var createProject* = Call_CreateProject_613281(name: "createProject",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProject",
    validator: validate_CreateProject_613282, base: "/", url: url_CreateProject_613283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProjectVersion_613296 = ref object of OpenApiRestCall_612659
proc url_CreateProjectVersion_613298(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProjectVersion_613297(path: JsonNode; query: JsonNode;
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
  var valid_613299 = header.getOrDefault("X-Amz-Target")
  valid_613299 = validateParameter(valid_613299, JString, required = true, default = newJString(
      "RekognitionService.CreateProjectVersion"))
  if valid_613299 != nil:
    section.add "X-Amz-Target", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Signature")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Signature", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Content-Sha256", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Date")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Date", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Credential")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Credential", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Security-Token")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Security-Token", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-Algorithm")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Algorithm", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-SignedHeaders", valid_613306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613308: Call_CreateProjectVersion_613296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ## 
  let valid = call_613308.validator(path, query, header, formData, body)
  let scheme = call_613308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613308.url(scheme.get, call_613308.host, call_613308.base,
                         call_613308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613308, url, valid)

proc call*(call_613309: Call_CreateProjectVersion_613296; body: JsonNode): Recallable =
  ## createProjectVersion
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_613310 = newJObject()
  if body != nil:
    body_613310 = body
  result = call_613309.call(nil, nil, nil, nil, body_613310)

var createProjectVersion* = Call_CreateProjectVersion_613296(
    name: "createProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProjectVersion",
    validator: validate_CreateProjectVersion_613297, base: "/",
    url: url_CreateProjectVersion_613298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamProcessor_613311 = ref object of OpenApiRestCall_612659
proc url_CreateStreamProcessor_613313(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStreamProcessor_613312(path: JsonNode; query: JsonNode;
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
  var valid_613314 = header.getOrDefault("X-Amz-Target")
  valid_613314 = validateParameter(valid_613314, JString, required = true, default = newJString(
      "RekognitionService.CreateStreamProcessor"))
  if valid_613314 != nil:
    section.add "X-Amz-Target", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Signature")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Signature", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Content-Sha256", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Date")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Date", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Credential")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Credential", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Security-Token")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Security-Token", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Algorithm")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Algorithm", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-SignedHeaders", valid_613321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613323: Call_CreateStreamProcessor_613311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ## 
  let valid = call_613323.validator(path, query, header, formData, body)
  let scheme = call_613323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613323.url(scheme.get, call_613323.host, call_613323.base,
                         call_613323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613323, url, valid)

proc call*(call_613324: Call_CreateStreamProcessor_613311; body: JsonNode): Recallable =
  ## createStreamProcessor
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ##   body: JObject (required)
  var body_613325 = newJObject()
  if body != nil:
    body_613325 = body
  result = call_613324.call(nil, nil, nil, nil, body_613325)

var createStreamProcessor* = Call_CreateStreamProcessor_613311(
    name: "createStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateStreamProcessor",
    validator: validate_CreateStreamProcessor_613312, base: "/",
    url: url_CreateStreamProcessor_613313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCollection_613326 = ref object of OpenApiRestCall_612659
proc url_DeleteCollection_613328(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCollection_613327(path: JsonNode; query: JsonNode;
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
  var valid_613329 = header.getOrDefault("X-Amz-Target")
  valid_613329 = validateParameter(valid_613329, JString, required = true, default = newJString(
      "RekognitionService.DeleteCollection"))
  if valid_613329 != nil:
    section.add "X-Amz-Target", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613338: Call_DeleteCollection_613326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ## 
  let valid = call_613338.validator(path, query, header, formData, body)
  let scheme = call_613338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613338.url(scheme.get, call_613338.host, call_613338.base,
                         call_613338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613338, url, valid)

proc call*(call_613339: Call_DeleteCollection_613326; body: JsonNode): Recallable =
  ## deleteCollection
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ##   body: JObject (required)
  var body_613340 = newJObject()
  if body != nil:
    body_613340 = body
  result = call_613339.call(nil, nil, nil, nil, body_613340)

var deleteCollection* = Call_DeleteCollection_613326(name: "deleteCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteCollection",
    validator: validate_DeleteCollection_613327, base: "/",
    url: url_DeleteCollection_613328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFaces_613341 = ref object of OpenApiRestCall_612659
proc url_DeleteFaces_613343(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFaces_613342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613344 = header.getOrDefault("X-Amz-Target")
  valid_613344 = validateParameter(valid_613344, JString, required = true, default = newJString(
      "RekognitionService.DeleteFaces"))
  if valid_613344 != nil:
    section.add "X-Amz-Target", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Signature")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Signature", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Content-Sha256", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Date")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Date", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Credential")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Credential", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Security-Token")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Security-Token", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Algorithm")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Algorithm", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-SignedHeaders", valid_613351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_DeleteFaces_613341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_DeleteFaces_613341; body: JsonNode): Recallable =
  ## deleteFaces
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ##   body: JObject (required)
  var body_613355 = newJObject()
  if body != nil:
    body_613355 = body
  result = call_613354.call(nil, nil, nil, nil, body_613355)

var deleteFaces* = Call_DeleteFaces_613341(name: "deleteFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DeleteFaces",
                                        validator: validate_DeleteFaces_613342,
                                        base: "/", url: url_DeleteFaces_613343,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamProcessor_613356 = ref object of OpenApiRestCall_612659
proc url_DeleteStreamProcessor_613358(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStreamProcessor_613357(path: JsonNode; query: JsonNode;
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
  var valid_613359 = header.getOrDefault("X-Amz-Target")
  valid_613359 = validateParameter(valid_613359, JString, required = true, default = newJString(
      "RekognitionService.DeleteStreamProcessor"))
  if valid_613359 != nil:
    section.add "X-Amz-Target", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Signature")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Signature", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Content-Sha256", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Date")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Date", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Credential")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Credential", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-Security-Token")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-Security-Token", valid_613364
  var valid_613365 = header.getOrDefault("X-Amz-Algorithm")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Algorithm", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-SignedHeaders", valid_613366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613368: Call_DeleteStreamProcessor_613356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ## 
  let valid = call_613368.validator(path, query, header, formData, body)
  let scheme = call_613368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613368.url(scheme.get, call_613368.host, call_613368.base,
                         call_613368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613368, url, valid)

proc call*(call_613369: Call_DeleteStreamProcessor_613356; body: JsonNode): Recallable =
  ## deleteStreamProcessor
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ##   body: JObject (required)
  var body_613370 = newJObject()
  if body != nil:
    body_613370 = body
  result = call_613369.call(nil, nil, nil, nil, body_613370)

var deleteStreamProcessor* = Call_DeleteStreamProcessor_613356(
    name: "deleteStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteStreamProcessor",
    validator: validate_DeleteStreamProcessor_613357, base: "/",
    url: url_DeleteStreamProcessor_613358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCollection_613371 = ref object of OpenApiRestCall_612659
proc url_DescribeCollection_613373(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCollection_613372(path: JsonNode; query: JsonNode;
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
  var valid_613374 = header.getOrDefault("X-Amz-Target")
  valid_613374 = validateParameter(valid_613374, JString, required = true, default = newJString(
      "RekognitionService.DescribeCollection"))
  if valid_613374 != nil:
    section.add "X-Amz-Target", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Signature")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Signature", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Content-Sha256", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Date")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Date", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Credential")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Credential", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Security-Token")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Security-Token", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Algorithm")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Algorithm", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-SignedHeaders", valid_613381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613383: Call_DescribeCollection_613371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613383.validator(path, query, header, formData, body)
  let scheme = call_613383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613383.url(scheme.get, call_613383.host, call_613383.base,
                         call_613383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613383, url, valid)

proc call*(call_613384: Call_DescribeCollection_613371; body: JsonNode): Recallable =
  ## describeCollection
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_613385 = newJObject()
  if body != nil:
    body_613385 = body
  result = call_613384.call(nil, nil, nil, nil, body_613385)

var describeCollection* = Call_DescribeCollection_613371(
    name: "describeCollection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeCollection",
    validator: validate_DescribeCollection_613372, base: "/",
    url: url_DescribeCollection_613373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjectVersions_613386 = ref object of OpenApiRestCall_612659
proc url_DescribeProjectVersions_613388(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProjectVersions_613387(path: JsonNode; query: JsonNode;
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
  var valid_613389 = query.getOrDefault("MaxResults")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "MaxResults", valid_613389
  var valid_613390 = query.getOrDefault("NextToken")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "NextToken", valid_613390
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
  var valid_613391 = header.getOrDefault("X-Amz-Target")
  valid_613391 = validateParameter(valid_613391, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjectVersions"))
  if valid_613391 != nil:
    section.add "X-Amz-Target", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Signature")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Signature", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Content-Sha256", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Date")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Date", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Credential")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Credential", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_DescribeProjectVersions_613386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ## 
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_DescribeProjectVersions_613386; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjectVersions
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613402 = newJObject()
  var body_613403 = newJObject()
  add(query_613402, "MaxResults", newJString(MaxResults))
  add(query_613402, "NextToken", newJString(NextToken))
  if body != nil:
    body_613403 = body
  result = call_613401.call(nil, query_613402, nil, nil, body_613403)

var describeProjectVersions* = Call_DescribeProjectVersions_613386(
    name: "describeProjectVersions", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjectVersions",
    validator: validate_DescribeProjectVersions_613387, base: "/",
    url: url_DescribeProjectVersions_613388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjects_613405 = ref object of OpenApiRestCall_612659
proc url_DescribeProjects_613407(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProjects_613406(path: JsonNode; query: JsonNode;
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
  var valid_613408 = query.getOrDefault("MaxResults")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "MaxResults", valid_613408
  var valid_613409 = query.getOrDefault("NextToken")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "NextToken", valid_613409
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
  var valid_613410 = header.getOrDefault("X-Amz-Target")
  valid_613410 = validateParameter(valid_613410, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjects"))
  if valid_613410 != nil:
    section.add "X-Amz-Target", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Signature")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Signature", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Content-Sha256", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Date")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Date", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Credential")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Credential", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Security-Token")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Security-Token", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Algorithm")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Algorithm", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-SignedHeaders", valid_613417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_DescribeProjects_613405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_DescribeProjects_613405; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjects
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613421 = newJObject()
  var body_613422 = newJObject()
  add(query_613421, "MaxResults", newJString(MaxResults))
  add(query_613421, "NextToken", newJString(NextToken))
  if body != nil:
    body_613422 = body
  result = call_613420.call(nil, query_613421, nil, nil, body_613422)

var describeProjects* = Call_DescribeProjects_613405(name: "describeProjects",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjects",
    validator: validate_DescribeProjects_613406, base: "/",
    url: url_DescribeProjects_613407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStreamProcessor_613423 = ref object of OpenApiRestCall_612659
proc url_DescribeStreamProcessor_613425(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeStreamProcessor_613424(path: JsonNode; query: JsonNode;
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
  var valid_613426 = header.getOrDefault("X-Amz-Target")
  valid_613426 = validateParameter(valid_613426, JString, required = true, default = newJString(
      "RekognitionService.DescribeStreamProcessor"))
  if valid_613426 != nil:
    section.add "X-Amz-Target", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613435: Call_DescribeStreamProcessor_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ## 
  let valid = call_613435.validator(path, query, header, formData, body)
  let scheme = call_613435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613435.url(scheme.get, call_613435.host, call_613435.base,
                         call_613435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613435, url, valid)

proc call*(call_613436: Call_DescribeStreamProcessor_613423; body: JsonNode): Recallable =
  ## describeStreamProcessor
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ##   body: JObject (required)
  var body_613437 = newJObject()
  if body != nil:
    body_613437 = body
  result = call_613436.call(nil, nil, nil, nil, body_613437)

var describeStreamProcessor* = Call_DescribeStreamProcessor_613423(
    name: "describeStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeStreamProcessor",
    validator: validate_DescribeStreamProcessor_613424, base: "/",
    url: url_DescribeStreamProcessor_613425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectCustomLabels_613438 = ref object of OpenApiRestCall_612659
proc url_DetectCustomLabels_613440(protocol: Scheme; host: string; base: string;
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

proc validate_DetectCustomLabels_613439(path: JsonNode; query: JsonNode;
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
  var valid_613441 = header.getOrDefault("X-Amz-Target")
  valid_613441 = validateParameter(valid_613441, JString, required = true, default = newJString(
      "RekognitionService.DetectCustomLabels"))
  if valid_613441 != nil:
    section.add "X-Amz-Target", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Signature")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Signature", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Content-Sha256", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Date")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Date", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Credential")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Credential", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Security-Token")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Security-Token", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Algorithm")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Algorithm", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-SignedHeaders", valid_613448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_DetectCustomLabels_613438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_DetectCustomLabels_613438; body: JsonNode): Recallable =
  ## detectCustomLabels
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ##   body: JObject (required)
  var body_613452 = newJObject()
  if body != nil:
    body_613452 = body
  result = call_613451.call(nil, nil, nil, nil, body_613452)

var detectCustomLabels* = Call_DetectCustomLabels_613438(
    name: "detectCustomLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectCustomLabels",
    validator: validate_DetectCustomLabels_613439, base: "/",
    url: url_DetectCustomLabels_613440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectFaces_613453 = ref object of OpenApiRestCall_612659
proc url_DetectFaces_613455(protocol: Scheme; host: string; base: string;
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

proc validate_DetectFaces_613454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613456 = header.getOrDefault("X-Amz-Target")
  valid_613456 = validateParameter(valid_613456, JString, required = true, default = newJString(
      "RekognitionService.DetectFaces"))
  if valid_613456 != nil:
    section.add "X-Amz-Target", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613465: Call_DetectFaces_613453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ## 
  let valid = call_613465.validator(path, query, header, formData, body)
  let scheme = call_613465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613465.url(scheme.get, call_613465.host, call_613465.base,
                         call_613465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613465, url, valid)

proc call*(call_613466: Call_DetectFaces_613453; body: JsonNode): Recallable =
  ## detectFaces
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ##   body: JObject (required)
  var body_613467 = newJObject()
  if body != nil:
    body_613467 = body
  result = call_613466.call(nil, nil, nil, nil, body_613467)

var detectFaces* = Call_DetectFaces_613453(name: "detectFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectFaces",
                                        validator: validate_DetectFaces_613454,
                                        base: "/", url: url_DetectFaces_613455,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectLabels_613468 = ref object of OpenApiRestCall_612659
proc url_DetectLabels_613470(protocol: Scheme; host: string; base: string;
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

proc validate_DetectLabels_613469(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613471 = header.getOrDefault("X-Amz-Target")
  valid_613471 = validateParameter(valid_613471, JString, required = true, default = newJString(
      "RekognitionService.DetectLabels"))
  if valid_613471 != nil:
    section.add "X-Amz-Target", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Signature")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Signature", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Content-Sha256", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Date")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Date", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Credential")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Credential", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Security-Token")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Security-Token", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Algorithm")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Algorithm", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-SignedHeaders", valid_613478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613480: Call_DetectLabels_613468; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ## 
  let valid = call_613480.validator(path, query, header, formData, body)
  let scheme = call_613480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613480.url(scheme.get, call_613480.host, call_613480.base,
                         call_613480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613480, url, valid)

proc call*(call_613481: Call_DetectLabels_613468; body: JsonNode): Recallable =
  ## detectLabels
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ##   body: JObject (required)
  var body_613482 = newJObject()
  if body != nil:
    body_613482 = body
  result = call_613481.call(nil, nil, nil, nil, body_613482)

var detectLabels* = Call_DetectLabels_613468(name: "detectLabels",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectLabels",
    validator: validate_DetectLabels_613469, base: "/", url: url_DetectLabels_613470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectModerationLabels_613483 = ref object of OpenApiRestCall_612659
proc url_DetectModerationLabels_613485(protocol: Scheme; host: string; base: string;
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

proc validate_DetectModerationLabels_613484(path: JsonNode; query: JsonNode;
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
  var valid_613486 = header.getOrDefault("X-Amz-Target")
  valid_613486 = validateParameter(valid_613486, JString, required = true, default = newJString(
      "RekognitionService.DetectModerationLabels"))
  if valid_613486 != nil:
    section.add "X-Amz-Target", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Signature")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Signature", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Content-Sha256", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Date")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Date", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Credential")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Credential", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Security-Token")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Security-Token", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Algorithm")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Algorithm", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-SignedHeaders", valid_613493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613495: Call_DetectModerationLabels_613483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ## 
  let valid = call_613495.validator(path, query, header, formData, body)
  let scheme = call_613495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613495.url(scheme.get, call_613495.host, call_613495.base,
                         call_613495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613495, url, valid)

proc call*(call_613496: Call_DetectModerationLabels_613483; body: JsonNode): Recallable =
  ## detectModerationLabels
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ##   body: JObject (required)
  var body_613497 = newJObject()
  if body != nil:
    body_613497 = body
  result = call_613496.call(nil, nil, nil, nil, body_613497)

var detectModerationLabels* = Call_DetectModerationLabels_613483(
    name: "detectModerationLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectModerationLabels",
    validator: validate_DetectModerationLabels_613484, base: "/",
    url: url_DetectModerationLabels_613485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectText_613498 = ref object of OpenApiRestCall_612659
proc url_DetectText_613500(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DetectText_613499(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613501 = header.getOrDefault("X-Amz-Target")
  valid_613501 = validateParameter(valid_613501, JString, required = true, default = newJString(
      "RekognitionService.DetectText"))
  if valid_613501 != nil:
    section.add "X-Amz-Target", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Signature")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Signature", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Content-Sha256", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Date")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Date", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Credential")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Credential", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Security-Token")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Security-Token", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Algorithm")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Algorithm", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-SignedHeaders", valid_613508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613510: Call_DetectText_613498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613510.validator(path, query, header, formData, body)
  let scheme = call_613510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613510.url(scheme.get, call_613510.host, call_613510.base,
                         call_613510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613510, url, valid)

proc call*(call_613511: Call_DetectText_613498; body: JsonNode): Recallable =
  ## detectText
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_613512 = newJObject()
  if body != nil:
    body_613512 = body
  result = call_613511.call(nil, nil, nil, nil, body_613512)

var detectText* = Call_DetectText_613498(name: "detectText",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectText",
                                      validator: validate_DetectText_613499,
                                      base: "/", url: url_DetectText_613500,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityInfo_613513 = ref object of OpenApiRestCall_612659
proc url_GetCelebrityInfo_613515(protocol: Scheme; host: string; base: string;
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

proc validate_GetCelebrityInfo_613514(path: JsonNode; query: JsonNode;
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
  var valid_613516 = header.getOrDefault("X-Amz-Target")
  valid_613516 = validateParameter(valid_613516, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityInfo"))
  if valid_613516 != nil:
    section.add "X-Amz-Target", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Signature")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Signature", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Content-Sha256", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Date")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Date", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Credential")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Credential", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Security-Token")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Security-Token", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Algorithm")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Algorithm", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-SignedHeaders", valid_613523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613525: Call_GetCelebrityInfo_613513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ## 
  let valid = call_613525.validator(path, query, header, formData, body)
  let scheme = call_613525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613525.url(scheme.get, call_613525.host, call_613525.base,
                         call_613525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613525, url, valid)

proc call*(call_613526: Call_GetCelebrityInfo_613513; body: JsonNode): Recallable =
  ## getCelebrityInfo
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ##   body: JObject (required)
  var body_613527 = newJObject()
  if body != nil:
    body_613527 = body
  result = call_613526.call(nil, nil, nil, nil, body_613527)

var getCelebrityInfo* = Call_GetCelebrityInfo_613513(name: "getCelebrityInfo",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityInfo",
    validator: validate_GetCelebrityInfo_613514, base: "/",
    url: url_GetCelebrityInfo_613515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityRecognition_613528 = ref object of OpenApiRestCall_612659
proc url_GetCelebrityRecognition_613530(protocol: Scheme; host: string; base: string;
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

proc validate_GetCelebrityRecognition_613529(path: JsonNode; query: JsonNode;
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
  var valid_613531 = query.getOrDefault("MaxResults")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "MaxResults", valid_613531
  var valid_613532 = query.getOrDefault("NextToken")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "NextToken", valid_613532
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
  var valid_613533 = header.getOrDefault("X-Amz-Target")
  valid_613533 = validateParameter(valid_613533, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityRecognition"))
  if valid_613533 != nil:
    section.add "X-Amz-Target", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Signature")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Signature", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Content-Sha256", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Date")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Date", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Credential")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Credential", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-Security-Token")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Security-Token", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Algorithm")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Algorithm", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-SignedHeaders", valid_613540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613542: Call_GetCelebrityRecognition_613528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ## 
  let valid = call_613542.validator(path, query, header, formData, body)
  let scheme = call_613542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613542.url(scheme.get, call_613542.host, call_613542.base,
                         call_613542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613542, url, valid)

proc call*(call_613543: Call_GetCelebrityRecognition_613528; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCelebrityRecognition
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613544 = newJObject()
  var body_613545 = newJObject()
  add(query_613544, "MaxResults", newJString(MaxResults))
  add(query_613544, "NextToken", newJString(NextToken))
  if body != nil:
    body_613545 = body
  result = call_613543.call(nil, query_613544, nil, nil, body_613545)

var getCelebrityRecognition* = Call_GetCelebrityRecognition_613528(
    name: "getCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityRecognition",
    validator: validate_GetCelebrityRecognition_613529, base: "/",
    url: url_GetCelebrityRecognition_613530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContentModeration_613546 = ref object of OpenApiRestCall_612659
proc url_GetContentModeration_613548(protocol: Scheme; host: string; base: string;
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

proc validate_GetContentModeration_613547(path: JsonNode; query: JsonNode;
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
  var valid_613549 = query.getOrDefault("MaxResults")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "MaxResults", valid_613549
  var valid_613550 = query.getOrDefault("NextToken")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "NextToken", valid_613550
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
  var valid_613551 = header.getOrDefault("X-Amz-Target")
  valid_613551 = validateParameter(valid_613551, JString, required = true, default = newJString(
      "RekognitionService.GetContentModeration"))
  if valid_613551 != nil:
    section.add "X-Amz-Target", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_GetContentModeration_613546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_GetContentModeration_613546; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getContentModeration
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613562 = newJObject()
  var body_613563 = newJObject()
  add(query_613562, "MaxResults", newJString(MaxResults))
  add(query_613562, "NextToken", newJString(NextToken))
  if body != nil:
    body_613563 = body
  result = call_613561.call(nil, query_613562, nil, nil, body_613563)

var getContentModeration* = Call_GetContentModeration_613546(
    name: "getContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetContentModeration",
    validator: validate_GetContentModeration_613547, base: "/",
    url: url_GetContentModeration_613548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceDetection_613564 = ref object of OpenApiRestCall_612659
proc url_GetFaceDetection_613566(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceDetection_613565(path: JsonNode; query: JsonNode;
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
  var valid_613567 = query.getOrDefault("MaxResults")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "MaxResults", valid_613567
  var valid_613568 = query.getOrDefault("NextToken")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "NextToken", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Target")
  valid_613569 = validateParameter(valid_613569, JString, required = true, default = newJString(
      "RekognitionService.GetFaceDetection"))
  if valid_613569 != nil:
    section.add "X-Amz-Target", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Signature")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Signature", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Content-Sha256", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Date")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Date", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Credential")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Credential", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Security-Token")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Security-Token", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Algorithm")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Algorithm", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-SignedHeaders", valid_613576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613578: Call_GetFaceDetection_613564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ## 
  let valid = call_613578.validator(path, query, header, formData, body)
  let scheme = call_613578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613578.url(scheme.get, call_613578.host, call_613578.base,
                         call_613578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613578, url, valid)

proc call*(call_613579: Call_GetFaceDetection_613564; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceDetection
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613580 = newJObject()
  var body_613581 = newJObject()
  add(query_613580, "MaxResults", newJString(MaxResults))
  add(query_613580, "NextToken", newJString(NextToken))
  if body != nil:
    body_613581 = body
  result = call_613579.call(nil, query_613580, nil, nil, body_613581)

var getFaceDetection* = Call_GetFaceDetection_613564(name: "getFaceDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceDetection",
    validator: validate_GetFaceDetection_613565, base: "/",
    url: url_GetFaceDetection_613566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceSearch_613582 = ref object of OpenApiRestCall_612659
proc url_GetFaceSearch_613584(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceSearch_613583(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613585 = query.getOrDefault("MaxResults")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "MaxResults", valid_613585
  var valid_613586 = query.getOrDefault("NextToken")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "NextToken", valid_613586
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
  var valid_613587 = header.getOrDefault("X-Amz-Target")
  valid_613587 = validateParameter(valid_613587, JString, required = true, default = newJString(
      "RekognitionService.GetFaceSearch"))
  if valid_613587 != nil:
    section.add "X-Amz-Target", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Signature")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Signature", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Content-Sha256", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Date")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Date", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Credential")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Credential", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Security-Token")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Security-Token", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Algorithm")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Algorithm", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-SignedHeaders", valid_613594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613596: Call_GetFaceSearch_613582; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ## 
  let valid = call_613596.validator(path, query, header, formData, body)
  let scheme = call_613596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613596.url(scheme.get, call_613596.host, call_613596.base,
                         call_613596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613596, url, valid)

proc call*(call_613597: Call_GetFaceSearch_613582; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceSearch
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613598 = newJObject()
  var body_613599 = newJObject()
  add(query_613598, "MaxResults", newJString(MaxResults))
  add(query_613598, "NextToken", newJString(NextToken))
  if body != nil:
    body_613599 = body
  result = call_613597.call(nil, query_613598, nil, nil, body_613599)

var getFaceSearch* = Call_GetFaceSearch_613582(name: "getFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceSearch",
    validator: validate_GetFaceSearch_613583, base: "/", url: url_GetFaceSearch_613584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLabelDetection_613600 = ref object of OpenApiRestCall_612659
proc url_GetLabelDetection_613602(protocol: Scheme; host: string; base: string;
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

proc validate_GetLabelDetection_613601(path: JsonNode; query: JsonNode;
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
  var valid_613603 = query.getOrDefault("MaxResults")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "MaxResults", valid_613603
  var valid_613604 = query.getOrDefault("NextToken")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "NextToken", valid_613604
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
  var valid_613605 = header.getOrDefault("X-Amz-Target")
  valid_613605 = validateParameter(valid_613605, JString, required = true, default = newJString(
      "RekognitionService.GetLabelDetection"))
  if valid_613605 != nil:
    section.add "X-Amz-Target", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-Signature")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-Signature", valid_613606
  var valid_613607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613607 = validateParameter(valid_613607, JString, required = false,
                                 default = nil)
  if valid_613607 != nil:
    section.add "X-Amz-Content-Sha256", valid_613607
  var valid_613608 = header.getOrDefault("X-Amz-Date")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Date", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Credential")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Credential", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Security-Token")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Security-Token", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Algorithm")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Algorithm", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-SignedHeaders", valid_613612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613614: Call_GetLabelDetection_613600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ## 
  let valid = call_613614.validator(path, query, header, formData, body)
  let scheme = call_613614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613614.url(scheme.get, call_613614.host, call_613614.base,
                         call_613614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613614, url, valid)

proc call*(call_613615: Call_GetLabelDetection_613600; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getLabelDetection
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613616 = newJObject()
  var body_613617 = newJObject()
  add(query_613616, "MaxResults", newJString(MaxResults))
  add(query_613616, "NextToken", newJString(NextToken))
  if body != nil:
    body_613617 = body
  result = call_613615.call(nil, query_613616, nil, nil, body_613617)

var getLabelDetection* = Call_GetLabelDetection_613600(name: "getLabelDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetLabelDetection",
    validator: validate_GetLabelDetection_613601, base: "/",
    url: url_GetLabelDetection_613602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPersonTracking_613618 = ref object of OpenApiRestCall_612659
proc url_GetPersonTracking_613620(protocol: Scheme; host: string; base: string;
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

proc validate_GetPersonTracking_613619(path: JsonNode; query: JsonNode;
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
  var valid_613621 = query.getOrDefault("MaxResults")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "MaxResults", valid_613621
  var valid_613622 = query.getOrDefault("NextToken")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "NextToken", valid_613622
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
  var valid_613623 = header.getOrDefault("X-Amz-Target")
  valid_613623 = validateParameter(valid_613623, JString, required = true, default = newJString(
      "RekognitionService.GetPersonTracking"))
  if valid_613623 != nil:
    section.add "X-Amz-Target", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Signature")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Signature", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Content-Sha256", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Date")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Date", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Credential")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Credential", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Security-Token")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Security-Token", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Algorithm")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Algorithm", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-SignedHeaders", valid_613630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613632: Call_GetPersonTracking_613618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ## 
  let valid = call_613632.validator(path, query, header, formData, body)
  let scheme = call_613632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613632.url(scheme.get, call_613632.host, call_613632.base,
                         call_613632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613632, url, valid)

proc call*(call_613633: Call_GetPersonTracking_613618; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPersonTracking
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613634 = newJObject()
  var body_613635 = newJObject()
  add(query_613634, "MaxResults", newJString(MaxResults))
  add(query_613634, "NextToken", newJString(NextToken))
  if body != nil:
    body_613635 = body
  result = call_613633.call(nil, query_613634, nil, nil, body_613635)

var getPersonTracking* = Call_GetPersonTracking_613618(name: "getPersonTracking",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetPersonTracking",
    validator: validate_GetPersonTracking_613619, base: "/",
    url: url_GetPersonTracking_613620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IndexFaces_613636 = ref object of OpenApiRestCall_612659
proc url_IndexFaces_613638(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_IndexFaces_613637(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613639 = header.getOrDefault("X-Amz-Target")
  valid_613639 = validateParameter(valid_613639, JString, required = true, default = newJString(
      "RekognitionService.IndexFaces"))
  if valid_613639 != nil:
    section.add "X-Amz-Target", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Signature")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Signature", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Content-Sha256", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Date")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Date", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Credential")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Credential", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Security-Token")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Security-Token", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Algorithm")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Algorithm", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-SignedHeaders", valid_613646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613648: Call_IndexFaces_613636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ## 
  let valid = call_613648.validator(path, query, header, formData, body)
  let scheme = call_613648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613648.url(scheme.get, call_613648.host, call_613648.base,
                         call_613648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613648, url, valid)

proc call*(call_613649: Call_IndexFaces_613636; body: JsonNode): Recallable =
  ## indexFaces
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ##   body: JObject (required)
  var body_613650 = newJObject()
  if body != nil:
    body_613650 = body
  result = call_613649.call(nil, nil, nil, nil, body_613650)

var indexFaces* = Call_IndexFaces_613636(name: "indexFaces",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.IndexFaces",
                                      validator: validate_IndexFaces_613637,
                                      base: "/", url: url_IndexFaces_613638,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCollections_613651 = ref object of OpenApiRestCall_612659
proc url_ListCollections_613653(protocol: Scheme; host: string; base: string;
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

proc validate_ListCollections_613652(path: JsonNode; query: JsonNode;
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
  var valid_613654 = query.getOrDefault("MaxResults")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "MaxResults", valid_613654
  var valid_613655 = query.getOrDefault("NextToken")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "NextToken", valid_613655
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
  var valid_613656 = header.getOrDefault("X-Amz-Target")
  valid_613656 = validateParameter(valid_613656, JString, required = true, default = newJString(
      "RekognitionService.ListCollections"))
  if valid_613656 != nil:
    section.add "X-Amz-Target", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Signature")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Signature", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Content-Sha256", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Date")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Date", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Credential")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Credential", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Security-Token")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Security-Token", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Algorithm")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Algorithm", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-SignedHeaders", valid_613663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613665: Call_ListCollections_613651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ## 
  let valid = call_613665.validator(path, query, header, formData, body)
  let scheme = call_613665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613665.url(scheme.get, call_613665.host, call_613665.base,
                         call_613665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613665, url, valid)

proc call*(call_613666: Call_ListCollections_613651; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCollections
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613667 = newJObject()
  var body_613668 = newJObject()
  add(query_613667, "MaxResults", newJString(MaxResults))
  add(query_613667, "NextToken", newJString(NextToken))
  if body != nil:
    body_613668 = body
  result = call_613666.call(nil, query_613667, nil, nil, body_613668)

var listCollections* = Call_ListCollections_613651(name: "listCollections",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListCollections",
    validator: validate_ListCollections_613652, base: "/", url: url_ListCollections_613653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFaces_613669 = ref object of OpenApiRestCall_612659
proc url_ListFaces_613671(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListFaces_613670(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613672 = query.getOrDefault("MaxResults")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "MaxResults", valid_613672
  var valid_613673 = query.getOrDefault("NextToken")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "NextToken", valid_613673
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
  var valid_613674 = header.getOrDefault("X-Amz-Target")
  valid_613674 = validateParameter(valid_613674, JString, required = true, default = newJString(
      "RekognitionService.ListFaces"))
  if valid_613674 != nil:
    section.add "X-Amz-Target", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Signature")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Signature", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Content-Sha256", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Date")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Date", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Credential")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Credential", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Security-Token")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Security-Token", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Algorithm")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Algorithm", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-SignedHeaders", valid_613681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613683: Call_ListFaces_613669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ## 
  let valid = call_613683.validator(path, query, header, formData, body)
  let scheme = call_613683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613683.url(scheme.get, call_613683.host, call_613683.base,
                         call_613683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613683, url, valid)

proc call*(call_613684: Call_ListFaces_613669; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFaces
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613685 = newJObject()
  var body_613686 = newJObject()
  add(query_613685, "MaxResults", newJString(MaxResults))
  add(query_613685, "NextToken", newJString(NextToken))
  if body != nil:
    body_613686 = body
  result = call_613684.call(nil, query_613685, nil, nil, body_613686)

var listFaces* = Call_ListFaces_613669(name: "listFaces", meth: HttpMethod.HttpPost,
                                    host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.ListFaces",
                                    validator: validate_ListFaces_613670,
                                    base: "/", url: url_ListFaces_613671,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamProcessors_613687 = ref object of OpenApiRestCall_612659
proc url_ListStreamProcessors_613689(protocol: Scheme; host: string; base: string;
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

proc validate_ListStreamProcessors_613688(path: JsonNode; query: JsonNode;
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
  var valid_613690 = query.getOrDefault("MaxResults")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "MaxResults", valid_613690
  var valid_613691 = query.getOrDefault("NextToken")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "NextToken", valid_613691
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
  var valid_613692 = header.getOrDefault("X-Amz-Target")
  valid_613692 = validateParameter(valid_613692, JString, required = true, default = newJString(
      "RekognitionService.ListStreamProcessors"))
  if valid_613692 != nil:
    section.add "X-Amz-Target", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Signature")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Signature", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Content-Sha256", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Date")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Date", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Credential")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Credential", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Security-Token")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Security-Token", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Algorithm")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Algorithm", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-SignedHeaders", valid_613699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613701: Call_ListStreamProcessors_613687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ## 
  let valid = call_613701.validator(path, query, header, formData, body)
  let scheme = call_613701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613701.url(scheme.get, call_613701.host, call_613701.base,
                         call_613701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613701, url, valid)

proc call*(call_613702: Call_ListStreamProcessors_613687; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreamProcessors
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613703 = newJObject()
  var body_613704 = newJObject()
  add(query_613703, "MaxResults", newJString(MaxResults))
  add(query_613703, "NextToken", newJString(NextToken))
  if body != nil:
    body_613704 = body
  result = call_613702.call(nil, query_613703, nil, nil, body_613704)

var listStreamProcessors* = Call_ListStreamProcessors_613687(
    name: "listStreamProcessors", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListStreamProcessors",
    validator: validate_ListStreamProcessors_613688, base: "/",
    url: url_ListStreamProcessors_613689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RecognizeCelebrities_613705 = ref object of OpenApiRestCall_612659
proc url_RecognizeCelebrities_613707(protocol: Scheme; host: string; base: string;
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

proc validate_RecognizeCelebrities_613706(path: JsonNode; query: JsonNode;
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
  var valid_613708 = header.getOrDefault("X-Amz-Target")
  valid_613708 = validateParameter(valid_613708, JString, required = true, default = newJString(
      "RekognitionService.RecognizeCelebrities"))
  if valid_613708 != nil:
    section.add "X-Amz-Target", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Signature")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Signature", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Content-Sha256", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Date")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Date", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Credential")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Credential", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Security-Token")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Security-Token", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Algorithm")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Algorithm", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-SignedHeaders", valid_613715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613717: Call_RecognizeCelebrities_613705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ## 
  let valid = call_613717.validator(path, query, header, formData, body)
  let scheme = call_613717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613717.url(scheme.get, call_613717.host, call_613717.base,
                         call_613717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613717, url, valid)

proc call*(call_613718: Call_RecognizeCelebrities_613705; body: JsonNode): Recallable =
  ## recognizeCelebrities
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ##   body: JObject (required)
  var body_613719 = newJObject()
  if body != nil:
    body_613719 = body
  result = call_613718.call(nil, nil, nil, nil, body_613719)

var recognizeCelebrities* = Call_RecognizeCelebrities_613705(
    name: "recognizeCelebrities", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.RecognizeCelebrities",
    validator: validate_RecognizeCelebrities_613706, base: "/",
    url: url_RecognizeCelebrities_613707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFaces_613720 = ref object of OpenApiRestCall_612659
proc url_SearchFaces_613722(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFaces_613721(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613723 = header.getOrDefault("X-Amz-Target")
  valid_613723 = validateParameter(valid_613723, JString, required = true, default = newJString(
      "RekognitionService.SearchFaces"))
  if valid_613723 != nil:
    section.add "X-Amz-Target", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Signature")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Signature", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Content-Sha256", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Date")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Date", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Credential")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Credential", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Security-Token")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Security-Token", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Algorithm")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Algorithm", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-SignedHeaders", valid_613730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613732: Call_SearchFaces_613720; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ## 
  let valid = call_613732.validator(path, query, header, formData, body)
  let scheme = call_613732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613732.url(scheme.get, call_613732.host, call_613732.base,
                         call_613732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613732, url, valid)

proc call*(call_613733: Call_SearchFaces_613720; body: JsonNode): Recallable =
  ## searchFaces
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ##   body: JObject (required)
  var body_613734 = newJObject()
  if body != nil:
    body_613734 = body
  result = call_613733.call(nil, nil, nil, nil, body_613734)

var searchFaces* = Call_SearchFaces_613720(name: "searchFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.SearchFaces",
                                        validator: validate_SearchFaces_613721,
                                        base: "/", url: url_SearchFaces_613722,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFacesByImage_613735 = ref object of OpenApiRestCall_612659
proc url_SearchFacesByImage_613737(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFacesByImage_613736(path: JsonNode; query: JsonNode;
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
  var valid_613738 = header.getOrDefault("X-Amz-Target")
  valid_613738 = validateParameter(valid_613738, JString, required = true, default = newJString(
      "RekognitionService.SearchFacesByImage"))
  if valid_613738 != nil:
    section.add "X-Amz-Target", valid_613738
  var valid_613739 = header.getOrDefault("X-Amz-Signature")
  valid_613739 = validateParameter(valid_613739, JString, required = false,
                                 default = nil)
  if valid_613739 != nil:
    section.add "X-Amz-Signature", valid_613739
  var valid_613740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Content-Sha256", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Date")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Date", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Credential")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Credential", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Security-Token")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Security-Token", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Algorithm")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Algorithm", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-SignedHeaders", valid_613745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613747: Call_SearchFacesByImage_613735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ## 
  let valid = call_613747.validator(path, query, header, formData, body)
  let scheme = call_613747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613747.url(scheme.get, call_613747.host, call_613747.base,
                         call_613747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613747, url, valid)

proc call*(call_613748: Call_SearchFacesByImage_613735; body: JsonNode): Recallable =
  ## searchFacesByImage
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ##   body: JObject (required)
  var body_613749 = newJObject()
  if body != nil:
    body_613749 = body
  result = call_613748.call(nil, nil, nil, nil, body_613749)

var searchFacesByImage* = Call_SearchFacesByImage_613735(
    name: "searchFacesByImage", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.SearchFacesByImage",
    validator: validate_SearchFacesByImage_613736, base: "/",
    url: url_SearchFacesByImage_613737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCelebrityRecognition_613750 = ref object of OpenApiRestCall_612659
proc url_StartCelebrityRecognition_613752(protocol: Scheme; host: string;
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

proc validate_StartCelebrityRecognition_613751(path: JsonNode; query: JsonNode;
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
  var valid_613753 = header.getOrDefault("X-Amz-Target")
  valid_613753 = validateParameter(valid_613753, JString, required = true, default = newJString(
      "RekognitionService.StartCelebrityRecognition"))
  if valid_613753 != nil:
    section.add "X-Amz-Target", valid_613753
  var valid_613754 = header.getOrDefault("X-Amz-Signature")
  valid_613754 = validateParameter(valid_613754, JString, required = false,
                                 default = nil)
  if valid_613754 != nil:
    section.add "X-Amz-Signature", valid_613754
  var valid_613755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Content-Sha256", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Date")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Date", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Credential")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Credential", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Security-Token")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Security-Token", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Algorithm")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Algorithm", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-SignedHeaders", valid_613760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613762: Call_StartCelebrityRecognition_613750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613762.validator(path, query, header, formData, body)
  let scheme = call_613762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613762.url(scheme.get, call_613762.host, call_613762.base,
                         call_613762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613762, url, valid)

proc call*(call_613763: Call_StartCelebrityRecognition_613750; body: JsonNode): Recallable =
  ## startCelebrityRecognition
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_613764 = newJObject()
  if body != nil:
    body_613764 = body
  result = call_613763.call(nil, nil, nil, nil, body_613764)

var startCelebrityRecognition* = Call_StartCelebrityRecognition_613750(
    name: "startCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartCelebrityRecognition",
    validator: validate_StartCelebrityRecognition_613751, base: "/",
    url: url_StartCelebrityRecognition_613752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContentModeration_613765 = ref object of OpenApiRestCall_612659
proc url_StartContentModeration_613767(protocol: Scheme; host: string; base: string;
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

proc validate_StartContentModeration_613766(path: JsonNode; query: JsonNode;
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
  var valid_613768 = header.getOrDefault("X-Amz-Target")
  valid_613768 = validateParameter(valid_613768, JString, required = true, default = newJString(
      "RekognitionService.StartContentModeration"))
  if valid_613768 != nil:
    section.add "X-Amz-Target", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Signature")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Signature", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Content-Sha256", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Date")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Date", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Credential")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Credential", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Security-Token")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Security-Token", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Algorithm")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Algorithm", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-SignedHeaders", valid_613775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613777: Call_StartContentModeration_613765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613777.validator(path, query, header, formData, body)
  let scheme = call_613777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613777.url(scheme.get, call_613777.host, call_613777.base,
                         call_613777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613777, url, valid)

proc call*(call_613778: Call_StartContentModeration_613765; body: JsonNode): Recallable =
  ## startContentModeration
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_613779 = newJObject()
  if body != nil:
    body_613779 = body
  result = call_613778.call(nil, nil, nil, nil, body_613779)

var startContentModeration* = Call_StartContentModeration_613765(
    name: "startContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartContentModeration",
    validator: validate_StartContentModeration_613766, base: "/",
    url: url_StartContentModeration_613767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceDetection_613780 = ref object of OpenApiRestCall_612659
proc url_StartFaceDetection_613782(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceDetection_613781(path: JsonNode; query: JsonNode;
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
  var valid_613783 = header.getOrDefault("X-Amz-Target")
  valid_613783 = validateParameter(valid_613783, JString, required = true, default = newJString(
      "RekognitionService.StartFaceDetection"))
  if valid_613783 != nil:
    section.add "X-Amz-Target", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Signature")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Signature", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-Content-Sha256", valid_613785
  var valid_613786 = header.getOrDefault("X-Amz-Date")
  valid_613786 = validateParameter(valid_613786, JString, required = false,
                                 default = nil)
  if valid_613786 != nil:
    section.add "X-Amz-Date", valid_613786
  var valid_613787 = header.getOrDefault("X-Amz-Credential")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Credential", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Security-Token")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Security-Token", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Algorithm")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Algorithm", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-SignedHeaders", valid_613790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613792: Call_StartFaceDetection_613780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_613792.validator(path, query, header, formData, body)
  let scheme = call_613792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613792.url(scheme.get, call_613792.host, call_613792.base,
                         call_613792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613792, url, valid)

proc call*(call_613793: Call_StartFaceDetection_613780; body: JsonNode): Recallable =
  ## startFaceDetection
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_613794 = newJObject()
  if body != nil:
    body_613794 = body
  result = call_613793.call(nil, nil, nil, nil, body_613794)

var startFaceDetection* = Call_StartFaceDetection_613780(
    name: "startFaceDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceDetection",
    validator: validate_StartFaceDetection_613781, base: "/",
    url: url_StartFaceDetection_613782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceSearch_613795 = ref object of OpenApiRestCall_612659
proc url_StartFaceSearch_613797(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceSearch_613796(path: JsonNode; query: JsonNode;
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
  var valid_613798 = header.getOrDefault("X-Amz-Target")
  valid_613798 = validateParameter(valid_613798, JString, required = true, default = newJString(
      "RekognitionService.StartFaceSearch"))
  if valid_613798 != nil:
    section.add "X-Amz-Target", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Signature")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Signature", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Content-Sha256", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Date")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Date", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Credential")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Credential", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Security-Token")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Security-Token", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Algorithm")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Algorithm", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-SignedHeaders", valid_613805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613807: Call_StartFaceSearch_613795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ## 
  let valid = call_613807.validator(path, query, header, formData, body)
  let scheme = call_613807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613807.url(scheme.get, call_613807.host, call_613807.base,
                         call_613807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613807, url, valid)

proc call*(call_613808: Call_StartFaceSearch_613795; body: JsonNode): Recallable =
  ## startFaceSearch
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ##   body: JObject (required)
  var body_613809 = newJObject()
  if body != nil:
    body_613809 = body
  result = call_613808.call(nil, nil, nil, nil, body_613809)

var startFaceSearch* = Call_StartFaceSearch_613795(name: "startFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceSearch",
    validator: validate_StartFaceSearch_613796, base: "/", url: url_StartFaceSearch_613797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLabelDetection_613810 = ref object of OpenApiRestCall_612659
proc url_StartLabelDetection_613812(protocol: Scheme; host: string; base: string;
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

proc validate_StartLabelDetection_613811(path: JsonNode; query: JsonNode;
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
  var valid_613813 = header.getOrDefault("X-Amz-Target")
  valid_613813 = validateParameter(valid_613813, JString, required = true, default = newJString(
      "RekognitionService.StartLabelDetection"))
  if valid_613813 != nil:
    section.add "X-Amz-Target", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Signature")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Signature", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Content-Sha256", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Date")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Date", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Credential")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Credential", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Security-Token")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Security-Token", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Algorithm")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Algorithm", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-SignedHeaders", valid_613820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613822: Call_StartLabelDetection_613810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ## 
  let valid = call_613822.validator(path, query, header, formData, body)
  let scheme = call_613822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613822.url(scheme.get, call_613822.host, call_613822.base,
                         call_613822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613822, url, valid)

proc call*(call_613823: Call_StartLabelDetection_613810; body: JsonNode): Recallable =
  ## startLabelDetection
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ##   body: JObject (required)
  var body_613824 = newJObject()
  if body != nil:
    body_613824 = body
  result = call_613823.call(nil, nil, nil, nil, body_613824)

var startLabelDetection* = Call_StartLabelDetection_613810(
    name: "startLabelDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartLabelDetection",
    validator: validate_StartLabelDetection_613811, base: "/",
    url: url_StartLabelDetection_613812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPersonTracking_613825 = ref object of OpenApiRestCall_612659
proc url_StartPersonTracking_613827(protocol: Scheme; host: string; base: string;
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

proc validate_StartPersonTracking_613826(path: JsonNode; query: JsonNode;
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
  var valid_613828 = header.getOrDefault("X-Amz-Target")
  valid_613828 = validateParameter(valid_613828, JString, required = true, default = newJString(
      "RekognitionService.StartPersonTracking"))
  if valid_613828 != nil:
    section.add "X-Amz-Target", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Signature")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Signature", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Content-Sha256", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Date")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Date", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Credential")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Credential", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Security-Token")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Security-Token", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Algorithm")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Algorithm", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-SignedHeaders", valid_613835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613837: Call_StartPersonTracking_613825; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ## 
  let valid = call_613837.validator(path, query, header, formData, body)
  let scheme = call_613837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613837.url(scheme.get, call_613837.host, call_613837.base,
                         call_613837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613837, url, valid)

proc call*(call_613838: Call_StartPersonTracking_613825; body: JsonNode): Recallable =
  ## startPersonTracking
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ##   body: JObject (required)
  var body_613839 = newJObject()
  if body != nil:
    body_613839 = body
  result = call_613838.call(nil, nil, nil, nil, body_613839)

var startPersonTracking* = Call_StartPersonTracking_613825(
    name: "startPersonTracking", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartPersonTracking",
    validator: validate_StartPersonTracking_613826, base: "/",
    url: url_StartPersonTracking_613827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartProjectVersion_613840 = ref object of OpenApiRestCall_612659
proc url_StartProjectVersion_613842(protocol: Scheme; host: string; base: string;
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

proc validate_StartProjectVersion_613841(path: JsonNode; query: JsonNode;
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
  var valid_613843 = header.getOrDefault("X-Amz-Target")
  valid_613843 = validateParameter(valid_613843, JString, required = true, default = newJString(
      "RekognitionService.StartProjectVersion"))
  if valid_613843 != nil:
    section.add "X-Amz-Target", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Signature")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Signature", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Content-Sha256", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Date")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Date", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Credential")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Credential", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Security-Token")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Security-Token", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Algorithm")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Algorithm", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-SignedHeaders", valid_613850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613852: Call_StartProjectVersion_613840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ## 
  let valid = call_613852.validator(path, query, header, formData, body)
  let scheme = call_613852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613852.url(scheme.get, call_613852.host, call_613852.base,
                         call_613852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613852, url, valid)

proc call*(call_613853: Call_StartProjectVersion_613840; body: JsonNode): Recallable =
  ## startProjectVersion
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_613854 = newJObject()
  if body != nil:
    body_613854 = body
  result = call_613853.call(nil, nil, nil, nil, body_613854)

var startProjectVersion* = Call_StartProjectVersion_613840(
    name: "startProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartProjectVersion",
    validator: validate_StartProjectVersion_613841, base: "/",
    url: url_StartProjectVersion_613842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartStreamProcessor_613855 = ref object of OpenApiRestCall_612659
proc url_StartStreamProcessor_613857(protocol: Scheme; host: string; base: string;
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

proc validate_StartStreamProcessor_613856(path: JsonNode; query: JsonNode;
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
  var valid_613858 = header.getOrDefault("X-Amz-Target")
  valid_613858 = validateParameter(valid_613858, JString, required = true, default = newJString(
      "RekognitionService.StartStreamProcessor"))
  if valid_613858 != nil:
    section.add "X-Amz-Target", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Signature")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Signature", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Content-Sha256", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Date")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Date", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Credential")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Credential", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Security-Token")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Security-Token", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Algorithm")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Algorithm", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-SignedHeaders", valid_613865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613867: Call_StartStreamProcessor_613855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ## 
  let valid = call_613867.validator(path, query, header, formData, body)
  let scheme = call_613867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613867.url(scheme.get, call_613867.host, call_613867.base,
                         call_613867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613867, url, valid)

proc call*(call_613868: Call_StartStreamProcessor_613855; body: JsonNode): Recallable =
  ## startStreamProcessor
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ##   body: JObject (required)
  var body_613869 = newJObject()
  if body != nil:
    body_613869 = body
  result = call_613868.call(nil, nil, nil, nil, body_613869)

var startStreamProcessor* = Call_StartStreamProcessor_613855(
    name: "startStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartStreamProcessor",
    validator: validate_StartStreamProcessor_613856, base: "/",
    url: url_StartStreamProcessor_613857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProjectVersion_613870 = ref object of OpenApiRestCall_612659
proc url_StopProjectVersion_613872(protocol: Scheme; host: string; base: string;
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

proc validate_StopProjectVersion_613871(path: JsonNode; query: JsonNode;
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
  var valid_613873 = header.getOrDefault("X-Amz-Target")
  valid_613873 = validateParameter(valid_613873, JString, required = true, default = newJString(
      "RekognitionService.StopProjectVersion"))
  if valid_613873 != nil:
    section.add "X-Amz-Target", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Signature")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Signature", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Content-Sha256", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Date")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Date", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Credential")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Credential", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Security-Token")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Security-Token", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Algorithm")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Algorithm", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-SignedHeaders", valid_613880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613882: Call_StopProjectVersion_613870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ## 
  let valid = call_613882.validator(path, query, header, formData, body)
  let scheme = call_613882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613882.url(scheme.get, call_613882.host, call_613882.base,
                         call_613882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613882, url, valid)

proc call*(call_613883: Call_StopProjectVersion_613870; body: JsonNode): Recallable =
  ## stopProjectVersion
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ##   body: JObject (required)
  var body_613884 = newJObject()
  if body != nil:
    body_613884 = body
  result = call_613883.call(nil, nil, nil, nil, body_613884)

var stopProjectVersion* = Call_StopProjectVersion_613870(
    name: "stopProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopProjectVersion",
    validator: validate_StopProjectVersion_613871, base: "/",
    url: url_StopProjectVersion_613872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopStreamProcessor_613885 = ref object of OpenApiRestCall_612659
proc url_StopStreamProcessor_613887(protocol: Scheme; host: string; base: string;
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

proc validate_StopStreamProcessor_613886(path: JsonNode; query: JsonNode;
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
  var valid_613888 = header.getOrDefault("X-Amz-Target")
  valid_613888 = validateParameter(valid_613888, JString, required = true, default = newJString(
      "RekognitionService.StopStreamProcessor"))
  if valid_613888 != nil:
    section.add "X-Amz-Target", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Signature")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Signature", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Content-Sha256", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Date")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Date", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Credential")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Credential", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Security-Token")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Security-Token", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Algorithm")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Algorithm", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-SignedHeaders", valid_613895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613897: Call_StopStreamProcessor_613885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ## 
  let valid = call_613897.validator(path, query, header, formData, body)
  let scheme = call_613897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613897.url(scheme.get, call_613897.host, call_613897.base,
                         call_613897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613897, url, valid)

proc call*(call_613898: Call_StopStreamProcessor_613885; body: JsonNode): Recallable =
  ## stopStreamProcessor
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ##   body: JObject (required)
  var body_613899 = newJObject()
  if body != nil:
    body_613899 = body
  result = call_613898.call(nil, nil, nil, nil, body_613899)

var stopStreamProcessor* = Call_StopStreamProcessor_613885(
    name: "stopStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopStreamProcessor",
    validator: validate_StopStreamProcessor_613886, base: "/",
    url: url_StopStreamProcessor_613887, schemes: {Scheme.Https, Scheme.Http})
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
