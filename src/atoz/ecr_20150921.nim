
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EC2 Container Registry
## version: 2015-09-21
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic Container Registry</fullname> <p>Amazon Elastic Container Registry (Amazon ECR) is a managed Docker registry service. Customers can use the familiar Docker CLI to push, pull, and manage images. Amazon ECR provides a secure, scalable, and reliable registry. Amazon ECR supports private Docker repositories with resource-based permissions using IAM so that specific users or Amazon EC2 instances can access repositories and images. Developers can use the Docker CLI to author and manage images.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ecr/
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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.ecr.us-west-2.amazonaws.com",
                           "eu-west-2": "api.ecr.eu-west-2.amazonaws.com", "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com", "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
                           "us-east-2": "api.ecr.us-east-2.amazonaws.com",
                           "us-east-1": "api.ecr.us-east-1.amazonaws.com", "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
                           "eu-north-1": "api.ecr.eu-north-1.amazonaws.com", "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.ecr.us-west-1.amazonaws.com", "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
                           "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.ecr.eu-west-1.amazonaws.com", "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.ecr.us-west-2.amazonaws.com",
      "eu-west-2": "api.ecr.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
      "us-east-2": "api.ecr.us-east-2.amazonaws.com",
      "us-east-1": "api.ecr.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
      "eu-north-1": "api.ecr.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.ecr.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
      "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
      "eu-west-1": "api.ecr.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ecr"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchCheckLayerAvailability_600768 = ref object of OpenApiRestCall_600426
