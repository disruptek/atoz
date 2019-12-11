
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

  OpenApiRestCall_597390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597390): Option[Scheme] {.used.} =
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
  Call_CompareFaces_597728 = ref object of OpenApiRestCall_597390
proc url_CompareFaces_597730(protocol: Scheme; host: string; base: string;
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

proc validate_CompareFaces_597729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597855 = header.getOrDefault("X-Amz-Target")
  valid_597855 = validateParameter(valid_597855, JString, required = true, default = newJString(
      "RekognitionService.CompareFaces"))
  if valid_597855 != nil:
    section.add "X-Amz-Target", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Signature")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Signature", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Content-Sha256", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Date")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Date", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Credential")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Credential", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Security-Token")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Security-Token", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Algorithm")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Algorithm", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-SignedHeaders", valid_597862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597886: Call_CompareFaces_597728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ## 
  let valid = call_597886.validator(path, query, header, formData, body)
  let scheme = call_597886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597886.url(scheme.get, call_597886.host, call_597886.base,
                         call_597886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597886, url, valid)

proc call*(call_597957: Call_CompareFaces_597728; body: JsonNode): Recallable =
  ## compareFaces
  ## <p>Compares a face in the <i>source</i> input image with each of the 100 largest faces detected in the <i>target</i> input image. </p> <note> <p> If the source image contains multiple faces, the service detects the largest face and compares it with each face detected in the target image. </p> </note> <p>You pass the input and target images either as base64-encoded image bytes or as references to images in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>In response, the operation returns an array of face matches ordered by similarity score in descending order. For each face match, the response provides a bounding box of the face, facial landmarks, pose details (pitch, role, and yaw), quality (brightness and sharpness), and confidence value (indicating the level of confidence that the bounding box contains a face). The response also provides a similarity score, which indicates how closely the faces match. </p> <note> <p>By default, only faces with a similarity score of greater than or equal to 80% are returned in the response. You can change this value by specifying the <code>SimilarityThreshold</code> parameter.</p> </note> <p> <code>CompareFaces</code> also returns an array of faces that don't match the source image. For each face, it returns a bounding box, confidence value, landmarks, pose details, and quality. The response also returns information about the face in the source image, including the bounding box of the face and confidence value.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>If the image doesn't contain Exif metadata, <code>CompareFaces</code> returns orientation information for the source and target images. Use these values to display the images with the correct image orientation.</p> <p>If no faces are detected in the source or target images, <code>CompareFaces</code> returns an <code>InvalidParameterException</code> error. </p> <note> <p> This is a stateless API operation. That is, data returned by this operation doesn't persist.</p> </note> <p>For an example, see Comparing Faces in Images in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:CompareFaces</code> action.</p>
  ##   body: JObject (required)
  var body_597958 = newJObject()
  if body != nil:
    body_597958 = body
  result = call_597957.call(nil, nil, nil, nil, body_597958)

var compareFaces* = Call_CompareFaces_597728(name: "compareFaces",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CompareFaces",
    validator: validate_CompareFaces_597729, base: "/", url: url_CompareFaces_597730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCollection_597997 = ref object of OpenApiRestCall_597390
proc url_CreateCollection_597999(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCollection_597998(path: JsonNode; query: JsonNode;
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
  var valid_598000 = header.getOrDefault("X-Amz-Target")
  valid_598000 = validateParameter(valid_598000, JString, required = true, default = newJString(
      "RekognitionService.CreateCollection"))
  if valid_598000 != nil:
    section.add "X-Amz-Target", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Signature")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Signature", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Content-Sha256", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Date")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Date", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Credential")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Credential", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Security-Token")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Security-Token", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Algorithm")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Algorithm", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-SignedHeaders", valid_598007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598009: Call_CreateCollection_597997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ## 
  let valid = call_598009.validator(path, query, header, formData, body)
  let scheme = call_598009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598009.url(scheme.get, call_598009.host, call_598009.base,
                         call_598009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598009, url, valid)

proc call*(call_598010: Call_CreateCollection_597997; body: JsonNode): Recallable =
  ## createCollection
  ## <p>Creates a collection in an AWS Region. You can add faces to the collection using the <a>IndexFaces</a> operation. </p> <p>For example, you might create collections, one for each of your application users. A user can then index faces using the <code>IndexFaces</code> operation and persist results in a specific collection. Then, a user can search the collection for faces in the user-specific container. </p> <p>When you create a collection, it is associated with the latest version of the face model version.</p> <note> <p>Collection names are case-sensitive.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:CreateCollection</code> action.</p>
  ##   body: JObject (required)
  var body_598011 = newJObject()
  if body != nil:
    body_598011 = body
  result = call_598010.call(nil, nil, nil, nil, body_598011)

var createCollection* = Call_CreateCollection_597997(name: "createCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateCollection",
    validator: validate_CreateCollection_597998, base: "/",
    url: url_CreateCollection_597999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProject_598012 = ref object of OpenApiRestCall_597390
proc url_CreateProject_598014(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProject_598013(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598015 = header.getOrDefault("X-Amz-Target")
  valid_598015 = validateParameter(valid_598015, JString, required = true, default = newJString(
      "RekognitionService.CreateProject"))
  if valid_598015 != nil:
    section.add "X-Amz-Target", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Signature")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Signature", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Content-Sha256", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Date")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Date", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Credential")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Credential", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Security-Token")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Security-Token", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-Algorithm")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-Algorithm", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-SignedHeaders", valid_598022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598024: Call_CreateProject_598012; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ## 
  let valid = call_598024.validator(path, query, header, formData, body)
  let scheme = call_598024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598024.url(scheme.get, call_598024.host, call_598024.base,
                         call_598024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598024, url, valid)

proc call*(call_598025: Call_CreateProject_598012; body: JsonNode): Recallable =
  ## createProject
  ## <p>Creates a new Amazon Rekognition Custom Labels project. A project is a logical grouping of resources (images, Labels, models) and operations (training, evaluation and detection). </p> <p>This operation requires permissions to perform the <code>rekognition:CreateProject</code> action.</p>
  ##   body: JObject (required)
  var body_598026 = newJObject()
  if body != nil:
    body_598026 = body
  result = call_598025.call(nil, nil, nil, nil, body_598026)

var createProject* = Call_CreateProject_598012(name: "createProject",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProject",
    validator: validate_CreateProject_598013, base: "/", url: url_CreateProject_598014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProjectVersion_598027 = ref object of OpenApiRestCall_597390
proc url_CreateProjectVersion_598029(protocol: Scheme; host: string; base: string;
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

proc validate_CreateProjectVersion_598028(path: JsonNode; query: JsonNode;
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
  var valid_598030 = header.getOrDefault("X-Amz-Target")
  valid_598030 = validateParameter(valid_598030, JString, required = true, default = newJString(
      "RekognitionService.CreateProjectVersion"))
  if valid_598030 != nil:
    section.add "X-Amz-Target", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Signature")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Signature", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Content-Sha256", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Date")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Date", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Credential")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Credential", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Security-Token")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Security-Token", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Algorithm")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Algorithm", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-SignedHeaders", valid_598037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598039: Call_CreateProjectVersion_598027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ## 
  let valid = call_598039.validator(path, query, header, formData, body)
  let scheme = call_598039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598039.url(scheme.get, call_598039.host, call_598039.base,
                         call_598039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598039, url, valid)

proc call*(call_598040: Call_CreateProjectVersion_598027; body: JsonNode): Recallable =
  ## createProjectVersion
  ## <p>Creates a new version of a model and begins training. Models are managed as part of an Amazon Rekognition Custom Labels project. You can specify one training dataset and one testing dataset. The response from <code>CreateProjectVersion</code> is an Amazon Resource Name (ARN) for the version of the model. </p> <p>Training takes a while to complete. You can get the current status by calling <a>DescribeProjectVersions</a>.</p> <p>Once training has successfully completed, call <a>DescribeProjectVersions</a> to get the training results and evaluate the model. </p> <p>After evaluating the model, you start the model by calling <a>StartProjectVersion</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:CreateProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_598041 = newJObject()
  if body != nil:
    body_598041 = body
  result = call_598040.call(nil, nil, nil, nil, body_598041)

var createProjectVersion* = Call_CreateProjectVersion_598027(
    name: "createProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateProjectVersion",
    validator: validate_CreateProjectVersion_598028, base: "/",
    url: url_CreateProjectVersion_598029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamProcessor_598042 = ref object of OpenApiRestCall_597390
proc url_CreateStreamProcessor_598044(protocol: Scheme; host: string; base: string;
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

proc validate_CreateStreamProcessor_598043(path: JsonNode; query: JsonNode;
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
  var valid_598045 = header.getOrDefault("X-Amz-Target")
  valid_598045 = validateParameter(valid_598045, JString, required = true, default = newJString(
      "RekognitionService.CreateStreamProcessor"))
  if valid_598045 != nil:
    section.add "X-Amz-Target", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Signature")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Signature", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Content-Sha256", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Date")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Date", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Credential")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Credential", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Security-Token")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Security-Token", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-Algorithm")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-Algorithm", valid_598051
  var valid_598052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-SignedHeaders", valid_598052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598054: Call_CreateStreamProcessor_598042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ## 
  let valid = call_598054.validator(path, query, header, formData, body)
  let scheme = call_598054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598054.url(scheme.get, call_598054.host, call_598054.base,
                         call_598054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598054, url, valid)

proc call*(call_598055: Call_CreateStreamProcessor_598042; body: JsonNode): Recallable =
  ## createStreamProcessor
  ## <p>Creates an Amazon Rekognition stream processor that you can use to detect and recognize faces in a streaming video.</p> <p>Amazon Rekognition Video is a consumer of live video from Amazon Kinesis Video Streams. Amazon Rekognition Video sends analysis results to Amazon Kinesis Data Streams.</p> <p>You provide as input a Kinesis video stream (<code>Input</code>) and a Kinesis data stream (<code>Output</code>) stream. You also specify the face recognition criteria in <code>Settings</code>. For example, the collection containing faces that you want to recognize. Use <code>Name</code> to assign an identifier for the stream processor. You use <code>Name</code> to manage the stream processor. For example, you can start processing the source video by calling <a>StartStreamProcessor</a> with the <code>Name</code> field. </p> <p>After you have finished analyzing a streaming video, use <a>StopStreamProcessor</a> to stop processing. You can delete the stream processor by calling <a>DeleteStreamProcessor</a>.</p>
  ##   body: JObject (required)
  var body_598056 = newJObject()
  if body != nil:
    body_598056 = body
  result = call_598055.call(nil, nil, nil, nil, body_598056)

var createStreamProcessor* = Call_CreateStreamProcessor_598042(
    name: "createStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.CreateStreamProcessor",
    validator: validate_CreateStreamProcessor_598043, base: "/",
    url: url_CreateStreamProcessor_598044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCollection_598057 = ref object of OpenApiRestCall_597390
proc url_DeleteCollection_598059(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCollection_598058(path: JsonNode; query: JsonNode;
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
  var valid_598060 = header.getOrDefault("X-Amz-Target")
  valid_598060 = validateParameter(valid_598060, JString, required = true, default = newJString(
      "RekognitionService.DeleteCollection"))
  if valid_598060 != nil:
    section.add "X-Amz-Target", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Signature")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Signature", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Content-Sha256", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Date")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Date", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Credential")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Credential", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Security-Token")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Security-Token", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-Algorithm")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-Algorithm", valid_598066
  var valid_598067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-SignedHeaders", valid_598067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598069: Call_DeleteCollection_598057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ## 
  let valid = call_598069.validator(path, query, header, formData, body)
  let scheme = call_598069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598069.url(scheme.get, call_598069.host, call_598069.base,
                         call_598069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598069, url, valid)

proc call*(call_598070: Call_DeleteCollection_598057; body: JsonNode): Recallable =
  ## deleteCollection
  ## <p>Deletes the specified collection. Note that this operation removes all faces in the collection. For an example, see <a>delete-collection-procedure</a>.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteCollection</code> action.</p>
  ##   body: JObject (required)
  var body_598071 = newJObject()
  if body != nil:
    body_598071 = body
  result = call_598070.call(nil, nil, nil, nil, body_598071)

var deleteCollection* = Call_DeleteCollection_598057(name: "deleteCollection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteCollection",
    validator: validate_DeleteCollection_598058, base: "/",
    url: url_DeleteCollection_598059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFaces_598072 = ref object of OpenApiRestCall_597390
proc url_DeleteFaces_598074(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFaces_598073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598075 = header.getOrDefault("X-Amz-Target")
  valid_598075 = validateParameter(valid_598075, JString, required = true, default = newJString(
      "RekognitionService.DeleteFaces"))
  if valid_598075 != nil:
    section.add "X-Amz-Target", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Signature")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Signature", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Content-Sha256", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Date")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Date", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Credential")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Credential", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Security-Token")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Security-Token", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-Algorithm")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-Algorithm", valid_598081
  var valid_598082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598082 = validateParameter(valid_598082, JString, required = false,
                                 default = nil)
  if valid_598082 != nil:
    section.add "X-Amz-SignedHeaders", valid_598082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598084: Call_DeleteFaces_598072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ## 
  let valid = call_598084.validator(path, query, header, formData, body)
  let scheme = call_598084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598084.url(scheme.get, call_598084.host, call_598084.base,
                         call_598084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598084, url, valid)

proc call*(call_598085: Call_DeleteFaces_598072; body: JsonNode): Recallable =
  ## deleteFaces
  ## <p>Deletes faces from a collection. You specify a collection ID and an array of face IDs to remove from the collection.</p> <p>This operation requires permissions to perform the <code>rekognition:DeleteFaces</code> action.</p>
  ##   body: JObject (required)
  var body_598086 = newJObject()
  if body != nil:
    body_598086 = body
  result = call_598085.call(nil, nil, nil, nil, body_598086)

var deleteFaces* = Call_DeleteFaces_598072(name: "deleteFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DeleteFaces",
                                        validator: validate_DeleteFaces_598073,
                                        base: "/", url: url_DeleteFaces_598074,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamProcessor_598087 = ref object of OpenApiRestCall_597390
proc url_DeleteStreamProcessor_598089(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteStreamProcessor_598088(path: JsonNode; query: JsonNode;
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
  var valid_598090 = header.getOrDefault("X-Amz-Target")
  valid_598090 = validateParameter(valid_598090, JString, required = true, default = newJString(
      "RekognitionService.DeleteStreamProcessor"))
  if valid_598090 != nil:
    section.add "X-Amz-Target", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Signature")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Signature", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Content-Sha256", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Date")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Date", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Credential")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Credential", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Security-Token")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Security-Token", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-Algorithm")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-Algorithm", valid_598096
  var valid_598097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598097 = validateParameter(valid_598097, JString, required = false,
                                 default = nil)
  if valid_598097 != nil:
    section.add "X-Amz-SignedHeaders", valid_598097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598099: Call_DeleteStreamProcessor_598087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ## 
  let valid = call_598099.validator(path, query, header, formData, body)
  let scheme = call_598099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598099.url(scheme.get, call_598099.host, call_598099.base,
                         call_598099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598099, url, valid)