proc url_BatchCheckLayerAvailability_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchCheckLayerAvailability_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_BatchCheckLayerAvailability_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_BatchCheckLayerAvailability_600768; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_600768(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_600769, base: "/",
    url: url_BatchCheckLayerAvailability_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_601037 = ref object of OpenApiRestCall_600426
proc url_BatchDeleteImage_601039(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDeleteImage_601038(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchDeleteImage_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchDeleteImage_601037; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchDeleteImage* = Call_BatchDeleteImage_601037(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_601038, base: "/",
    url: url_BatchDeleteImage_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_601052 = ref object of OpenApiRestCall_600426
proc url_BatchGetImage_601054(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetImage_601053(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_BatchGetImage_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_BatchGetImage_601052; body: JsonNode): Recallable =
  ## batchGetImage
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var batchGetImage* = Call_BatchGetImage_601052(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_601053, base: "/", url: url_BatchGetImage_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_601067 = ref object of OpenApiRestCall_600426
proc url_CompleteLayerUpload_601069(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CompleteLayerUpload_601068(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CompleteLayerUpload_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CompleteLayerUpload_601067; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var completeLayerUpload* = Call_CompleteLayerUpload_601067(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_601068, base: "/",
    url: url_CompleteLayerUpload_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_601082 = ref object of OpenApiRestCall_600426
proc url_CreateRepository_601084(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRepository_601083(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an image repository.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateRepository_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an image repository.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateRepository_601082; body: JsonNode): Recallable =
  ## createRepository
  ## Creates an image repository.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createRepository* = Call_CreateRepository_601082(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_601083, base: "/",
    url: url_CreateRepository_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteLifecyclePolicy_601099(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteLifecyclePolicy_601098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified lifecycle policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteLifecyclePolicy_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteLifecyclePolicy_601097; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_601097(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_601098, base: "/",
    url: url_DeleteLifecyclePolicy_601099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_601112 = ref object of OpenApiRestCall_600426
proc url_DeleteRepository_601114(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRepository_601113(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DeleteRepository_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeleteRepository_601112; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deleteRepository* = Call_DeleteRepository_601112(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_601113, base: "/",
    url: url_DeleteRepository_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_601127 = ref object of OpenApiRestCall_600426
proc url_DeleteRepositoryPolicy_601129(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRepositoryPolicy_601128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the repository policy from a specified repository.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeleteRepositoryPolicy_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the repository policy from a specified repository.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeleteRepositoryPolicy_601127; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy from a specified repository.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_601127(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_601128, base: "/",
    url: url_DeleteRepositoryPolicy_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_601142 = ref object of OpenApiRestCall_600426
proc url_DescribeImages_601144(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeImages_601143(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601145 = query.getOrDefault("maxResults")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "maxResults", valid_601145
  var valid_601146 = query.getOrDefault("nextToken")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "nextToken", valid_601146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601149 = header.getOrDefault("X-Amz-Target")
  valid_601149 = validateParameter(valid_601149, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
  if valid_601149 != nil:
    section.add "X-Amz-Target", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_DescribeImages_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_DescribeImages_601142; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601158 = newJObject()
  var body_601159 = newJObject()
  add(query_601158, "maxResults", newJString(maxResults))
  add(query_601158, "nextToken", newJString(nextToken))
  if body != nil:
    body_601159 = body
  result = call_601157.call(nil, query_601158, nil, nil, body_601159)

var describeImages* = Call_DescribeImages_601142(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_601143, base: "/", url: url_DescribeImages_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_601161 = ref object of OpenApiRestCall_600426
proc url_DescribeRepositories_601163(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRepositories_601162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes image repositories in a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601164 = query.getOrDefault("maxResults")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "maxResults", valid_601164
  var valid_601165 = query.getOrDefault("nextToken")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "nextToken", valid_601165
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601168 = header.getOrDefault("X-Amz-Target")
  valid_601168 = validateParameter(valid_601168, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
  if valid_601168 != nil:
    section.add "X-Amz-Target", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_DescribeRepositories_601161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_DescribeRepositories_601161; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601177 = newJObject()
  var body_601178 = newJObject()
  add(query_601177, "maxResults", newJString(maxResults))
  add(query_601177, "nextToken", newJString(nextToken))
  if body != nil:
    body_601178 = body
  result = call_601176.call(nil, query_601177, nil, nil, body_601178)

var describeRepositories* = Call_DescribeRepositories_601161(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_601162, base: "/",
    url: url_DescribeRepositories_601163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_601179 = ref object of OpenApiRestCall_600426
proc url_GetAuthorizationToken_601181(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAuthorizationToken_601180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601184 = header.getOrDefault("X-Amz-Target")
  valid_601184 = validateParameter(valid_601184, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
  if valid_601184 != nil:
    section.add "X-Amz-Target", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_GetAuthorizationToken_601179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_GetAuthorizationToken_601179; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ##   body: JObject (required)
  var body_601193 = newJObject()
  if body != nil:
    body_601193 = body
  result = call_601192.call(nil, nil, nil, nil, body_601193)

var getAuthorizationToken* = Call_GetAuthorizationToken_601179(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_601180, base: "/",
    url: url_GetAuthorizationToken_601181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_601194 = ref object of OpenApiRestCall_600426
proc url_GetDownloadUrlForLayer_601196(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadUrlForLayer_601195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601199 = header.getOrDefault("X-Amz-Target")
  valid_601199 = validateParameter(valid_601199, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
  if valid_601199 != nil:
    section.add "X-Amz-Target", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Content-Sha256", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Algorithm")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Algorithm", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Signature")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Signature", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-SignedHeaders", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Credential")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Credential", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601206: Call_GetDownloadUrlForLayer_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_601206.validator(path, query, header, formData, body)
  let scheme = call_601206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601206.url(scheme.get, call_601206.host, call_601206.base,
                         call_601206.route, valid.getOrDefault("path"))
  result = hook(call_601206, url, valid)

proc call*(call_601207: Call_GetDownloadUrlForLayer_601194; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_601208 = newJObject()
  if body != nil:
    body_601208 = body
  result = call_601207.call(nil, nil, nil, nil, body_601208)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_601194(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_601195, base: "/",
    url: url_GetDownloadUrlForLayer_601196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_601209 = ref object of OpenApiRestCall_600426
proc url_GetLifecyclePolicy_601211(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLifecyclePolicy_601210(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the specified lifecycle policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601212 = header.getOrDefault("X-Amz-Date")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Date", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Security-Token")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Security-Token", valid_601213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601214 = header.getOrDefault("X-Amz-Target")
  valid_601214 = validateParameter(valid_601214, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
  if valid_601214 != nil:
    section.add "X-Amz-Target", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601221: Call_GetLifecyclePolicy_601209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified lifecycle policy.
  ## 
  let valid = call_601221.validator(path, query, header, formData, body)
  let scheme = call_601221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601221.url(scheme.get, call_601221.host, call_601221.base,
                         call_601221.route, valid.getOrDefault("path"))
  result = hook(call_601221, url, valid)

proc call*(call_601222: Call_GetLifecyclePolicy_601209; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the specified lifecycle policy.
  ##   body: JObject (required)
  var body_601223 = newJObject()
  if body != nil:
    body_601223 = body
  result = call_601222.call(nil, nil, nil, nil, body_601223)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_601209(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_601210, base: "/",
    url: url_GetLifecyclePolicy_601211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_601224 = ref object of OpenApiRestCall_600426
proc url_GetLifecyclePolicyPreview_601226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetLifecyclePolicyPreview_601225(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the results of the specified lifecycle policy preview request.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601227 = header.getOrDefault("X-Amz-Date")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Date", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Security-Token")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Security-Token", valid_601228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601229 = header.getOrDefault("X-Amz-Target")
  valid_601229 = validateParameter(valid_601229, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_601229 != nil:
    section.add "X-Amz-Target", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601236: Call_GetLifecyclePolicyPreview_601224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  let valid = call_601236.validator(path, query, header, formData, body)
  let scheme = call_601236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601236.url(scheme.get, call_601236.host, call_601236.base,
                         call_601236.route, valid.getOrDefault("path"))
  result = hook(call_601236, url, valid)

proc call*(call_601237: Call_GetLifecyclePolicyPreview_601224; body: JsonNode): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the specified lifecycle policy preview request.
  ##   body: JObject (required)
  var body_601238 = newJObject()
  if body != nil:
    body_601238 = body
  result = call_601237.call(nil, nil, nil, nil, body_601238)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_601224(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_601225, base: "/",
    url: url_GetLifecyclePolicyPreview_601226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_601239 = ref object of OpenApiRestCall_600426
proc url_GetRepositoryPolicy_601241(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRepositoryPolicy_601240(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the repository policy for a specified repository.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_GetRepositoryPolicy_601239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the repository policy for a specified repository.
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_GetRepositoryPolicy_601239; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for a specified repository.
  ##   body: JObject (required)
  var body_601253 = newJObject()
  if body != nil:
    body_601253 = body
  result = call_601252.call(nil, nil, nil, nil, body_601253)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_601239(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_601240, base: "/",
    url: url_GetRepositoryPolicy_601241, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_601254 = ref object of OpenApiRestCall_600426
proc url_InitiateLayerUpload_601256(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InitiateLayerUpload_601255(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601259 = header.getOrDefault("X-Amz-Target")
  valid_601259 = validateParameter(valid_601259, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_601259 != nil:
    section.add "X-Amz-Target", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_InitiateLayerUpload_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_InitiateLayerUpload_601254; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_601268 = newJObject()
  if body != nil:
    body_601268 = body
  result = call_601267.call(nil, nil, nil, nil, body_601268)

var initiateLayerUpload* = Call_InitiateLayerUpload_601254(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_601255, base: "/",
    url: url_InitiateLayerUpload_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_601269 = ref object of OpenApiRestCall_600426
proc url_ListImages_601271(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListImages_601270(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601272 = query.getOrDefault("maxResults")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "maxResults", valid_601272
  var valid_601273 = query.getOrDefault("nextToken")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "nextToken", valid_601273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601274 = header.getOrDefault("X-Amz-Date")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "X-Amz-Date", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Security-Token")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Security-Token", valid_601275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601276 = header.getOrDefault("X-Amz-Target")
  valid_601276 = validateParameter(valid_601276, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_601276 != nil:
    section.add "X-Amz-Target", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Content-Sha256", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Algorithm")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Algorithm", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Signature")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Signature", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-SignedHeaders", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Credential")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Credential", valid_601281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_ListImages_601269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_ListImages_601269; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601285 = newJObject()
  var body_601286 = newJObject()
  add(query_601285, "maxResults", newJString(maxResults))
  add(query_601285, "nextToken", newJString(nextToken))
  if body != nil:
    body_601286 = body
  result = call_601284.call(nil, query_601285, nil, nil, body_601286)

var listImages* = Call_ListImages_601269(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                      validator: validate_ListImages_601270,
                                      base: "/", url: url_ListImages_601271,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601287 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601289(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601288(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an Amazon ECR resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601290 = header.getOrDefault("X-Amz-Date")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Date", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Security-Token")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Security-Token", valid_601291
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601292 = header.getOrDefault("X-Amz-Target")
  valid_601292 = validateParameter(valid_601292, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_601292 != nil:
    section.add "X-Amz-Target", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Content-Sha256", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Algorithm")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Algorithm", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Signature")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Signature", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-SignedHeaders", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Credential")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Credential", valid_601297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601299: Call_ListTagsForResource_601287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_601299.validator(path, query, header, formData, body)
  let scheme = call_601299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601299.url(scheme.get, call_601299.host, call_601299.base,
                         call_601299.route, valid.getOrDefault("path"))
  result = hook(call_601299, url, valid)

proc call*(call_601300: Call_ListTagsForResource_601287; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_601301 = newJObject()
  if body != nil:
    body_601301 = body
  result = call_601300.call(nil, nil, nil, nil, body_601301)

var listTagsForResource* = Call_ListTagsForResource_601287(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_601288, base: "/",
    url: url_ListTagsForResource_601289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_601302 = ref object of OpenApiRestCall_600426
proc url_PutImage_601304(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutImage_601303(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601305 = header.getOrDefault("X-Amz-Date")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Date", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Security-Token")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Security-Token", valid_601306
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601307 = header.getOrDefault("X-Amz-Target")
  valid_601307 = validateParameter(valid_601307, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_601307 != nil:
    section.add "X-Amz-Target", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601314: Call_PutImage_601302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_601314.validator(path, query, header, formData, body)
  let scheme = call_601314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601314.url(scheme.get, call_601314.host, call_601314.base,
                         call_601314.route, valid.getOrDefault("path"))
  result = hook(call_601314, url, valid)

proc call*(call_601315: Call_PutImage_601302; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_601316 = newJObject()
  if body != nil:
    body_601316 = body
  result = call_601315.call(nil, nil, nil, nil, body_601316)

var putImage* = Call_PutImage_601302(name: "putImage", meth: HttpMethod.HttpPost,
                                  host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                  validator: validate_PutImage_601303, base: "/",
                                  url: url_PutImage_601304,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_601317 = ref object of OpenApiRestCall_600426
proc url_PutImageTagMutability_601319(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutImageTagMutability_601318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image tag mutability settings for a repository.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601320 = header.getOrDefault("X-Amz-Date")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Date", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-Security-Token")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Security-Token", valid_601321
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601322 = header.getOrDefault("X-Amz-Target")
  valid_601322 = validateParameter(valid_601322, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_601322 != nil:
    section.add "X-Amz-Target", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Content-Sha256", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Algorithm")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Algorithm", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Signature")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Signature", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-SignedHeaders", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Credential")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Credential", valid_601327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601329: Call_PutImageTagMutability_601317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image tag mutability settings for a repository.
  ## 
  let valid = call_601329.validator(path, query, header, formData, body)
  let scheme = call_601329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601329.url(scheme.get, call_601329.host, call_601329.base,
                         call_601329.route, valid.getOrDefault("path"))
  result = hook(call_601329, url, valid)

proc call*(call_601330: Call_PutImageTagMutability_601317; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for a repository.
  ##   body: JObject (required)
  var body_601331 = newJObject()
  if body != nil:
    body_601331 = body
  result = call_601330.call(nil, nil, nil, nil, body_601331)

var putImageTagMutability* = Call_PutImageTagMutability_601317(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_601318, base: "/",
    url: url_PutImageTagMutability_601319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_601332 = ref object of OpenApiRestCall_600426
proc url_PutLifecyclePolicy_601334(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutLifecyclePolicy_601333(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601335 = header.getOrDefault("X-Amz-Date")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Date", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Security-Token")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Security-Token", valid_601336
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601337 = header.getOrDefault("X-Amz-Target")
  valid_601337 = validateParameter(valid_601337, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_601337 != nil:
    section.add "X-Amz-Target", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Content-Sha256", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Algorithm")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Algorithm", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Signature")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Signature", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-SignedHeaders", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Credential")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Credential", valid_601342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601344: Call_PutLifecyclePolicy_601332; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_601344.validator(path, query, header, formData, body)
  let scheme = call_601344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601344.url(scheme.get, call_601344.host, call_601344.base,
                         call_601344.route, valid.getOrDefault("path"))
  result = hook(call_601344, url, valid)

proc call*(call_601345: Call_PutLifecyclePolicy_601332; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_601346 = newJObject()
  if body != nil:
    body_601346 = body
  result = call_601345.call(nil, nil, nil, nil, body_601346)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_601332(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_601333, base: "/",
    url: url_PutLifecyclePolicy_601334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_601347 = ref object of OpenApiRestCall_600426
proc url_SetRepositoryPolicy_601349(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetRepositoryPolicy_601348(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601350 = header.getOrDefault("X-Amz-Date")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Date", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Security-Token")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Security-Token", valid_601351
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601352 = header.getOrDefault("X-Amz-Target")
  valid_601352 = validateParameter(valid_601352, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_601352 != nil:
    section.add "X-Amz-Target", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Content-Sha256", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Algorithm")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Algorithm", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Signature")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Signature", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-SignedHeaders", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Credential")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Credential", valid_601357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601359: Call_SetRepositoryPolicy_601347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_601359.validator(path, query, header, formData, body)
  let scheme = call_601359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601359.url(scheme.get, call_601359.host, call_601359.base,
                         call_601359.route, valid.getOrDefault("path"))
  result = hook(call_601359, url, valid)

proc call*(call_601360: Call_SetRepositoryPolicy_601347; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_601361 = newJObject()
  if body != nil:
    body_601361 = body
  result = call_601360.call(nil, nil, nil, nil, body_601361)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_601347(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_601348, base: "/",
    url: url_SetRepositoryPolicy_601349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_601362 = ref object of OpenApiRestCall_600426
proc url_StartLifecyclePolicyPreview_601364(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartLifecyclePolicyPreview_601363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601365 = header.getOrDefault("X-Amz-Date")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Date", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Security-Token")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Security-Token", valid_601366
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601367 = header.getOrDefault("X-Amz-Target")
  valid_601367 = validateParameter(valid_601367, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_601367 != nil:
    section.add "X-Amz-Target", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Content-Sha256", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Algorithm")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Algorithm", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Signature")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Signature", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-SignedHeaders", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Credential")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Credential", valid_601372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601374: Call_StartLifecyclePolicyPreview_601362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ## 
  let valid = call_601374.validator(path, query, header, formData, body)
  let scheme = call_601374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601374.url(scheme.get, call_601374.host, call_601374.base,
                         call_601374.route, valid.getOrDefault("path"))
  result = hook(call_601374, url, valid)

proc call*(call_601375: Call_StartLifecyclePolicyPreview_601362; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ##   body: JObject (required)
  var body_601376 = newJObject()
  if body != nil:
    body_601376 = body
  result = call_601375.call(nil, nil, nil, nil, body_601376)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_601362(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_601363, base: "/",
    url: url_StartLifecyclePolicyPreview_601364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601377 = ref object of OpenApiRestCall_600426
proc url_TagResource_601379(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601378(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601380 = header.getOrDefault("X-Amz-Date")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Date", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Security-Token")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Security-Token", valid_601381
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601382 = header.getOrDefault("X-Amz-Target")
  valid_601382 = validateParameter(valid_601382, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_601382 != nil:
    section.add "X-Amz-Target", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Content-Sha256", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Algorithm")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Algorithm", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Signature")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Signature", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-SignedHeaders", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Credential")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Credential", valid_601387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601389: Call_TagResource_601377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_601389.validator(path, query, header, formData, body)
  let scheme = call_601389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601389.url(scheme.get, call_601389.host, call_601389.base,
                         call_601389.route, valid.getOrDefault("path"))
  result = hook(call_601389, url, valid)

proc call*(call_601390: Call_TagResource_601377; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_601391 = newJObject()
  if body != nil:
    body_601391 = body
  result = call_601390.call(nil, nil, nil, nil, body_601391)

var tagResource* = Call_TagResource_601377(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
                                        validator: validate_TagResource_601378,
                                        base: "/", url: url_TagResource_601379,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601392 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601394(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601393(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601395 = header.getOrDefault("X-Amz-Date")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Date", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Security-Token")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Security-Token", valid_601396
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601397 = header.getOrDefault("X-Amz-Target")
  valid_601397 = validateParameter(valid_601397, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_601397 != nil:
    section.add "X-Amz-Target", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Content-Sha256", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Algorithm")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Algorithm", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Signature")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Signature", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-SignedHeaders", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Credential")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Credential", valid_601402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601404: Call_UntagResource_601392; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_601404.validator(path, query, header, formData, body)
  let scheme = call_601404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601404.url(scheme.get, call_601404.host, call_601404.base,
                         call_601404.route, valid.getOrDefault("path"))
  result = hook(call_601404, url, valid)

proc call*(call_601405: Call_UntagResource_601392; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_601406 = newJObject()
  if body != nil:
    body_601406 = body
  result = call_601405.call(nil, nil, nil, nil, body_601406)

var untagResource* = Call_UntagResource_601392(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_601393, base: "/", url: url_UntagResource_601394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_601407 = ref object of OpenApiRestCall_600426
proc url_UploadLayerPart_601409(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UploadLayerPart_601408(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601410 = header.getOrDefault("X-Amz-Date")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Date", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Security-Token")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Security-Token", valid_601411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601412 = header.getOrDefault("X-Amz-Target")
  valid_601412 = validateParameter(valid_601412, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_601412 != nil:
    section.add "X-Amz-Target", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Content-Sha256", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Algorithm")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Algorithm", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Signature")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Signature", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-SignedHeaders", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Credential")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Credential", valid_601417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601419: Call_UploadLayerPart_601407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_601419.validator(path, query, header, formData, body)
  let scheme = call_601419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601419.url(scheme.get, call_601419.host, call_601419.base,
                         call_601419.route, valid.getOrDefault("path"))
  result = hook(call_601419, url, valid)

proc call*(call_601420: Call_UploadLayerPart_601407; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_601421 = newJObject()
  if body != nil:
    body_601421 = body
  result = call_601420.call(nil, nil, nil, nil, body_601421)

var uploadLayerPart* = Call_UploadLayerPart_601407(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_601408, base: "/", url: url_UploadLayerPart_601409,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