proc call*(call_598100: Call_DeleteStreamProcessor_598087; body: JsonNode): Recallable =
  ## deleteStreamProcessor
  ## Deletes the stream processor identified by <code>Name</code>. You assign the value for <code>Name</code> when you create the stream processor with <a>CreateStreamProcessor</a>. You might not be able to use the same name for a stream processor for a few seconds after calling <code>DeleteStreamProcessor</code>.
  ##   body: JObject (required)
  var body_598101 = newJObject()
  if body != nil:
    body_598101 = body
  result = call_598100.call(nil, nil, nil, nil, body_598101)

var deleteStreamProcessor* = Call_DeleteStreamProcessor_598087(
    name: "deleteStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DeleteStreamProcessor",
    validator: validate_DeleteStreamProcessor_598088, base: "/",
    url: url_DeleteStreamProcessor_598089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCollection_598102 = ref object of OpenApiRestCall_597390
proc url_DescribeCollection_598104(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCollection_598103(path: JsonNode; query: JsonNode;
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
  var valid_598105 = header.getOrDefault("X-Amz-Target")
  valid_598105 = validateParameter(valid_598105, JString, required = true, default = newJString(
      "RekognitionService.DescribeCollection"))
  if valid_598105 != nil:
    section.add "X-Amz-Target", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Signature")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Signature", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Content-Sha256", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Date")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Date", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Credential")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Credential", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Security-Token")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Security-Token", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-Algorithm")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-Algorithm", valid_598111
  var valid_598112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598112 = validateParameter(valid_598112, JString, required = false,
                                 default = nil)
  if valid_598112 != nil:
    section.add "X-Amz-SignedHeaders", valid_598112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598114: Call_DescribeCollection_598102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598114.validator(path, query, header, formData, body)
  let scheme = call_598114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598114.url(scheme.get, call_598114.host, call_598114.base,
                         call_598114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598114, url, valid)

proc call*(call_598115: Call_DescribeCollection_598102; body: JsonNode): Recallable =
  ## describeCollection
  ## <p>Describes the specified collection. You can use <code>DescribeCollection</code> to get information, such as the number of faces indexed into a collection and the version of the model used by the collection for face detection.</p> <p>For more information, see Describing a Collection in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_598116 = newJObject()
  if body != nil:
    body_598116 = body
  result = call_598115.call(nil, nil, nil, nil, body_598116)

var describeCollection* = Call_DescribeCollection_598102(
    name: "describeCollection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeCollection",
    validator: validate_DescribeCollection_598103, base: "/",
    url: url_DescribeCollection_598104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjectVersions_598117 = ref object of OpenApiRestCall_597390
proc url_DescribeProjectVersions_598119(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProjectVersions_598118(path: JsonNode; query: JsonNode;
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
  var valid_598120 = query.getOrDefault("MaxResults")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "MaxResults", valid_598120
  var valid_598121 = query.getOrDefault("NextToken")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "NextToken", valid_598121
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
  var valid_598122 = header.getOrDefault("X-Amz-Target")
  valid_598122 = validateParameter(valid_598122, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjectVersions"))
  if valid_598122 != nil:
    section.add "X-Amz-Target", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Signature")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Signature", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Content-Sha256", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Date")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Date", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-Credential")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-Credential", valid_598126
  var valid_598127 = header.getOrDefault("X-Amz-Security-Token")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Security-Token", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Algorithm")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Algorithm", valid_598128
  var valid_598129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "X-Amz-SignedHeaders", valid_598129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598131: Call_DescribeProjectVersions_598117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ## 
  let valid = call_598131.validator(path, query, header, formData, body)
  let scheme = call_598131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598131.url(scheme.get, call_598131.host, call_598131.base,
                         call_598131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598131, url, valid)

proc call*(call_598132: Call_DescribeProjectVersions_598117; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjectVersions
  ## <p>Lists and describes the models in an Amazon Rekognition Custom Labels project. You can specify up to 10 model versions in <code>ProjectVersionArns</code>. If you don't specify a value, descriptions for all models are returned.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjectVersions</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598133 = newJObject()
  var body_598134 = newJObject()
  add(query_598133, "MaxResults", newJString(MaxResults))
  add(query_598133, "NextToken", newJString(NextToken))
  if body != nil:
    body_598134 = body
  result = call_598132.call(nil, query_598133, nil, nil, body_598134)

var describeProjectVersions* = Call_DescribeProjectVersions_598117(
    name: "describeProjectVersions", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjectVersions",
    validator: validate_DescribeProjectVersions_598118, base: "/",
    url: url_DescribeProjectVersions_598119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProjects_598136 = ref object of OpenApiRestCall_597390
proc url_DescribeProjects_598138(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProjects_598137(path: JsonNode; query: JsonNode;
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
  var valid_598139 = query.getOrDefault("MaxResults")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "MaxResults", valid_598139
  var valid_598140 = query.getOrDefault("NextToken")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "NextToken", valid_598140
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
  var valid_598141 = header.getOrDefault("X-Amz-Target")
  valid_598141 = validateParameter(valid_598141, JString, required = true, default = newJString(
      "RekognitionService.DescribeProjects"))
  if valid_598141 != nil:
    section.add "X-Amz-Target", valid_598141
  var valid_598142 = header.getOrDefault("X-Amz-Signature")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Signature", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Content-Sha256", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Date")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Date", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Credential")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Credential", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Security-Token")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Security-Token", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Algorithm")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Algorithm", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-SignedHeaders", valid_598148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598150: Call_DescribeProjects_598136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ## 
  let valid = call_598150.validator(path, query, header, formData, body)
  let scheme = call_598150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598150.url(scheme.get, call_598150.host, call_598150.base,
                         call_598150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598150, url, valid)

proc call*(call_598151: Call_DescribeProjects_598136; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeProjects
  ## <p>Lists and gets information about your Amazon Rekognition Custom Labels projects.</p> <p>This operation requires permissions to perform the <code>rekognition:DescribeProjects</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598152 = newJObject()
  var body_598153 = newJObject()
  add(query_598152, "MaxResults", newJString(MaxResults))
  add(query_598152, "NextToken", newJString(NextToken))
  if body != nil:
    body_598153 = body
  result = call_598151.call(nil, query_598152, nil, nil, body_598153)

var describeProjects* = Call_DescribeProjects_598136(name: "describeProjects",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeProjects",
    validator: validate_DescribeProjects_598137, base: "/",
    url: url_DescribeProjects_598138, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStreamProcessor_598154 = ref object of OpenApiRestCall_597390
proc url_DescribeStreamProcessor_598156(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeStreamProcessor_598155(path: JsonNode; query: JsonNode;
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
  var valid_598157 = header.getOrDefault("X-Amz-Target")
  valid_598157 = validateParameter(valid_598157, JString, required = true, default = newJString(
      "RekognitionService.DescribeStreamProcessor"))
  if valid_598157 != nil:
    section.add "X-Amz-Target", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-Signature")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Signature", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Content-Sha256", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Date")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Date", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Credential")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Credential", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Security-Token")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Security-Token", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-Algorithm")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Algorithm", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-SignedHeaders", valid_598164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598166: Call_DescribeStreamProcessor_598154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ## 
  let valid = call_598166.validator(path, query, header, formData, body)
  let scheme = call_598166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598166.url(scheme.get, call_598166.host, call_598166.base,
                         call_598166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598166, url, valid)

proc call*(call_598167: Call_DescribeStreamProcessor_598154; body: JsonNode): Recallable =
  ## describeStreamProcessor
  ## Provides information about a stream processor created by <a>CreateStreamProcessor</a>. You can get information about the input and output streams, the input parameters for the face recognition being performed, and the current status of the stream processor.
  ##   body: JObject (required)
  var body_598168 = newJObject()
  if body != nil:
    body_598168 = body
  result = call_598167.call(nil, nil, nil, nil, body_598168)

var describeStreamProcessor* = Call_DescribeStreamProcessor_598154(
    name: "describeStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DescribeStreamProcessor",
    validator: validate_DescribeStreamProcessor_598155, base: "/",
    url: url_DescribeStreamProcessor_598156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectCustomLabels_598169 = ref object of OpenApiRestCall_597390
proc url_DetectCustomLabels_598171(protocol: Scheme; host: string; base: string;
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

proc validate_DetectCustomLabels_598170(path: JsonNode; query: JsonNode;
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
  var valid_598172 = header.getOrDefault("X-Amz-Target")
  valid_598172 = validateParameter(valid_598172, JString, required = true, default = newJString(
      "RekognitionService.DetectCustomLabels"))
  if valid_598172 != nil:
    section.add "X-Amz-Target", valid_598172
  var valid_598173 = header.getOrDefault("X-Amz-Signature")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-Signature", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Content-Sha256", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Date")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Date", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Credential")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Credential", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Security-Token")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Security-Token", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Algorithm")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Algorithm", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-SignedHeaders", valid_598179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598181: Call_DetectCustomLabels_598169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ## 
  let valid = call_598181.validator(path, query, header, formData, body)
  let scheme = call_598181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598181.url(scheme.get, call_598181.host, call_598181.base,
                         call_598181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598181, url, valid)

proc call*(call_598182: Call_DetectCustomLabels_598169; body: JsonNode): Recallable =
  ## detectCustomLabels
  ## <p>Detects custom labels in a supplied image by using an Amazon Rekognition Custom Labels model. </p> <p>You specify which version of a model version to use by using the <code>ProjectVersionArn</code> input parameter. </p> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object that the model version detects on an image, the API returns a (<code>CustomLabel</code>) object in an array (<code>CustomLabels</code>). Each <code>CustomLabel</code> object provides the label name (<code>Name</code>), the level of confidence that the image contains the object (<code>Confidence</code>), and object location information, if it exists, for the label on the image (<code>Geometry</code>). </p> <p>During training model calculates a threshold value that determines if a prediction for a label is true. By default, <code>DetectCustomLabels</code> doesn't return labels whose confidence value is below the model's calculated threshold value. To filter labels that are returned, specify a value for <code>MinConfidence</code> that is higher than the model's calculated threshold. You can get the model's calculated threshold from the model's training results shown in the Amazon Rekognition Custom Labels console. To get all labels, regardless of confidence, specify a <code>MinConfidence</code> value of 0. </p> <p>You can also add the <code>MaxResults</code> parameter to limit the number of labels returned. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectCustomLabels</code> action. </p>
  ##   body: JObject (required)
  var body_598183 = newJObject()
  if body != nil:
    body_598183 = body
  result = call_598182.call(nil, nil, nil, nil, body_598183)

var detectCustomLabels* = Call_DetectCustomLabels_598169(
    name: "detectCustomLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectCustomLabels",
    validator: validate_DetectCustomLabels_598170, base: "/",
    url: url_DetectCustomLabels_598171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectFaces_598184 = ref object of OpenApiRestCall_597390
proc url_DetectFaces_598186(protocol: Scheme; host: string; base: string;
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

proc validate_DetectFaces_598185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598187 = header.getOrDefault("X-Amz-Target")
  valid_598187 = validateParameter(valid_598187, JString, required = true, default = newJString(
      "RekognitionService.DetectFaces"))
  if valid_598187 != nil:
    section.add "X-Amz-Target", valid_598187
  var valid_598188 = header.getOrDefault("X-Amz-Signature")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "X-Amz-Signature", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Content-Sha256", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Date")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Date", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Credential")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Credential", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Security-Token")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Security-Token", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Algorithm")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Algorithm", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-SignedHeaders", valid_598194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598196: Call_DetectFaces_598184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ## 
  let valid = call_598196.validator(path, query, header, formData, body)
  let scheme = call_598196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598196.url(scheme.get, call_598196.host, call_598196.base,
                         call_598196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598196, url, valid)

proc call*(call_598197: Call_DetectFaces_598184; body: JsonNode): Recallable =
  ## detectFaces
  ## <p>Detects faces within an image that is provided as input.</p> <p> <code>DetectFaces</code> detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), presence of beard, sunglasses, and so on. </p> <p>The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. </p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <note> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:DetectFaces</code> action. </p>
  ##   body: JObject (required)
  var body_598198 = newJObject()
  if body != nil:
    body_598198 = body
  result = call_598197.call(nil, nil, nil, nil, body_598198)

var detectFaces* = Call_DetectFaces_598184(name: "detectFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectFaces",
                                        validator: validate_DetectFaces_598185,
                                        base: "/", url: url_DetectFaces_598186,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectLabels_598199 = ref object of OpenApiRestCall_597390
proc url_DetectLabels_598201(protocol: Scheme; host: string; base: string;
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

proc validate_DetectLabels_598200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598202 = header.getOrDefault("X-Amz-Target")
  valid_598202 = validateParameter(valid_598202, JString, required = true, default = newJString(
      "RekognitionService.DetectLabels"))
  if valid_598202 != nil:
    section.add "X-Amz-Target", valid_598202
  var valid_598203 = header.getOrDefault("X-Amz-Signature")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "X-Amz-Signature", valid_598203
  var valid_598204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598204 = validateParameter(valid_598204, JString, required = false,
                                 default = nil)
  if valid_598204 != nil:
    section.add "X-Amz-Content-Sha256", valid_598204
  var valid_598205 = header.getOrDefault("X-Amz-Date")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Date", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Credential")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Credential", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Security-Token")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Security-Token", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-Algorithm")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-Algorithm", valid_598208
  var valid_598209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598209 = validateParameter(valid_598209, JString, required = false,
                                 default = nil)
  if valid_598209 != nil:
    section.add "X-Amz-SignedHeaders", valid_598209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598211: Call_DetectLabels_598199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ## 
  let valid = call_598211.validator(path, query, header, formData, body)
  let scheme = call_598211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598211.url(scheme.get, call_598211.host, call_598211.base,
                         call_598211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598211, url, valid)

proc call*(call_598212: Call_DetectLabels_598199; body: JsonNode): Recallable =
  ## detectLabels
  ## <p>Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. </p> <p>For an example, see Analyzing Images Stored in an Amazon S3 Bucket in the Amazon Rekognition Developer Guide.</p> <note> <p> <code>DetectLabels</code> does not support the detection of activities. However, activity detection is supported for label detection in videos. For more information, see StartLabelDetection in the Amazon Rekognition Developer Guide.</p> </note> <p>You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> For each object, scene, and concept the API returns one or more labels. Each label provides the object name, and the level of confidence that the image contains the object. For example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object. </p> <p> <code>{Name: lighthouse, Confidence: 98.4629}</code> </p> <p> <code>{Name: rock,Confidence: 79.2097}</code> </p> <p> <code> {Name: sea,Confidence: 75.061}</code> </p> <p>In the preceding example, the operation returns one label for each of the three objects. The operation can also return multiple labels for the same object in the image. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. </p> <p> <code>{Name: flower,Confidence: 99.0562}</code> </p> <p> <code>{Name: plant,Confidence: 99.0562}</code> </p> <p> <code>{Name: tulip,Confidence: 99.0562}</code> </p> <p>In this example, the detection algorithm more precisely identifies the flower as a tulip.</p> <p>In response, the API returns an array of labels. In addition, the response also includes the orientation correction. Optionally, you can specify <code>MinConfidence</code> to control the confidence threshold for the labels returned. The default is 55%. You can also add the <code>MaxLabels</code> parameter to limit the number of labels returned. </p> <note> <p>If the object detected is a person, the operation doesn't provide the same facial details that the <a>DetectFaces</a> operation provides.</p> </note> <p> <code>DetectLabels</code> returns bounding boxes for instances of common object labels in an array of <a>Instance</a> objects. An <code>Instance</code> object contains a <a>BoundingBox</a> object, for the location of the label on the image. It also includes the confidence by which the bounding box was detected.</p> <p> <code>DetectLabels</code> also returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label <i>car</i>. The label <i>car</i> has two parent labels: <i>Vehicle</i> (its parent) and <i>Transportation</i> (its grandparent). The response returns the entire list of ancestors for a label. Each ancestor is a unique label in the response. In the previous example, <i>Car</i>, <i>Vehicle</i>, and <i>Transportation</i> are returned as unique labels in the response. </p> <p>This is a stateless API operation. That is, the operation does not persist any data.</p> <p>This operation requires permissions to perform the <code>rekognition:DetectLabels</code> action. </p>
  ##   body: JObject (required)
  var body_598213 = newJObject()
  if body != nil:
    body_598213 = body
  result = call_598212.call(nil, nil, nil, nil, body_598213)

var detectLabels* = Call_DetectLabels_598199(name: "detectLabels",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectLabels",
    validator: validate_DetectLabels_598200, base: "/", url: url_DetectLabels_598201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectModerationLabels_598214 = ref object of OpenApiRestCall_597390
proc url_DetectModerationLabels_598216(protocol: Scheme; host: string; base: string;
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

proc validate_DetectModerationLabels_598215(path: JsonNode; query: JsonNode;
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
  var valid_598217 = header.getOrDefault("X-Amz-Target")
  valid_598217 = validateParameter(valid_598217, JString, required = true, default = newJString(
      "RekognitionService.DetectModerationLabels"))
  if valid_598217 != nil:
    section.add "X-Amz-Target", valid_598217
  var valid_598218 = header.getOrDefault("X-Amz-Signature")
  valid_598218 = validateParameter(valid_598218, JString, required = false,
                                 default = nil)
  if valid_598218 != nil:
    section.add "X-Amz-Signature", valid_598218
  var valid_598219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598219 = validateParameter(valid_598219, JString, required = false,
                                 default = nil)
  if valid_598219 != nil:
    section.add "X-Amz-Content-Sha256", valid_598219
  var valid_598220 = header.getOrDefault("X-Amz-Date")
  valid_598220 = validateParameter(valid_598220, JString, required = false,
                                 default = nil)
  if valid_598220 != nil:
    section.add "X-Amz-Date", valid_598220
  var valid_598221 = header.getOrDefault("X-Amz-Credential")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Credential", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-Security-Token")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-Security-Token", valid_598222
  var valid_598223 = header.getOrDefault("X-Amz-Algorithm")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "X-Amz-Algorithm", valid_598223
  var valid_598224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598224 = validateParameter(valid_598224, JString, required = false,
                                 default = nil)
  if valid_598224 != nil:
    section.add "X-Amz-SignedHeaders", valid_598224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598226: Call_DetectModerationLabels_598214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ## 
  let valid = call_598226.validator(path, query, header, formData, body)
  let scheme = call_598226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598226.url(scheme.get, call_598226.host, call_598226.base,
                         call_598226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598226, url, valid)

proc call*(call_598227: Call_DetectModerationLabels_598214; body: JsonNode): Recallable =
  ## detectModerationLabels
  ## <p>Detects unsafe content in a specified JPEG or PNG format image. Use <code>DetectModerationLabels</code> to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content.</p> <p>To filter images, use the labels returned by <code>DetectModerationLabels</code> to determine which types of content are appropriate.</p> <p>For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p>
  ##   body: JObject (required)
  var body_598228 = newJObject()
  if body != nil:
    body_598228 = body
  result = call_598227.call(nil, nil, nil, nil, body_598228)

var detectModerationLabels* = Call_DetectModerationLabels_598214(
    name: "detectModerationLabels", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.DetectModerationLabels",
    validator: validate_DetectModerationLabels_598215, base: "/",
    url: url_DetectModerationLabels_598216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DetectText_598229 = ref object of OpenApiRestCall_597390
proc url_DetectText_598231(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DetectText_598230(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598232 = header.getOrDefault("X-Amz-Target")
  valid_598232 = validateParameter(valid_598232, JString, required = true, default = newJString(
      "RekognitionService.DetectText"))
  if valid_598232 != nil:
    section.add "X-Amz-Target", valid_598232
  var valid_598233 = header.getOrDefault("X-Amz-Signature")
  valid_598233 = validateParameter(valid_598233, JString, required = false,
                                 default = nil)
  if valid_598233 != nil:
    section.add "X-Amz-Signature", valid_598233
  var valid_598234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598234 = validateParameter(valid_598234, JString, required = false,
                                 default = nil)
  if valid_598234 != nil:
    section.add "X-Amz-Content-Sha256", valid_598234
  var valid_598235 = header.getOrDefault("X-Amz-Date")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-Date", valid_598235
  var valid_598236 = header.getOrDefault("X-Amz-Credential")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Credential", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-Security-Token")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Security-Token", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Algorithm")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Algorithm", valid_598238
  var valid_598239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-SignedHeaders", valid_598239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598241: Call_DetectText_598229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598241.validator(path, query, header, formData, body)
  let scheme = call_598241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598241.url(scheme.get, call_598241.host, call_598241.base,
                         call_598241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598241, url, valid)

proc call*(call_598242: Call_DetectText_598229; body: JsonNode): Recallable =
  ## detectText
  ## <p>Detects text in the input image and converts it into machine-readable text.</p> <p>Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. </p> <p>The <code>DetectText</code> operation returns text in an array of <a>TextDetection</a> elements, <code>TextDetections</code>. Each <code>TextDetection</code> element provides information about a single word or line of text that was detected in the image. </p> <p>A word is one or more ISO basic latin script characters that are not separated by spaces. <code>DetectText</code> can detect up to 50 words in an image.</p> <p>A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the <code>DetectText</code> operation returns multiple lines.</p> <p>To determine whether a <code>TextDetection</code> element is a line of text or a word, use the <code>TextDetection</code> object <code>Type</code> field. </p> <p>To be detected, text must be within +/- 90 degrees orientation of the horizontal axis.</p> <p>For more information, see DetectText in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_598243 = newJObject()
  if body != nil:
    body_598243 = body
  result = call_598242.call(nil, nil, nil, nil, body_598243)

var detectText* = Call_DetectText_598229(name: "detectText",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.DetectText",
                                      validator: validate_DetectText_598230,
                                      base: "/", url: url_DetectText_598231,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityInfo_598244 = ref object of OpenApiRestCall_597390
proc url_GetCelebrityInfo_598246(protocol: Scheme; host: string; base: string;
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

proc validate_GetCelebrityInfo_598245(path: JsonNode; query: JsonNode;
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
  var valid_598247 = header.getOrDefault("X-Amz-Target")
  valid_598247 = validateParameter(valid_598247, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityInfo"))
  if valid_598247 != nil:
    section.add "X-Amz-Target", valid_598247
  var valid_598248 = header.getOrDefault("X-Amz-Signature")
  valid_598248 = validateParameter(valid_598248, JString, required = false,
                                 default = nil)
  if valid_598248 != nil:
    section.add "X-Amz-Signature", valid_598248
  var valid_598249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598249 = validateParameter(valid_598249, JString, required = false,
                                 default = nil)
  if valid_598249 != nil:
    section.add "X-Amz-Content-Sha256", valid_598249
  var valid_598250 = header.getOrDefault("X-Amz-Date")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-Date", valid_598250
  var valid_598251 = header.getOrDefault("X-Amz-Credential")
  valid_598251 = validateParameter(valid_598251, JString, required = false,
                                 default = nil)
  if valid_598251 != nil:
    section.add "X-Amz-Credential", valid_598251
  var valid_598252 = header.getOrDefault("X-Amz-Security-Token")
  valid_598252 = validateParameter(valid_598252, JString, required = false,
                                 default = nil)
  if valid_598252 != nil:
    section.add "X-Amz-Security-Token", valid_598252
  var valid_598253 = header.getOrDefault("X-Amz-Algorithm")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Algorithm", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-SignedHeaders", valid_598254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598256: Call_GetCelebrityInfo_598244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ## 
  let valid = call_598256.validator(path, query, header, formData, body)
  let scheme = call_598256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598256.url(scheme.get, call_598256.host, call_598256.base,
                         call_598256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598256, url, valid)

proc call*(call_598257: Call_GetCelebrityInfo_598244; body: JsonNode): Recallable =
  ## getCelebrityInfo
  ## <p>Gets the name and additional information about a celebrity based on his or her Amazon Rekognition ID. The additional information is returned as an array of URLs. If there is no additional information about the celebrity, this list is empty.</p> <p>For more information, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:GetCelebrityInfo</code> action. </p>
  ##   body: JObject (required)
  var body_598258 = newJObject()
  if body != nil:
    body_598258 = body
  result = call_598257.call(nil, nil, nil, nil, body_598258)

var getCelebrityInfo* = Call_GetCelebrityInfo_598244(name: "getCelebrityInfo",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityInfo",
    validator: validate_GetCelebrityInfo_598245, base: "/",
    url: url_GetCelebrityInfo_598246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCelebrityRecognition_598259 = ref object of OpenApiRestCall_597390
proc url_GetCelebrityRecognition_598261(protocol: Scheme; host: string; base: string;
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

proc validate_GetCelebrityRecognition_598260(path: JsonNode; query: JsonNode;
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
  var valid_598262 = query.getOrDefault("MaxResults")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "MaxResults", valid_598262
  var valid_598263 = query.getOrDefault("NextToken")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "NextToken", valid_598263
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
  var valid_598264 = header.getOrDefault("X-Amz-Target")
  valid_598264 = validateParameter(valid_598264, JString, required = true, default = newJString(
      "RekognitionService.GetCelebrityRecognition"))
  if valid_598264 != nil:
    section.add "X-Amz-Target", valid_598264
  var valid_598265 = header.getOrDefault("X-Amz-Signature")
  valid_598265 = validateParameter(valid_598265, JString, required = false,
                                 default = nil)
  if valid_598265 != nil:
    section.add "X-Amz-Signature", valid_598265
  var valid_598266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598266 = validateParameter(valid_598266, JString, required = false,
                                 default = nil)
  if valid_598266 != nil:
    section.add "X-Amz-Content-Sha256", valid_598266
  var valid_598267 = header.getOrDefault("X-Amz-Date")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Date", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Credential")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Credential", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Security-Token")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Security-Token", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Algorithm")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Algorithm", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-SignedHeaders", valid_598271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598273: Call_GetCelebrityRecognition_598259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ## 
  let valid = call_598273.validator(path, query, header, formData, body)
  let scheme = call_598273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598273.url(scheme.get, call_598273.host, call_598273.base,
                         call_598273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598273, url, valid)

proc call*(call_598274: Call_GetCelebrityRecognition_598259; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCelebrityRecognition
  ## <p>Gets the celebrity recognition results for a Amazon Rekognition Video analysis started by <a>StartCelebrityRecognition</a>.</p> <p>Celebrity recognition in a video is an asynchronous operation. Analysis is started by a call to <a>StartCelebrityRecognition</a> which returns a job identifier (<code>JobId</code>). When the celebrity recognition operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartCelebrityRecognition</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetCelebrityDetection</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityDetection</code>. </p> <p>For more information, see Working With Stored Videos in the Amazon Rekognition Developer Guide.</p> <p> <code>GetCelebrityRecognition</code> returns detected celebrities and the time(s) they are detected in an array (<code>Celebrities</code>) of <a>CelebrityRecognition</a> objects. Each <code>CelebrityRecognition</code> contains information about the celebrity in a <a>CelebrityDetail</a> object and the time, <code>Timestamp</code>, the celebrity was detected. </p> <note> <p> <code>GetCelebrityRecognition</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Celebrities</code> array is sorted by time (milliseconds from the start of the video). You can also sort the array by celebrity by specifying the value <code>ID</code> in the <code>SortBy</code> input parameter.</p> <p>The <code>CelebrityDetail</code> object includes the celebrity identifer and additional information urls. If you don't store the additional information urls, you can get them later by calling <a>GetCelebrityInfo</a> with the celebrity identifer.</p> <p>No information is returned for faces not recognized as celebrities.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetCelebrityDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetCelebrityRecognition</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598275 = newJObject()
  var body_598276 = newJObject()
  add(query_598275, "MaxResults", newJString(MaxResults))
  add(query_598275, "NextToken", newJString(NextToken))
  if body != nil:
    body_598276 = body
  result = call_598274.call(nil, query_598275, nil, nil, body_598276)

var getCelebrityRecognition* = Call_GetCelebrityRecognition_598259(
    name: "getCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetCelebrityRecognition",
    validator: validate_GetCelebrityRecognition_598260, base: "/",
    url: url_GetCelebrityRecognition_598261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetContentModeration_598277 = ref object of OpenApiRestCall_597390
proc url_GetContentModeration_598279(protocol: Scheme; host: string; base: string;
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

proc validate_GetContentModeration_598278(path: JsonNode; query: JsonNode;
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
  var valid_598280 = query.getOrDefault("MaxResults")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "MaxResults", valid_598280
  var valid_598281 = query.getOrDefault("NextToken")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "NextToken", valid_598281
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
  var valid_598282 = header.getOrDefault("X-Amz-Target")
  valid_598282 = validateParameter(valid_598282, JString, required = true, default = newJString(
      "RekognitionService.GetContentModeration"))
  if valid_598282 != nil:
    section.add "X-Amz-Target", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Signature")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Signature", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Content-Sha256", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-Date")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Date", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-Credential")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-Credential", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Security-Token")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Security-Token", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-Algorithm")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Algorithm", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-SignedHeaders", valid_598289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598291: Call_GetContentModeration_598277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598291.validator(path, query, header, formData, body)
  let scheme = call_598291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598291.url(scheme.get, call_598291.host, call_598291.base,
                         call_598291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598291, url, valid)

proc call*(call_598292: Call_GetContentModeration_598277; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getContentModeration
  ## <p>Gets the unsafe content analysis results for a Amazon Rekognition Video analysis started by <a>StartContentModeration</a>.</p> <p>Unsafe content analysis of a video is an asynchronous operation. You start analysis by calling <a>StartContentModeration</a> which returns a job identifier (<code>JobId</code>). When analysis finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartContentModeration</code>. To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetContentModeration</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Working with Stored Videos in the Amazon Rekognition Devlopers Guide.</p> <p> <code>GetContentModeration</code> returns detected unsafe content labels, and the time they are detected, in an array, <code>ModerationLabels</code>, of <a>ContentModerationDetection</a> objects. </p> <p>By default, the moderated labels are returned sorted by time, in milliseconds from the start of the video. You can also sort them by moderated label by specifying <code>NAME</code> for the <code>SortBy</code> input parameter. </p> <p>Since video analysis can return a large number of results, use the <code>MaxResults</code> parameter to limit the number of labels returned in a single call to <code>GetContentModeration</code>. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetContentModeration</code> and populate the <code>NextToken</code> request parameter with the value of <code>NextToken</code> returned from the previous call to <code>GetContentModeration</code>.</p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598293 = newJObject()
  var body_598294 = newJObject()
  add(query_598293, "MaxResults", newJString(MaxResults))
  add(query_598293, "NextToken", newJString(NextToken))
  if body != nil:
    body_598294 = body
  result = call_598292.call(nil, query_598293, nil, nil, body_598294)

var getContentModeration* = Call_GetContentModeration_598277(
    name: "getContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetContentModeration",
    validator: validate_GetContentModeration_598278, base: "/",
    url: url_GetContentModeration_598279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceDetection_598295 = ref object of OpenApiRestCall_597390
proc url_GetFaceDetection_598297(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceDetection_598296(path: JsonNode; query: JsonNode;
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
  var valid_598298 = query.getOrDefault("MaxResults")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "MaxResults", valid_598298
  var valid_598299 = query.getOrDefault("NextToken")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "NextToken", valid_598299
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
  var valid_598300 = header.getOrDefault("X-Amz-Target")
  valid_598300 = validateParameter(valid_598300, JString, required = true, default = newJString(
      "RekognitionService.GetFaceDetection"))
  if valid_598300 != nil:
    section.add "X-Amz-Target", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Signature")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Signature", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Content-Sha256", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Date")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Date", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-Credential")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Credential", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-Security-Token")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-Security-Token", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-Algorithm")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-Algorithm", valid_598306
  var valid_598307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598307 = validateParameter(valid_598307, JString, required = false,
                                 default = nil)
  if valid_598307 != nil:
    section.add "X-Amz-SignedHeaders", valid_598307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598309: Call_GetFaceDetection_598295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ## 
  let valid = call_598309.validator(path, query, header, formData, body)
  let scheme = call_598309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598309.url(scheme.get, call_598309.host, call_598309.base,
                         call_598309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598309, url, valid)

proc call*(call_598310: Call_GetFaceDetection_598295; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceDetection
  ## <p>Gets face detection results for a Amazon Rekognition Video analysis started by <a>StartFaceDetection</a>.</p> <p>Face detection with Amazon Rekognition Video is an asynchronous operation. You start face detection by calling <a>StartFaceDetection</a> which returns a job identifier (<code>JobId</code>). When the face detection operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceDetection</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p> <code>GetFaceDetection</code> returns an array of detected faces (<code>Faces</code>) sorted by the time the faces were detected. </p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetFaceDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetFaceDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598311 = newJObject()
  var body_598312 = newJObject()
  add(query_598311, "MaxResults", newJString(MaxResults))
  add(query_598311, "NextToken", newJString(NextToken))
  if body != nil:
    body_598312 = body
  result = call_598310.call(nil, query_598311, nil, nil, body_598312)

var getFaceDetection* = Call_GetFaceDetection_598295(name: "getFaceDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceDetection",
    validator: validate_GetFaceDetection_598296, base: "/",
    url: url_GetFaceDetection_598297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFaceSearch_598313 = ref object of OpenApiRestCall_597390
proc url_GetFaceSearch_598315(protocol: Scheme; host: string; base: string;
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

proc validate_GetFaceSearch_598314(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598316 = query.getOrDefault("MaxResults")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "MaxResults", valid_598316
  var valid_598317 = query.getOrDefault("NextToken")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "NextToken", valid_598317
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
  var valid_598318 = header.getOrDefault("X-Amz-Target")
  valid_598318 = validateParameter(valid_598318, JString, required = true, default = newJString(
      "RekognitionService.GetFaceSearch"))
  if valid_598318 != nil:
    section.add "X-Amz-Target", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Signature")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Signature", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-Content-Sha256", valid_598320
  var valid_598321 = header.getOrDefault("X-Amz-Date")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "X-Amz-Date", valid_598321
  var valid_598322 = header.getOrDefault("X-Amz-Credential")
  valid_598322 = validateParameter(valid_598322, JString, required = false,
                                 default = nil)
  if valid_598322 != nil:
    section.add "X-Amz-Credential", valid_598322
  var valid_598323 = header.getOrDefault("X-Amz-Security-Token")
  valid_598323 = validateParameter(valid_598323, JString, required = false,
                                 default = nil)
  if valid_598323 != nil:
    section.add "X-Amz-Security-Token", valid_598323
  var valid_598324 = header.getOrDefault("X-Amz-Algorithm")
  valid_598324 = validateParameter(valid_598324, JString, required = false,
                                 default = nil)
  if valid_598324 != nil:
    section.add "X-Amz-Algorithm", valid_598324
  var valid_598325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598325 = validateParameter(valid_598325, JString, required = false,
                                 default = nil)
  if valid_598325 != nil:
    section.add "X-Amz-SignedHeaders", valid_598325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598327: Call_GetFaceSearch_598313; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ## 
  let valid = call_598327.validator(path, query, header, formData, body)
  let scheme = call_598327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598327.url(scheme.get, call_598327.host, call_598327.base,
                         call_598327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598327, url, valid)

proc call*(call_598328: Call_GetFaceSearch_598313; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFaceSearch
  ## <p>Gets the face search results for Amazon Rekognition Video face search started by <a>StartFaceSearch</a>. The search returns faces in a collection that match the faces of persons detected in a video. It also includes the time(s) that faces are matched in the video.</p> <p>Face search in a video is an asynchronous operation. You start face search by calling to <a>StartFaceSearch</a> which returns a job identifier (<code>JobId</code>). When the search operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartFaceSearch</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <code>GetFaceSearch</code> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>.</p> <p>For more information, see Searching Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>The search results are retured in an array, <code>Persons</code>, of <a>PersonMatch</a> objects. Each<code>PersonMatch</code> element contains details about the matching faces in the input collection, person information (facial attributes, bounding boxes, and person identifer) for the matched person, and the time the person was matched in the video.</p> <note> <p> <code>GetFaceSearch</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. For more information, see FaceDetail in the Amazon Rekognition Developer Guide. </p> </note> <p>By default, the <code>Persons</code> array is sorted by the time, in milliseconds from the start of the video, persons are matched. You can also sort by persons by specifying <code>INDEX</code> for the <code>SORTBY</code> input parameter.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598329 = newJObject()
  var body_598330 = newJObject()
  add(query_598329, "MaxResults", newJString(MaxResults))
  add(query_598329, "NextToken", newJString(NextToken))
  if body != nil:
    body_598330 = body
  result = call_598328.call(nil, query_598329, nil, nil, body_598330)

var getFaceSearch* = Call_GetFaceSearch_598313(name: "getFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetFaceSearch",
    validator: validate_GetFaceSearch_598314, base: "/", url: url_GetFaceSearch_598315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLabelDetection_598331 = ref object of OpenApiRestCall_597390
proc url_GetLabelDetection_598333(protocol: Scheme; host: string; base: string;
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

proc validate_GetLabelDetection_598332(path: JsonNode; query: JsonNode;
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
  var valid_598334 = query.getOrDefault("MaxResults")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "MaxResults", valid_598334
  var valid_598335 = query.getOrDefault("NextToken")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "NextToken", valid_598335
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
  var valid_598336 = header.getOrDefault("X-Amz-Target")
  valid_598336 = validateParameter(valid_598336, JString, required = true, default = newJString(
      "RekognitionService.GetLabelDetection"))
  if valid_598336 != nil:
    section.add "X-Amz-Target", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-Signature")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-Signature", valid_598337
  var valid_598338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598338 = validateParameter(valid_598338, JString, required = false,
                                 default = nil)
  if valid_598338 != nil:
    section.add "X-Amz-Content-Sha256", valid_598338
  var valid_598339 = header.getOrDefault("X-Amz-Date")
  valid_598339 = validateParameter(valid_598339, JString, required = false,
                                 default = nil)
  if valid_598339 != nil:
    section.add "X-Amz-Date", valid_598339
  var valid_598340 = header.getOrDefault("X-Amz-Credential")
  valid_598340 = validateParameter(valid_598340, JString, required = false,
                                 default = nil)
  if valid_598340 != nil:
    section.add "X-Amz-Credential", valid_598340
  var valid_598341 = header.getOrDefault("X-Amz-Security-Token")
  valid_598341 = validateParameter(valid_598341, JString, required = false,
                                 default = nil)
  if valid_598341 != nil:
    section.add "X-Amz-Security-Token", valid_598341
  var valid_598342 = header.getOrDefault("X-Amz-Algorithm")
  valid_598342 = validateParameter(valid_598342, JString, required = false,
                                 default = nil)
  if valid_598342 != nil:
    section.add "X-Amz-Algorithm", valid_598342
  var valid_598343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598343 = validateParameter(valid_598343, JString, required = false,
                                 default = nil)
  if valid_598343 != nil:
    section.add "X-Amz-SignedHeaders", valid_598343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598345: Call_GetLabelDetection_598331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ## 
  let valid = call_598345.validator(path, query, header, formData, body)
  let scheme = call_598345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598345.url(scheme.get, call_598345.host, call_598345.base,
                         call_598345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598345, url, valid)

proc call*(call_598346: Call_GetLabelDetection_598331; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getLabelDetection
  ## <p>Gets the label detection results of a Amazon Rekognition Video analysis started by <a>StartLabelDetection</a>. </p> <p>The label detection operation is started by a call to <a>StartLabelDetection</a> which returns a job identifier (<code>JobId</code>). When the label detection operation finishes, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartlabelDetection</code>. To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p> <code>GetLabelDetection</code> returns an array of detected labels (<code>Labels</code>) sorted by the time the labels were detected. You can also sort by the label name by specifying <code>NAME</code> for the <code>SortBy</code> input parameter.</p> <p>The labels returned include the label name, the percentage confidence in the accuracy of the detected label, and the time the label was detected in the video.</p> <p>The returned labels also include bounding box information for common objects, a hierarchical taxonomy of detected labels, and the version of the label model used for detection.</p> <p>Use MaxResults parameter to limit the number of labels returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetlabelDetection</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetLabelDetection</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598347 = newJObject()
  var body_598348 = newJObject()
  add(query_598347, "MaxResults", newJString(MaxResults))
  add(query_598347, "NextToken", newJString(NextToken))
  if body != nil:
    body_598348 = body
  result = call_598346.call(nil, query_598347, nil, nil, body_598348)

var getLabelDetection* = Call_GetLabelDetection_598331(name: "getLabelDetection",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetLabelDetection",
    validator: validate_GetLabelDetection_598332, base: "/",
    url: url_GetLabelDetection_598333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPersonTracking_598349 = ref object of OpenApiRestCall_597390
proc url_GetPersonTracking_598351(protocol: Scheme; host: string; base: string;
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

proc validate_GetPersonTracking_598350(path: JsonNode; query: JsonNode;
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
  var valid_598352 = query.getOrDefault("MaxResults")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "MaxResults", valid_598352
  var valid_598353 = query.getOrDefault("NextToken")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "NextToken", valid_598353
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
  var valid_598354 = header.getOrDefault("X-Amz-Target")
  valid_598354 = validateParameter(valid_598354, JString, required = true, default = newJString(
      "RekognitionService.GetPersonTracking"))
  if valid_598354 != nil:
    section.add "X-Amz-Target", valid_598354
  var valid_598355 = header.getOrDefault("X-Amz-Signature")
  valid_598355 = validateParameter(valid_598355, JString, required = false,
                                 default = nil)
  if valid_598355 != nil:
    section.add "X-Amz-Signature", valid_598355
  var valid_598356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598356 = validateParameter(valid_598356, JString, required = false,
                                 default = nil)
  if valid_598356 != nil:
    section.add "X-Amz-Content-Sha256", valid_598356
  var valid_598357 = header.getOrDefault("X-Amz-Date")
  valid_598357 = validateParameter(valid_598357, JString, required = false,
                                 default = nil)
  if valid_598357 != nil:
    section.add "X-Amz-Date", valid_598357
  var valid_598358 = header.getOrDefault("X-Amz-Credential")
  valid_598358 = validateParameter(valid_598358, JString, required = false,
                                 default = nil)
  if valid_598358 != nil:
    section.add "X-Amz-Credential", valid_598358
  var valid_598359 = header.getOrDefault("X-Amz-Security-Token")
  valid_598359 = validateParameter(valid_598359, JString, required = false,
                                 default = nil)
  if valid_598359 != nil:
    section.add "X-Amz-Security-Token", valid_598359
  var valid_598360 = header.getOrDefault("X-Amz-Algorithm")
  valid_598360 = validateParameter(valid_598360, JString, required = false,
                                 default = nil)
  if valid_598360 != nil:
    section.add "X-Amz-Algorithm", valid_598360
  var valid_598361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598361 = validateParameter(valid_598361, JString, required = false,
                                 default = nil)
  if valid_598361 != nil:
    section.add "X-Amz-SignedHeaders", valid_598361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598363: Call_GetPersonTracking_598349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ## 
  let valid = call_598363.validator(path, query, header, formData, body)
  let scheme = call_598363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598363.url(scheme.get, call_598363.host, call_598363.base,
                         call_598363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598363, url, valid)

proc call*(call_598364: Call_GetPersonTracking_598349; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPersonTracking
  ## <p>Gets the path tracking results of a Amazon Rekognition Video analysis started by <a>StartPersonTracking</a>.</p> <p>The person path tracking operation is started by a call to <code>StartPersonTracking</code> which returns a job identifier (<code>JobId</code>). When the operation finishes, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic registered in the initial call to <code>StartPersonTracking</code>.</p> <p>To get the results of the person path tracking operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p> <p> <code>GetPersonTracking</code> returns an array, <code>Persons</code>, of tracked persons and the time(s) their paths were tracked in the video. </p> <note> <p> <code>GetPersonTracking</code> only returns the default facial attributes (<code>BoundingBox</code>, <code>Confidence</code>, <code>Landmarks</code>, <code>Pose</code>, and <code>Quality</code>). The other facial attributes listed in the <code>Face</code> object of the following response syntax are not returned. </p> <p>For more information, see FaceDetail in the Amazon Rekognition Developer Guide.</p> </note> <p>By default, the array is sorted by the time(s) a person's path is tracked in the video. You can sort by tracked persons by specifying <code>INDEX</code> for the <code>SortBy</code> input parameter.</p> <p>Use the <code>MaxResults</code> parameter to limit the number of items returned. If there are more results than specified in <code>MaxResults</code>, the value of <code>NextToken</code> in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call <code>GetPersonTracking</code> and populate the <code>NextToken</code> request parameter with the token value returned from the previous call to <code>GetPersonTracking</code>.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598365 = newJObject()
  var body_598366 = newJObject()
  add(query_598365, "MaxResults", newJString(MaxResults))
  add(query_598365, "NextToken", newJString(NextToken))
  if body != nil:
    body_598366 = body
  result = call_598364.call(nil, query_598365, nil, nil, body_598366)

var getPersonTracking* = Call_GetPersonTracking_598349(name: "getPersonTracking",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.GetPersonTracking",
    validator: validate_GetPersonTracking_598350, base: "/",
    url: url_GetPersonTracking_598351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_IndexFaces_598367 = ref object of OpenApiRestCall_597390
proc url_IndexFaces_598369(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_IndexFaces_598368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598370 = header.getOrDefault("X-Amz-Target")
  valid_598370 = validateParameter(valid_598370, JString, required = true, default = newJString(
      "RekognitionService.IndexFaces"))
  if valid_598370 != nil:
    section.add "X-Amz-Target", valid_598370
  var valid_598371 = header.getOrDefault("X-Amz-Signature")
  valid_598371 = validateParameter(valid_598371, JString, required = false,
                                 default = nil)
  if valid_598371 != nil:
    section.add "X-Amz-Signature", valid_598371
  var valid_598372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598372 = validateParameter(valid_598372, JString, required = false,
                                 default = nil)
  if valid_598372 != nil:
    section.add "X-Amz-Content-Sha256", valid_598372
  var valid_598373 = header.getOrDefault("X-Amz-Date")
  valid_598373 = validateParameter(valid_598373, JString, required = false,
                                 default = nil)
  if valid_598373 != nil:
    section.add "X-Amz-Date", valid_598373
  var valid_598374 = header.getOrDefault("X-Amz-Credential")
  valid_598374 = validateParameter(valid_598374, JString, required = false,
                                 default = nil)
  if valid_598374 != nil:
    section.add "X-Amz-Credential", valid_598374
  var valid_598375 = header.getOrDefault("X-Amz-Security-Token")
  valid_598375 = validateParameter(valid_598375, JString, required = false,
                                 default = nil)
  if valid_598375 != nil:
    section.add "X-Amz-Security-Token", valid_598375
  var valid_598376 = header.getOrDefault("X-Amz-Algorithm")
  valid_598376 = validateParameter(valid_598376, JString, required = false,
                                 default = nil)
  if valid_598376 != nil:
    section.add "X-Amz-Algorithm", valid_598376
  var valid_598377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "X-Amz-SignedHeaders", valid_598377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598379: Call_IndexFaces_598367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ## 
  let valid = call_598379.validator(path, query, header, formData, body)
  let scheme = call_598379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598379.url(scheme.get, call_598379.host, call_598379.base,
                         call_598379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598379, url, valid)

proc call*(call_598380: Call_IndexFaces_598367; body: JsonNode): Recallable =
  ## indexFaces
  ## <p>Detects faces in the input image and adds them to the specified collection. </p> <p>Amazon Rekognition doesn't save the actual faces that are detected. Instead, the underlying detection algorithm first detects the faces in the input image. For each face, the algorithm extracts facial features into a feature vector, and stores it in the backend database. Amazon Rekognition uses feature vectors when it performs face match and search operations using the <a>SearchFaces</a> and <a>SearchFacesByImage</a> operations.</p> <p>For more information, see Adding Faces to a Collection in the Amazon Rekognition Developer Guide.</p> <p>To get the number of faces in a collection, call <a>DescribeCollection</a>. </p> <p>If you're using version 1.0 of the face detection model, <code>IndexFaces</code> indexes the 15 largest faces in the input image. Later versions of the face detection model index the 100 largest faces in the input image. </p> <p>If you're using version 4 or later of the face model, image orientation information is not returned in the <code>OrientationCorrection</code> field. </p> <p>To determine which version of the model you're using, call <a>DescribeCollection</a> and supply the collection ID. You can also get the model version from the value of <code>FaceModelVersion</code> in the response from <code>IndexFaces</code> </p> <p>For more information, see Model Versioning in the Amazon Rekognition Developer Guide.</p> <p>If you provide the optional <code>ExternalImageID</code> for the input image you provided, Amazon Rekognition associates this ID with all faces that it detects. When you call the <a>ListFaces</a> operation, the response returns the external ID. You can use this external image ID to create a client-side index to associate the faces with each image. You can then use the index to find all faces in an image.</p> <p>You can specify the maximum number of faces to index with the <code>MaxFaces</code> input parameter. This is useful when you want to index the largest faces in an image and don't want to index smaller faces, such as those belonging to people standing in the background.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. By default, <code>IndexFaces</code> chooses the quality bar that's used to filter faces. You can also explicitly choose the quality bar. Use <code>QualityFilter</code>, to set the quality bar by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. </p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>Information about faces detected in an image, but not indexed, is returned in an array of <a>UnindexedFace</a> objects, <code>UnindexedFaces</code>. Faces aren't indexed for reasons such as:</p> <ul> <li> <p>The number of faces detected exceeds the value of the <code>MaxFaces</code> request parameter.</p> </li> <li> <p>The face is too small compared to the image dimensions.</p> </li> <li> <p>The face is too blurry.</p> </li> <li> <p>The image is too dark.</p> </li> <li> <p>The face has an extreme pose.</p> </li> <li> <p>The face doesn’t have enough detail to be suitable for face search.</p> </li> </ul> <p>In response, the <code>IndexFaces</code> operation returns an array of metadata for all detected faces, <code>FaceRecords</code>. This includes: </p> <ul> <li> <p>The bounding box, <code>BoundingBox</code>, of the detected face. </p> </li> <li> <p>A confidence value, <code>Confidence</code>, which indicates the confidence that the bounding box contains a face.</p> </li> <li> <p>A face ID, <code>FaceId</code>, assigned by the service for each face that's detected and stored.</p> </li> <li> <p>An image ID, <code>ImageId</code>, assigned by the service for the input image.</p> </li> </ul> <p>If you request all facial attributes (by using the <code>detectionAttributes</code> parameter), Amazon Rekognition returns detailed facial attributes, such as facial landmarks (for example, location of eye and mouth) and other facial attributes. If you provide the same image, specify the same collection, and use the same external ID in the <code>IndexFaces</code> operation, Amazon Rekognition doesn't save duplicate face metadata.</p> <p/> <p>The input image is passed either as base64-encoded image bytes, or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes isn't supported. The image must be formatted as a PNG or JPEG file. </p> <p>This operation requires permissions to perform the <code>rekognition:IndexFaces</code> action.</p>
  ##   body: JObject (required)
  var body_598381 = newJObject()
  if body != nil:
    body_598381 = body
  result = call_598380.call(nil, nil, nil, nil, body_598381)

var indexFaces* = Call_IndexFaces_598367(name: "indexFaces",
                                      meth: HttpMethod.HttpPost,
                                      host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.IndexFaces",
                                      validator: validate_IndexFaces_598368,
                                      base: "/", url: url_IndexFaces_598369,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCollections_598382 = ref object of OpenApiRestCall_597390
proc url_ListCollections_598384(protocol: Scheme; host: string; base: string;
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

proc validate_ListCollections_598383(path: JsonNode; query: JsonNode;
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
  var valid_598385 = query.getOrDefault("MaxResults")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "MaxResults", valid_598385
  var valid_598386 = query.getOrDefault("NextToken")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "NextToken", valid_598386
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
  var valid_598387 = header.getOrDefault("X-Amz-Target")
  valid_598387 = validateParameter(valid_598387, JString, required = true, default = newJString(
      "RekognitionService.ListCollections"))
  if valid_598387 != nil:
    section.add "X-Amz-Target", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-Signature")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-Signature", valid_598388
  var valid_598389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598389 = validateParameter(valid_598389, JString, required = false,
                                 default = nil)
  if valid_598389 != nil:
    section.add "X-Amz-Content-Sha256", valid_598389
  var valid_598390 = header.getOrDefault("X-Amz-Date")
  valid_598390 = validateParameter(valid_598390, JString, required = false,
                                 default = nil)
  if valid_598390 != nil:
    section.add "X-Amz-Date", valid_598390
  var valid_598391 = header.getOrDefault("X-Amz-Credential")
  valid_598391 = validateParameter(valid_598391, JString, required = false,
                                 default = nil)
  if valid_598391 != nil:
    section.add "X-Amz-Credential", valid_598391
  var valid_598392 = header.getOrDefault("X-Amz-Security-Token")
  valid_598392 = validateParameter(valid_598392, JString, required = false,
                                 default = nil)
  if valid_598392 != nil:
    section.add "X-Amz-Security-Token", valid_598392
  var valid_598393 = header.getOrDefault("X-Amz-Algorithm")
  valid_598393 = validateParameter(valid_598393, JString, required = false,
                                 default = nil)
  if valid_598393 != nil:
    section.add "X-Amz-Algorithm", valid_598393
  var valid_598394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598394 = validateParameter(valid_598394, JString, required = false,
                                 default = nil)
  if valid_598394 != nil:
    section.add "X-Amz-SignedHeaders", valid_598394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598396: Call_ListCollections_598382; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ## 
  let valid = call_598396.validator(path, query, header, formData, body)
  let scheme = call_598396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598396.url(scheme.get, call_598396.host, call_598396.base,
                         call_598396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598396, url, valid)

proc call*(call_598397: Call_ListCollections_598382; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCollections
  ## <p>Returns list of collection IDs in your account. If the result is truncated, the response also provides a <code>NextToken</code> that you can use in the subsequent request to fetch the next set of collection IDs.</p> <p>For an example, see Listing Collections in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListCollections</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598398 = newJObject()
  var body_598399 = newJObject()
  add(query_598398, "MaxResults", newJString(MaxResults))
  add(query_598398, "NextToken", newJString(NextToken))
  if body != nil:
    body_598399 = body
  result = call_598397.call(nil, query_598398, nil, nil, body_598399)

var listCollections* = Call_ListCollections_598382(name: "listCollections",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListCollections",
    validator: validate_ListCollections_598383, base: "/", url: url_ListCollections_598384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFaces_598400 = ref object of OpenApiRestCall_597390
proc url_ListFaces_598402(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListFaces_598401(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598403 = query.getOrDefault("MaxResults")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "MaxResults", valid_598403
  var valid_598404 = query.getOrDefault("NextToken")
  valid_598404 = validateParameter(valid_598404, JString, required = false,
                                 default = nil)
  if valid_598404 != nil:
    section.add "NextToken", valid_598404
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
  var valid_598405 = header.getOrDefault("X-Amz-Target")
  valid_598405 = validateParameter(valid_598405, JString, required = true, default = newJString(
      "RekognitionService.ListFaces"))
  if valid_598405 != nil:
    section.add "X-Amz-Target", valid_598405
  var valid_598406 = header.getOrDefault("X-Amz-Signature")
  valid_598406 = validateParameter(valid_598406, JString, required = false,
                                 default = nil)
  if valid_598406 != nil:
    section.add "X-Amz-Signature", valid_598406
  var valid_598407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598407 = validateParameter(valid_598407, JString, required = false,
                                 default = nil)
  if valid_598407 != nil:
    section.add "X-Amz-Content-Sha256", valid_598407
  var valid_598408 = header.getOrDefault("X-Amz-Date")
  valid_598408 = validateParameter(valid_598408, JString, required = false,
                                 default = nil)
  if valid_598408 != nil:
    section.add "X-Amz-Date", valid_598408
  var valid_598409 = header.getOrDefault("X-Amz-Credential")
  valid_598409 = validateParameter(valid_598409, JString, required = false,
                                 default = nil)
  if valid_598409 != nil:
    section.add "X-Amz-Credential", valid_598409
  var valid_598410 = header.getOrDefault("X-Amz-Security-Token")
  valid_598410 = validateParameter(valid_598410, JString, required = false,
                                 default = nil)
  if valid_598410 != nil:
    section.add "X-Amz-Security-Token", valid_598410
  var valid_598411 = header.getOrDefault("X-Amz-Algorithm")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-Algorithm", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-SignedHeaders", valid_598412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598414: Call_ListFaces_598400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ## 
  let valid = call_598414.validator(path, query, header, formData, body)
  let scheme = call_598414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598414.url(scheme.get, call_598414.host, call_598414.base,
                         call_598414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598414, url, valid)

proc call*(call_598415: Call_ListFaces_598400; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFaces
  ## <p>Returns metadata for faces in the specified collection. This metadata includes information such as the bounding box coordinates, the confidence (that the bounding box contains a face), and face ID. For an example, see Listing Faces in a Collection in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:ListFaces</code> action.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598416 = newJObject()
  var body_598417 = newJObject()
  add(query_598416, "MaxResults", newJString(MaxResults))
  add(query_598416, "NextToken", newJString(NextToken))
  if body != nil:
    body_598417 = body
  result = call_598415.call(nil, query_598416, nil, nil, body_598417)

var listFaces* = Call_ListFaces_598400(name: "listFaces", meth: HttpMethod.HttpPost,
                                    host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.ListFaces",
                                    validator: validate_ListFaces_598401,
                                    base: "/", url: url_ListFaces_598402,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamProcessors_598418 = ref object of OpenApiRestCall_597390
proc url_ListStreamProcessors_598420(protocol: Scheme; host: string; base: string;
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

proc validate_ListStreamProcessors_598419(path: JsonNode; query: JsonNode;
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
  var valid_598421 = query.getOrDefault("MaxResults")
  valid_598421 = validateParameter(valid_598421, JString, required = false,
                                 default = nil)
  if valid_598421 != nil:
    section.add "MaxResults", valid_598421
  var valid_598422 = query.getOrDefault("NextToken")
  valid_598422 = validateParameter(valid_598422, JString, required = false,
                                 default = nil)
  if valid_598422 != nil:
    section.add "NextToken", valid_598422
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
  var valid_598423 = header.getOrDefault("X-Amz-Target")
  valid_598423 = validateParameter(valid_598423, JString, required = true, default = newJString(
      "RekognitionService.ListStreamProcessors"))
  if valid_598423 != nil:
    section.add "X-Amz-Target", valid_598423
  var valid_598424 = header.getOrDefault("X-Amz-Signature")
  valid_598424 = validateParameter(valid_598424, JString, required = false,
                                 default = nil)
  if valid_598424 != nil:
    section.add "X-Amz-Signature", valid_598424
  var valid_598425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598425 = validateParameter(valid_598425, JString, required = false,
                                 default = nil)
  if valid_598425 != nil:
    section.add "X-Amz-Content-Sha256", valid_598425
  var valid_598426 = header.getOrDefault("X-Amz-Date")
  valid_598426 = validateParameter(valid_598426, JString, required = false,
                                 default = nil)
  if valid_598426 != nil:
    section.add "X-Amz-Date", valid_598426
  var valid_598427 = header.getOrDefault("X-Amz-Credential")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Credential", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Security-Token")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Security-Token", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Algorithm")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Algorithm", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-SignedHeaders", valid_598430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598432: Call_ListStreamProcessors_598418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ## 
  let valid = call_598432.validator(path, query, header, formData, body)
  let scheme = call_598432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598432.url(scheme.get, call_598432.host, call_598432.base,
                         call_598432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598432, url, valid)

proc call*(call_598433: Call_ListStreamProcessors_598418; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listStreamProcessors
  ## Gets a list of stream processors that you have created with <a>CreateStreamProcessor</a>. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_598434 = newJObject()
  var body_598435 = newJObject()
  add(query_598434, "MaxResults", newJString(MaxResults))
  add(query_598434, "NextToken", newJString(NextToken))
  if body != nil:
    body_598435 = body
  result = call_598433.call(nil, query_598434, nil, nil, body_598435)

var listStreamProcessors* = Call_ListStreamProcessors_598418(
    name: "listStreamProcessors", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.ListStreamProcessors",
    validator: validate_ListStreamProcessors_598419, base: "/",
    url: url_ListStreamProcessors_598420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RecognizeCelebrities_598436 = ref object of OpenApiRestCall_597390
proc url_RecognizeCelebrities_598438(protocol: Scheme; host: string; base: string;
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

proc validate_RecognizeCelebrities_598437(path: JsonNode; query: JsonNode;
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
  var valid_598439 = header.getOrDefault("X-Amz-Target")
  valid_598439 = validateParameter(valid_598439, JString, required = true, default = newJString(
      "RekognitionService.RecognizeCelebrities"))
  if valid_598439 != nil:
    section.add "X-Amz-Target", valid_598439
  var valid_598440 = header.getOrDefault("X-Amz-Signature")
  valid_598440 = validateParameter(valid_598440, JString, required = false,
                                 default = nil)
  if valid_598440 != nil:
    section.add "X-Amz-Signature", valid_598440
  var valid_598441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598441 = validateParameter(valid_598441, JString, required = false,
                                 default = nil)
  if valid_598441 != nil:
    section.add "X-Amz-Content-Sha256", valid_598441
  var valid_598442 = header.getOrDefault("X-Amz-Date")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Date", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Credential")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Credential", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Security-Token")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Security-Token", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Algorithm")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Algorithm", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-SignedHeaders", valid_598446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598448: Call_RecognizeCelebrities_598436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ## 
  let valid = call_598448.validator(path, query, header, formData, body)
  let scheme = call_598448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598448.url(scheme.get, call_598448.host, call_598448.base,
                         call_598448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598448, url, valid)

proc call*(call_598449: Call_RecognizeCelebrities_598436; body: JsonNode): Recallable =
  ## recognizeCelebrities
  ## <p>Returns an array of celebrities recognized in the input image. For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide. </p> <p> <code>RecognizeCelebrities</code> returns the 100 largest faces in the image. It lists recognized celebrities in the <code>CelebrityFaces</code> array and unrecognized faces in the <code>UnrecognizedFaces</code> array. <code>RecognizeCelebrities</code> doesn't return celebrities whose faces aren't among the largest 100 faces in the image.</p> <p>For each celebrity recognized, <code>RecognizeCelebrities</code> returns a <code>Celebrity</code> object. The <code>Celebrity</code> object contains the celebrity name, ID, URL links to additional information, match confidence, and a <code>ComparedFace</code> object that you can use to locate the celebrity's face on the image.</p> <p>Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the <code>Celebrity</code> ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by <code>RecognizeCelebrities</code>, you will need the ID to identify the celebrity in a call to the <a>GetCelebrityInfo</a> operation.</p> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p>For an example, see Recognizing Celebrities in an Image in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:RecognizeCelebrities</code> operation.</p>
  ##   body: JObject (required)
  var body_598450 = newJObject()
  if body != nil:
    body_598450 = body
  result = call_598449.call(nil, nil, nil, nil, body_598450)

var recognizeCelebrities* = Call_RecognizeCelebrities_598436(
    name: "recognizeCelebrities", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.RecognizeCelebrities",
    validator: validate_RecognizeCelebrities_598437, base: "/",
    url: url_RecognizeCelebrities_598438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFaces_598451 = ref object of OpenApiRestCall_597390
proc url_SearchFaces_598453(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFaces_598452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598454 = header.getOrDefault("X-Amz-Target")
  valid_598454 = validateParameter(valid_598454, JString, required = true, default = newJString(
      "RekognitionService.SearchFaces"))
  if valid_598454 != nil:
    section.add "X-Amz-Target", valid_598454
  var valid_598455 = header.getOrDefault("X-Amz-Signature")
  valid_598455 = validateParameter(valid_598455, JString, required = false,
                                 default = nil)
  if valid_598455 != nil:
    section.add "X-Amz-Signature", valid_598455
  var valid_598456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598456 = validateParameter(valid_598456, JString, required = false,
                                 default = nil)
  if valid_598456 != nil:
    section.add "X-Amz-Content-Sha256", valid_598456
  var valid_598457 = header.getOrDefault("X-Amz-Date")
  valid_598457 = validateParameter(valid_598457, JString, required = false,
                                 default = nil)
  if valid_598457 != nil:
    section.add "X-Amz-Date", valid_598457
  var valid_598458 = header.getOrDefault("X-Amz-Credential")
  valid_598458 = validateParameter(valid_598458, JString, required = false,
                                 default = nil)
  if valid_598458 != nil:
    section.add "X-Amz-Credential", valid_598458
  var valid_598459 = header.getOrDefault("X-Amz-Security-Token")
  valid_598459 = validateParameter(valid_598459, JString, required = false,
                                 default = nil)
  if valid_598459 != nil:
    section.add "X-Amz-Security-Token", valid_598459
  var valid_598460 = header.getOrDefault("X-Amz-Algorithm")
  valid_598460 = validateParameter(valid_598460, JString, required = false,
                                 default = nil)
  if valid_598460 != nil:
    section.add "X-Amz-Algorithm", valid_598460
  var valid_598461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598461 = validateParameter(valid_598461, JString, required = false,
                                 default = nil)
  if valid_598461 != nil:
    section.add "X-Amz-SignedHeaders", valid_598461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598463: Call_SearchFaces_598451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ## 
  let valid = call_598463.validator(path, query, header, formData, body)
  let scheme = call_598463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598463.url(scheme.get, call_598463.host, call_598463.base,
                         call_598463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598463, url, valid)

proc call*(call_598464: Call_SearchFaces_598451; body: JsonNode): Recallable =
  ## searchFaces
  ## <p>For a given input face ID, searches for matching faces in the collection the face belongs to. You get a face ID when you add a face to the collection using the <a>IndexFaces</a> operation. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>You can also search faces without indexing faces by using the <code>SearchFacesByImage</code> operation.</p> </note> <p> The operation response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match that is found. Along with the metadata, the response also includes a <code>confidence</code> value for each face match, indicating the confidence that the specific face matches the input face. </p> <p>For an example, see Searching for a Face Using Its Face ID in the Amazon Rekognition Developer Guide.</p> <p>This operation requires permissions to perform the <code>rekognition:SearchFaces</code> action.</p>
  ##   body: JObject (required)
  var body_598465 = newJObject()
  if body != nil:
    body_598465 = body
  result = call_598464.call(nil, nil, nil, nil, body_598465)

var searchFaces* = Call_SearchFaces_598451(name: "searchFaces",
                                        meth: HttpMethod.HttpPost,
                                        host: "rekognition.amazonaws.com", route: "/#X-Amz-Target=RekognitionService.SearchFaces",
                                        validator: validate_SearchFaces_598452,
                                        base: "/", url: url_SearchFaces_598453,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchFacesByImage_598466 = ref object of OpenApiRestCall_597390
proc url_SearchFacesByImage_598468(protocol: Scheme; host: string; base: string;
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

proc validate_SearchFacesByImage_598467(path: JsonNode; query: JsonNode;
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
  var valid_598469 = header.getOrDefault("X-Amz-Target")
  valid_598469 = validateParameter(valid_598469, JString, required = true, default = newJString(
      "RekognitionService.SearchFacesByImage"))
  if valid_598469 != nil:
    section.add "X-Amz-Target", valid_598469
  var valid_598470 = header.getOrDefault("X-Amz-Signature")
  valid_598470 = validateParameter(valid_598470, JString, required = false,
                                 default = nil)
  if valid_598470 != nil:
    section.add "X-Amz-Signature", valid_598470
  var valid_598471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598471 = validateParameter(valid_598471, JString, required = false,
                                 default = nil)
  if valid_598471 != nil:
    section.add "X-Amz-Content-Sha256", valid_598471
  var valid_598472 = header.getOrDefault("X-Amz-Date")
  valid_598472 = validateParameter(valid_598472, JString, required = false,
                                 default = nil)
  if valid_598472 != nil:
    section.add "X-Amz-Date", valid_598472
  var valid_598473 = header.getOrDefault("X-Amz-Credential")
  valid_598473 = validateParameter(valid_598473, JString, required = false,
                                 default = nil)
  if valid_598473 != nil:
    section.add "X-Amz-Credential", valid_598473
  var valid_598474 = header.getOrDefault("X-Amz-Security-Token")
  valid_598474 = validateParameter(valid_598474, JString, required = false,
                                 default = nil)
  if valid_598474 != nil:
    section.add "X-Amz-Security-Token", valid_598474
  var valid_598475 = header.getOrDefault("X-Amz-Algorithm")
  valid_598475 = validateParameter(valid_598475, JString, required = false,
                                 default = nil)
  if valid_598475 != nil:
    section.add "X-Amz-Algorithm", valid_598475
  var valid_598476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598476 = validateParameter(valid_598476, JString, required = false,
                                 default = nil)
  if valid_598476 != nil:
    section.add "X-Amz-SignedHeaders", valid_598476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598478: Call_SearchFacesByImage_598466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ## 
  let valid = call_598478.validator(path, query, header, formData, body)
  let scheme = call_598478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598478.url(scheme.get, call_598478.host, call_598478.base,
                         call_598478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598478, url, valid)

proc call*(call_598479: Call_SearchFacesByImage_598466; body: JsonNode): Recallable =
  ## searchFacesByImage
  ## <p>For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. </p> <note> <p>To search for all faces in an input image, you might first call the <a>IndexFaces</a> operation, and then use the face IDs returned in subsequent calls to the <a>SearchFaces</a> operation. </p> <p> You can also call the <code>DetectFaces</code> operation and use the bounding boxes in the response to make face crops, which then you can pass in to the <code>SearchFacesByImage</code> operation. </p> </note> <p>You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. </p> <p> The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a <code>similarity</code> indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. </p> <p>For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide.</p> <p>The <code>QualityFilter</code> input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use <code>QualityFilter</code> to set the quality bar for filtering by specifying <code>LOW</code>, <code>MEDIUM</code>, or <code>HIGH</code>. If you do not want to filter detected faces, specify <code>NONE</code>. The default value is <code>NONE</code>.</p> <note> <p>To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call <a>DescribeCollection</a>. </p> </note> <p>This operation requires permissions to perform the <code>rekognition:SearchFacesByImage</code> action.</p>
  ##   body: JObject (required)
  var body_598480 = newJObject()
  if body != nil:
    body_598480 = body
  result = call_598479.call(nil, nil, nil, nil, body_598480)

var searchFacesByImage* = Call_SearchFacesByImage_598466(
    name: "searchFacesByImage", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.SearchFacesByImage",
    validator: validate_SearchFacesByImage_598467, base: "/",
    url: url_SearchFacesByImage_598468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCelebrityRecognition_598481 = ref object of OpenApiRestCall_597390
proc url_StartCelebrityRecognition_598483(protocol: Scheme; host: string;
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

proc validate_StartCelebrityRecognition_598482(path: JsonNode; query: JsonNode;
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
  var valid_598484 = header.getOrDefault("X-Amz-Target")
  valid_598484 = validateParameter(valid_598484, JString, required = true, default = newJString(
      "RekognitionService.StartCelebrityRecognition"))
  if valid_598484 != nil:
    section.add "X-Amz-Target", valid_598484
  var valid_598485 = header.getOrDefault("X-Amz-Signature")
  valid_598485 = validateParameter(valid_598485, JString, required = false,
                                 default = nil)
  if valid_598485 != nil:
    section.add "X-Amz-Signature", valid_598485
  var valid_598486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598486 = validateParameter(valid_598486, JString, required = false,
                                 default = nil)
  if valid_598486 != nil:
    section.add "X-Amz-Content-Sha256", valid_598486
  var valid_598487 = header.getOrDefault("X-Amz-Date")
  valid_598487 = validateParameter(valid_598487, JString, required = false,
                                 default = nil)
  if valid_598487 != nil:
    section.add "X-Amz-Date", valid_598487
  var valid_598488 = header.getOrDefault("X-Amz-Credential")
  valid_598488 = validateParameter(valid_598488, JString, required = false,
                                 default = nil)
  if valid_598488 != nil:
    section.add "X-Amz-Credential", valid_598488
  var valid_598489 = header.getOrDefault("X-Amz-Security-Token")
  valid_598489 = validateParameter(valid_598489, JString, required = false,
                                 default = nil)
  if valid_598489 != nil:
    section.add "X-Amz-Security-Token", valid_598489
  var valid_598490 = header.getOrDefault("X-Amz-Algorithm")
  valid_598490 = validateParameter(valid_598490, JString, required = false,
                                 default = nil)
  if valid_598490 != nil:
    section.add "X-Amz-Algorithm", valid_598490
  var valid_598491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598491 = validateParameter(valid_598491, JString, required = false,
                                 default = nil)
  if valid_598491 != nil:
    section.add "X-Amz-SignedHeaders", valid_598491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598493: Call_StartCelebrityRecognition_598481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598493.validator(path, query, header, formData, body)
  let scheme = call_598493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598493.url(scheme.get, call_598493.host, call_598493.base,
                         call_598493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598493, url, valid)

proc call*(call_598494: Call_StartCelebrityRecognition_598481; body: JsonNode): Recallable =
  ## startCelebrityRecognition
  ## <p>Starts asynchronous recognition of celebrities in a stored video.</p> <p>Amazon Rekognition Video can detect celebrities in a video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartCelebrityRecognition</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When celebrity recognition analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the celebrity recognition analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetCelebrityRecognition</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartCelebrityRecognition</code>. </p> <p>For more information, see Recognizing Celebrities in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_598495 = newJObject()
  if body != nil:
    body_598495 = body
  result = call_598494.call(nil, nil, nil, nil, body_598495)

var startCelebrityRecognition* = Call_StartCelebrityRecognition_598481(
    name: "startCelebrityRecognition", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartCelebrityRecognition",
    validator: validate_StartCelebrityRecognition_598482, base: "/",
    url: url_StartCelebrityRecognition_598483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContentModeration_598496 = ref object of OpenApiRestCall_597390
proc url_StartContentModeration_598498(protocol: Scheme; host: string; base: string;
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

proc validate_StartContentModeration_598497(path: JsonNode; query: JsonNode;
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
  var valid_598499 = header.getOrDefault("X-Amz-Target")
  valid_598499 = validateParameter(valid_598499, JString, required = true, default = newJString(
      "RekognitionService.StartContentModeration"))
  if valid_598499 != nil:
    section.add "X-Amz-Target", valid_598499
  var valid_598500 = header.getOrDefault("X-Amz-Signature")
  valid_598500 = validateParameter(valid_598500, JString, required = false,
                                 default = nil)
  if valid_598500 != nil:
    section.add "X-Amz-Signature", valid_598500
  var valid_598501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598501 = validateParameter(valid_598501, JString, required = false,
                                 default = nil)
  if valid_598501 != nil:
    section.add "X-Amz-Content-Sha256", valid_598501
  var valid_598502 = header.getOrDefault("X-Amz-Date")
  valid_598502 = validateParameter(valid_598502, JString, required = false,
                                 default = nil)
  if valid_598502 != nil:
    section.add "X-Amz-Date", valid_598502
  var valid_598503 = header.getOrDefault("X-Amz-Credential")
  valid_598503 = validateParameter(valid_598503, JString, required = false,
                                 default = nil)
  if valid_598503 != nil:
    section.add "X-Amz-Credential", valid_598503
  var valid_598504 = header.getOrDefault("X-Amz-Security-Token")
  valid_598504 = validateParameter(valid_598504, JString, required = false,
                                 default = nil)
  if valid_598504 != nil:
    section.add "X-Amz-Security-Token", valid_598504
  var valid_598505 = header.getOrDefault("X-Amz-Algorithm")
  valid_598505 = validateParameter(valid_598505, JString, required = false,
                                 default = nil)
  if valid_598505 != nil:
    section.add "X-Amz-Algorithm", valid_598505
  var valid_598506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598506 = validateParameter(valid_598506, JString, required = false,
                                 default = nil)
  if valid_598506 != nil:
    section.add "X-Amz-SignedHeaders", valid_598506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598508: Call_StartContentModeration_598496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598508.validator(path, query, header, formData, body)
  let scheme = call_598508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598508.url(scheme.get, call_598508.host, call_598508.base,
                         call_598508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598508, url, valid)

proc call*(call_598509: Call_StartContentModeration_598496; body: JsonNode): Recallable =
  ## startContentModeration
  ## <p> Starts asynchronous detection of unsafe content in a stored video.</p> <p>Amazon Rekognition Video can moderate content in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartContentModeration</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the analysis. When unsafe content analysis is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the unsafe content analysis, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetContentModeration</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartContentModeration</code>. </p> <p>For more information, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_598510 = newJObject()
  if body != nil:
    body_598510 = body
  result = call_598509.call(nil, nil, nil, nil, body_598510)

var startContentModeration* = Call_StartContentModeration_598496(
    name: "startContentModeration", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartContentModeration",
    validator: validate_StartContentModeration_598497, base: "/",
    url: url_StartContentModeration_598498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceDetection_598511 = ref object of OpenApiRestCall_597390
proc url_StartFaceDetection_598513(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceDetection_598512(path: JsonNode; query: JsonNode;
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
  var valid_598514 = header.getOrDefault("X-Amz-Target")
  valid_598514 = validateParameter(valid_598514, JString, required = true, default = newJString(
      "RekognitionService.StartFaceDetection"))
  if valid_598514 != nil:
    section.add "X-Amz-Target", valid_598514
  var valid_598515 = header.getOrDefault("X-Amz-Signature")
  valid_598515 = validateParameter(valid_598515, JString, required = false,
                                 default = nil)
  if valid_598515 != nil:
    section.add "X-Amz-Signature", valid_598515
  var valid_598516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598516 = validateParameter(valid_598516, JString, required = false,
                                 default = nil)
  if valid_598516 != nil:
    section.add "X-Amz-Content-Sha256", valid_598516
  var valid_598517 = header.getOrDefault("X-Amz-Date")
  valid_598517 = validateParameter(valid_598517, JString, required = false,
                                 default = nil)
  if valid_598517 != nil:
    section.add "X-Amz-Date", valid_598517
  var valid_598518 = header.getOrDefault("X-Amz-Credential")
  valid_598518 = validateParameter(valid_598518, JString, required = false,
                                 default = nil)
  if valid_598518 != nil:
    section.add "X-Amz-Credential", valid_598518
  var valid_598519 = header.getOrDefault("X-Amz-Security-Token")
  valid_598519 = validateParameter(valid_598519, JString, required = false,
                                 default = nil)
  if valid_598519 != nil:
    section.add "X-Amz-Security-Token", valid_598519
  var valid_598520 = header.getOrDefault("X-Amz-Algorithm")
  valid_598520 = validateParameter(valid_598520, JString, required = false,
                                 default = nil)
  if valid_598520 != nil:
    section.add "X-Amz-Algorithm", valid_598520
  var valid_598521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598521 = validateParameter(valid_598521, JString, required = false,
                                 default = nil)
  if valid_598521 != nil:
    section.add "X-Amz-SignedHeaders", valid_598521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598523: Call_StartFaceDetection_598511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ## 
  let valid = call_598523.validator(path, query, header, formData, body)
  let scheme = call_598523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598523.url(scheme.get, call_598523.host, call_598523.base,
                         call_598523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598523, url, valid)

proc call*(call_598524: Call_StartFaceDetection_598511; body: JsonNode): Recallable =
  ## startFaceDetection
  ## <p>Starts asynchronous detection of faces in a stored video.</p> <p>Amazon Rekognition Video can detect faces in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceDetection</code> returns a job identifier (<code>JobId</code>) that you use to get the results of the operation. When face detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the results of the face detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceDetection</code>.</p> <p>For more information, see Detecting Faces in a Stored Video in the Amazon Rekognition Developer Guide.</p>
  ##   body: JObject (required)
  var body_598525 = newJObject()
  if body != nil:
    body_598525 = body
  result = call_598524.call(nil, nil, nil, nil, body_598525)

var startFaceDetection* = Call_StartFaceDetection_598511(
    name: "startFaceDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceDetection",
    validator: validate_StartFaceDetection_598512, base: "/",
    url: url_StartFaceDetection_598513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFaceSearch_598526 = ref object of OpenApiRestCall_597390
proc url_StartFaceSearch_598528(protocol: Scheme; host: string; base: string;
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

proc validate_StartFaceSearch_598527(path: JsonNode; query: JsonNode;
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
  var valid_598529 = header.getOrDefault("X-Amz-Target")
  valid_598529 = validateParameter(valid_598529, JString, required = true, default = newJString(
      "RekognitionService.StartFaceSearch"))
  if valid_598529 != nil:
    section.add "X-Amz-Target", valid_598529
  var valid_598530 = header.getOrDefault("X-Amz-Signature")
  valid_598530 = validateParameter(valid_598530, JString, required = false,
                                 default = nil)
  if valid_598530 != nil:
    section.add "X-Amz-Signature", valid_598530
  var valid_598531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598531 = validateParameter(valid_598531, JString, required = false,
                                 default = nil)
  if valid_598531 != nil:
    section.add "X-Amz-Content-Sha256", valid_598531
  var valid_598532 = header.getOrDefault("X-Amz-Date")
  valid_598532 = validateParameter(valid_598532, JString, required = false,
                                 default = nil)
  if valid_598532 != nil:
    section.add "X-Amz-Date", valid_598532
  var valid_598533 = header.getOrDefault("X-Amz-Credential")
  valid_598533 = validateParameter(valid_598533, JString, required = false,
                                 default = nil)
  if valid_598533 != nil:
    section.add "X-Amz-Credential", valid_598533
  var valid_598534 = header.getOrDefault("X-Amz-Security-Token")
  valid_598534 = validateParameter(valid_598534, JString, required = false,
                                 default = nil)
  if valid_598534 != nil:
    section.add "X-Amz-Security-Token", valid_598534
  var valid_598535 = header.getOrDefault("X-Amz-Algorithm")
  valid_598535 = validateParameter(valid_598535, JString, required = false,
                                 default = nil)
  if valid_598535 != nil:
    section.add "X-Amz-Algorithm", valid_598535
  var valid_598536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598536 = validateParameter(valid_598536, JString, required = false,
                                 default = nil)
  if valid_598536 != nil:
    section.add "X-Amz-SignedHeaders", valid_598536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598538: Call_StartFaceSearch_598526; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ## 
  let valid = call_598538.validator(path, query, header, formData, body)
  let scheme = call_598538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598538.url(scheme.get, call_598538.host, call_598538.base,
                         call_598538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598538, url, valid)

proc call*(call_598539: Call_StartFaceSearch_598526; body: JsonNode): Recallable =
  ## startFaceSearch
  ## <p>Starts the asynchronous search for faces in a collection that match the faces of persons detected in a stored video.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartFaceSearch</code> returns a job identifier (<code>JobId</code>) which you use to get the search results once the search has completed. When searching is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. To get the search results, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetFaceSearch</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartFaceSearch</code>. For more information, see <a>procedure-person-search-videos</a>.</p>
  ##   body: JObject (required)
  var body_598540 = newJObject()
  if body != nil:
    body_598540 = body
  result = call_598539.call(nil, nil, nil, nil, body_598540)

var startFaceSearch* = Call_StartFaceSearch_598526(name: "startFaceSearch",
    meth: HttpMethod.HttpPost, host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartFaceSearch",
    validator: validate_StartFaceSearch_598527, base: "/", url: url_StartFaceSearch_598528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLabelDetection_598541 = ref object of OpenApiRestCall_597390
proc url_StartLabelDetection_598543(protocol: Scheme; host: string; base: string;
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

proc validate_StartLabelDetection_598542(path: JsonNode; query: JsonNode;
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
  var valid_598544 = header.getOrDefault("X-Amz-Target")
  valid_598544 = validateParameter(valid_598544, JString, required = true, default = newJString(
      "RekognitionService.StartLabelDetection"))
  if valid_598544 != nil:
    section.add "X-Amz-Target", valid_598544
  var valid_598545 = header.getOrDefault("X-Amz-Signature")
  valid_598545 = validateParameter(valid_598545, JString, required = false,
                                 default = nil)
  if valid_598545 != nil:
    section.add "X-Amz-Signature", valid_598545
  var valid_598546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598546 = validateParameter(valid_598546, JString, required = false,
                                 default = nil)
  if valid_598546 != nil:
    section.add "X-Amz-Content-Sha256", valid_598546
  var valid_598547 = header.getOrDefault("X-Amz-Date")
  valid_598547 = validateParameter(valid_598547, JString, required = false,
                                 default = nil)
  if valid_598547 != nil:
    section.add "X-Amz-Date", valid_598547
  var valid_598548 = header.getOrDefault("X-Amz-Credential")
  valid_598548 = validateParameter(valid_598548, JString, required = false,
                                 default = nil)
  if valid_598548 != nil:
    section.add "X-Amz-Credential", valid_598548
  var valid_598549 = header.getOrDefault("X-Amz-Security-Token")
  valid_598549 = validateParameter(valid_598549, JString, required = false,
                                 default = nil)
  if valid_598549 != nil:
    section.add "X-Amz-Security-Token", valid_598549
  var valid_598550 = header.getOrDefault("X-Amz-Algorithm")
  valid_598550 = validateParameter(valid_598550, JString, required = false,
                                 default = nil)
  if valid_598550 != nil:
    section.add "X-Amz-Algorithm", valid_598550
  var valid_598551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598551 = validateParameter(valid_598551, JString, required = false,
                                 default = nil)
  if valid_598551 != nil:
    section.add "X-Amz-SignedHeaders", valid_598551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598553: Call_StartLabelDetection_598541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ## 
  let valid = call_598553.validator(path, query, header, formData, body)
  let scheme = call_598553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598553.url(scheme.get, call_598553.host, call_598553.base,
                         call_598553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598553, url, valid)

proc call*(call_598554: Call_StartLabelDetection_598541; body: JsonNode): Recallable =
  ## startLabelDetection
  ## <p>Starts asynchronous detection of labels in a stored video.</p> <p>Amazon Rekognition Video can detect labels in a video. Labels are instances of real-world entities. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; concepts like landscape, evening, and nature; and activities like a person getting out of a car or a person skiing.</p> <p>The video must be stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartLabelDetection</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition Video publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>.</p> <p>To get the results of the label detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetLabelDetection</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartLabelDetection</code>.</p> <p/>
  ##   body: JObject (required)
  var body_598555 = newJObject()
  if body != nil:
    body_598555 = body
  result = call_598554.call(nil, nil, nil, nil, body_598555)

var startLabelDetection* = Call_StartLabelDetection_598541(
    name: "startLabelDetection", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartLabelDetection",
    validator: validate_StartLabelDetection_598542, base: "/",
    url: url_StartLabelDetection_598543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartPersonTracking_598556 = ref object of OpenApiRestCall_597390
proc url_StartPersonTracking_598558(protocol: Scheme; host: string; base: string;
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

proc validate_StartPersonTracking_598557(path: JsonNode; query: JsonNode;
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
  var valid_598559 = header.getOrDefault("X-Amz-Target")
  valid_598559 = validateParameter(valid_598559, JString, required = true, default = newJString(
      "RekognitionService.StartPersonTracking"))
  if valid_598559 != nil:
    section.add "X-Amz-Target", valid_598559
  var valid_598560 = header.getOrDefault("X-Amz-Signature")
  valid_598560 = validateParameter(valid_598560, JString, required = false,
                                 default = nil)
  if valid_598560 != nil:
    section.add "X-Amz-Signature", valid_598560
  var valid_598561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598561 = validateParameter(valid_598561, JString, required = false,
                                 default = nil)
  if valid_598561 != nil:
    section.add "X-Amz-Content-Sha256", valid_598561
  var valid_598562 = header.getOrDefault("X-Amz-Date")
  valid_598562 = validateParameter(valid_598562, JString, required = false,
                                 default = nil)
  if valid_598562 != nil:
    section.add "X-Amz-Date", valid_598562
  var valid_598563 = header.getOrDefault("X-Amz-Credential")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Credential", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Security-Token")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Security-Token", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-Algorithm")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Algorithm", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-SignedHeaders", valid_598566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598568: Call_StartPersonTracking_598556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ## 
  let valid = call_598568.validator(path, query, header, formData, body)
  let scheme = call_598568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598568.url(scheme.get, call_598568.host, call_598568.base,
                         call_598568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598568, url, valid)

proc call*(call_598569: Call_StartPersonTracking_598556; body: JsonNode): Recallable =
  ## startPersonTracking
  ## <p>Starts the asynchronous tracking of a person's path in a stored video.</p> <p>Amazon Rekognition Video can track the path of people in a video stored in an Amazon S3 bucket. Use <a>Video</a> to specify the bucket name and the filename of the video. <code>StartPersonTracking</code> returns a job identifier (<code>JobId</code>) which you use to get the results of the operation. When label detection is finished, Amazon Rekognition publishes a completion status to the Amazon Simple Notification Service topic that you specify in <code>NotificationChannel</code>. </p> <p>To get the results of the person detection operation, first check that the status value published to the Amazon SNS topic is <code>SUCCEEDED</code>. If so, call <a>GetPersonTracking</a> and pass the job identifier (<code>JobId</code>) from the initial call to <code>StartPersonTracking</code>.</p>
  ##   body: JObject (required)
  var body_598570 = newJObject()
  if body != nil:
    body_598570 = body
  result = call_598569.call(nil, nil, nil, nil, body_598570)

var startPersonTracking* = Call_StartPersonTracking_598556(
    name: "startPersonTracking", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartPersonTracking",
    validator: validate_StartPersonTracking_598557, base: "/",
    url: url_StartPersonTracking_598558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartProjectVersion_598571 = ref object of OpenApiRestCall_597390
proc url_StartProjectVersion_598573(protocol: Scheme; host: string; base: string;
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

proc validate_StartProjectVersion_598572(path: JsonNode; query: JsonNode;
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
  var valid_598574 = header.getOrDefault("X-Amz-Target")
  valid_598574 = validateParameter(valid_598574, JString, required = true, default = newJString(
      "RekognitionService.StartProjectVersion"))
  if valid_598574 != nil:
    section.add "X-Amz-Target", valid_598574
  var valid_598575 = header.getOrDefault("X-Amz-Signature")
  valid_598575 = validateParameter(valid_598575, JString, required = false,
                                 default = nil)
  if valid_598575 != nil:
    section.add "X-Amz-Signature", valid_598575
  var valid_598576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598576 = validateParameter(valid_598576, JString, required = false,
                                 default = nil)
  if valid_598576 != nil:
    section.add "X-Amz-Content-Sha256", valid_598576
  var valid_598577 = header.getOrDefault("X-Amz-Date")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "X-Amz-Date", valid_598577
  var valid_598578 = header.getOrDefault("X-Amz-Credential")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Credential", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Security-Token")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Security-Token", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Algorithm")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Algorithm", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-SignedHeaders", valid_598581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598583: Call_StartProjectVersion_598571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ## 
  let valid = call_598583.validator(path, query, header, formData, body)
  let scheme = call_598583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598583.url(scheme.get, call_598583.host, call_598583.base,
                         call_598583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598583, url, valid)

proc call*(call_598584: Call_StartProjectVersion_598571; body: JsonNode): Recallable =
  ## startProjectVersion
  ## <p>Starts the running of the version of a model. Starting a model takes a while to complete. To check the current state of the model, use <a>DescribeProjectVersions</a>.</p> <p>Once the model is running, you can detect custom labels in new images by calling <a>DetectCustomLabels</a>.</p> <note> <p>You are charged for the amount of time that the model is running. To stop a running model, call <a>StopProjectVersion</a>.</p> </note> <p>This operation requires permissions to perform the <code>rekognition:StartProjectVersion</code> action.</p>
  ##   body: JObject (required)
  var body_598585 = newJObject()
  if body != nil:
    body_598585 = body
  result = call_598584.call(nil, nil, nil, nil, body_598585)

var startProjectVersion* = Call_StartProjectVersion_598571(
    name: "startProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartProjectVersion",
    validator: validate_StartProjectVersion_598572, base: "/",
    url: url_StartProjectVersion_598573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartStreamProcessor_598586 = ref object of OpenApiRestCall_597390
proc url_StartStreamProcessor_598588(protocol: Scheme; host: string; base: string;
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

proc validate_StartStreamProcessor_598587(path: JsonNode; query: JsonNode;
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
  var valid_598589 = header.getOrDefault("X-Amz-Target")
  valid_598589 = validateParameter(valid_598589, JString, required = true, default = newJString(
      "RekognitionService.StartStreamProcessor"))
  if valid_598589 != nil:
    section.add "X-Amz-Target", valid_598589
  var valid_598590 = header.getOrDefault("X-Amz-Signature")
  valid_598590 = validateParameter(valid_598590, JString, required = false,
                                 default = nil)
  if valid_598590 != nil:
    section.add "X-Amz-Signature", valid_598590
  var valid_598591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598591 = validateParameter(valid_598591, JString, required = false,
                                 default = nil)
  if valid_598591 != nil:
    section.add "X-Amz-Content-Sha256", valid_598591
  var valid_598592 = header.getOrDefault("X-Amz-Date")
  valid_598592 = validateParameter(valid_598592, JString, required = false,
                                 default = nil)
  if valid_598592 != nil:
    section.add "X-Amz-Date", valid_598592
  var valid_598593 = header.getOrDefault("X-Amz-Credential")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = nil)
  if valid_598593 != nil:
    section.add "X-Amz-Credential", valid_598593
  var valid_598594 = header.getOrDefault("X-Amz-Security-Token")
  valid_598594 = validateParameter(valid_598594, JString, required = false,
                                 default = nil)
  if valid_598594 != nil:
    section.add "X-Amz-Security-Token", valid_598594
  var valid_598595 = header.getOrDefault("X-Amz-Algorithm")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Algorithm", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-SignedHeaders", valid_598596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598598: Call_StartStreamProcessor_598586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ## 
  let valid = call_598598.validator(path, query, header, formData, body)
  let scheme = call_598598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598598.url(scheme.get, call_598598.host, call_598598.base,
                         call_598598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598598, url, valid)

proc call*(call_598599: Call_StartStreamProcessor_598586; body: JsonNode): Recallable =
  ## startStreamProcessor
  ## Starts processing a stream processor. You create a stream processor by calling <a>CreateStreamProcessor</a>. To tell <code>StartStreamProcessor</code> which stream processor to start, use the value of the <code>Name</code> field specified in the call to <code>CreateStreamProcessor</code>.
  ##   body: JObject (required)
  var body_598600 = newJObject()
  if body != nil:
    body_598600 = body
  result = call_598599.call(nil, nil, nil, nil, body_598600)

var startStreamProcessor* = Call_StartStreamProcessor_598586(
    name: "startStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StartStreamProcessor",
    validator: validate_StartStreamProcessor_598587, base: "/",
    url: url_StartStreamProcessor_598588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopProjectVersion_598601 = ref object of OpenApiRestCall_597390
proc url_StopProjectVersion_598603(protocol: Scheme; host: string; base: string;
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

proc validate_StopProjectVersion_598602(path: JsonNode; query: JsonNode;
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
  var valid_598604 = header.getOrDefault("X-Amz-Target")
  valid_598604 = validateParameter(valid_598604, JString, required = true, default = newJString(
      "RekognitionService.StopProjectVersion"))
  if valid_598604 != nil:
    section.add "X-Amz-Target", valid_598604
  var valid_598605 = header.getOrDefault("X-Amz-Signature")
  valid_598605 = validateParameter(valid_598605, JString, required = false,
                                 default = nil)
  if valid_598605 != nil:
    section.add "X-Amz-Signature", valid_598605
  var valid_598606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598606 = validateParameter(valid_598606, JString, required = false,
                                 default = nil)
  if valid_598606 != nil:
    section.add "X-Amz-Content-Sha256", valid_598606
  var valid_598607 = header.getOrDefault("X-Amz-Date")
  valid_598607 = validateParameter(valid_598607, JString, required = false,
                                 default = nil)
  if valid_598607 != nil:
    section.add "X-Amz-Date", valid_598607
  var valid_598608 = header.getOrDefault("X-Amz-Credential")
  valid_598608 = validateParameter(valid_598608, JString, required = false,
                                 default = nil)
  if valid_598608 != nil:
    section.add "X-Amz-Credential", valid_598608
  var valid_598609 = header.getOrDefault("X-Amz-Security-Token")
  valid_598609 = validateParameter(valid_598609, JString, required = false,
                                 default = nil)
  if valid_598609 != nil:
    section.add "X-Amz-Security-Token", valid_598609
  var valid_598610 = header.getOrDefault("X-Amz-Algorithm")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Algorithm", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-SignedHeaders", valid_598611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598613: Call_StopProjectVersion_598601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ## 
  let valid = call_598613.validator(path, query, header, formData, body)
  let scheme = call_598613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598613.url(scheme.get, call_598613.host, call_598613.base,
                         call_598613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598613, url, valid)

proc call*(call_598614: Call_StopProjectVersion_598601; body: JsonNode): Recallable =
  ## stopProjectVersion
  ## Stops a running model. The operation might take a while to complete. To check the current status, call <a>DescribeProjectVersions</a>. 
  ##   body: JObject (required)
  var body_598615 = newJObject()
  if body != nil:
    body_598615 = body
  result = call_598614.call(nil, nil, nil, nil, body_598615)

var stopProjectVersion* = Call_StopProjectVersion_598601(
    name: "stopProjectVersion", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopProjectVersion",
    validator: validate_StopProjectVersion_598602, base: "/",
    url: url_StopProjectVersion_598603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopStreamProcessor_598616 = ref object of OpenApiRestCall_597390
proc url_StopStreamProcessor_598618(protocol: Scheme; host: string; base: string;
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

proc validate_StopStreamProcessor_598617(path: JsonNode; query: JsonNode;
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
  var valid_598619 = header.getOrDefault("X-Amz-Target")
  valid_598619 = validateParameter(valid_598619, JString, required = true, default = newJString(
      "RekognitionService.StopStreamProcessor"))
  if valid_598619 != nil:
    section.add "X-Amz-Target", valid_598619
  var valid_598620 = header.getOrDefault("X-Amz-Signature")
  valid_598620 = validateParameter(valid_598620, JString, required = false,
                                 default = nil)
  if valid_598620 != nil:
    section.add "X-Amz-Signature", valid_598620
  var valid_598621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598621 = validateParameter(valid_598621, JString, required = false,
                                 default = nil)
  if valid_598621 != nil:
    section.add "X-Amz-Content-Sha256", valid_598621
  var valid_598622 = header.getOrDefault("X-Amz-Date")
  valid_598622 = validateParameter(valid_598622, JString, required = false,
                                 default = nil)
  if valid_598622 != nil:
    section.add "X-Amz-Date", valid_598622
  var valid_598623 = header.getOrDefault("X-Amz-Credential")
  valid_598623 = validateParameter(valid_598623, JString, required = false,
                                 default = nil)
  if valid_598623 != nil:
    section.add "X-Amz-Credential", valid_598623
  var valid_598624 = header.getOrDefault("X-Amz-Security-Token")
  valid_598624 = validateParameter(valid_598624, JString, required = false,
                                 default = nil)
  if valid_598624 != nil:
    section.add "X-Amz-Security-Token", valid_598624
  var valid_598625 = header.getOrDefault("X-Amz-Algorithm")
  valid_598625 = validateParameter(valid_598625, JString, required = false,
                                 default = nil)
  if valid_598625 != nil:
    section.add "X-Amz-Algorithm", valid_598625
  var valid_598626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = nil)
  if valid_598626 != nil:
    section.add "X-Amz-SignedHeaders", valid_598626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598628: Call_StopStreamProcessor_598616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ## 
  let valid = call_598628.validator(path, query, header, formData, body)
  let scheme = call_598628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598628.url(scheme.get, call_598628.host, call_598628.base,
                         call_598628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598628, url, valid)

proc call*(call_598629: Call_StopStreamProcessor_598616; body: JsonNode): Recallable =
  ## stopStreamProcessor
  ## Stops a running stream processor that was created by <a>CreateStreamProcessor</a>.
  ##   body: JObject (required)
  var body_598630 = newJObject()
  if body != nil:
    body_598630 = body
  result = call_598629.call(nil, nil, nil, nil, body_598630)

var stopStreamProcessor* = Call_StopStreamProcessor_598616(
    name: "stopStreamProcessor", meth: HttpMethod.HttpPost,
    host: "rekognition.amazonaws.com",
    route: "/#X-Amz-Target=RekognitionService.StopStreamProcessor",
    validator: validate_StopStreamProcessor_598617, base: "/",
    url: url_StopStreamProcessor_598618, schemes: {Scheme.Https, Scheme.Http})
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
